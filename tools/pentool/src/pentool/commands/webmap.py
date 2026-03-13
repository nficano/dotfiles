"""Web surface mapping command that discovers directories, historical URLs, and subdomains.

This module performs comprehensive web surface discovery by orchestrating multiple
specialized tools to map the attack surface of a target domain:

- gobuster: Directory and file brute-forcing tool that discovers web paths by
  testing common directory and file names from wordlists. Uses wildcard detection,
  follows redirects, and identifies accessible paths with their HTTP status codes
  and response lengths. Supports custom wordlists or defaults to common security
  wordlists (SecLists, DirBuster).

- waybackurls: Historical URL discovery tool that queries the Wayback Machine
  archive to find previously indexed URLs for the target domain. Discovers old
  endpoints, parameters, and file paths that may still be accessible or reveal
  information about the application structure. Results are limited by depth setting
  (depth * 500 URLs) to manage output size.

- amass: Passive subdomain enumeration tool that aggregates subdomain information
  from various OSINT sources without actively probing targets. Discovers subdomains
  through DNS data, certificate transparency logs, and other passive intelligence
  sources, expanding the attack surface beyond the primary domain.

- httpx: HTTP probe tool that verifies discovered URLs and subdomains for
  accessibility. Extracts HTTP metadata including status codes, page titles,
  content lengths, and technology stack information. Runs with configurable
  thread count for efficient large-scale verification.

Targets are provided as a base URL, from which the domain is extracted. The module
runs discovery tools in parallel, then aggregates all discovered paths, URLs,
and subdomains into a unified target list. httpx verifies accessibility of all
discovered endpoints, producing a comprehensive web surface map.

Results include discovered directories with status codes, historical URLs from
archive services, enumerated subdomains, and verified HTTP endpoints with their
metadata. All findings are consolidated into both JSON summary reports and CSV
exports for easy analysis and integration with other tools.

Supports result caching, configurable discovery depth (limits historical URL count),
custom wordlists for directory brute-forcing, and adjustable HTTP probe rates
for balancing speed against target responsiveness.
"""

from __future__ import annotations

import csv
import json
import logging
from pathlib import Path
from typing import Dict, List, Optional
from urllib.parse import urlparse

from pentool.commands import WebMapOptions
from pentool.common import check_cache
from pentool.docker_runner import DockerRunner
from pentool.parsers import parse_httpx_entries
from pentool.utils import CacheKey, load_json, utc_timestamp, write_json

logger = logging.getLogger(__name__)

DEFAULT_WORDLISTS = (
    "/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt",
    "/usr/share/seclists/Discovery/Web-Content/common.txt",
    "/usr/share/wordlists/dirbuster/directory-list-2.3-small.txt",
)


# ──────────────────────────────────────────────────────────────────────────────
# Setup and initialization
# ──────────────────────────────────────────────────────────────────────────────


def _descriptor(options: WebMapOptions) -> str:
    """Generate descriptor string from webmap options."""
    return f"webmap:{options.url}"


def _check_cache(runner: DockerRunner, key: CacheKey) -> Optional[Path]:
    """Check if cached webmap results exist and return summary path if found."""
    return check_cache(runner, key, "webmap.json")


def _parse_url(url: str) -> tuple[str, str]:
    """Parse URL and extract domain and netloc."""
    parsed = urlparse(url)
    domain = parsed.hostname or ""
    if not domain:
        raise RuntimeError("Invalid target URL")
    return domain, parsed.netloc


def _write_target_data(
    run_dir: Path, url: str, domain: str, netloc: str
) -> None:
    """Write target metadata to JSON file."""
    target_data = {"url": url, "domain": domain, "netloc": netloc}
    write_json(run_dir / "target.json", target_data)


def _resolve_wordlist(
    run_dir: Path, run_rel: str, provided: Optional[Path]
) -> str:
    """Resolve wordlist path, copying custom wordlist if provided."""
    if provided:
        if not provided.exists():
            raise RuntimeError(f"Wordlist not found: {provided}")
        destination = run_dir / "wordlist.txt"
        destination.write_text(
            provided.read_text(encoding="utf-8"), encoding="utf-8"
        )
        return f"/work/{run_rel}/wordlist.txt"
    return DEFAULT_WORDLISTS[0]


# ──────────────────────────────────────────────────────────────────────────────
# Tool execution
# ──────────────────────────────────────────────────────────────────────────────


def _run_gobuster(
    runner: DockerRunner, run_rel: str, url: str, wordlist_path: str, env: dict
) -> None:
    """Run gobuster directory scan."""
    logger.info("gobuster against %s", url)
    gobuster_cmd = [
        "gobuster",
        "dir",
        "-u",
        url,
        "-w",
        wordlist_path,
        "--timeout",
        "5s",
        "--no-error",
        "--follow-redirect",
        "-q",
        "--delay",
        "200ms",
        "--wildcard",
        "--add-slash",
        "--json",
        "-o",
        f"/work/{run_rel}/gobuster.json",
    ]
    result = runner.run(gobuster_cmd, env, check=False)
    if result.returncode != 0:
        logger.warning("gobuster exited with code %s", result.returncode)


def _run_waybackurls(
    runner: DockerRunner, run_dir: Path, domain: str, depth: int, env: dict
) -> None:
    """Run waybackurls historical URL discovery."""
    logger.info("waybackurls %s", domain)
    wayback_code, wayback_output = runner.run_collect(
        ["waybackurls", domain],
        env,
        allow_failure=True,
    )
    limit = depth * 500
    wayback_lines = wayback_output.splitlines()[:limit]
    wayback_path = run_dir / "waybackurls.txt"
    wayback_path.write_text(
        "\n".join(wayback_lines) + ("\n" if wayback_lines else ""),
        encoding="utf-8",
    )
    if wayback_code != 0:
        logger.warning("waybackurls exited with code %s", wayback_code)


def _run_amass(
    runner: DockerRunner, run_dir: Path, domain: str, env: dict
) -> None:
    """Run amass passive subdomain enumeration."""
    logger.info("amass passive %s", domain)
    amass_code, amass_output = runner.run_collect(
        ["amass", "enum", "-passive", "-d", domain],
        env,
        allow_failure=True,
    )
    (run_dir / "amass.txt").write_text(amass_output, encoding="utf-8")
    if amass_code != 0:
        logger.warning("amass exited with code %s", amass_code)


def _run_httpx(
    runner: DockerRunner, run_rel: str, rate: int, env: dict
) -> None:
    """Run httpx HTTP verification."""
    logger.info("httpx verification")
    httpx_cmd = [
        "httpx",
        "-l",
        f"/work/{run_rel}/httpx-targets.txt",
        "-json",
        "-o",
        f"/work/{run_rel}/httpx.json",
        "-threads",
        str(rate),
        "-silent",
    ]
    httpx_result = runner.run(httpx_cmd, env, check=False)
    if httpx_result.returncode != 0:
        logger.warning("httpx exited with code %s", httpx_result.returncode)


# ──────────────────────────────────────────────────────────────────────────────
# Result parsing
# ──────────────────────────────────────────────────────────────────────────────


def _parse_gobuster_line(line: str) -> Optional[Dict[str, object]]:
    """Parse a single line from gobuster JSON output."""
    record = line.strip()
    if not record:
        return None
    try:
        data = json.loads(record)
    except json.JSONDecodeError:
        return None
    return {
        "path": data.get("path"),
        "status": data.get("status"),
        "length": data.get("length"),
    }


def _parse_gobuster_results(
    run_dir: Path, base_url: str
) -> List[Dict[str, object]]:
    """Parse gobuster JSON results."""
    paths: List[Dict[str, object]] = []
    gobuster_path = run_dir / "gobuster.json"
    if not gobuster_path.exists():
        return paths

    with gobuster_path.open("r", encoding="utf-8", errors="ignore") as fh:
        for line in fh:
            parsed = _parse_gobuster_line(line)
            if parsed:
                paths.append(parsed)
    return paths


def _parse_waybackurls_results(run_dir: Path, depth: int) -> List[str]:
    """Parse waybackurls historical URLs."""
    historical: List[str] = []
    wayback_path = run_dir / "waybackurls.txt"
    if not wayback_path.exists():
        return historical

    limit = depth * 1000
    with wayback_path.open("r", encoding="utf-8", errors="ignore") as fh:
        for idx, line in enumerate(fh):
            if idx >= limit:
                break
            url = line.strip()
            if url:
                historical.append(url)
    return historical


def _parse_amass_results(run_dir: Path) -> List[str]:
    """Parse amass subdomain results."""
    subdomains: List[str] = []
    amass_path = run_dir / "amass.txt"
    if not amass_path.exists():
        return subdomains

    with amass_path.open("r", encoding="utf-8", errors="ignore") as fh:
        for line in fh:
            host = line.strip()
            if host:
                subdomains.append(host)
    return subdomains


def _parse_httpx_entries(httpx_path: Path) -> List[Dict[str, object]]:
    """Parse httpx JSON entries."""
    return parse_httpx_entries(httpx_path)


# ──────────────────────────────────────────────────────────────────────────────
# Metadata building
# ──────────────────────────────────────────────────────────────────────────────


def _collect_unique_urls(
    base_url: str,
    paths: List[Dict[str, object]],
    historical: List[str],
    subdomains: List[str],
) -> set[str]:
    """Collect all unique URLs from various sources."""
    seen = {base_url}

    for path_data in paths:
        path = path_data.get("path", "")
        full = base_url.rstrip("/") + "/" + path.lstrip("/")
        seen.add(full)

    seen.update(historical)

    for host in subdomains:
        seen.add(f"https://{host}")

    return seen


def _write_httpx_targets(run_dir: Path, seen: set[str]) -> None:
    """Write unique URLs to httpx targets file."""
    httpx_targets = run_dir / "httpx-targets.txt"
    with httpx_targets.open("w", encoding="utf-8") as fh:
        for url in sorted(filter(None, seen)):
            fh.write(f"{url}\n")


def _build_metadata(run_dir: Path, depth: int) -> Dict[str, object]:
    """Build metadata from all discovery sources."""
    target = load_json(run_dir / "target.json")
    base_url = target.get("url", "")

    paths = _parse_gobuster_results(run_dir, base_url)
    historical = _parse_waybackurls_results(run_dir, depth)
    subdomains = _parse_amass_results(run_dir)

    seen = _collect_unique_urls(base_url, paths, historical, subdomains)
    _write_httpx_targets(run_dir, seen)

    meta = {"paths": paths, "historical": historical, "subdomains": subdomains}
    write_json(run_dir / "webmap-meta.json", meta)
    return meta


# ──────────────────────────────────────────────────────────────────────────────
# Summary building
# ──────────────────────────────────────────────────────────────────────────────


def _write_csv_rows(
    writer: csv.writer,
    paths: List[Dict[str, object]],
    historical: List[str],
    subdomains: List[str],
    http_entries: List[Dict[str, object]],
) -> None:
    """Write CSV rows for all discovery data."""
    for item in paths:
        writer.writerow(
            [
                "directory",
                "gobuster",
                item.get("path"),
                item.get("status"),
                item.get("length"),
            ]
        )

    for url in historical:
        writer.writerow(["historical-url", "waybackurls", url, "", ""])

    for host in subdomains:
        writer.writerow(["subdomain", "amass", host, "", ""])

    for entry in http_entries:
        writer.writerow(
            [
                "http",
                "httpx",
                entry.get("url"),
                entry.get("status_code"),
                entry.get("title"),
            ]
        )


def _write_csv_summary(
    run_dir: Path,
    paths: List[Dict[str, object]],
    historical: List[str],
    subdomains: List[str],
    http_entries: List[Dict[str, object]],
) -> None:
    """Write CSV summary file."""
    csv_path = run_dir / "webmap.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["category", "source", "value", "status", "notes"])
        _write_csv_rows(writer, paths, historical, subdomains, http_entries)


def _build_summary(run_dir: Path, depth: int, rate: int) -> Dict[str, object]:
    """Build final summary JSON with all discovery data."""
    target = load_json(run_dir / "target.json")
    meta = load_json(run_dir / "webmap-meta.json")
    http_entries = _parse_httpx_entries(run_dir / "httpx.json")

    paths = meta.get("paths", [])
    historical = meta.get("historical", [])
    subdomains = meta.get("subdomains", [])

    summary = {
        "target": target,
        "generated_at": utc_timestamp(),
        "discovery": {
            "directories": paths,
            "historical_urls": historical,
            "subdomains": subdomains,
            "http": http_entries,
        },
        "artifacts": {
            "gobuster_json": "gobuster.json",
            "wayback_urls": "waybackurls.txt",
            "amass_output": "amass.txt",
            "httpx_json": "httpx.json",
        },
        "settings": {
            "depth": int(depth),
            "rate": int(rate),
        },
    }

    _write_csv_summary(run_dir, paths, historical, subdomains, http_entries)
    write_json(run_dir / "webmap.json", summary)
    return summary


# ──────────────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────────────


def run_webmap(options: WebMapOptions, runner: DockerRunner) -> Path:
    """Run web surface mapping scan."""
    descriptor = _descriptor(options)
    key = CacheKey(
        namespace="webmap",
        components=(
            "webmap",
            descriptor,
            f"depth={options.depth}",
            f"rate={options.rate}",
            f"wordlist={options.wordlist.name if options.wordlist else 'default'}",
        ),
    )

    if not options.refresh:
        cached_summary = _check_cache(runner, key)
        if cached_summary:
            return cached_summary

    runner.ensure_image()
    run_dir = runner.new_run_dir("webmap", descriptor)
    run_rel = runner.relative_posix(run_dir)
    env = {
        "RUN_DIR": f"/work/{run_rel}",
        "WEBMAP_DEPTH": str(options.depth),
        "WEBMAP_RATE": str(options.rate),
    }

    domain, netloc = _parse_url(options.url)
    _write_target_data(run_dir, options.url, domain, netloc)

    wordlist_path = _resolve_wordlist(run_dir, run_rel, options.wordlist)

    _run_gobuster(runner, run_rel, options.url, wordlist_path, env)
    _run_waybackurls(runner, run_dir, domain, options.depth, env)
    _run_amass(runner, run_dir, domain, env)

    _build_metadata(run_dir, options.depth)
    _run_httpx(runner, run_rel, options.rate, env)

    summary = _build_summary(run_dir, options.depth, options.rate)
    summary_path = run_dir / "webmap.json"
    write_json(summary_path, summary)
    runner.cache_store(key, run_dir, descriptor)
    return summary_path

"""Service fingerprinting command that enriches port scan results with detailed service
information.

This module performs comprehensive service fingerprinting on discovered hosts and ports
by orchestrating multiple specialized tools:

- nmap: Service version detection that identifies running services, versions, and
  banners on discovered TCP ports
- sslyze: TLS/SSL certificate analysis that extracts certificate details, accepted
  TLS versions, and cipher suite information for TLS-enabled services (ports 443,
  465, 993, 995, etc.)
- httpx: HTTP service fingerprinting that extracts page titles, status codes,
  response headers, and technology stack information (optional, can be enabled/disabled)

Targets can be provided from multiple sources: discover JSON output, targets file,
or command-line host list. The module processes each host:port combination, runs
appropriate fingerprinting tools based on port type, and merges results into a
unified data structure per host:port endpoint.

Results include service names, versions, banners, TLS certificate details, HTTP
metadata, and technology stack information. All findings are consolidated into
a JSON summary with source attribution, enabling comprehensive service mapping
and technology identification across the target infrastructure.

Supports result caching, configurable HTTP scanning, and multi-threaded HTTP
probe execution for efficient large-scale fingerprinting operations.
"""

from __future__ import annotations

import json
import logging
from collections import defaultdict
from pathlib import Path
from typing import Dict, Iterator, List, Optional, Sequence, Tuple

from pentool.commands import FingerprintOptions
from pentool.common import check_cache, iter_lines, safe_int
from pentool.docker_runner import DockerRunner
from pentool.parsers import (
    build_http_info,
    extract_host_from_httpx,
    extract_port_from_httpx,
    iter_gnmap,
    iter_httpx,
    iter_sslyze,
)
from pentool.utils import (
    CacheKey,
    load_json,
    parse_host_port,
    utc_timestamp,
    write_json,
)

LOG = logging.getLogger(__name__)


# ──────────────────────────────────────────────────────────────────────────────
# Setup and initialization
# ──────────────────────────────────────────────────────────────────────────────


def _descriptor(opts: FingerprintOptions) -> str:
    """Generate descriptor string from fingerprint options."""
    if opts.input_path:
        return f"fingerprint:{opts.input_path.name}"
    if opts.targets:
        return f"fingerprint:{opts.targets.name}"
    if opts.hosts:
        return f"fingerprint:{opts.hosts[0]}"
    return "fingerprint"


def _check_cache(runner: DockerRunner, key: CacheKey) -> Optional[Path]:
    """Check if cached fingerprint results exist and return summary path if found."""
    return check_cache(runner, key, "fingerprint.json")


def _empty_summary(
    desc: str, *, enable_http: bool, threads: int
) -> Dict[str, object]:
    """Create empty summary JSON when no targets are found."""
    return {
        "descriptor": desc,
        "generated_at": utc_timestamp(),
        "targets": [],
        "artifacts": {},
        "settings": {"http": bool(enable_http), "threads": int(threads)},
    }


# ──────────────────────────────────────────────────────────────────────────────
# Target collection
# ──────────────────────────────────────────────────────────────────────────────


def _extract_address_from_row(row: Dict[str, object]) -> Optional[str]:
    """Extract address from a host row."""
    if not isinstance(row, dict):
        return None
    address = row.get("address")
    return str(address) if address else None


def _extract_ports_from_row(row: Dict[str, object]) -> Iterator[int]:
    """Extract valid port numbers from a host row."""
    for p in row.get("ports", []):
        if not isinstance(p, dict):
            continue
        port = safe_int(p.get("port"))
        if port is not None:
            yield port


def _iter_targets_from_discover(
    data: Dict[str, object],
) -> Iterator[Tuple[str, int]]:
    """Iterate host:port pairs from discover JSON format."""
    hosts = data.get("hosts")
    if not isinstance(hosts, list):
        return
    for row in hosts:
        address = _extract_address_from_row(row)
        if not address:
            continue
        for port in _extract_ports_from_row(row):
            yield address, port


def _iter_targets_from_file(path: Path) -> Iterator[Tuple[str, int]]:
    """Iterate host:port pairs from targets file."""
    for line in iter_lines(path):
        parsed = parse_host_port(line)
        if parsed:
            yield parsed


def _iter_targets_from_list(values: Sequence[str]) -> Iterator[Tuple[str, int]]:
    """Iterate host:port pairs from list of host strings."""
    for v in values:
        parsed = parse_host_port(v)
        if parsed:
            yield parsed


def _collect_targets_from_input(
    opts: FingerprintOptions, dedup: set[Tuple[str, int]]
) -> None:
    """Collect targets from input_path option."""
    if not opts.input_path:
        return
    if not opts.input_path.exists():
        raise RuntimeError(f"Input file not found: {opts.input_path}")
    dedup.update(_iter_targets_from_discover(load_json(opts.input_path)))


def _collect_targets_from_file(
    opts: FingerprintOptions, dedup: set[Tuple[str, int]]
) -> None:
    """Collect targets from targets file option."""
    if not opts.targets:
        return
    if not opts.targets.exists():
        raise RuntimeError(f"Targets file not found: {opts.targets}")
    dedup.update(_iter_targets_from_file(opts.targets))


def _collect_targets_from_list(
    opts: FingerprintOptions, dedup: set[Tuple[str, int]]
) -> None:
    """Collect targets from hosts list option."""
    if opts.hosts:
        dedup.update(_iter_targets_from_list(opts.hosts))


def _collect_target_rows(opts: FingerprintOptions) -> List[Tuple[str, int]]:
    """Collect and deduplicate target rows from all sources."""
    dedup: set[Tuple[str, int]] = set()
    _collect_targets_from_input(opts, dedup)
    _collect_targets_from_file(opts, dedup)
    _collect_targets_from_list(opts, dedup)
    return sorted(dedup)


def _write_targets(path: Path, rows: Sequence[Tuple[str, int]]) -> None:
    """Write target rows to file in host port format."""
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    with path.open("w", encoding="utf-8") as fh:
        fh.writelines(f"{h} {p}\n" for h, p in rows)


# ──────────────────────────────────────────────────────────────────────────────
# Support file building
# ──────────────────────────────────────────────────────────────────────────────


def _parse_hosts_from_targets(targets_path: Path) -> Dict[str, set[int]]:
    """Parse hosts and ports from targets file."""
    hosts: Dict[str, set[int]] = defaultdict(set)
    for line in iter_lines(targets_path):
        parts = line.split()
        if len(parts) != 2:
            continue
        host, port_str = parts[0], parts[1]
        port = safe_int(port_str)
        if port is not None:
            hosts[host].add(port)
    return hosts


def _extract_all_ports(hosts: Dict[str, set[int]]) -> List[int]:
    """Extract and sort all unique ports from hosts dictionary."""
    return sorted({p for s in hosts.values() for p in s})


def _get_tls_ports() -> set[int]:
    """Return set of common TLS port numbers."""
    return {443, 465, 993, 995, 8443, 9443, 10443, 12443}


def _write_nmap_hosts_file(
    nmap_hosts: Path, hosts: Dict[str, set[int]]
) -> None:
    """Write sorted unique host IPs to nmap hosts file."""
    with nmap_hosts.open("w", encoding="utf-8") as fh:
        fh.writelines(f"{h}\n" for h in sorted(hosts))


def _write_ports_file(ports_file: Path, all_ports: List[int]) -> None:
    """Write sorted port numbers to ports file."""
    with ports_file.open("w", encoding="utf-8") as fh:
        fh.writelines(f"{p}\n" for p in all_ports)


def _write_tls_targets_file(
    tls_targets: Path, hosts: Dict[str, set[int]]
) -> None:
    """Write TLS targets file with host:port pairs for TLS ports."""
    tls_ports = _get_tls_ports()
    with tls_targets.open("w", encoding="utf-8") as fh:
        fh.writelines(
            f"{h}:{p}\n"
            for h, s in hosts.items()
            for p in sorted(s)
            if p in tls_ports
        )


def _write_http_targets_file(
    http_targets: Path, hosts: Dict[str, set[int]]
) -> None:
    """Write HTTP targets file with all host:port pairs."""
    with http_targets.open("w", encoding="utf-8") as fh:
        fh.writelines(f"{h}:{p}\n" for h, s in hosts.items() for p in sorted(s))


def _build_support_files(
    targets_path: Path, run_dir: Path
) -> Dict[str, object]:
    """Build support files for nmap, TLS, and HTTP scanning."""
    hosts = _parse_hosts_from_targets(targets_path)
    run_dir.mkdir(parents=True, exist_ok=True)

    nmap_hosts = run_dir / "nmap-hosts.txt"
    ports_file = run_dir / "ports.txt"
    tls_targets = run_dir / "tls-targets.txt"
    http_targets = run_dir / "http-targets.txt"

    all_ports = _extract_all_ports(hosts)
    _write_nmap_hosts_file(nmap_hosts, hosts)
    _write_ports_file(ports_file, all_ports)
    _write_tls_targets_file(tls_targets, hosts)
    _write_http_targets_file(http_targets, hosts)

    return {
        "hosts": hosts,
        "ports": all_ports,
        "nmap_targets": nmap_hosts,
        "tls_targets": tls_targets,
        "http_targets": http_targets,
    }


# ──────────────────────────────────────────────────────────────────────────────
# Scan execution
# ──────────────────────────────────────────────────────────────────────────────


def _run_nmap_scan(
    runner: DockerRunner,
    run_rel: str,
    descriptor: str,
    port_list: str,
    env: Dict[str, str],
) -> None:
    """Run nmap service scan for fingerprinting."""
    LOG.info("nmap fingerprint %s", descriptor)
    runner.run(
        [
            "nmap",
            "-sV",
            "-Pn",
            "-p",
            port_list,
            "-oG",
            f"/work/{run_rel}/nmap.gnmap",
            "-oX",
            f"/work/{run_rel}/nmap.xml",
            "-oN",
            f"/work/{run_rel}/nmap.txt",
            "-iL",
            f"/work/{run_rel}/nmap-hosts.txt",
        ],
        env,
    )


def _run_sslyze_scan(
    runner: DockerRunner,
    run_dir: Path,
    run_rel: str,
    tls_targets: Path,
    env: Dict[str, str],
) -> None:
    """Run sslyze TLS scan if TLS targets exist."""
    if tls_targets.exists() and tls_targets.stat().st_size > 0:
        LOG.info("sslyze TLS checks")
        res = runner.run(
            [
                "sslyze",
                "--json_out",
                f"/work/{run_rel}/sslyze.json",
                "--targets_in",
                f"/work/{run_rel}/tls-targets.txt",
            ],
            env,
            check=False,
        )
        if res.returncode != 0:
            LOG.warning("sslyze exited with code %s", res.returncode)
    else:
        (run_dir / "sslyze.json").write_text("{}", encoding="utf-8")


def _run_httpx_scan(
    runner: DockerRunner,
    run_dir: Path,
    run_rel: str,
    http_targets: Path,
    enable_http: bool,
    threads: int,
    env: Dict[str, str],
) -> None:
    """Run httpx HTTP scan if enabled or targets exist."""
    if enable_http or (
        http_targets.exists() and http_targets.stat().st_size > 0
    ):
        LOG.info("httpx banner collection")
        res = runner.run(
            [
                "httpx",
                "-l",
                f"/work/{run_rel}/http-targets.txt",
                "-json",
                "-o",
                f"/work/{run_rel}/httpx.json",
                "-threads",
                str(threads),
                "-silent",
            ],
            env,
            check=False,
        )
        if res.returncode != 0:
            LOG.warning("httpx exited with code %s", res.returncode)
    else:
        (run_dir / "httpx.json").write_text("", encoding="utf-8")


# ──────────────────────────────────────────────────────────────────────────────
# Summary building
# ──────────────────────────────────────────────────────────────────────────────


def _seed_hosts_from_targets(
    run_dir: Path, hosts_map: Dict[str, Dict[int, Dict[str, object]]]
) -> None:
    """Seed hosts map with entries from targets file."""
    for line in iter_lines(run_dir / "targets.txt"):
        parts = line.split()
        if len(parts) != 2:
            continue
        host, port_str = parts[0], parts[1]
        port = safe_int(port_str)
        if port is None:
            continue
        entry = _ensure_entry(hosts_map, host, port, state="unknown")
        entry.setdefault("service", {})


def _merge_scanner_results(
    hosts_map: Dict[str, Dict[int, Dict[str, object]]],
    scanner_iter: Iterator[Tuple[str, int, Dict[str, object]]],
    source_name: str,
) -> None:
    """Merge scanner results into hosts map."""
    for host, port, fields in scanner_iter:
        entry = _ensure_entry(hosts_map, host, port)
        entry.update({k: v for k, v in fields.items() if k not in {"src"}})
        _add_source(entry, source_name)


def _build_targets_list(
    hosts_map: Dict[str, Dict[int, Dict[str, object]]],
) -> List[Dict[str, object]]:
    """Build sorted targets list from hosts map."""
    return [
        {
            "address": host,
            "ports": [entry for _, entry in sorted(ports.items())],
        }
        for host, ports in sorted(hosts_map.items())
    ]


def _build_summary(
    run_dir: Path,
    descriptor: str,
    *,
    enable_http: bool,
    threads: int,
) -> Dict[str, object]:
    """Build final summary JSON with all scanner results."""
    hosts_map: Dict[str, Dict[int, Dict[str, object]]] = defaultdict(dict)

    _seed_hosts_from_targets(run_dir, hosts_map)
    _merge_scanner_results(
        hosts_map, iter_gnmap(run_dir / "nmap.gnmap"), "nmap"
    )
    _merge_scanner_results(
        hosts_map, iter_sslyze(run_dir / "sslyze.json"), "sslyze"
    )
    _merge_scanner_results(
        hosts_map, iter_httpx(run_dir / "httpx.json"), "httpx"
    )

    targets = _build_targets_list(hosts_map)

    return {
        "descriptor": descriptor,
        "generated_at": utc_timestamp(),
        "targets": targets,
        "artifacts": {
            "nmap_gnmap": "nmap.gnmap",
            "nmap_xml": "nmap.xml",
            "nmap_text": "nmap.txt",
            "sslyze_json": "sslyze.json",
            "httpx_json": "httpx.json",
        },
        "settings": {"http": bool(enable_http), "threads": int(threads)},
    }


# ──────────────────────────────────────────────────────────────────────────────
# Low-level utilities
# ──────────────────────────────────────────────────────────────────────────────


def _ensure_entry(
    hosts_map: Dict[str, Dict[int, Dict[str, object]]],
    host: str,
    port: int,
    *,
    state: str = "open",
) -> Dict[str, object]:
    """Ensure and return entry for host:port in hosts map."""
    host_bucket = hosts_map.setdefault(host, {})
    return host_bucket.setdefault(
        port,
        {
            "port": port,
            "state": state,
            "protocol": "tcp",
            "service": {},
            "sources": [],
        },
    )


def _add_source(entry: Dict[str, object], name: str) -> None:
    """Add source name to entry's sources list if not already present."""
    sources = entry.setdefault("sources", [])
    if name not in sources:
        sources.append(name)


# ──────────────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────────────


def run_fingerprint(options: FingerprintOptions, runner: DockerRunner) -> Path:
    """Run fingerprint scan with nmap, sslyze, and httpx."""
    desc = _descriptor(options)
    key = CacheKey(
        namespace="fingerprint",
        components=(
            "fingerprint",
            desc,
            f"http={int(options.enable_http)}",
            f"threads={options.threads}",
        ),
    )

    if not options.refresh:
        cached_summary = _check_cache(runner, key)
        if cached_summary:
            return cached_summary

    runner.ensure_image()
    run_dir = runner.new_run_dir("fingerprint", desc)
    run_rel = runner.relative_posix(run_dir)
    env = {"RUN_DIR": f"/work/{run_rel}"}

    targets_path = run_dir / "targets.txt"
    rows = _collect_target_rows(options)
    _write_targets(targets_path, rows)

    summary_path = run_dir / "fingerprint.json"
    if not rows:
        write_json(
            summary_path,
            _empty_summary(
                desc, enable_http=options.enable_http, threads=options.threads
            ),
        )
        runner.cache_store(key, run_dir, desc)
        return summary_path

    support = _build_support_files(targets_path, run_dir)
    nmap_hosts: Path = support["nmap_targets"]  # type: ignore[assignment]
    ports: List[int] = support["ports"]  # type: ignore[assignment]

    if not nmap_hosts.exists() or nmap_hosts.stat().st_size == 0:
        write_json(
            summary_path,
            _empty_summary(
                desc, enable_http=options.enable_http, threads=options.threads
            ),
        )
        runner.cache_store(key, run_dir, desc)
        return summary_path

    port_list = ",".join(map(str, ports)) if ports else "80,443"
    _run_nmap_scan(runner, run_rel, desc, port_list, env)

    tls_targets: Path = support["tls_targets"]  # type: ignore[assignment]
    _run_sslyze_scan(runner, run_dir, run_rel, tls_targets, env)

    http_targets: Path = support["http_targets"]  # type: ignore[assignment]
    _run_httpx_scan(
        runner,
        run_dir,
        run_rel,
        http_targets,
        options.enable_http,
        options.threads,
        env,
    )

    summary = _build_summary(
        run_dir, desc, enable_http=options.enable_http, threads=options.threads
    )
    write_json(summary_path, summary)
    runner.cache_store(key, run_dir, desc)
    return summary_path

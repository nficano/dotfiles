"""Security scan command that runs multiple tools and aggregates findings.

This module orchestrates comprehensive security scans against a target URL using
multiple specialized tools:

- nikto: Web server scanner that identifies dangerous files, misconfigurations,
  and outdated software versions
- sslyze: TLS/SSL analyzer that checks for handshake failures and certificate
  issues (only runs for HTTPS URLs)
- OWASP ZAP: Web application security scanner performing baseline automated
  security testing
- sqlmap: SQL injection detection tool with configurable scan depth and risk levels

Findings from each tool are parsed, normalized into a unified Finding model with
standardized severity levels (critical, high, medium, low, info), and aggregated
into consolidated reports. The module generates both JSON summary reports for
human review and SARIF (Static Analysis Results Interchange Format) output for
integration with CI/CD pipelines and security analysis platforms.

Supports result caching to avoid redundant scans and configurable scan profiles
(basic/extended) that adjust tool aggressiveness and coverage depth.
"""

from __future__ import annotations

import logging
from collections import OrderedDict
from itertools import chain
from pathlib import Path
from typing import Iterable, Iterator, List, Optional

from pentool.commands import ScanOptions
from pentool.common import check_cache
from pentool.docker_runner import DockerRunner
from pentool.models import (
    Finding,
    NiktoFindingModel,
    SslyzeOutputModel,
    ZapBaselineModel,
)
from pentool.utils import CacheKey, load_json, utc_timestamp, write_json

logger = logging.getLogger(__name__)


# ──────────────────────────────────────────────────────────────────────────────
# Setup and initialization
# ──────────────────────────────────────────────────────────────────────────────


def _descriptor(options: ScanOptions) -> str:
    """Generate descriptor string from scan options."""
    return f"scan:{options.url}:{options.profile}"


def _check_cache(runner: DockerRunner, key: CacheKey) -> Optional[Path]:
    """Check if cached scan results exist and return summary path if found."""
    return check_cache(runner, key, "scan.json")


# ──────────────────────────────────────────────────────────────────────────────
# Command building
# ──────────────────────────────────────────────────────────────────────────────


def _nikto_command(run_rel: str, url: str) -> List[str]:
    """Build nikto command."""
    return [
        "nikto",
        "-h",
        url,
        "-Format",
        "json",
        "-output",
        f"/work/{run_rel}/nikto.json",
    ]


def _sqlmap_base_args(run_rel: str, url: str) -> List[str]:
    """Build base sqlmap arguments."""
    return [
        "sqlmap",
        "-u",
        url,
        "--batch",
        "--smart",
        "--fresh-queries",
        "--output-dir",
        f"/work/{run_rel}/sqlmap",
    ]


def _sqlmap_profile_args(profile: str) -> List[str]:
    """Build sqlmap profile-specific arguments."""
    if profile == "extended":
        return [
            "--crawl=1",
            "--level",
            "3",
            "--risk",
            "2",
            "--threads",
            "6",
            "--timeout=20",
        ]
    return [
        "--crawl=0",
        "--level",
        "1",
        "--risk",
        "1",
        "--threads",
        "4",
        "--timeout=10",
    ]


def _sqlmap_command(run_rel: str, url: str, profile: str) -> List[str]:
    """Build complete sqlmap command."""
    base = _sqlmap_base_args(run_rel, url)
    base.extend(_sqlmap_profile_args(profile))
    return base


def _sslyze_command(run_rel: str, url: str) -> List[str]:
    """Build sslyze command."""
    return [
        "sslyze",
        "--json_out",
        f"/work/{run_rel}/sslyze.json",
        url,
    ]


def _zap_command(run_rel: str, url: str) -> List[str]:
    """Build OWASP ZAP baseline command."""
    return [
        "python3",
        "/usr/share/zaproxy/zap-baseline.py",
        "-t",
        url,
        "-m",
        "10",
        "-J",
        f"/work/{run_rel}/zap.json",
        "-r",
        f"/work/{run_rel}/zap.html",
        "-n",
        "-I",
    ]


# ──────────────────────────────────────────────────────────────────────────────
# Scan execution
# ──────────────────────────────────────────────────────────────────────────────


def _run_tool(
    runner: DockerRunner,
    command: List[str],
    env: dict,
    description: str,
    *,
    capture_output: bool = False,
) -> Optional[str]:
    """Run a scan tool and return output if requested."""
    logger.info(description)
    result = runner.run(
        command, env, check=False, capture_output=capture_output
    )
    if result.returncode != 0:
        logger.warning("%s exited with code %s", command[0], result.returncode)
    return result.stdout if capture_output else None


def _is_https_url(url: str) -> bool:
    """Check if URL uses HTTPS protocol."""
    return url.lower().startswith("https://")


def _run_nikto_scan(
    runner: DockerRunner, run_rel: str, url: str, env: dict
) -> None:
    """Run nikto baseline scan."""
    command = _nikto_command(run_rel, url)
    _run_tool(runner, command, env, f"nikto baseline {url}")


def _run_sslyze_scan(
    runner: DockerRunner, run_dir: Path, run_rel: str, url: str, env: dict
) -> None:
    """Run sslyze TLS scan if URL is HTTPS."""
    sslyze_path = run_dir / "sslyze.json"
    if _is_https_url(url):
        command = _sslyze_command(run_rel, url)
        _run_tool(runner, command, env, "sslyze TLS audit")
    else:
        sslyze_path.write_text("{}\n", encoding="utf-8")


def _run_zap_scan(
    runner: DockerRunner, run_rel: str, url: str, env: dict
) -> None:
    """Run OWASP ZAP baseline scan."""
    command = _zap_command(run_rel, url)
    _run_tool(runner, command, env, "OWASP ZAP baseline")


def _run_sqlmap_scan(
    runner: DockerRunner,
    run_dir: Path,
    run_rel: str,
    url: str,
    profile: str,
    env: dict,
) -> None:
    """Run sqlmap audit and save output."""
    command = _sqlmap_command(run_rel, url, profile)
    sqlmap_output = _run_tool(
        runner, command, env, "sqlmap audit", capture_output=True
    )
    sqlmap_log = run_dir / "sqlmap.log"
    sqlmap_log.parent.mkdir(parents=True, exist_ok=True)
    sqlmap_log.write_text(sqlmap_output or "", encoding="utf-8")


# ──────────────────────────────────────────────────────────────────────────────
# Finding extraction
# ──────────────────────────────────────────────────────────────────────────────


def _iter_nikto_findings(path: Path) -> Iterator[Finding]:
    """Iterate findings from nikto JSON output."""
    data = load_json(path)
    entries = data.get("findings", [])
    for entry in entries:
        model = NiktoFindingModel.model_validate(entry)
        yield model.to_finding()


def _iter_zap_findings(path: Path) -> Iterator[Finding]:
    """Iterate findings from ZAP JSON output."""
    data = ZapBaselineModel.model_validate(load_json(path))
    for alert in chain.from_iterable(site.alerts for site in data.site):
        yield alert.to_finding()


def _parse_sqlmap_line(line: str) -> Optional[Finding]:
    """Parse a single line from sqlmap log."""
    trimmed = line.strip()
    if "[CRITICAL]" in trimmed:
        return Finding(
            source="sqlmap",
            severity="high",
            title="SQLMap critical finding",
            description=trimmed,
        )
    if "[WARNING]" in trimmed:
        return Finding(
            source="sqlmap",
            severity="medium",
            title="SQLMap warning",
            description=trimmed,
        )
    return None


def _iter_sqlmap_findings(path: Path) -> Iterator[Finding]:
    """Iterate findings from sqlmap log output."""
    if not path.exists():
        return
    with path.open("r", encoding="utf-8", errors="ignore") as handle:
        for line in handle:
            finding = _parse_sqlmap_line(line)
            if finding:
                yield finding


def _iter_sslyze_findings(path: Path) -> Iterator[Finding]:
    """Iterate findings from sslyze JSON output."""
    data = SslyzeOutputModel.model_validate(load_json(path))
    for item in data.server_scan_results:
        finding = item.to_finding()
        if finding:
            yield finding


def _collect_findings(run_dir: Path) -> List[Finding]:
    """Collect all findings from scan outputs."""
    generators = (
        _iter_nikto_findings(run_dir / "nikto.json"),
        _iter_zap_findings(run_dir / "zap.json"),
        _iter_sqlmap_findings(run_dir / "sqlmap.log"),
        _iter_sslyze_findings(run_dir / "sslyze.json"),
    )
    return list(chain.from_iterable(generators))


# ──────────────────────────────────────────────────────────────────────────────
# Output generation
# ──────────────────────────────────────────────────────────────────────────────


def _summary_payload(
    url: str, profile: str, findings: Iterable[Finding]
) -> dict:
    """Generate summary JSON payload."""
    return {
        "target": url,
        "profile": profile,
        "generated_at": utc_timestamp(),
        "findings": [finding.summary_payload() for finding in findings],
        "artifacts": {
            "nikto_json": "nikto.json",
            "zap_json": "zap.json",
            "zap_html": "zap.html",
            "sslyze_json": "sslyze.json",
            "sqlmap_log": "sqlmap.log",
        },
    }


def _build_sarif_rules(findings: List[Finding]) -> List[dict]:
    """Build unique SARIF rules from findings."""
    rules = OrderedDict()
    for finding in findings:
        rules.setdefault(finding.rule_id, finding.rule_metadata())
    return list(rules.values())


def _sarif_payload(url: str, findings: Iterable[Finding]) -> dict:
    """Generate SARIF JSON payload."""
    findings_list = list(findings)
    return {
        "version": "2.1.0",
        "runs": [
            {
                "tool": {
                    "driver": {
                        "name": "Pen Test Toolkit",
                        "informationUri": "https://example.com/pentool",
                        "rules": _build_sarif_rules(findings_list),
                    }
                },
                "artifacts": [{"location": {"uri": url}}],
                "results": [
                    finding.sarif_result(url) for finding in findings_list
                ],
            }
        ],
    }


def _write_outputs(
    run_dir: Path, url: str, profile: str, findings: List[Finding]
) -> None:
    """Write all output files."""
    summary = _summary_payload(url, profile, findings)
    sarif = _sarif_payload(url, findings)
    write_json(run_dir / "scan.json", summary)
    write_json(run_dir / "scan.sarif", sarif)


# ──────────────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────────────


def run_scan(options: ScanOptions, runner: DockerRunner) -> Path:
    """Run security scan with multiple tools."""
    descriptor = _descriptor(options)
    key = CacheKey(namespace="scan", components=("scan", descriptor))

    if not options.refresh:
        cached_summary = _check_cache(runner, key)
        if cached_summary:
            return cached_summary

    runner.ensure_image()
    run_dir = runner.new_run_dir("scan", descriptor)
    run_rel = runner.relative_posix(run_dir)
    env = {"RUN_DIR": f"/work/{run_rel}"}

    _run_nikto_scan(runner, run_rel, options.url, env)
    _run_sslyze_scan(runner, run_dir, run_rel, options.url, env)
    _run_zap_scan(runner, run_rel, options.url, env)
    _run_sqlmap_scan(
        runner, run_dir, run_rel, options.url, options.profile, env
    )

    findings = _collect_findings(run_dir)
    _write_outputs(run_dir, options.url, options.profile, findings)

    runner.cache_store(key, run_dir, descriptor)
    return run_dir / "scan.json"

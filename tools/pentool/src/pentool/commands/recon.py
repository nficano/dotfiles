"""Network reconnaissance command that discovers hosts and open ports across target ranges.

This module performs fast network reconnaissance by orchestrating two complementary tools:

- masscan: High-speed port scanner that rapidly sweeps large CIDR ranges or host lists
  to identify open TCP ports. Uses a configurable scan rate and focuses on common
  TCP ports (derived from nmap-services frequency data) for efficient discovery.
  Outputs JSON results with discovered host:port combinations.

- nmap: Service version detection scanner that performs detailed analysis on discovered
  ports. Runs service version detection (-sV) to identify running services, versions,
  and banners. Only executes when ports are discovered by masscan, providing enriched
  service information beyond simple port discovery.

Targets can be specified as CIDR ranges (e.g., 192.168.1.0/24), single hosts, or
target files containing host lists. The module processes masscan results, extracts
unique hosts and ports, then runs nmap service detection on discovered ports to
identify running services and versions.

Results are merged to combine masscan's fast discovery with nmap's detailed service
identification, producing a consolidated JSON summary with hosts, open ports, service
names, versions, and banners. If no ports are discovered, the scan completes early
with a summary indicating no open ports were found.

Supports result caching, configurable port count (top N common ports), and adjustable
masscan scan rates for balancing speed against network impact. Generates multiple
output formats (JSON summary, nmap XML/text/gnmap) for integration with other tools.
"""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Dict, Iterator, List, Optional, Tuple

from pentool.commands import DiscoverOptions
from pentool.common import check_cache, iter_lines, safe_int
from pentool.constants import COMMON_TCP_PORTS
from pentool.docker_runner import DockerRunner
from pentool.parsers import (
    extract_ip_from_gnmap_line,
    extract_ports_segment_from_gnmap,
    parse_gnmap_port_block,
)
from pentool.utils import CacheKey, load_json, utc_timestamp, write_json

logger = logging.getLogger(__name__)

PORT_FALLBACK_RANGE = "1-1024"


def _choose_port_seed(count: int) -> str:
    """Choose a comma-separated seed of unique common ports or a safe fallback."""
    if count <= 0:
        return PORT_FALLBACK_RANGE
    seen: set[int] = set()
    picked: List[int] = []
    for p in COMMON_TCP_PORTS:
        if p not in seen:
            seen.add(p)
            picked.append(p)
            if len(picked) == count:
                break
    if len(picked) != count:
        return PORT_FALLBACK_RANGE
    return ",".join(str(p) for p in picked)


def _descriptor(options: DiscoverOptions) -> str:
    if options.cidr:
        return f"cidr:{options.cidr}"
    if options.host:
        return f"host:{options.host}"
    if options.targets:
        return f"targets:{options.targets.name}"
    return "recon"


def _write_targets_from_file(run_dir: Path, targets_file: Path) -> None:
    """Write target files from an existing targets file."""
    if not targets_file.exists():
        raise RuntimeError(f"Targets file not found: {targets_file}")
    content = targets_file.read_text(encoding="utf-8")
    (run_dir / "masscan-targets.txt").write_text(content, encoding="utf-8")
    (run_dir / "source_targets.txt").write_text(content, encoding="utf-8")


def _write_targets_from_value(run_dir: Path, value: str) -> None:
    """Write target files from a CIDR or host value."""
    line = f"{value}\n"
    (run_dir / "masscan-targets.txt").write_text(line, encoding="utf-8")
    (run_dir / "source_targets.txt").write_text(line, encoding="utf-8")


def _prepare_targets(run_dir: Path, options: DiscoverOptions) -> None:
    """Prepare target files for masscan from options."""
    if options.targets:
        _write_targets_from_file(run_dir, options.targets)
        return

    value = (options.cidr or options.host or "").strip()
    if not value:
        raise RuntimeError("Provide CIDR, host, or targets file")
    _write_targets_from_value(run_dir, value)


def _load_masscan_data(masscan_path: Path) -> List[Dict[str, object]]:
    """Load masscan JSON data, handling both dict and list formats."""
    data = load_json(masscan_path) or []
    if isinstance(data, dict):
        data = data.get("results", [])
    return data


def _extract_ip_from_entry(entry: Dict[str, object]) -> Optional[str]:
    """Extract IP address from a masscan entry."""
    return entry.get("ip") or entry.get("addr")


def _is_valid_tcp_port(port_entry: Dict[str, object]) -> bool:
    """Check if a port entry is a valid TCP port."""
    proto = (port_entry.get("proto") or "tcp").lower()
    return proto == "tcp"


def _create_port_dict(port: int) -> Dict[str, object]:
    """Create a port dictionary entry for masscan results."""
    return {
        "port": port,
        "protocol": "tcp",
        "state": "open",
        "source": "masscan",
    }


def _parse_masscan_entries(
    data: List[Dict[str, object]],
) -> Dict[str, Dict[str, object]]:
    """Parse masscan JSON entries into a hosts dictionary."""
    hosts: Dict[str, Dict[str, object]] = {}
    for entry in data:
        ip = _extract_ip_from_entry(entry)
        if not ip:
            continue
        rec = hosts.setdefault(ip, {"address": ip, "ports": []})
        ports = rec["ports"]  # type: ignore[assignment]
        for p in entry.get("ports", []):
            port = safe_int(p.get("port"))
            if port is None or not _is_valid_tcp_port(p):
                continue
            ports.append(_create_port_dict(port))
    return hosts


def _extract_unique_ports(hosts: Dict[str, Dict[str, object]]) -> List[int]:
    """Extract and sort unique port numbers from hosts."""
    return sorted(
        {
            int(pe["port"])
            for h in hosts.values()
            for pe in h.get("ports", [])
            if isinstance(pe, dict) and isinstance(pe.get("port"), int)
        }
    )


def _write_targets_file(
    targets_path: Path, hosts: Dict[str, Dict[str, object]]
) -> None:
    """Write sorted host IPs to targets file."""
    content = "\n".join(sorted(hosts)) + ("\n" if hosts else "")
    targets_path.write_text(content, encoding="utf-8")


def _write_ports_file(ports_path: Path, port_values: List[int]) -> None:
    """Write sorted port numbers to ports file."""
    content = "\n".join(map(str, port_values)) + ("\n" if port_values else "")
    ports_path.write_text(content, encoding="utf-8")


def _process_masscan_results(
    masscan_path: Path,
    summary_path: Path,
    targets_path: Path,
    ports_path: Path,
) -> Tuple[Dict[str, Dict[str, object]], List[int]]:
    """Process masscan JSON results and write output files."""
    data = _load_masscan_data(masscan_path)
    hosts = _parse_masscan_entries(data)
    write_json(summary_path, {"hosts": hosts})
    port_values = _extract_unique_ports(hosts)
    _write_targets_file(targets_path, hosts)
    _write_ports_file(ports_path, port_values)
    return hosts, port_values


def _build_summary_no_ports(
    masscan_summary_path: Path, descriptor: str
) -> Dict[str, object]:
    data = load_json(masscan_summary_path) or {}
    hosts_list = [
        {"address": h.get("address"), "ports": h.get("ports", [])}
        for h in (data.get("hosts") or {}).values()
    ]
    return {
        "descriptor": descriptor,
        "generated_at": utc_timestamp(),
        "hosts": hosts_list,
        "stats": {
            "hosts": len(hosts_list),
            "services": sum(len(h.get("ports", [])) for h in hosts_list),
        },
        "artifacts": {"masscan_json": "masscan.json"},
        "notes": "No open TCP ports identified; nmap enrichment skipped.",
    }


def _find_existing_port_entry(
    host: Dict[str, object], port: int, protocol: str
) -> Optional[Dict[str, object]]:
    """Find existing port entry matching port and protocol."""
    return next(
        (
            e
            for e in host["ports"]
            if isinstance(e, dict)
            and e.get("port") == port
            and e.get("protocol") == protocol
        ),
        None,
    )


def _create_port_detail(
    port: int, protocol: str, state: str, service: str, banner: str
) -> Dict[str, object]:
    """Create a port detail dictionary for nmap results."""
    detail = {
        "port": port,
        "protocol": protocol,
        "state": state,
        "service": service,
        "source": "nmap",
    }
    if banner:
        detail["banner"] = banner
    return detail


def _update_host_with_port(
    host: Dict[str, object],
    port: int,
    protocol: str,
    state: str,
    service: str,
    banner: str,
) -> None:
    """Update or add a port entry to a host."""
    merged = _find_existing_port_entry(host, port, protocol)
    detail = _create_port_detail(port, protocol, state, service, banner)
    if merged:
        merged.update(detail)
        merged["source"] = "masscan+nmap"
    else:
        host["ports"].append(detail)


def _process_gnmap_line(
    line: str, hosts_map: Dict[str, Dict[str, object]]
) -> None:
    """Process a single gnmap line and update hosts map."""
    if not line.startswith("Host: "):
        return
    ip = extract_ip_from_gnmap_line(line)
    if not ip:
        return
    host = hosts_map.setdefault(ip, {"address": ip, "ports": []})
    parts = line.split("\t")
    ports_segment = extract_ports_segment_from_gnmap(parts)
    if not ports_segment:
        return
    for block in ports_segment.split(","):
        parsed = parse_gnmap_port_block(block)
        if not parsed:
            continue
        port, state, protocol, service, banner = parsed
        _update_host_with_port(host, port, protocol, state, service, banner)


def _merge_gnmap_into_hosts(
    run_dir: Path, hosts_map: Dict[str, Dict[str, object]]
) -> None:
    """Update hosts_map in-place with nmap .gnmap details."""
    gnmap_path = run_dir / "nmap.gnmap"
    if not gnmap_path.exists():
        return
    for line in iter_lines(gnmap_path):
        _process_gnmap_line(line, hosts_map)


def _load_hosts_from_masscan_summary(
    run_dir: Path,
) -> Dict[str, Dict[str, object]]:
    """Load hosts dictionary from masscan summary JSON."""
    hosts_map: Dict[str, Dict[str, object]] = {}
    masscan_data = load_json(run_dir / "masscan-summary.json") or {}
    for ip, details in (masscan_data.get("hosts") or {}).items():
        ports = [
            {
                "port": p.get("port"),
                "protocol": p.get("protocol", "tcp"),
                "state": p.get("state", "open"),
                "source": p.get("source", "masscan"),
            }
            for p in details.get("ports", [])
        ]
        hosts_map[ip] = {"address": ip, "ports": ports}
    return hosts_map


def _build_sorted_hosts_list(
    hosts_map: Dict[str, Dict[str, object]],
) -> List[Dict[str, object]]:
    """Build sorted list of hosts with sorted ports."""
    return [
        {
            "address": ip,
            "ports": sorted(h["ports"], key=lambda item: item.get("port", 0)),
        }
        for ip, h in sorted(hosts_map.items())
    ]


def _build_summary(
    run_dir: Path,
    descriptor: str,
    *,
    top_ports: int,
    max_rate: int,
) -> Dict[str, object]:
    """Build final summary JSON with masscan and nmap results."""
    hosts_map = _load_hosts_from_masscan_summary(run_dir)
    _merge_gnmap_into_hosts(run_dir, hosts_map)
    hosts = _build_sorted_hosts_list(hosts_map)

    return {
        "descriptor": descriptor,
        "generated_at": utc_timestamp(),
        "hosts": hosts,
        "stats": {
            "hosts": len(hosts),
            "services": sum(len(h["ports"]) for h in hosts),
        },
        "artifacts": {
            "masscan_json": "masscan.json",
            "masscan_summary": "masscan-summary.json",
            "nmap_gnmap": "nmap.gnmap",
            "nmap_xml": "nmap.xml",
            "nmap_text": "nmap.txt",
        },
        "settings": {"top_ports": int(top_ports), "max_rate": int(max_rate)},
    }


def _validate_options(options: DiscoverOptions) -> None:
    """Validate that options are correctly specified."""
    if options.cidr and options.host:
        raise RuntimeError("Specify either --cidr or --host, not both")
    if not any([options.cidr, options.host, options.targets]):
        raise RuntimeError("Provide a CIDR, host, or target list")


def _check_cache(runner: DockerRunner, key: CacheKey) -> Optional[Path]:
    """Check if cached recon results exist and return summary path if found."""
    return check_cache(runner, key, "recon.json")


def _run_masscan_scan(
    runner: DockerRunner,
    run_dir: Path,
    run_rel: str,
    descriptor: str,
    port_seed: str,
    rate: int,
    env: Dict[str, str],
) -> None:
    """Run masscan port scan."""
    logger.info(
        "masscan sweep %s (ports %s)", descriptor or "targets", port_seed
    )
    runner.run(
        [
            "masscan",
            "--wait",
            "0",
            "--open",
            "--rate",
            str(rate),
            "--ports",
            port_seed,
            "-oJ",
            f"/work/{run_rel}/masscan.json",
            "-iL",
            f"/work/{run_rel}/masscan-targets.txt",
        ],
        env,
    )


def _run_nmap_scan(
    runner: DockerRunner,
    run_dir: Path,
    run_rel: str,
    descriptor: str,
    port_list: str,
    env: Dict[str, str],
) -> None:
    """Run nmap service scan on discovered ports."""
    logger.info("nmap enrichment %s", descriptor or "targets")
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
            f"/work/{run_rel}/nmap-targets.txt",
        ],
        env,
    )


def run_recon(options: DiscoverOptions, runner: DockerRunner) -> Path:
    """Run reconnaissance scan with masscan and nmap."""
    _validate_options(options)

    descriptor = _descriptor(options)
    key = CacheKey(
        namespace="recon",
        components=(
            "recon",
            descriptor,
            f"top={options.top_ports}",
            f"rate={options.rate}",
        ),
    )

    if not options.refresh:
        cached_summary = _check_cache(runner, key)
        if cached_summary:
            return cached_summary

    runner.ensure_image()
    run_dir = runner.new_run_dir("recon", descriptor)
    run_rel = runner.relative_posix(run_dir)
    env = {"RUN_DIR": f"/work/{run_rel}"}

    _prepare_targets(run_dir, options)

    port_seed = _choose_port_seed(options.top_ports)
    _run_masscan_scan(
        runner, run_dir, run_rel, descriptor, port_seed, options.rate, env
    )

    masscan_json = run_dir / "masscan.json"
    masscan_summary = run_dir / "masscan-summary.json"
    nmap_targets = run_dir / "nmap-targets.txt"
    ports_file = run_dir / "ports.txt"
    _, port_values = _process_masscan_results(
        masscan_json, masscan_summary, nmap_targets, ports_file
    )

    summary_path = run_dir / "recon.json"
    if not port_values:
        write_json(
            summary_path, _build_summary_no_ports(masscan_summary, descriptor)
        )
        runner.cache_store(key, run_dir, descriptor)
        return summary_path

    port_list = ",".join(str(p) for p in port_values) or PORT_FALLBACK_RANGE
    _run_nmap_scan(runner, run_dir, run_rel, descriptor, port_list, env)

    summary = _build_summary(
        run_dir, descriptor, top_ports=options.top_ports, max_rate=options.rate
    )
    write_json(summary_path, summary)
    runner.cache_store(key, run_dir, descriptor)
    return summary_path

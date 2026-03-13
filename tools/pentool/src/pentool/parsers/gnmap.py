"""gnmap (nmap greppable output) parsing utilities."""

from __future__ import annotations

from pathlib import Path
from typing import Dict, Iterator, List, Optional, Tuple

from pentool.common import iter_lines, safe_int


def extract_ip_from_gnmap_line(line: str) -> Optional[str]:
    """Extract IP address from gnmap Host line."""
    parts = line.split("\t")
    if not parts:
        return None
    ip_parts = parts[0].split()
    return ip_parts[1] if len(ip_parts) > 1 else None


def extract_ports_segment_from_gnmap(parts: List[str]) -> Optional[str]:
    """Extract ports segment from gnmap line parts."""
    return next((p[7:] for p in parts if p.startswith("Ports: ")), None)


def parse_gnmap_port_block(
    block: str,
) -> Optional[Tuple[int, str, str, str, str]]:
    """Parse a port block from gnmap ports segment."""
    fields = block.strip().split("/")
    if len(fields) < 5:
        return None
    port = safe_int(fields[0])
    if port is None:
        return None
    state, proto, service = fields[1], fields[2], fields[4]
    banner = "/".join(fields[5:]) if len(fields) > 5 else ""
    return port, state, proto, service, banner


def create_gnmap_port_dict(
    port: int, state: str, proto: str, service: str, banner: str
) -> Dict[str, object]:
    """Create port dictionary from gnmap fields."""
    service_dict = {"name": service}
    if banner:
        service_dict["banner"] = banner
    return {
        "port": port,
        "state": state,
        "protocol": proto,
        "service": service_dict,
    }


def iter_gnmap_ports_from_line(
    line: str,
) -> Iterator[Tuple[str, int, Dict[str, object]]]:
    """Iterate port entries from a single gnmap line."""
    if not line.startswith("Host: "):
        return
    ip = extract_ip_from_gnmap_line(line)
    if not ip:
        return
    parts = line.split("\t")
    ports_seg = extract_ports_segment_from_gnmap(parts)
    if not ports_seg:
        return
    for block in ports_seg.split(","):
        parsed = parse_gnmap_port_block(block)
        if not parsed:
            continue
        port, state, proto, service, banner = parsed
        port_dict = create_gnmap_port_dict(port, state, proto, service, banner)
        yield ip, port, port_dict


def iter_gnmap(
    gnmap_path: Path,
) -> Iterator[Tuple[str, int, Dict[str, object]]]:
    """Iterate host, port, and port details from gnmap file."""
    for line in iter_lines(gnmap_path):
        yield from iter_gnmap_ports_from_line(line)

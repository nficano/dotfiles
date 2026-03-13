"""Tool output parsers for various security scanning tools."""

from __future__ import annotations

from pentool.parsers.gnmap import (
    create_gnmap_port_dict,
    extract_ip_from_gnmap_line,
    extract_ports_segment_from_gnmap,
    iter_gnmap,
    iter_gnmap_ports_from_line,
    parse_gnmap_port_block,
)
from pentool.parsers.httpx import (
    build_http_info,
    extract_host_from_httpx,
    extract_port_from_httpx,
    iter_httpx,
    parse_httpx_entries,
    parse_httpx_line,
)
from pentool.parsers.sslyze import (
    build_tls_info,
    extract_server_info,
    extract_tls_accepted_versions,
    iter_sslyze,
)

__all__ = [
    # gnmap
    "create_gnmap_port_dict",
    "extract_ip_from_gnmap_line",
    "extract_ports_segment_from_gnmap",
    "iter_gnmap",
    "iter_gnmap_ports_from_line",
    "parse_gnmap_port_block",
    # httpx
    "build_http_info",
    "extract_host_from_httpx",
    "extract_port_from_httpx",
    "iter_httpx",
    "parse_httpx_entries",
    "parse_httpx_line",
    # sslyze
    "build_tls_info",
    "extract_server_info",
    "extract_tls_accepted_versions",
    "iter_sslyze",
]

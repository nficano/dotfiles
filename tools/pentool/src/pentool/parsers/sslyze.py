"""sslyze JSON output parsing utilities."""

from __future__ import annotations

from pathlib import Path
from typing import Dict, Iterator, List, Optional, Tuple

from pentool.common import safe_int
from pentool.utils import load_json


def extract_server_info(
    scan_result: Dict[str, object],
) -> Optional[Tuple[str, int]]:
    """Extract host and port from sslyze scan result."""
    server = scan_result.get("server_info") or {}
    host = server.get("hostname") or server.get("ip_address")
    port = safe_int(server.get("port"))
    if not host or port is None:
        return None
    return str(host), port


def extract_tls_accepted_versions(results: Dict[str, object]) -> List[str]:
    """Extract accepted TLS versions from sslyze results."""
    tls_suites = results.get("tls_1_3_cipher_suites", {})
    accepted = tls_suites.get("accepted_cipher_suites", [])
    return [it.get("tls_version") for it in accepted if it.get("tls_version")]


def build_tls_info(results: Dict[str, object]) -> Dict[str, object]:
    """Build TLS info dictionary from sslyze scan results."""
    tls_accepted = extract_tls_accepted_versions(results)
    cert = results.get("certificate_info") or {}
    tls_info = {
        "accepted_tls_versions": tls_accepted or None,
        "certificate_subject": cert.get("certificate_subject"),
        "certificate_issuer": cert.get("certificate_issuer"),
    }
    return {k: v for k, v in tls_info.items() if v is not None}


def iter_sslyze(
    sslyze_path: Path,
) -> Iterator[Tuple[str, int, Dict[str, object]]]:
    """Iterate host, port, and TLS info from sslyze JSON."""
    data = load_json(sslyze_path) if sslyze_path.exists() else {}
    for r in data.get("server_scan_results", []):
        server_info = extract_server_info(r)
        if not server_info:
            continue
        host, port = server_info
        results = r.get("scan_commands_results") or {}
        tls_info = build_tls_info(results)
        if not tls_info:
            continue
        yield host, port, {"tls": tls_info, "src": "sslyze"}

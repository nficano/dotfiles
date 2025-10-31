"""httpx JSON output parsing utilities."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, Iterator, List, Optional, Tuple

from pentool.common import iter_lines, safe_int


def parse_httpx_line(raw: str) -> Optional[Dict[str, object]]:
    """Parse a single JSON line from httpx output."""
    if not raw:
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def extract_host_from_httpx(data: Dict[str, object]) -> Optional[str]:
    """Extract host from httpx JSON data."""
    return data.get("host") or data.get("input")


def extract_port_from_httpx(data: Dict[str, object]) -> Optional[int]:
    """Extract port from httpx JSON data."""
    return safe_int(data.get("port"))


def build_http_info(data: Dict[str, object]) -> Dict[str, object]:
    """Build HTTP info dictionary from httpx data."""
    http_info = {
        "url": data.get("url"),
        "status_code": data.get("status-code"),
        "title": data.get("title"),
        "technologies": data.get("technologies"),
    }
    return {k: v for k, v in http_info.items() if v}


def parse_httpx_entries(httpx_path: Path) -> List[Dict[str, object]]:
    """Parse httpx JSON entries returning list of parsed entries."""
    entries: List[Dict[str, object]] = []
    if not httpx_path.exists() or httpx_path.stat().st_size == 0:
        return entries

    with httpx_path.open("r", encoding="utf-8", errors="ignore") as fh:
        for line in fh:
            parsed = parse_httpx_line(line.strip())
            if parsed:
                entries.append(
                    {
                        "url": parsed.get("url"),
                        "status_code": parsed.get("status-code"),
                        "title": parsed.get("title"),
                        "content_length": parsed.get("content-length"),
                        "technologies": parsed.get("technologies"),
                    }
                )
    return entries


def iter_httpx(
    httpx_path: Path,
) -> Iterator[Tuple[str, int, Dict[str, object]]]:
    """Iterate host, port, and HTTP info from httpx JSON lines."""
    for raw in iter_lines(httpx_path):
        data = parse_httpx_line(raw)
        if not data:
            continue
        host = extract_host_from_httpx(data)
        port = extract_port_from_httpx(data)
        if not host or port is None:
            continue
        http_info = build_http_info(data)
        if not http_info:
            continue
        yield host, port, {"http": http_info, "src": "httpx"}

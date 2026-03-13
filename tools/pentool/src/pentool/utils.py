"""Utility helpers for pentool."""

from __future__ import annotations

import datetime as dt
import hashlib
import json
import logging
import os
import re
from dataclasses import dataclass
from datetime import timezone as tz
from pathlib import Path
from typing import Any, Iterable, Optional, Sequence, Tuple

logger = logging.getLogger("pentool")


def utc_timestamp() -> str:
    return dt.datetime.now(tz.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def slugify(value: str) -> str:
    cleaned = value.lower()
    cleaned = re.sub(r"[^a-z0-9._-]+", "-", cleaned)
    cleaned = re.sub(r"-+", "-", cleaned)
    cleaned = cleaned.strip("-")
    return cleaned or "target"


def sha1(value: str) -> str:
    return hashlib.sha1(value.encode()).hexdigest()


def parse_host_port(value: str) -> Optional[Tuple[str, int]]:
    entry = value.strip()
    if not entry or entry.startswith("#"):
        return None
    host = entry
    port_str = "80"
    if " " in entry and entry.count(":") == 0:
        host, port_str = entry.split(None, 1)
    elif "://" in entry:
        host = entry
        port_str = "80"
    elif ":" in entry:
        host, port_str = entry.rsplit(":", 1)
    try:
        port = int(port_str.strip())
    except ValueError:
        return None
    return host.strip(), port


def load_json(path: Path) -> Any:
    if not path.exists() or path.stat().st_size == 0:
        return {}
    with path.open("r", encoding="utf-8") as fh:
        try:
            return json.load(fh)
        except json.JSONDecodeError as exc:
            logger.debug("Failed to parse JSON from %s: %s", path, exc)
            return {}


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")


def append_log(path: Path, message: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(message)


@dataclass(frozen=True)
class CacheKey:
    namespace: str
    components: Sequence[str]

    def render(self) -> str:
        joined = "|".join(self.components)
        return sha1(joined)

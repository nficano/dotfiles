"""Command implementations for pentool."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Sequence


@dataclass(frozen=True)
class DiscoverOptions:
    cidr: Optional[str]
    host: Optional[str]
    targets: Optional[Path]
    top_ports: int
    rate: int
    refresh: bool


@dataclass(frozen=True)
class FingerprintOptions:
    input_path: Optional[Path]
    targets: Optional[Path]
    hosts: Sequence[str]
    enable_http: bool
    threads: int
    refresh: bool


@dataclass(frozen=True)
class WebMapOptions:
    url: str
    depth: int
    wordlist: Optional[Path]
    rate: int
    refresh: bool


@dataclass(frozen=True)
class ScanOptions:
    url: str
    profile: str
    refresh: bool

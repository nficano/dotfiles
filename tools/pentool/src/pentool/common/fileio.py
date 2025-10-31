"""File I/O utilities for efficient line iteration."""

from __future__ import annotations

import mmap
from pathlib import Path
from typing import Iterator


def iter_lines_mmap(path: Path) -> Iterator[str]:
    """Iterate lines using mmap for efficient reading, skipping empty lines."""
    with path.open("rb") as fh, mmap.mmap(
        fh.fileno(), 0, access=mmap.ACCESS_READ
    ) as mm:
        start = 0
        while True:
            i = mm.find(b"\n", start)
            if i == -1:
                chunk = mm[start:].rstrip(b"\r\n")
                if chunk:
                    yield chunk.decode("utf-8", "ignore")
                return
            chunk = mm[start:i].rstrip(b"\r\n")
            if chunk:
                yield chunk.decode("utf-8", "ignore")
            start = i + 1


def iter_lines_buffered(path: Path) -> Iterator[str]:
    """Iterate lines using buffered text IO as fallback, skipping empty lines."""
    with path.open("r", encoding="utf-8", errors="ignore") as fh:
        for line in fh:
            stripped = line.rstrip("\r\n")
            if stripped:
                yield stripped


def iter_lines(path: Path) -> Iterator[str]:
    """Yield non-empty lines from file, trying mmap first then falling back to buffered IO."""
    if not path.exists() or path.stat().st_size == 0:
        return iter(())
    try:
        yield from iter_lines_mmap(path)
    except Exception:
        yield from iter_lines_buffered(path)

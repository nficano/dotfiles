"""Common utility functions shared across command modules."""

from __future__ import annotations

from pentool.common.cache import check_cache
from pentool.common.convert import safe_int
from pentool.common.fileio import (
    iter_lines,
    iter_lines_buffered,
    iter_lines_mmap,
)

__all__ = [
    "check_cache",
    "iter_lines",
    "iter_lines_buffered",
    "iter_lines_mmap",
    "safe_int",
]

"""Type conversion utilities."""

from __future__ import annotations

from typing import Optional


def safe_int(value: object) -> Optional[int]:
    """Safely convert value to integer, returning None on failure."""
    try:
        return int(value)
    except (TypeError, ValueError):
        return None

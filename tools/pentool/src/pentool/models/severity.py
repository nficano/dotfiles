"""Severity normalization and risk level conversion utilities."""

from __future__ import annotations

from typing import Optional

SEVERITY_ORDER = ("critical", "high", "medium", "low", "info")
SEVERITY_LEVEL = {
    "critical": "error",
    "high": "error",
    "medium": "warning",
    "low": "note",
    "info": "note",
}


def normalise_severity(value: str) -> str:
    """Normalize severity string to valid severity level."""
    lower = (value or "").lower()
    return lower if lower in SEVERITY_ORDER else "info"


def risk_to_severity(value: Optional[str]) -> str:
    """Convert risk value to severity level."""
    mapping = {"high": "high", "medium": "medium", "low": "low"}
    return mapping.get((value or "").lower(), "info")

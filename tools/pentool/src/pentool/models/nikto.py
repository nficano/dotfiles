"""Nikto scan result models."""

from __future__ import annotations

from typing import Optional

from pentool.models.finding import Finding
from pentool.models.severity import risk_to_severity
from pydantic import BaseModel


class NiktoFindingModel(BaseModel):
    """Nikto scan finding model."""

    risk: Optional[str] = None
    description: Optional[str] = None
    id: Optional[str] = None
    reference: Optional[str] = None

    def to_finding(self) -> Finding:
        """Convert to standard Finding."""
        title = self.description or self.id or "Nikto finding"
        references = [self.reference] if self.reference else []
        return Finding(
            source="nikto",
            severity=risk_to_severity(self.risk),
            title=title,
            description=self.description or "",
            references=references,
        )

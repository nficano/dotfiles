"""ZAP scan result models."""

from __future__ import annotations

from typing import List, Optional

from pentool.models.finding import Finding
from pentool.models.severity import risk_to_severity
from pydantic import BaseModel, Field


class ZapAlertModel(BaseModel):
    """ZAP alert model."""

    riskdesc: Optional[str] = Field(default=None, alias="riskdesc")
    alert: Optional[str] = None
    desc: Optional[str] = None
    reference: Optional[str] = None
    cweid: Optional[str] = None

    def to_finding(self) -> Finding:
        """Convert to standard Finding."""
        severity_token = (self.riskdesc or "").split()
        severity = risk_to_severity(
            severity_token[0] if severity_token else None
        )
        references = (
            [
                ref.strip()
                for ref in (self.reference or "").split(",")
                if ref.strip()
            ]
            if self.reference
            else []
        )
        return Finding(
            source="zap",
            severity=severity,
            title=self.alert or "ZAP Alert",
            description=self.desc or "",
            references=references,
            cwe=self.cweid,
        )


class ZapSiteModel(BaseModel):
    """ZAP site model."""

    alerts: List[ZapAlertModel] = Field(default_factory=list)


class ZapBaselineModel(BaseModel):
    """ZAP baseline scan model."""

    site: List[ZapSiteModel] = Field(default_factory=list)

"""Core Finding model for security scan results."""

from __future__ import annotations

from typing import List, Optional

from pentool.models.severity import SEVERITY_LEVEL, normalise_severity
from pydantic import BaseModel, Field


class Finding(BaseModel):
    """Represents a security finding from any scan tool."""

    source: str
    severity: str
    title: str
    description: str = ""
    references: List[str] = Field(default_factory=list)
    cwe: Optional[str] = None

    @property
    def normalised_severity(self) -> str:
        """Normalized severity level."""
        return normalise_severity(self.severity)

    @property
    def level(self) -> str:
        """SARIF level corresponding to severity."""
        return SEVERITY_LEVEL[self.normalised_severity]

    @property
    def rule_id(self) -> str:
        """Unique rule identifier."""
        trimmed = (self.title or "finding")[:48]
        return f"{self.source}:{trimmed}"

    def summary_payload(self) -> dict:
        """Generate summary payload for JSON output."""
        payload = self.model_dump()
        payload.update(
            {
                "severity": self.normalised_severity,
                "rule_id": self.rule_id,
                "level": self.level,
            }
        )
        return payload

    def rule_metadata(self) -> dict:
        """Generate SARIF rule metadata."""
        return {
            "id": self.rule_id,
            "name": self.title[:64] or self.rule_id,
            "shortDescription": {"text": self.title[:64] or self.rule_id},
            "fullDescription": {"text": (self.description or "")[:256]},
            "helpUri": (self.references or [None])[0],
            "defaultConfiguration": {"level": self.level},
        }

    def sarif_result(self, url: str) -> dict:
        """Generate SARIF result entry."""
        return {
            "ruleId": self.rule_id,
            "level": self.level,
            "message": {"text": (self.description[:512] or self.title)},
            "properties": {
                "source": self.source,
                "severity": self.normalised_severity,
            },
            "locations": [
                {
                    "physicalLocation": {
                        "artifactLocation": {"uri": url},
                    }
                }
            ],
        }

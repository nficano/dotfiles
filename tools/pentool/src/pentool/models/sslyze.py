"""sslyze scan result models."""

from __future__ import annotations

from typing import List, Optional

from pentool.models.finding import Finding
from pydantic import BaseModel, Field


class SslyzeConnectivityModel(BaseModel):
    """Sslyze connectivity result model."""

    status: Optional[str] = None
    error_message: Optional[str] = None


class SslyzeServerInfoModel(BaseModel):
    """Sslyze server info model."""

    hostname: Optional[str] = None
    ip_address: Optional[str] = None
    port: Optional[int] = None


class SslyzeResultModel(BaseModel):
    """Sslyze scan result model."""

    server_info: SslyzeServerInfoModel = Field(
        default_factory=SslyzeServerInfoModel
    )
    connectivity_result: SslyzeConnectivityModel = Field(
        default_factory=SslyzeConnectivityModel
    )

    def to_finding(self) -> Optional[Finding]:
        """Convert to Finding if connectivity error exists."""
        if self.connectivity_result.status != "ERROR":
            return None
        host = self.server_info.hostname or self.server_info.ip_address or ""
        message = (
            self.connectivity_result.error_message or "TLS handshake failure"
        )
        description = f"{host} - {message}" if host else message
        return Finding(
            source="sslyze",
            severity="medium",
            title="TLS handshake failure",
            description=description,
        )


class SslyzeOutputModel(BaseModel):
    """Sslyze output model."""

    server_scan_results: List[SslyzeResultModel] = Field(default_factory=list)

"""Data models for security scan findings and tool outputs."""

from __future__ import annotations

from pentool.models.finding import Finding
from pentool.models.nikto import NiktoFindingModel
from pentool.models.severity import (
    SEVERITY_LEVEL,
    SEVERITY_ORDER,
    normalise_severity,
    risk_to_severity,
)
from pentool.models.sslyze import (
    SslyzeConnectivityModel,
    SslyzeOutputModel,
    SslyzeResultModel,
    SslyzeServerInfoModel,
)
from pentool.models.zap import ZapAlertModel, ZapBaselineModel, ZapSiteModel

__all__ = [
    # Finding
    "Finding",
    # Severity helpers
    "SEVERITY_LEVEL",
    "SEVERITY_ORDER",
    "normalise_severity",
    "risk_to_severity",
    # Nikto
    "NiktoFindingModel",
    # ZAP
    "ZapAlertModel",
    "ZapBaselineModel",
    "ZapSiteModel",
    # sslyze
    "SslyzeConnectivityModel",
    "SslyzeOutputModel",
    "SslyzeResultModel",
    "SslyzeServerInfoModel",
]

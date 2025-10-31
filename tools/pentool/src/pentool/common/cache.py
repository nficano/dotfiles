"""Cache checking utilities."""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Optional

from pentool.docker_runner import DockerRunner
from pentool.utils import CacheKey

logger = logging.getLogger(__name__)


def check_cache(
    runner: DockerRunner, key: CacheKey, summary_filename: str
) -> Optional[Path]:
    """Check if cached results exist and return summary path if found."""
    cached = runner.cache_lookup(key)
    if not cached:
        return None
    summary = cached / summary_filename
    if summary.exists():
        logger.info("Using cached results: %s", summary)
        return summary
    return None

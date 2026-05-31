"""
Simple in-memory rate limiter for API endpoints.
Tracks daily usage counts per service to stay within free tier quotas.
Resets at midnight UTC.
"""

import time
from datetime import datetime, timezone
from threading import Lock

from app.utils.logging_config import get_logger

logger = get_logger("rate_limiter")


class DailyRateLimiter:
    """
    Tracks daily call counts for a named service.
    Thread-safe via Lock.
    """

    def __init__(self, name: str, daily_limit: int):
        self.name = name
        self.daily_limit = daily_limit
        self._count = 0
        self._reset_date = self._today()
        self._lock = Lock()

    @staticmethod
    def _today() -> str:
        return datetime.now(timezone.utc).strftime("%Y-%m-%d")

    def _maybe_reset(self) -> None:
        """Reset counter if the date has changed."""
        today = self._today()
        if today != self._reset_date:
            self._count = 0
            self._reset_date = today
            logger.info(f"Rate limiter '{self.name}' reset for new day: {today}")

    def check(self) -> bool:
        """Return True if we're under the daily limit."""
        with self._lock:
            self._maybe_reset()
            return self._count < self.daily_limit

    def increment(self) -> int:
        """Increment the counter and return the new count."""
        with self._lock:
            self._maybe_reset()
            self._count += 1
            return self._count

    @property
    def remaining(self) -> int:
        """Return the remaining calls for today."""
        with self._lock:
            self._maybe_reset()
            return max(0, self.daily_limit - self._count)

    @property
    def is_approaching_limit(self) -> bool:
        """Return True if we're within 10% of the daily limit."""
        with self._lock:
            self._maybe_reset()
            return self._count >= (self.daily_limit * 0.9)

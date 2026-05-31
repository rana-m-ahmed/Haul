"""
Health check endpoint — keep-alive target for GitHub Actions ping.
Zero Firestore reads, zero external API calls.
"""

from datetime import datetime, timezone

from fastapi import APIRouter

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check():
    """Health check endpoint. Returns OK with timestamp."""
    return {
        "status": "ok",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "service": "haul-api",
    }

"""
Explain product endpoint: generates personalized "Why you'll love this" copy
using Groq LLaMA 3.1 with template-based fallback.
"""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Request

from app.models.domain import ProductNotFoundError
from app.models.requests import ExplainProductRequest
from app.models.responses import ApiResponse
from app.services.firestore_service import firestore_service
from app.services.groq_service import groq_service
from app.utils.logging_config import get_logger

logger = get_logger("explain")
router = APIRouter(tags=["explain"])


@router.post("/explain-product")
async def explain_product(
    body: ExplainProductRequest,
    request: Request,
):
    """
    Generate a personalized 2-3 sentence explanation of why a product
    suits this specific user.

    Reads: 1 (user document). Product comes from in-memory cache.
    """
    request_id = getattr(request.state, "request_id", "")

    # Get product from cache (zero reads)
    await firestore_service.ensure_cache_fresh()
    product = firestore_service.get_product(body.product_id)

    if not product:
        return ApiResponse.fail(
            code="PRODUCT_NOT_FOUND",
            message=f"Product '{body.product_id}' not found.",
            request_id=request_id,
        ).model_dump(by_alias=True)

    # Get user profile (1 read)
    user_profile = firestore_service.get_user_profile(body.user_id)

    if not user_profile:
        # Create a minimal profile for guests
        from app.models.domain import UserProfile
        user_profile = UserProfile(uid=body.user_id, is_guest=True)

    # Generate explanation (never raises — always returns something)
    explanation = await groq_service.generate_explanation(product, user_profile)

    events = firestore_service.get_user_events(body.user_id, limit=1)
    is_personalized = len(events) > 0

    return ApiResponse.ok(
        data={
            "explanation": explanation,
            "generatedAt": datetime.now(timezone.utc).isoformat(),
            "isPersonalized": is_personalized,
        },
        request_id=request_id,
    ).model_dump(by_alias=True)

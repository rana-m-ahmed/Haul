"""
Recommendations endpoint: computes personalized product recommendations
using the TF-IDF content-based filtering engine.
"""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Query, Request

from app.models.responses import ApiResponse
import dataclasses
from app.services.firestore_service import firestore_service
from app.services.recommendation_engine import recommendation_engine
from app.utils.logging_config import get_logger

logger = get_logger("recommendations")
router = APIRouter(tags=["recommendations"])

def _enrich_recommendations(recs: list[dict]) -> list[dict]:
    enriched = []
    for r in recs:
        p = firestore_service.get_product(r["productId"])
        if p:
            new_r = r.copy()
            new_r["product"] = dataclasses.asdict(p)
            enriched.append(new_r)
    return enriched

@router.get("/recommendations/{user_id}")
async def get_recommendations(
    user_id: str,
    request: Request,
    limit: int = Query(default=12, ge=1, le=30),
    exclude: str = Query(default="", description="Comma-separated product IDs to exclude"),
):
    """
    Compute personalized recommendations for a user.

    Strategy:
    1. Check for a cached preference vector (saves event reads).
    2. If stale, recompute from user events.
    3. If no events (cold start), use onboarding preferences.
    4. If no preferences (guest), return trending.
    """
    request_id = getattr(request.state, "request_id", "")

    # Parse exclusion list
    exclude_ids = set(
        pid.strip() for pid in exclude.split(",") if pid.strip()
    )

    # Ensure product cache is fresh and engine is initialized
    await firestore_service.ensure_cache_fresh()
    products = firestore_service.get_all_products()

    if not recommendation_engine._initialized:
        recommendation_engine.initialize(products)

    # --- Step 1: Check for cached preference vector ---
    user_profile = firestore_service.get_user_profile(user_id)
    use_cached_vector = False

    if user_profile and user_profile.preference_vector:
        # Check if vector is recent (within 60 minutes)
        if user_profile.preference_vector_updated_at:
            age_seconds = (
                datetime.now(timezone.utc) - user_profile.preference_vector_updated_at
            ).total_seconds()
            if age_seconds < 3600:
                use_cached_vector = True

    if use_cached_vector:
        import numpy as np
        user_vector = np.array(user_profile.preference_vector)
        logger.info(f"Using cached vector for {user_id}")

        recommendations = recommendation_engine.recommend(
            user_vector=user_vector,
            exclude_ids=exclude_ids,
            limit=limit,
        )

        return ApiResponse.ok(
            data={
                "recommendations": _enrich_recommendations(recommendations),
                "isPersonalized": True,
                "computedAt": datetime.now(timezone.utc).isoformat(),
            },
            request_id=request_id,
        ).model_dump(by_alias=True)

    # --- Step 2: Recompute from events ---
    events = firestore_service.get_user_events(user_id, limit=200)

    if events:
        user_vector = recommendation_engine.compute_user_vector(events)

        if user_vector is not None:
            # Cache the vector for future requests (saves reads)
            recently_viewed = []
            seen_products = set()
            for event in events:
                product = firestore_service.get_product(event.product_id)
                if product and product.id not in seen_products:
                    recently_viewed.append(product.name)
                    seen_products.add(product.id)
                    if len(recently_viewed) >= 5:
                        break

            firestore_service.update_user_preference_vector(
                user_id,
                recommendation_engine.get_user_vector_as_list(user_vector),
                recently_viewed,
            )

            recommendations = recommendation_engine.recommend(
                user_vector=user_vector,
                exclude_ids=exclude_ids,
                limit=limit,
            )

            return ApiResponse.ok(
                data={
                    "recommendations": _enrich_recommendations(recommendations),
                    "isPersonalized": True,
                    "computedAt": datetime.now(timezone.utc).isoformat(),
                },
                request_id=request_id,
            ).model_dump(by_alias=True)

    # --- Step 3: Cold start — use onboarding preferences ---
    recommendations = recommendation_engine.recommend(
        user_profile=user_profile,
        products=products,
        exclude_ids=exclude_ids,
        limit=limit,
    )

    is_personalized = bool(user_profile and user_profile.preferences)

    return ApiResponse.ok(
        data={
            "recommendations": _enrich_recommendations(recommendations),
            "isPersonalized": is_personalized,
            "computedAt": datetime.now(timezone.utc).isoformat(),
        },
        request_id=request_id,
    ).model_dump(by_alias=True)

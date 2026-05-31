"""
Search endpoint: translates text queries + filters into results
using the in-memory product cache for zero Firestore reads.
"""

from __future__ import annotations

import base64
import json
import math
from typing import Optional

from fastapi import APIRouter, Request

from app.models.requests import SearchRequest
from app.models.responses import ApiResponse
from app.services.firestore_service import firestore_service
from app.utils.logging_config import get_logger

logger = get_logger("search")
router = APIRouter(tags=["search"])


def _tokenize(query: str) -> list[str]:
    """Split query into lowercase tokens, removing short words."""
    return [
        w.lower().strip()
        for w in query.split()
        if len(w.strip()) >= 2
    ]


def _keyword_score(product_keywords: set[str], query_tokens: list[str]) -> float:
    """Score a product by keyword overlap with the query."""
    score = 0.0
    for token in query_tokens:
        # Exact match
        if token in product_keywords:
            score += 3.0
        else:
            # Partial match
            for kw in product_keywords:
                if token in kw or kw in token:
                    score += 1.0
                    break
    return score


@router.post("/search")
async def search_products(
    body: SearchRequest,
    request: Request,
):
    """
    Search the product catalog with text query, filters, and pagination.
    Uses the in-memory cache — zero Firestore reads after cache is warm.
    """
    request_id = getattr(request.state, "request_id", "")

    # Ensure cache is fresh
    await firestore_service.ensure_cache_fresh()
    all_products = firestore_service.get_all_products()

    if not all_products:
        return ApiResponse.ok(
            data={
                "products": [],
                "nextPageToken": None,
                "totalEstimate": 0,
                "appliedFilters": {
                    "category": body.category,
                    "priceRange": (
                        [body.price_min, body.price_max]
                        if body.price_min is not None or body.price_max is not None
                        else None
                    ),
                    "minRating": body.min_rating,
                },
            },
            request_id=request_id,
        ).model_dump(by_alias=True)

    # --- Step 1: Apply hard filters ---
    filtered = all_products

    if body.category:
        filtered = [p for p in filtered if p.category == body.category]

    if body.price_min is not None:
        filtered = [p for p in filtered if p.price >= body.price_min]

    if body.price_max is not None:
        filtered = [p for p in filtered if p.price <= body.price_max]

    if body.min_rating is not None:
        filtered = [p for p in filtered if p.rating >= body.min_rating]

    # --- Step 2: Keyword matching (if query provided) ---
    query_tokens = _tokenize(body.query) if body.query else []

    if query_tokens:
        scored = []
        for product in filtered:
            product_kw = set(product.search_keywords)
            score = _keyword_score(product_kw, query_tokens)
            if score > 0:
                scored.append((product, score))

        # If keyword matching found results, use them
        if scored:
            scored.sort(key=lambda x: x[1], reverse=True)
            filtered = [p for p, _ in scored]
        # If no keyword matches, keep all filtered products (broad result)

    # --- Step 3: Sort ---
    if body.sort_by == "price_asc":
        filtered.sort(key=lambda p: p.price)
    elif body.sort_by == "price_desc":
        filtered.sort(key=lambda p: p.price, reverse=True)
    elif body.sort_by == "newest":
        filtered.sort(
            key=lambda p: p.created_at or 0, reverse=True
        )
    elif body.sort_by == "rating":
        filtered.sort(
            key=lambda p: p.rating * math.log(p.review_count + 1),
            reverse=True,
        )
    # "relevance" keeps the keyword-score order from Step 2

    # --- Step 4: Pagination ---
    total = len(filtered)
    offset = 0

    if body.page_token:
        try:
            decoded = base64.b64decode(body.page_token).decode()
            offset = int(json.loads(decoded).get("offset", 0))
        except Exception:
            offset = 0

    page = filtered[offset : offset + body.page_size]

    # Build next page token
    next_offset = offset + body.page_size
    next_page_token = None
    if next_offset < total:
        token_data = json.dumps({"offset": next_offset})
        next_page_token = base64.b64encode(token_data.encode()).decode()

    # --- Step 5: Format response ---
    products_data = [p.to_api_dict() for p in page]

    return ApiResponse.ok(
        data={
            "products": products_data,
            "nextPageToken": next_page_token,
            "totalEstimate": total,
            "appliedFilters": {
                "category": body.category,
                "priceRange": (
                    [body.price_min, body.price_max]
                    if body.price_min is not None or body.price_max is not None
                    else None
                ),
                "minRating": body.min_rating,
            },
        },
        request_id=request_id,
    ).model_dump(by_alias=True)

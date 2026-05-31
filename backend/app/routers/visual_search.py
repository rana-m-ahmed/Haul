"""
Visual search endpoint: receives an image, identifies the product via Gemini Vision,
and returns matching products from the in-memory catalog.
"""

from __future__ import annotations

import time

from fastapi import APIRouter, File, Query, Request, UploadFile

from app.models.domain import (
    GeminiQuotaExhaustedError,
    GeminiUnavailableError,
    IdentificationFailedError,
)
from app.models.responses import ApiResponse, GeminiQuery, VisualSearchData
from app.services.firestore_service import firestore_service
from app.services.gemini_service import gemini_service
from app.services.product_matcher import product_matcher
from app.utils.logging_config import get_logger

logger = get_logger("visual_search")
router = APIRouter(tags=["visual-search"])

# Max upload size: 4MB
MAX_IMAGE_SIZE = 4 * 1024 * 1024
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/jpg", "image/webp"}


@router.post("/visual-search")
async def visual_search(
    request: Request,
    image: UploadFile = File(...),
    max_results: int = Query(default=8, ge=1, le=15),
):
    """
    Receive an image, identify the product, and return matching catalog products.

    Flow:
    1. Validate image (size, type)
    2. Send to Gemini Vision for identification
    3. Score products from in-memory cache
    4. Return ranked matches
    """
    request_id = getattr(request.state, "request_id", "")
    start_time = time.time()

    # --- Validate image ---
    if image.content_type and image.content_type not in ALLOWED_CONTENT_TYPES:
        return ApiResponse.fail(
            code="INVALID_IMAGE_TYPE",
            message=f"Unsupported image type: {image.content_type}. Use JPEG or PNG.",
            request_id=request_id,
        ).model_dump(by_alias=True)

    image_bytes = await image.read()

    if len(image_bytes) > MAX_IMAGE_SIZE:
        return ApiResponse.fail(
            code="IMAGE_TOO_LARGE",
            message=f"Image size ({len(image_bytes)} bytes) exceeds 4MB limit.",
            request_id=request_id,
        ).model_dump(by_alias=True)

    if len(image_bytes) == 0:
        return ApiResponse.fail(
            code="EMPTY_IMAGE",
            message="Uploaded image is empty.",
            request_id=request_id,
        ).model_dump(by_alias=True)

    # --- Ensure product cache is fresh ---
    await firestore_service.ensure_cache_fresh()

    # --- Call Gemini Vision ---
    try:
        gemini_result = await gemini_service.identify_product(image_bytes)
    except GeminiQuotaExhaustedError:
        return ApiResponse.fail(
            code="QUOTA_APPROACHING",
            message="Visual search quota is limited today. Please try again tomorrow or use text search.",
            request_id=request_id,
        ).model_dump(by_alias=True)
    except GeminiUnavailableError as e:
        logger.warning(f"Gemini unavailable: {e}")
        return ApiResponse.fail(
            code="GEMINI_UNAVAILABLE",
            message="Visual search is temporarily unavailable. Please try again.",
            request_id=request_id,
        ).model_dump(by_alias=True)
    except IdentificationFailedError as e:
        logger.warning(f"Identification failed: {e}")
        return ApiResponse.fail(
            code="IDENTIFICATION_FAILED",
            message="Could not identify the product. Please try a clearer image.",
            request_id=request_id,
        ).model_dump(by_alias=True)

    # --- Check confidence ---
    confidence = gemini_result.get("confidence", 0.0)
    if confidence < 0.3:
        return ApiResponse.ok(
            data=VisualSearchData(
                query=GeminiQuery(**gemini_result),
                products=[],
                processing_time_ms=int((time.time() - start_time) * 1000),
            ).model_dump(by_alias=True),
            request_id=request_id,
        ).model_dump(by_alias=True)

    # --- Match products ---
    all_products = firestore_service.get_all_products()
    matches = product_matcher.match(
        products=all_products,
        gemini_result=gemini_result,
        max_results=max_results,
    )

    elapsed_ms = int((time.time() - start_time) * 1000)

    if not matches:
        return ApiResponse.ok(
            data=VisualSearchData(
                query=GeminiQuery(**gemini_result),
                products=[],
                processing_time_ms=elapsed_ms,
                no_results_reason=f"No products in catalog match the identified category: '{gemini_result.get('category')}'"
            ).model_dump(by_alias=True),
            request_id=request_id,
        ).model_dump(by_alias=True)
    logger.info(
        f"Visual search completed: {len(matches)} matches in {elapsed_ms}ms "
        f"(category={gemini_result.get('category')}, confidence={confidence})"
    )

    return ApiResponse.ok(
        data=VisualSearchData(
            query=GeminiQuery(**gemini_result),
            products=matches,
            processing_time_ms=elapsed_ms,
        ).model_dump(by_alias=True),
        request_id=request_id,
    ).model_dump(by_alias=True)

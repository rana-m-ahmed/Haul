"""
Products endpoint: fetch single or batch products.
"""

from __future__ import annotations

from fastapi import APIRouter, Request

from app.models.requests import BatchProductRequest
from app.models.responses import ApiResponse
from app.services.firestore_service import firestore_service
from app.utils.logging_config import get_logger

logger = get_logger("products")
router = APIRouter(tags=["products"])


@router.get("/products/{product_id}")
async def get_product(product_id: str, request: Request):
    """
    Fetch a single product by ID.
    """
    request_id = getattr(request.state, "request_id", "")
    
    product = firestore_service.get_product(product_id)
    if not product:
        return ApiResponse.fail(
            code="PRODUCT_NOT_FOUND",
            message=f"Product '{product_id}' not found.",
            request_id=request_id,
        ).model_dump(by_alias=True)

    return ApiResponse.ok(
        data=product.to_api_dict(),
        request_id=request_id,
    ).model_dump(by_alias=True)


@router.post("/products/batch")
async def get_products_batch(body: BatchProductRequest, request: Request):
    """
    Fetch multiple products by ID.
    Omit missing products.
    """
    request_id = getattr(request.state, "request_id", "")
    
    products = []
    for pid in body.product_ids:
        product = firestore_service.get_product(pid)
        if product:
            products.append(product.to_api_dict())

    return ApiResponse.ok(
        data={"products": products},
        request_id=request_id,
    ).model_dump(by_alias=True)

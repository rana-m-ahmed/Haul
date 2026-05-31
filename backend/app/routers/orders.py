"""
Orders endpoint: creates orders after successful payment and
writes purchase events for the recommendation engine.
"""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Request

from app.models.requests import CreateOrderRequest
from app.models.responses import ApiResponse
from app.services.firestore_service import firestore_service
from app.utils.logging_config import get_logger

logger = get_logger("orders")
router = APIRouter(tags=["orders"])


@router.get("/orders")
async def get_orders(userId: str, request: Request):
    """Fetch all orders for a specific user."""
    request_id = getattr(request.state, "request_id", "")
    try:
        orders = firestore_service.get_user_orders(userId)
        # Orders from firestore_service need to be returned as dictionaries
        return ApiResponse.ok(
            data={"orders": orders},
            request_id=request_id,
        ).model_dump(by_alias=True)
    except Exception as e:
        logger.error(f"Failed to fetch orders: {e}")
        return ApiResponse.fail(
            code="FETCH_ORDERS_FAILED",
            message="Failed to fetch orders.",
            request_id=request_id,
        ).model_dump(by_alias=True)

@router.post("/orders")
async def create_order(
    body: CreateOrderRequest,
    request: Request,
):
    """
    Create an order document in Firestore and write purchase events.
    Validates items against the product catalog (prices must match).

    Writes: 1 (order) + N (purchase events, one per item).
    """
    request_id = getattr(request.state, "request_id", "")

    # Ensure cache is fresh for price validation
    await firestore_service.ensure_cache_fresh()

    # --- Validate items against catalog ---
    order_items = []
    total = 0.0
    product_ids = []

    for item in body.items:
        product = firestore_service.get_product(item.product_id)
        if not product:
            return ApiResponse.fail(
                code="PRODUCT_NOT_FOUND",
                message=f"Product '{item.product_id}' not found in catalog.",
                request_id=request_id,
            ).model_dump(by_alias=True)

        item_total = product.price * item.quantity
        total += item_total
        product_ids.append(product.id)

        order_items.append({
            "productId": product.id,
            "name": product.name,
            "price": product.price,
            "quantity": item.quantity,
            "variant": item.variant,
            "imageUrl": product.image_urls[0] if product.image_urls else "",
        })

    # --- Validate payment intent ---
    from app.services.stripe_service import stripe_service
    is_paid = await stripe_service.verify_payment_intent(body.stripe_payment_intent_id)
    if not is_paid:
        return ApiResponse.fail(
            code="PAYMENT_NOT_CONFIRMED",
            message="The payment for this order was not confirmed.",
            request_id=request_id,
        ).model_dump(by_alias=True)

    # --- Create order document ---
    order_data = {
        "userId": body.user_id,
        "items": order_items,
        "subtotal": round(total, 2),
        "shipping": 0.00,  # Free shipping for demo
        "total": round(total, 2),
        "status": "confirmed",
        "shippingAddress": {
            "name": body.shipping_address.name,
            "line1": body.shipping_address.line1,
            "line2": body.shipping_address.line2,
            "city": body.shipping_address.city,
            "state": body.shipping_address.state,
            "zip": body.shipping_address.zip_code,
            "country": body.shipping_address.country,
        },
        "stripePaymentIntentId": body.stripe_payment_intent_id,
    }

    try:
        order_id = firestore_service.create_order(order_data)
    except Exception as e:
        logger.error(f"Failed to create order: {e}")
        return ApiResponse.fail(
            code="ORDER_CREATION_FAILED",
            message="Failed to create order. Please try again.",
            request_id=request_id,
        ).model_dump(by_alias=True)

    # --- Write purchase events (for recommendation engine) ---
    try:
        firestore_service.write_purchase_events(body.user_id, product_ids)
    except Exception as e:
        # Non-critical — order is already created
        logger.error(f"Failed to write purchase events: {e}")

    return ApiResponse.ok(
        data={
            "orderId": order_id,
            "status": "confirmed",
            "total": round(total, 2),
            "createdAt": datetime.now(timezone.utc).isoformat(),
        },
        request_id=request_id,
    ).model_dump(by_alias=True)

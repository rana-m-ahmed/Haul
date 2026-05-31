"""
Payment endpoint: creates Stripe PaymentIntents.
The Stripe secret key stays on the backend — the client receives only the client secret.
"""

from __future__ import annotations

from fastapi import APIRouter, Request

from app.models.domain import PaymentError
from app.models.requests import CreatePaymentIntentRequest
from app.models.responses import ApiResponse
from app.services.stripe_service import stripe_service
from app.utils.logging_config import get_logger

logger = get_logger("payments")
router = APIRouter(tags=["payments"])


@router.get("/config/stripe")
async def get_stripe_config(request: Request):
    """Return the Stripe publishable key."""
    from app.config import settings
    request_id = getattr(request.state, "request_id", "")
    return ApiResponse.ok(
        data={"publishableKey": settings.stripe_publishable_key},
        request_id=request_id,
    ).model_dump(by_alias=True)

@router.post("/create-payment-intent")
async def create_payment_intent(
    body: CreatePaymentIntentRequest,
    request: Request,
):
    """
    Create a Stripe PaymentIntent and return the client secret.
    Zero Firestore reads — pure Stripe API call.
    """
    request_id = getattr(request.state, "request_id", "")

    from fastapi.responses import JSONResponse
    if body.amount < 50:
        return JSONResponse(
            status_code=422,
            content=ApiResponse.fail(
                code="INVALID_AMOUNT",
                message="Amount must be at least 50 cents.",
                request_id=request_id,
            ).model_dump(by_alias=True),
        )

    try:
        result = await stripe_service.create_payment_intent(
            amount=body.amount,
            currency=body.currency,
            user_id=body.user_id,
            order_id=body.order_id or "",
        )

        return ApiResponse.ok(
            data=result,
            request_id=request_id,
        ).model_dump(by_alias=True)

    except PaymentError as e:
        logger.error(f"Payment intent creation failed: {e}")
        return ApiResponse.fail(
            code="PAYMENT_FAILED",
            message=str(e),
            request_id=request_id,
        ).model_dump(by_alias=True)

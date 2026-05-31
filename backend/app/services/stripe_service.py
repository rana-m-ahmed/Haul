"""
Stripe service for creating PaymentIntents.
Keeps the Stripe secret key on the backend — the Flutter app only receives
the client secret needed to confirm the payment.
"""

from __future__ import annotations

import stripe

from app.config import settings
from app.models.domain import PaymentError
from app.utils.logging_config import get_logger

logger = get_logger("stripe_service")


class StripeService:
    """Handles Stripe PaymentIntent creation."""

    def __init__(self):
        self._initialized = False

    def _ensure_initialized(self) -> None:
        if not self._initialized:
            if not settings.stripe_secret_key:
                raise PaymentError("STRIPE_SECRET_KEY not configured")
            stripe.api_key = settings.stripe_secret_key
            self._initialized = True

    async def create_payment_intent(
        self,
        amount: int,
        currency: str = "usd",
        user_id: str = "",
        order_id: str = "",
    ) -> dict:
        """
        Create a Stripe PaymentIntent and return the client secret.

        Args:
            amount: Amount in cents (e.g., 4999 for $49.99).
            currency: Three-letter currency code.
            user_id: Firebase UID for metadata.
            order_id: Order ID for metadata.

        Returns:
            Dict with clientSecret and paymentIntentId.

        Raises:
            PaymentError: If Stripe call fails.
        """
        self._ensure_initialized()

        try:
            intent = stripe.PaymentIntent.create(
                amount=amount,
                currency=currency,
                payment_method="pm_card_visa",
                confirm=True,
                automatic_payment_methods={"enabled": True, "allow_redirects": "never"},
                metadata={
                    "userId": user_id,
                    "orderId": order_id,
                    "app": "haul",
                },
            )

            logger.info(f"PaymentIntent created: {intent.id} for \${amount/100:.2f}")

            return {
                "clientSecret": intent.client_secret,
                "paymentIntentId": intent.id,
            }

        except stripe.error.StripeError as e:
            logger.error(f"Stripe error: {e}")
            raise PaymentError(f"Payment failed: {str(e)}")
        except Exception as e:
            logger.error(f"Unexpected Stripe error: {e}")
            raise PaymentError(f"Payment service unavailable: {str(e)}")

    async def verify_payment_intent(self, intent_id: str) -> bool:
        """
        Check if a Stripe PaymentIntent is successful.

        Args:
            intent_id: The Stripe PaymentIntent ID.

        Returns:
            True if status is 'succeeded', False otherwise.
        """
        self._ensure_initialized()
        try:
            intent = stripe.PaymentIntent.retrieve(intent_id)
            return intent.status == "succeeded"
        except Exception as e:
            logger.error(f"Failed to verify PaymentIntent {intent_id}: {e}")
            return False


# Singleton instance
stripe_service = StripeService()

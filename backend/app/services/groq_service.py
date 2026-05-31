"""
Groq API wrapper for generating personalized product explanations.
Uses LLaMA 3.1 8B via Groq's inference API with template-based fallback.
"""

from __future__ import annotations

import time
from typing import Optional

from groq import Groq

from app.config import settings
from app.models.domain import GroqUnavailableError, Product, UserProfile
from app.utils.logging_config import get_logger
from app.utils.rate_limiter import DailyRateLimiter

logger = get_logger("groq_service")

# Prompt template for personalized product explanations
EXPLANATION_PROMPT = """You are a shopping assistant for Haul, a modern e-commerce app. Write a 2-3 sentence personalized explanation of why this product is a great fit for this specific user. Be warm, specific, and reference their browsing patterns. Do not use generic marketing language. Do not use exclamation marks excessively.

Product: {product_name}
Category: {product_category}
Description: {product_description}
Tags: {product_tags}

User's preferred categories: {user_preferences}
User's recently viewed products: {recent_product_names}
User's browsing pattern: Focused on {pattern_summary}

Write the explanation as if you're a knowledgeable friend recommending something, not a salesperson. Keep it under 60 words."""


class GroqService:
    """Handles Groq API calls for personalized product explanations."""

    def __init__(self):
        self._client: Optional[Groq] = None
        self._rate_limiter = DailyRateLimiter(
            name="groq", daily_limit=settings.groq_daily_limit
        )

    def _ensure_client(self) -> None:
        """Lazily initialize the Groq client."""
        if self._client is None:
            if not settings.groq_api_key:
                raise GroqUnavailableError("GROQ_API_KEY not configured")
            self._client = Groq(api_key=settings.groq_api_key)
            logger.info("Groq client initialized")

    def _build_prompt(
        self, product: Product, user: UserProfile
    ) -> str:
        """Build the explanation prompt with real user and product data."""
        # Summarize user's browsing pattern from preferences
        if user.preferences:
            pattern = ", ".join(user.preferences[:3])
        else:
            pattern = product.category.replace("-", " ")

        # Get recently viewed product names
        recent = ", ".join(user.recently_viewed_names[:5]) if user.recently_viewed_names else "various items"

        return EXPLANATION_PROMPT.format(
            product_name=product.name,
            product_category=product.category.replace("-", " "),
            product_description=product.description,
            product_tags=", ".join(product.tags[:8]),
            user_preferences=", ".join(user.preferences) if user.preferences else "general browsing",
            recent_product_names=recent,
            pattern_summary=pattern,
        )

    def _generate_fallback(self, product: Product, user: UserProfile) -> str:
        """
        Template-based fallback when Groq is unavailable.
        Good enough to fill the UI without looking broken.
        """
        category = product.category.replace("-", " ")
        top_tags = ", ".join(product.tags[:2]) if product.tags else category

        if user.preferences:
            user_interest = user.preferences[0].replace("-", " ")
            return (
                f"Based on your interest in {user_interest}, this "
                f"{product.subcategory.replace('-', ' ')} could be a great fit. "
                f"It features {top_tags} that complement the items you've been exploring."
            )
        else:
            return (
                f"This {product.subcategory.replace('-', ' ')} stands out for its "
                f"{top_tags}. It's a popular choice in the {category} category "
                f"and pairs well with similar items in the collection."
            )

    async def generate_explanation(
        self, product: Product, user: UserProfile
    ) -> str:
        """
        Generate a personalized explanation for why a product suits this user.
        Falls back to template-based explanation if Groq is unavailable.

        Returns the explanation string (never raises — always returns something).
        """
        # Check rate limit
        if not self._rate_limiter.check():
            from app.models.domain import GroqRateLimitError
            raise GroqRateLimitError("Groq daily limit reached.")

        try:
            self._ensure_client()
        except GroqUnavailableError:
            return self._generate_fallback(product, user)

        prompt = self._build_prompt(product, user)
        start_time = time.time()

        try:
            response = self._client.chat.completions.create(
                model="llama-3.1-8b-instant",
                messages=[
                    {
                        "role": "system",
                        "content": "You are a helpful shopping assistant. Respond with only the explanation text, no quotes or formatting.",
                    },
                    {"role": "user", "content": prompt},
                ],
                temperature=0.7,
                max_tokens=150,
                timeout=settings.groq_timeout,
            )

            self._rate_limiter.increment()
            elapsed_ms = int((time.time() - start_time) * 1000)
            logger.info(f"Groq responded in {elapsed_ms}ms")

            explanation = response.choices[0].message.content.strip()

            # Basic sanity check — if the response is too short or looks wrong
            if len(explanation) < 20:
                logger.warning(f"Groq response too short ({len(explanation)} chars), using fallback")
                return self._generate_fallback(product, user)

            return explanation

        except Exception as e:
            elapsed_ms = int((time.time() - start_time) * 1000)
            logger.error(f"Groq call failed after {elapsed_ms}ms: {e}")
            return self._generate_fallback(product, user)


# Singleton instance
groq_service = GroqService()

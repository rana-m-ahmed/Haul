"""
Product matcher for visual search results.
Scores products against Gemini-extracted attributes using weighted keyword matching.
"""

from __future__ import annotations

from app.models.domain import Product
from app.utils.logging_config import get_logger

logger = get_logger("product_matcher")

# Scoring weights
WEIGHT_SUBCATEGORY = 4.0
WEIGHT_EXACT_KEYWORD = 3.0
WEIGHT_COLOR = 2.0
WEIGHT_PARTIAL_KEYWORD = 1.0
WEIGHT_STYLE = 1.0
WEIGHT_MATERIAL = 0.5


class ProductMatcher:
    """
    Matches products from the cached catalog against Gemini Vision attributes.
    Two-stage approach: hard filter by category, then soft scoring by attributes.
    """

    def match(
        self,
        products: list[Product],
        gemini_result: dict,
        max_results: int = 8,
    ) -> list[dict]:
        """
        Score and rank products against the visual search attributes.

        Args:
            products: List of all products (from in-memory cache).
            gemini_result: Validated dict from GeminiService.identify_product().
            max_results: Maximum number of results to return.

        Returns:
            List of dicts with product data + matchScore + matchReason, sorted by score desc.
        """
        category = gemini_result.get("category", "")
        subcategory = gemini_result.get("subcategory", "")
        color = gemini_result.get("color", "unknown")
        material = gemini_result.get("material", "unknown")
        style = gemini_result.get("style", "general")
        keywords = gemini_result.get("keywords", [])

        # Stage A: Hard filter by category
        if category:
            category_matches = [p for p in products if p.category == category]
            # If too few results, broaden to all products
            if len(category_matches) < 3:
                category_matches = products
        else:
            category_matches = products

        # Stage B: Soft scoring
        scored: list[tuple[Product, float, str]] = []
        for product in category_matches:
            score, reason = self._compute_score(
                product, subcategory, color, material, style, keywords
            )
            if score > 0:
                scored.append((product, score, reason))

        # Sort by score descending
        scored.sort(key=lambda x: x[1], reverse=True)

        # Normalize scores to 0-1 range
        max_score = scored[0][1] if scored else 1.0
        if max_score == 0:
            max_score = 1.0

        results = []
        for product, raw_score, reason in scored[:max_results]:
            normalized = round(min(raw_score / max_score, 1.0), 2)
            results.append({
                "productId": product.id,
                "name": product.name,
                "price": product.price,
                "imageUrl": product.image_urls[0] if product.image_urls else "",
                "rating": product.rating,
                "matchScore": normalized,
                "matchReason": reason,
            })

        return results

    def _compute_score(
        self,
        product: Product,
        subcategory: str,
        color: str,
        material: str,
        style: str,
        keywords: list[str],
    ) -> tuple[float, str]:
        """
        Compute a weighted match score for a product.
        Returns (score, reason_string).
        """
        score = 0.0
        reasons: list[str] = []
        product_text = set(product.search_keywords + product.tags)

        # Subcategory match (highest weight)
        if subcategory and (
            subcategory in product.subcategory
            or product.subcategory in subcategory
        ):
            score += WEIGHT_SUBCATEGORY
            reasons.append(product.subcategory)

        # Color match
        if color and color != "unknown":
            if color in product_text or any(color in tag for tag in product.tags):
                score += WEIGHT_COLOR
                reasons.append(f"{color} color")

        # Material match
        if material and material != "unknown":
            if material in product_text or any(material in tag for tag in product.tags):
                score += WEIGHT_MATERIAL
                reasons.append(f"{material} material")

        # Style match
        if style and style != "general":
            if style in product_text or any(style in tag for tag in product.tags):
                score += WEIGHT_STYLE
                reasons.append(f"{style} style")

        # Keyword matching
        for kw in keywords:
            kw_lower = kw.lower()
            # Exact match in tags/keywords
            if kw_lower in product_text:
                score += WEIGHT_EXACT_KEYWORD
                reasons.append(kw)
            else:
                # Partial match — keyword is contained in a tag or vice versa
                for tag in product_text:
                    if kw_lower in tag or tag in kw_lower:
                        score += WEIGHT_PARTIAL_KEYWORD
                        break

        # Build human-readable reason
        if reasons:
            reason = ", ".join(reasons[:4])
            reason = f"{product.category.replace('-', ' ').title()}: {reason}"
        else:
            reason = f"General match in {product.category.replace('-', ' ')}"

        return score, reason


# Singleton instance
product_matcher = ProductMatcher()

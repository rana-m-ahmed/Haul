"""
Content-based recommendation engine using TF-IDF + cosine similarity.
Fully in-memory, no external ML service needed.

The TF-IDF matrix is built at startup from the product catalog's attributeText field.
Per-user recommendations compute a weighted preference vector from browsing behavior
and rank products by cosine similarity.
"""

from __future__ import annotations

import math
from datetime import datetime, timezone
from typing import Optional

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from app.models.domain import EVENT_WEIGHTS, EventType, Product, UserEvent, UserProfile
from app.utils.logging_config import get_logger

logger = get_logger("recommendation_engine")


class RecommendationEngine:
    """
    Content-based filtering using TF-IDF on product attributes.
    """

    def __init__(self):
        self._vectorizer: Optional[TfidfVectorizer] = None
        self._tfidf_matrix: Optional[np.ndarray] = None
        self._product_ids: list[str] = []
        self._product_map: dict[str, int] = {}  # product_id → matrix row index
        self._initialized = False

    def initialize(self, products: list[Product]) -> None:
        """
        Build the TF-IDF matrix from all products' attributeText fields.
        Called once at startup and whenever the product cache refreshes.
        """
        if not products:
            logger.warning("No products to initialize recommendation engine")
            return

        self._product_ids = [p.id for p in products]
        self._product_map = {pid: idx for idx, pid in enumerate(self._product_ids)}

        # Build corpus from attributeText (dense text description of product attributes)
        corpus = []
        for p in products:
            # Combine attributeText with tags and category for richer features
            text = f"{p.attribute_text} {' '.join(p.tags)} {p.category} {p.subcategory}"
            corpus.append(text)

        self._vectorizer = TfidfVectorizer(
            max_features=500,
            ngram_range=(1, 2),
            stop_words="english",
            lowercase=True,
        )
        self._tfidf_matrix = self._vectorizer.fit_transform(corpus).toarray()
        self._initialized = True

        logger.info(
            f"Recommendation engine initialized: {len(products)} products, "
            f"{self._tfidf_matrix.shape[1]} features"
        )

    def compute_user_vector(
        self, events: list[UserEvent]
    ) -> Optional[np.ndarray]:
        """
        Compute a user preference vector as the weighted average of
        TF-IDF vectors of products they interacted with.
        """
        if not self._initialized or not events:
            return None

        weighted_sum = np.zeros(self._tfidf_matrix.shape[1])
        total_weight = 0.0

        for event in events:
            idx = self._product_map.get(event.product_id)
            if idx is None:
                continue

            # Determine weight based on event type
            try:
                event_type = EventType(event.event_type)
            except ValueError:
                event_type = EventType.VIEW

            weight = EVENT_WEIGHTS.get(event_type, 1.0)

            # For time_spent events, boost weight if > 30 seconds
            if event_type == EventType.VIEW and event.value and event.value > 30:
                weight = EVENT_WEIGHTS[EventType.TIME_SPENT]

            weighted_sum += self._tfidf_matrix[idx] * weight
            total_weight += weight

        if total_weight == 0:
            return None

        return weighted_sum / total_weight

    def compute_category_vector(self, categories: list[str]) -> Optional[np.ndarray]:
        """
        Compute a synthetic preference vector for cold-start users
        by averaging TF-IDF vectors of products in their preferred categories.
        """
        if not self._initialized or not categories:
            return None

        # We need the product list to filter by category
        # Since we only have the matrix, we need to match by product_id
        # This is called with the product list available in the caller
        return None  # Handled in recommend() below

    def recommend(
        self,
        user_vector: Optional[np.ndarray] = None,
        user_profile: Optional[UserProfile] = None,
        products: Optional[list[Product]] = None,
        exclude_ids: Optional[set[str]] = None,
        limit: int = 12,
    ) -> list[dict]:
        """
        Return ranked product recommendations.

        Strategy:
        1. If user_vector is provided, use it directly (warm user).
        2. If user_profile has preferences, build a category-based vector (cold start).
        3. Otherwise, return trending products (popularity fallback).

        Returns list of {productId, score, reason} dicts.
        """
        if not self._initialized:
            logger.warning("Recommendation engine not initialized")
            return []

        exclude = exclude_ids or set()

        # --- Warm user path ---
        if user_vector is not None:
            return self._rank_by_similarity(
                user_vector, exclude, limit, reason="based_on_browsing"
            )

        # --- Cold start: category preferences ---
        if user_profile and user_profile.preferences and products:
            category_products_indices = []
            for i, pid in enumerate(self._product_ids):
                product = next((p for p in products if p.id == pid), None)
                if product and product.category in user_profile.preferences:
                    category_products_indices.append(i)

            if category_products_indices:
                cat_vector = np.mean(
                    self._tfidf_matrix[category_products_indices], axis=0
                )
                return self._rank_by_similarity(
                    cat_vector, exclude, limit, reason="based_on_category_preference"
                )

        # --- Fallback: trending (highest rating × log(reviewCount)) ---
        if products:
            return self._trending_fallback(products, exclude, limit)

        return []

    def _rank_by_similarity(
        self,
        user_vector: np.ndarray,
        exclude: set[str],
        limit: int,
        reason: str,
    ) -> list[dict]:
        """Rank products by cosine similarity to the user vector."""
        # Reshape for sklearn
        user_vec_2d = user_vector.reshape(1, -1)
        similarities = cosine_similarity(user_vec_2d, self._tfidf_matrix)[0]

        # Build scored list excluding specific products
        scored = []
        for i, score in enumerate(similarities):
            pid = self._product_ids[i]
            if pid not in exclude:
                scored.append((pid, float(score)))

        # Sort by score descending
        scored.sort(key=lambda x: x[1], reverse=True)

        return [
            {"productId": pid, "score": round(score, 4), "reason": reason}
            for pid, score in scored[:limit]
        ]

    def _trending_fallback(
        self, products: list[Product], exclude: set[str], limit: int
    ) -> list[dict]:
        """Fallback: rank by popularity score = rating × log(reviewCount + 1)."""
        scored = []
        for p in products:
            if p.id not in exclude and p.in_stock:
                pop_score = p.rating * math.log(p.review_count + 1)
                scored.append((p.id, pop_score))

        scored.sort(key=lambda x: x[1], reverse=True)

        return [
            {"productId": pid, "score": round(score, 4), "reason": "trending"}
            for pid, score in scored[:limit]
        ]

    def get_user_vector_as_list(self, vector: np.ndarray) -> list[float]:
        """Convert numpy vector to a plain Python list for Firestore storage."""
        return vector.tolist()


# Singleton instance
recommendation_engine = RecommendationEngine()

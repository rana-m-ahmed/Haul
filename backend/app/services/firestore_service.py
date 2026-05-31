"""
Firestore service: cached product catalog + read/write helpers.

The product catalog is loaded into memory at startup and refreshed periodically.
This eliminates thousands of Firestore reads per day — the single biggest
quota-saving decision in the architecture.
"""

from __future__ import annotations

import asyncio
import time
from datetime import datetime, timezone
from typing import Optional

from google.cloud.firestore_v1 import AsyncClient
from google.cloud.firestore_v1.base_query import FieldFilter

from app.config import settings
from app.dependencies import get_firestore_client
from app.models.domain import Product, UserEvent, UserProfile
from app.utils.logging_config import get_logger

logger = get_logger("firestore_service")


class FirestoreService:
    """
    Manages all Firestore interactions with an in-memory product cache.
    """

    def __init__(self):
        self._products_cache: dict[str, Product] = {}
        self._cache_loaded_at: float = 0.0
        self._cache_ttl: float = settings.product_cache_ttl
        self._db = None

    @property
    def db(self):
        if self._db is None:
            self._db = get_firestore_client()
        return self._db

    # ------------------------------------------------------------------
    # Product Catalog Cache
    # ------------------------------------------------------------------

    async def load_product_cache(self) -> None:
        """Load all products from Firestore into memory."""
        try:
            products_ref = self.db.collection("products")
            docs = products_ref.stream()

            new_cache: dict[str, Product] = {}
            count = 0
            for doc in docs:
                product = Product.from_firestore(doc.id, doc.to_dict())
                new_cache[doc.id] = product
                count += 1

            self._products_cache = new_cache
            self._cache_loaded_at = time.time()
            logger.info(f"Product cache loaded: {count} products")
        except Exception as e:
            logger.error(f"Failed to load product cache: {e}", exc_info=True)
            # Gracefully continue with an empty cache for local/dev environments
            # where Firestore credentials may not be configured. This avoids
            # crashing the app during tests or local development.
            if not self._products_cache:
                self._products_cache = {}
                self._cache_loaded_at = time.time()
            # Do not re-raise; callers should handle empty cache states.

    async def ensure_cache_fresh(self) -> None:
        """Reload cache if it's stale."""
        if time.time() - self._cache_loaded_at > self._cache_ttl:
            await self.load_product_cache()

    def get_all_products(self) -> list[Product]:
        """Return all cached products."""
        return list(self._products_cache.values())

    def get_product(self, product_id: str) -> Optional[Product]:
        """Return a single product from cache by ID."""
        return self._products_cache.get(product_id)

    def get_products_by_category(self, category: str) -> list[Product]:
        """Return all products matching a category."""
        return [p for p in self._products_cache.values() if p.category == category]

    # ------------------------------------------------------------------
    # User Profile
    # ------------------------------------------------------------------

    def get_user_profile(self, user_id: str) -> Optional[UserProfile]:
        """Fetch a user profile from Firestore. Costs 1 read."""
        try:
            doc = self.db.collection("users").document(user_id).get()
            if doc.exists:
                return UserProfile.from_firestore(user_id, doc.to_dict())
            return None
        except Exception as e:
            logger.error(f"Failed to fetch user {user_id}: {e}")
            return None

    def update_user_preference_vector(
        self, user_id: str, vector: list[float], recently_viewed: list[str]
    ) -> None:
        """Write the computed preference vector back to the user doc. Costs 1 write."""
        try:
            self.db.collection("users").document(user_id).update({
                "preferenceVector": vector,
                "preferenceVectorUpdatedAt": datetime.now(timezone.utc),
                "recentlyViewedNames": recently_viewed[:5],
            })
        except Exception as e:
            logger.error(f"Failed to update preference vector for {user_id}: {e}")

    # ------------------------------------------------------------------
    # User Events
    # ------------------------------------------------------------------

    def get_user_events(
        self, user_id: str, limit: int = 200
    ) -> list[UserEvent]:
        """
        Fetch recent events for a user, ordered by timestamp desc.
        Costs up to `limit` reads.
        """
        try:
            events_ref = (
                self.db.collection("users")
                .document(user_id)
                .collection("events")
                .order_by("timestamp", direction="DESCENDING")
                .limit(limit)
            )
            docs = events_ref.stream()
            return [UserEvent.from_firestore(doc.to_dict()) for doc in docs]
        except Exception as e:
            logger.error(f"Failed to fetch events for {user_id}: {e}")
            return []

    def record_event(
        self, user_id: str, event_type: str, product_id: str, metadata: Optional[dict] = None
    ) -> bool:
        """
        Write a single user event to the user's subcollection.
        Costs 1 write.
        """
        try:
            now = datetime.now(timezone.utc)
            event_data = {
                "userId": user_id,
                "productId": product_id,
                "eventType": event_type,
                "timestamp": now,
            }
            if metadata:
                if "timeSpentSeconds" in metadata:
                    event_data["value"] = metadata["timeSpentSeconds"]
                elif "variantSelected" in metadata:
                    event_data["variantSelected"] = metadata["variantSelected"]

            self.db.collection("users").document(user_id).collection("events").add(event_data)
            return True
        except Exception as e:
            logger.error(f"Failed to record event for {user_id}: {e}")
            return False

    # ------------------------------------------------------------------
    # Orders
    # ------------------------------------------------------------------

    def get_user_orders(self, user_id: str) -> list[dict]:
        """Fetch all orders for a specific user. Costs up to N reads."""
        try:
            orders_ref = (
                self.db.collection("orders")
                .where(filter=FieldFilter("userId", "==", user_id))
                .order_by("createdAt", direction="DESCENDING")
            )
            docs = orders_ref.stream()
            orders = []
            for doc in docs:
                data = doc.to_dict()
                data["id"] = doc.id
                if "createdAt" in data and hasattr(data["createdAt"], "isoformat"):
                    data["createdAt"] = data["createdAt"].isoformat()
                if "updatedAt" in data and hasattr(data["updatedAt"], "isoformat"):
                    data["updatedAt"] = data["updatedAt"].isoformat()
                orders.append(data)
            return orders
        except Exception as e:
            logger.error(f"Failed to fetch orders for {user_id}: {e}")
            return []

    def create_order(self, order_data: dict) -> str:
        """
        Create an order document in Firestore.
        Returns the auto-generated order ID. Costs 1 write.
        """
        try:
            order_data["createdAt"] = datetime.now(timezone.utc)
            order_data["updatedAt"] = datetime.now(timezone.utc)
            _, doc_ref = self.db.collection("orders").add(order_data)
            logger.info(f"Order created: {doc_ref.id}")
            return doc_ref.id
        except Exception as e:
            logger.error(f"Failed to create order: {e}")
            raise

    def write_purchase_events(self, user_id: str, product_ids: list[str]) -> None:
        """
        Write purchase events for the recommendation engine.
        Uses batch write for efficiency. Costs N writes.
        """
        try:
            batch = self.db.batch()
            now = datetime.now(timezone.utc)

            for pid in product_ids:
                ref = self.db.collection("users").document(user_id).collection("events").document()
                batch.set(ref, {
                    "userId": user_id,
                    "productId": pid,
                    "eventType": "purchase",
                    "value": None,
                    "timestamp": now,
                })

            batch.commit()
            logger.info(f"Wrote {len(product_ids)} purchase events for {user_id}")
        except Exception as e:
            logger.error(f"Failed to write purchase events: {e}")

    # ------------------------------------------------------------------
    # Search (Firestore-backed, for when backend cache isn't sufficient)
    # ------------------------------------------------------------------

    def search_products_firestore(
        self,
        keyword: Optional[str] = None,
        category: Optional[str] = None,
        limit: int = 50,
    ) -> list[Product]:
        """
        Query Firestore for products matching keyword/category.
        Used as a fallback if the in-memory cache is empty.
        Costs up to `limit` reads.
        """
        try:
            ref = self.db.collection("products")

            if category:
                ref = ref.where(filter=FieldFilter("category", "==", category))

            if keyword:
                ref = ref.where(
                    filter=FieldFilter("searchKeywords", "array_contains", keyword.lower())
                )

            ref = ref.limit(limit)
            docs = ref.stream()

            return [Product.from_firestore(doc.id, doc.to_dict()) for doc in docs]
        except Exception as e:
            logger.error(f"Firestore search failed: {e}")
            return []


# Singleton instance
firestore_service = FirestoreService()

"""
Internal domain types used across the backend.
These are not API models — they represent the internal representation of business objects.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Optional


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class ProductCategory(str, Enum):
    FASHION = "fashion"
    ELECTRONICS = "electronics"
    HOME_DECOR = "home-decor"
    SKINCARE_BEAUTY = "skincare-beauty"
    FITNESS = "fitness"


class EventType(str, Enum):
    VIEW = "view"
    CART_ADD = "cart_add"
    PURCHASE = "purchase"
    WISHLIST = "wishlist"
    TIME_SPENT = "time_spent"


class OrderStatus(str, Enum):
    CONFIRMED = "confirmed"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    DELIVERED = "delivered"


# Event weights for the recommendation engine
EVENT_WEIGHTS: dict[EventType, float] = {
    EventType.PURCHASE: 5.0,
    EventType.CART_ADD: 3.0,
    EventType.WISHLIST: 2.0,
    EventType.TIME_SPENT: 1.5,  # > 30s
    EventType.VIEW: 1.0,       # ≤ 30s or default
}


# ---------------------------------------------------------------------------
# Domain Data Classes
# ---------------------------------------------------------------------------

@dataclass
class ProductVariant:
    type: str          # "color", "size"
    value: str         # "Black", "M"
    in_stock: bool = True


@dataclass
class Product:
    id: str
    name: str
    price: float
    category: str
    subcategory: str
    tags: list[str] = field(default_factory=list)
    description: str = ""
    short_description: str = ""
    image_urls: list[str] = field(default_factory=list)
    thumbnail_url: str = ""
    variants: list[ProductVariant] = field(default_factory=list)
    rating: float = 0.0
    review_count: int = 0
    in_stock: bool = True
    is_new: bool = False
    is_on_sale: bool = False
    original_price: Optional[float] = None
    currency: str = "USD"
    search_keywords: list[str] = field(default_factory=list)
    search_text: str = ""
    attribute_text: str = ""
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    @classmethod
    def from_firestore(cls, doc_id: str, data: dict) -> Product:
        """Create a Product from a Firestore document dict."""
        variants = []
        for v in data.get("variants", []):
            variants.append(ProductVariant(
                type=v.get("type", ""),
                value=v.get("value", ""),
                in_stock=v.get("inStock", True),
            ))

        return cls(
            id=doc_id,
            name=data.get("name", ""),
            price=data.get("price", 0.0),
            category=data.get("category", ""),
            subcategory=data.get("subcategory", ""),
            tags=data.get("tags", []),
            description=data.get("description", ""),
            short_description=data.get("shortDescription", ""),
            image_urls=data.get("imageUrls", []),
            thumbnail_url=data.get("thumbnailUrl", ""),
            variants=variants,
            rating=data.get("rating", 0.0),
            review_count=data.get("reviewCount", 0),
            in_stock=data.get("inStock", True),
            is_new=data.get("isNew", False),
            is_on_sale=data.get("isOnSale", False),
            original_price=data.get("originalPrice"),
            currency=data.get("currency", "USD"),
            search_keywords=data.get("searchKeywords", []),
            search_text=data.get("searchText", ""),
            attribute_text=data.get("attributeText", ""),
            created_at=data.get("createdAt"),
            updated_at=data.get("updatedAt"),
        )

    def to_api_dict(self) -> dict:
        """Convert to a dict suitable for API responses (camelCase keys)."""
        return {
            "productId": self.id,
            "name": self.name,
            "price": self.price,
            "originalPrice": self.original_price,
            "currency": self.currency,
            "category": self.category,
            "subcategory": self.subcategory,
            "tags": self.tags,
            "description": self.description,
            "shortDescription": self.short_description,
            "imageUrls": self.image_urls,
            "thumbnailUrl": self.thumbnail_url,
            "variants": [
                {"type": v.type, "value": v.value, "inStock": v.in_stock}
                for v in self.variants
            ],
            "rating": self.rating,
            "reviewCount": self.review_count,
            "inStock": self.in_stock,
            "isNew": self.is_new,
            "isOnSale": self.is_on_sale,
        }


@dataclass
class UserProfile:
    uid: str
    email: Optional[str] = None
    display_name: str = ""
    is_guest: bool = False
    preferences: list[str] = field(default_factory=list)
    preference_vector: Optional[list[float]] = None
    preference_vector_updated_at: Optional[datetime] = None
    recently_viewed_names: list[str] = field(default_factory=list)

    @classmethod
    def from_firestore(cls, uid: str, data: dict) -> UserProfile:
        return cls(
            uid=uid,
            email=data.get("email"),
            display_name=data.get("displayName", ""),
            is_guest=data.get("isGuest", False),
            preferences=data.get("preferences", []),
            preference_vector=data.get("preferenceVector"),
            preference_vector_updated_at=data.get("preferenceVectorUpdatedAt"),
            recently_viewed_names=data.get("recentlyViewedNames", []),
        )


@dataclass
class UserEvent:
    user_id: str
    product_id: str
    event_type: str
    value: Optional[float] = None
    timestamp: Optional[datetime] = None

    @classmethod
    def from_firestore(cls, data: dict) -> UserEvent:
        return cls(
            user_id=data.get("userId", ""),
            product_id=data.get("productId", ""),
            event_type=data.get("eventType", ""),
            value=data.get("value"),
            timestamp=data.get("timestamp"),
        )


@dataclass
class OrderItem:
    product_id: str
    name: str
    price: float
    quantity: int
    variant: Optional[str] = None
    image_url: str = ""


@dataclass
class ShippingAddress:
    name: str
    line1: str
    city: str
    state: str
    zip_code: str
    country: str
    line2: str = ""


# ---------------------------------------------------------------------------
# Custom Exceptions
# ---------------------------------------------------------------------------

class GeminiUnavailableError(Exception):
    """Raised when Gemini Vision API is unavailable or times out."""
    pass


class GeminiQuotaExhaustedError(Exception):
    """Raised when Gemini daily quota is approaching the limit."""
    pass


class GroqUnavailableError(Exception):
    """Raised when Groq API is unavailable or times out."""
    pass


class GroqRateLimitError(Exception):
    """Raised when Groq daily quota is exhausted."""
    pass


class ProductNotFoundError(Exception):
    """Raised when a requested product doesn't exist in the catalog."""
    pass


class IdentificationFailedError(Exception):
    """Raised when Gemini cannot identify a product from the image."""
    pass


class PaymentError(Exception):
    """Raised when a Stripe payment operation fails."""
    pass

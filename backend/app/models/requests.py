"""
Pydantic request models for all API endpoints.
Validated automatically by FastAPI before the route handler runs.
"""

from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Auth & Users
# ---------------------------------------------------------------------------

class SignupRequest(BaseModel):
    """POST body for /auth/signup endpoint."""
    email: str = Field(min_length=3, max_length=150)
    password: str = Field(min_length=6, max_length=150)
    name: Optional[str] = Field(default=None, max_length=100)

class PreferencesRequest(BaseModel):
    """POST body for /users/{uid}/preferences endpoint."""
    categories: list[str] = Field(min_length=1)

# ---------------------------------------------------------------------------
# Visual Search
# ---------------------------------------------------------------------------

class VisualSearchRequest(BaseModel):
    """Query params sent alongside the uploaded image."""
    max_results: int = Field(default=8, ge=1, le=15)


# ---------------------------------------------------------------------------
# Search
# ---------------------------------------------------------------------------

class SearchRequest(BaseModel):
    """POST body for /search endpoint."""
    query: str = Field(default="", max_length=200)
    category: Optional[str] = None
    price_min: Optional[float] = Field(default=None, ge=0, alias="priceMin")
    price_max: Optional[float] = Field(default=None, ge=0, alias="priceMax")
    min_rating: Optional[float] = Field(default=None, ge=0, le=5, alias="minRating")
    sort_by: str = Field(
        default="relevance",
        pattern="^(relevance|price_asc|price_desc|newest|rating)$",
        alias="sortBy",
    )
    page_size: int = Field(default=20, ge=1, le=50, alias="pageSize")
    page_token: Optional[str] = Field(default=None, alias="pageToken")

    model_config = {"populate_by_name": True}


# ---------------------------------------------------------------------------
# Explain Product
# ---------------------------------------------------------------------------

class ExplainProductRequest(BaseModel):
    """POST body for /explain-product endpoint."""
    product_id: str = Field(alias="productId")
    user_id: str = Field(alias="userId")

    model_config = {"populate_by_name": True}


# ---------------------------------------------------------------------------
# Payment Intent
# ---------------------------------------------------------------------------

class CreatePaymentIntentRequest(BaseModel):
    """POST body for /create-payment-intent endpoint."""
    amount: int = Field(le=9999999, description="Amount in cents")
    currency: str = Field(default="usd", pattern="^[a-z]{3}$")
    user_id: str = Field(alias="userId")
    order_id: Optional[str] = Field(default=None, alias="orderId")

    model_config = {"populate_by_name": True}


# ---------------------------------------------------------------------------
# Orders
# ---------------------------------------------------------------------------

class OrderItemRequest(BaseModel):
    """A single item in a create-order request."""
    product_id: str = Field(alias="productId")
    quantity: int = Field(ge=1, le=99)
    variant: Optional[str] = None

    model_config = {"populate_by_name": True}


class ShippingAddressRequest(BaseModel):
    """Shipping address in a create-order request."""
    name: str = Field(min_length=1, max_length=100)
    line1: str = Field(min_length=1, max_length=200)
    line2: str = Field(default="", max_length=200)
    city: str = Field(min_length=1, max_length=100)
    state: str = Field(min_length=1, max_length=100)
    zip_code: str = Field(min_length=1, max_length=20, alias="zip")
    country: str = Field(min_length=1, max_length=100)

    model_config = {"populate_by_name": True}


class CreateOrderRequest(BaseModel):
    """POST body for /orders endpoint."""
    user_id: str = Field(alias="userId")
    items: list[OrderItemRequest] = Field(min_length=1)
    shipping_address: ShippingAddressRequest = Field(alias="shippingAddress")
    stripe_payment_intent_id: str = Field(alias="stripePaymentIntentId")

    model_config = {"populate_by_name": True}


# ---------------------------------------------------------------------------
# Products
# ---------------------------------------------------------------------------

class BatchProductRequest(BaseModel):
    """POST body for /products/batch endpoint."""
    product_ids: list[str] = Field(max_length=20, alias="productIds")

    model_config = {"populate_by_name": True}


# ---------------------------------------------------------------------------
# Events
# ---------------------------------------------------------------------------

class EventMetadata(BaseModel):
    time_spent_seconds: Optional[int] = Field(default=None, alias="timeSpentSeconds")
    variant_selected: Optional[str] = Field(default=None, alias="variantSelected")

    model_config = {"populate_by_name": True}


class UserEventRequest(BaseModel):
    """POST body for /events endpoint."""
    user_id: str = Field(alias="userId")
    event_type: str = Field(pattern="^(view|cart_add|wishlist|purchase)$", alias="eventType")
    product_id: str = Field(alias="productId")
    metadata: Optional[EventMetadata] = None

    model_config = {"populate_by_name": True}

"""
Pydantic response models for all API endpoints.
Every endpoint returns an ApiResponse envelope with success, data, error, and requestId.
"""

from __future__ import annotations

from typing import Any, Generic, Optional, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


# ---------------------------------------------------------------------------
# Standard Envelope
# ---------------------------------------------------------------------------

class ErrorDetail(BaseModel):
    code: str
    message: str


class ApiResponse(BaseModel):
    """Standard response envelope for all endpoints."""
    success: bool
    data: Optional[Any] = None
    error: Optional[ErrorDetail] = None
    request_id: str = Field(alias="requestId", default="")

    model_config = {"populate_by_name": True}

    @classmethod
    def ok(cls, data: Any, request_id: str = "") -> "ApiResponse":
        return cls(success=True, data=data, request_id=request_id)

    @classmethod
    def fail(cls, code: str, message: str, request_id: str = "") -> "ApiResponse":
        return cls(
            success=False,
            error=ErrorDetail(code=code, message=message),
            request_id=request_id,
        )


# ---------------------------------------------------------------------------
# Visual Search
# ---------------------------------------------------------------------------

class GeminiQuery(BaseModel):
    """Structured product identification from Gemini Vision."""
    category: str = ""
    subcategory: str = ""
    color: str = ""
    material: str = ""
    style: str = ""
    keywords: list[str] = Field(default_factory=list)
    confidence: float = 0.0


class MatchedProduct(BaseModel):
    """A product match result from visual search."""
    product_id: str = Field(alias="productId")
    name: str
    price: float
    image_url: str = Field(alias="imageUrl")
    rating: float
    match_score: float = Field(alias="matchScore")
    match_reason: str = Field(default="", alias="matchReason")

    model_config = {"populate_by_name": True}


class VisualSearchData(BaseModel):
    """Data payload for visual search response."""
    query: GeminiQuery
    products: list[MatchedProduct]
    processing_time_ms: int = Field(alias="processingTimeMs")
    no_results_reason: Optional[str] = Field(default=None, alias="noResultsReason")

    model_config = {"populate_by_name": True}


# ---------------------------------------------------------------------------
# Recommendations
# ---------------------------------------------------------------------------

class RecommendationItem(BaseModel):
    product_id: str = Field(alias="productId")
    score: float
    reason: str = ""
    product: Optional[dict] = None

    model_config = {"populate_by_name": True}


class RecommendationsData(BaseModel):
    recommendations: list[RecommendationItem]
    is_personalized: bool = Field(alias="isPersonalized")
    computed_at: str = Field(alias="computedAt")

    model_config = {"populate_by_name": True}


# ---------------------------------------------------------------------------
# Explain Product
# ---------------------------------------------------------------------------

class ExplainProductData(BaseModel):
    explanation: str
    generated_at: str = Field(alias="generatedAt")
    is_personalized: bool = Field(default=True, alias="isPersonalized")

    model_config = {"populate_by_name": True}


# ---------------------------------------------------------------------------
# Search
# ---------------------------------------------------------------------------

class AppliedFilters(BaseModel):
    category: Optional[str] = None
    price_range: Optional[list[float]] = Field(default=None, alias="priceRange")
    min_rating: Optional[float] = Field(default=None, alias="minRating")

    model_config = {"populate_by_name": True}


class SearchData(BaseModel):
    products: list[dict]  # Product API dicts
    next_page_token: Optional[str] = Field(default=None, alias="nextPageToken")
    total_estimate: int = Field(alias="totalEstimate")
    applied_filters: AppliedFilters = Field(alias="appliedFilters")

    model_config = {"populate_by_name": True}


# ---------------------------------------------------------------------------
# Payments
# ---------------------------------------------------------------------------

class PaymentIntentData(BaseModel):
    client_secret: str = Field(alias="clientSecret")
    payment_intent_id: str = Field(alias="paymentIntentId")

    model_config = {"populate_by_name": True}


# ---------------------------------------------------------------------------
# Orders
# ---------------------------------------------------------------------------

class OrderData(BaseModel):
    order_id: str = Field(alias="orderId")
    status: str
    total: float
    created_at: str = Field(alias="createdAt")

    model_config = {"populate_by_name": True}

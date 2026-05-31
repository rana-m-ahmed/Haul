"""
Haul API — FastAPI application factory.
Entry point for the backend service.

Configures CORS, lifespan events (Firebase init, product cache, recommendation engine),
request ID middleware, global error handling, and registers all routers.
"""

from __future__ import annotations

import uuid
import time
import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.dependencies import init_firebase
from app.models.domain import GeminiQuotaExhaustedError, GroqRateLimitError
from app.models.responses import ApiResponse
from app.services.firestore_service import firestore_service
from app.services.recommendation_engine import recommendation_engine
from app.utils.logging_config import get_logger, setup_logging

# --- Routers ---
from app.routers import auth, users, health, visual_search, recommendations, explain, search, payments, orders, products, events

logger = get_logger("main")


# ---------------------------------------------------------------------------
# Lifespan: startup and shutdown events
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup:
    1. Configure logging
    2. Initialize Firebase Admin SDK
    3. Load product catalog into memory
    4. Initialize recommendation engine TF-IDF matrix
    """
    setup_logging(settings.log_level)
    logger.info(f"Starting {settings.app_name} v{settings.app_version}")

    # Initialize Firebase
    try:
        init_firebase()
        logger.info("Firebase initialized")
    except Exception as e:
        logger.error(f"Firebase initialization failed: {e}")
        # Don't crash — health endpoint should still work

    # Load product cache
    try:
        await firestore_service.load_product_cache()
        products = firestore_service.get_all_products()

        # Initialize recommendation engine
        if products:
            recommendation_engine.initialize(products)
            logger.info("Recommendation engine initialized")
        else:
            logger.warning("No products found — recommendation engine not initialized")
    except Exception as e:
        logger.error(f"Product cache load failed: {e}")

    logger.info(f"{settings.app_name} started successfully")
    yield
    logger.info(f"{settings.app_name} shutting down")


# ---------------------------------------------------------------------------
# App Factory
# ---------------------------------------------------------------------------

app = FastAPI(
    title="Haul API",
    description="AI-powered e-commerce backend for Haul — Shop what you see",
    version=settings.app_version,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url=None,
)


# ---------------------------------------------------------------------------
# CORS Middleware
# ---------------------------------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Open for mobile clients; tighten for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Request ID Middleware
# ---------------------------------------------------------------------------

@app.middleware("http")
async def add_request_id(request: Request, call_next):
    """
    Assign a unique request ID to every request.
    Logged in every log entry and returned in every response.
    """
    request_id = str(uuid.uuid4())[:8]
    request.state.request_id = request_id

    start_time = time.time()
    response = await call_next(request)
    elapsed_ms = int((time.time() - start_time) * 1000)

    response.headers["X-Request-ID"] = request_id

    # Log request (skip health checks to reduce noise)
    if request.url.path != "/health":
        logger.info(
            f"{request.method} {request.url.path} → {response.status_code} ({elapsed_ms}ms)",
            extra={"request_id": request_id},
        )

    return response


# ---------------------------------------------------------------------------
# API Key Middleware
# ---------------------------------------------------------------------------

@app.middleware("http")
async def verify_api_key_middleware(request: Request, call_next):
    """Ensure all requests (except docs/health) have the correct API key."""
    # Allow CORS preflight requests and public metadata paths through
    if (
        request.method == "OPTIONS"
        or "access-control-request-method" in (h.lower() for h in request.headers.keys())
        or request.url.path in ["/health", "/docs", "/openapi.json", "/redoc"]
    ):
        return await call_next(request)

    api_key = request.headers.get("x-api-key")
    if not api_key or api_key != settings.haul_api_key:
        request_id = getattr(request.state, "request_id", "")
        return JSONResponse(
            status_code=401,
            content=ApiResponse.fail(
                code="UNAUTHORIZED",
                message="Invalid API key.",
                request_id=request_id,
            ).model_dump(by_alias=True),
        )

    return await call_next(request)


# ---------------------------------------------------------------------------
# Global Exception Handler
# ---------------------------------------------------------------------------

@app.exception_handler(GeminiQuotaExhaustedError)
@app.exception_handler(GroqRateLimitError)
async def rate_limit_exception_handler(request: Request, exc: Exception):
    request_id = getattr(request.state, "request_id", "unknown")
    logger.warning(f"Rate limit exceeded: {exc}", extra={"request_id": request_id})
    return JSONResponse(
        status_code=429,
        content=ApiResponse.fail(
            code="RATE_LIMIT_EXCEEDED",
            message="AI service daily limit reached. Try again tomorrow.",
            request_id=request_id,
        ).model_dump(by_alias=True),
    )

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch-all handler to prevent raw tracebacks in responses."""
    request_id = getattr(request.state, "request_id", "unknown")
    logger.error(
        f"Unhandled exception: {type(exc).__name__}: {exc}",
        exc_info=True,
        extra={"request_id": request_id},
    )
    return JSONResponse(
        status_code=500,
        content=ApiResponse.fail(
            code="INTERNAL_ERROR",
            message="An unexpected error occurred. Please try again.",
            request_id=request_id,
        ).model_dump(by_alias=True),
    )


# ---------------------------------------------------------------------------
# Register Routers
# ---------------------------------------------------------------------------

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(visual_search.router)
app.include_router(recommendations.router)
app.include_router(explain.router)
app.include_router(search.router)
app.include_router(payments.router)
app.include_router(orders.router)
app.include_router(products.router)
app.include_router(events.router)


# ---------------------------------------------------------------------------
# Root
# ---------------------------------------------------------------------------

@app.get("/")
async def root():
    return {
        "name": "Haul API",
        "version": settings.app_version,
        "description": "AI-powered e-commerce backend — Shop what you see",
        "docs": "/docs",
    }

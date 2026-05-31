# Haul Backend Summary

This concise summary gathers the backend context for immersive frontend debugging and development.

**Run:**
- **Local venv:** Activate and run:

```powershell
cd backend
& .\.venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --host 0.0.0.0 --port 7860 --reload
```

- **Docs:** Open the OpenAPI UI at `http://127.0.0.1:7860/docs` while the server is running.

**Key files:**
- **App entry:** [backend/app/main.py](backend/app/main.py)
- **Config:** [backend/app/config.py](backend/app/config.py)
- **Firebase deps:** [backend/app/dependencies.py](backend/app/dependencies.py)
- **Models:** [backend/app/models/requests.py](backend/app/models/requests.py), [backend/app/models/responses.py](backend/app/models/responses.py), [backend/app/models/domain.py](backend/app/models/domain.py)
- **Services (external integrations & caching):**
  - Firestore cache: [backend/app/services/firestore_service.py](backend/app/services/firestore_service.py)
  - Recommendations: [backend/app/services/recommendation_engine.py](backend/app/services/recommendation_engine.py)
  - Stripe: [backend/app/services/stripe_service.py](backend/app/services/stripe_service.py)
  - Gemini Vision: [backend/app/services/gemini_service.py](backend/app/services/gemini_service.py)
  - Groq LLM: [backend/app/services/groq_service.py](backend/app/services/groq_service.py)
  - Visual matching: [backend/app/services/product_matcher.py](backend/app/services/product_matcher.py)

**Primary API endpoints (fast lookup):**
- **GET /health:** Health check — returns `ApiResponse` with `status` and `timestamp`. See [backend/app/routers/health.py](backend/app/routers/health.py)
- **POST /search:** Catalog text search. Request model: `SearchRequest` (`backend/app/models/requests.py`). Returns `SearchData` inside `ApiResponse`. See [backend/app/routers/search.py](backend/app/routers/search.py)
- **POST /explain-product:** Generates personalized explanation. Request: `ExplainProductRequest`. Returns explanation inside `ApiResponse`. See [backend/app/routers/explain.py](backend/app/routers/explain.py)
- **POST /create-payment-intent:** Create Stripe PaymentIntent. Request: `CreatePaymentIntentRequest`. Returns `PaymentIntentData` inside `ApiResponse`. See [backend/app/routers/payments.py](backend/app/routers/payments.py)
- **GET /recommendations/{user_id}:** Personalized recommendations. Returns `RecommendationsData`. See [backend/app/routers/recommendations.py](backend/app/routers/recommendations.py)
- **POST /visual-search:** Upload image file (multipart). Returns `VisualSearchData` with matched products. See [backend/app/routers/visual_search.py](backend/app/routers/visual_search.py)
- **POST /orders:** Create order and write purchase events. Request: `CreateOrderRequest`. See [backend/app/routers/orders.py](backend/app/routers/orders.py)

**Response envelope:**
- All endpoints wrap results in `ApiResponse` (`success`, `data`, `error`, `requestId`) — see [backend/app/models/responses.py](backend/app/models/responses.py)

**External integrations & important env vars (`backend/app/config.py`):**
- `GEMINI_API_KEY` — Gemini Vision (image identification) [gemini_service]
- `GROQ_API_KEY` — Groq LLM (explanations) [groq_service]
- `STRIPE_SECRET_KEY` — Stripe API (payments) [stripe_service]
- `FIREBASE_CREDENTIALS_JSON` — Base64 service account JSON for Firestore [dependencies]
- Other settings: `product_cache_ttl`, daily rate limits, timeouts

**Caching & performance notes:**
- Product catalog is loaded into memory at startup by `firestore_service.load_product_cache()` and used for zero-Read searches and matching.
- Recommendation engine builds a TF-IDF matrix at startup (`recommendation_engine.initialize`). Re-initialized when cache refreshes.
- Gemini/Groq have in-memory daily rate limiters to avoid exceeding free tiers.

**Tests & dev utilities:**
- Quick integration runner: `backend/run_tests.py` (uses FastAPI `TestClient`) — already executed successfully.
- Dependencies: see [backend/requirements.txt](backend/requirements.txt)
- Dockerfile for HF Spaces: [backend/Dockerfile](backend/Dockerfile)

**Suggested next steps for immersive frontend debugging:**
- Open `http://127.0.0.1:7860/docs` to see live request/response schemas and try sample payloads.
- I can generate a Postman/Insomnia collection or a small `swagger-to-ts` client for the frontend.
- If you want offline mocks, I can create a lightweight mock server that returns canned `ApiResponse` payloads for all endpoints.

---

If you want, I can now:
- Generate a Postman collection from the OpenAPI spec,
- Create a mock server returning example responses, or
- Run `pytest --maxfail=1 --disable-warnings -q` with coverage to measure test coverage.

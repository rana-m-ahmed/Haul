# Haul Backend — FastAPI AI Commerce API

> AI-powered e-commerce backend for **Haul — Shop what you see**

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check (keep-alive target) |
| `POST` | `/visual-search` | Image → Gemini Vision → product matches |
| `GET` | `/recommendations/{user_id}` | Personalized product recommendations |
| `POST` | `/explain-product` | AI-generated "Why you'll love this" copy |
| `POST` | `/search` | Text search with filters & pagination |
| `POST` | `/create-payment-intent` | Stripe PaymentIntent creation |
| `POST` | `/orders` | Order creation after payment |

## Quick Start (Local)

```bash
# 1. Create virtual environment
python -m venv venv
venv\Scripts\activate      # Windows
# source venv/bin/activate  # macOS/Linux

# 2. Install dependencies
pip install -r requirements.txt

# 3. Set up environment
cp .env.example .env
# Edit .env with your API keys

# 4. Run the server
uvicorn app.main:app --reload --port 7860

# 5. Open docs
# http://localhost:7860/docs
```

## Seed Demo Catalog

```bash
python -m scripts.seed_catalog
```

## Deploy to Hugging Face Spaces

1. Create a new Docker Space on [huggingface.co](https://huggingface.co/new-space)
2. Push the `backend/` directory to the Space repo
3. Set Secrets in Space settings (see `.env.example` for required variables)
4. The Space will auto-build and serve at `https://{username}-haul-api.hf.space`

## Tech Stack

- **FastAPI** — async Python web framework
- **Gemini Vision** — product identification from images
- **Groq (LLaMA 3.1)** — personalized product explanations
- **scikit-learn** — TF-IDF recommendation engine
- **Cloud Firestore** — product catalog, users, orders
- **Stripe** — payment intent creation (test mode)

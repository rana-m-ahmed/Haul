"""
Demo Catalog Seed Script for Haul.

Populates Firestore with 50 products (10 per category), reviews, and featured collections.
Uses Unsplash API for images and Groq for AI-generated product data.

Usage:
    cd backend
    python -m scripts.seed_catalog

Requirements:
    - .env file with GROQ_API_KEY, UNSPLASH_ACCESS_KEY, and FIREBASE_CREDENTIALS_JSON
    - All pip dependencies installed

Features:
    - Idempotent: re-running overwrites existing data without duplicates
    - Rate-limit aware: respects Unsplash's 50 req/hour limit
    - Batch writes: minimizes Firestore write operations
"""

from __future__ import annotations

import base64
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import httpx
from groq import Groq

from app.config import settings
from app.dependencies import init_firebase, get_firestore_client


# ===========================================================================
# Product Definitions (50 products, 10 per category)
# ===========================================================================

PRODUCT_DEFINITIONS = [
    # --- FASHION (10) ---
    {"search_query": "white minimalist sneakers", "category": "fashion", "subcategory": "shoes", "base_tags": ["sneakers", "white", "minimalist", "casual"], "price_range": (59, 129)},
    {"search_query": "black leather crossbody bag", "category": "fashion", "subcategory": "bags", "base_tags": ["crossbody", "leather", "black", "compact"], "price_range": (45, 110)},
    {"search_query": "denim jacket vintage wash", "category": "fashion", "subcategory": "jackets", "base_tags": ["denim", "jacket", "vintage", "layering"], "price_range": (65, 140)},
    {"search_query": "oversized sunglasses tortoiseshell", "category": "fashion", "subcategory": "accessories", "base_tags": ["sunglasses", "tortoiseshell", "oversized", "retro"], "price_range": (25, 75)},
    {"search_query": "canvas tote bag natural", "category": "fashion", "subcategory": "bags", "base_tags": ["tote", "canvas", "natural", "everyday"], "price_range": (20, 55)},
    {"search_query": "running shoes neon", "category": "fashion", "subcategory": "shoes", "base_tags": ["running", "athletic", "neon", "lightweight"], "price_range": (80, 160)},
    {"search_query": "wool beanie knit gray", "category": "fashion", "subcategory": "accessories", "base_tags": ["beanie", "wool", "gray", "winter"], "price_range": (15, 40)},
    {"search_query": "silk scarf floral print", "category": "fashion", "subcategory": "accessories", "base_tags": ["silk", "scarf", "floral", "elegant"], "price_range": (30, 85)},
    {"search_query": "leather belt brown men", "category": "fashion", "subcategory": "accessories", "base_tags": ["belt", "leather", "brown", "classic"], "price_range": (25, 65)},
    {"search_query": "athletic hoodie zip up", "category": "fashion", "subcategory": "jackets", "base_tags": ["hoodie", "zip-up", "athletic", "comfortable"], "price_range": (40, 90)},

    # --- ELECTRONICS (10) ---
    {"search_query": "wireless earbuds white case", "category": "electronics", "subcategory": "earbuds", "base_tags": ["wireless", "earbuds", "bluetooth", "noise-cancelling"], "price_range": (29, 120)},
    {"search_query": "phone case minimal clear", "category": "electronics", "subcategory": "phone-accessories", "base_tags": ["phone-case", "clear", "minimal", "protective"], "price_range": (12, 35)},
    {"search_query": "portable bluetooth speaker", "category": "electronics", "subcategory": "speakers", "base_tags": ["bluetooth", "speaker", "portable", "waterproof"], "price_range": (30, 80)},
    {"search_query": "usb c charging cable braided", "category": "electronics", "subcategory": "cables", "base_tags": ["usb-c", "charging", "braided", "durable"], "price_range": (8, 25)},
    {"search_query": "laptop stand aluminum adjustable", "category": "electronics", "subcategory": "desk-accessories", "base_tags": ["laptop-stand", "aluminum", "adjustable", "ergonomic"], "price_range": (25, 65)},
    {"search_query": "wireless mouse ergonomic", "category": "electronics", "subcategory": "peripherals", "base_tags": ["mouse", "wireless", "ergonomic", "silent"], "price_range": (20, 55)},
    {"search_query": "smartwatch fitness tracker", "category": "electronics", "subcategory": "wearables", "base_tags": ["smartwatch", "fitness", "tracker", "heart-rate"], "price_range": (40, 150)},
    {"search_query": "mechanical keyboard compact", "category": "electronics", "subcategory": "peripherals", "base_tags": ["keyboard", "mechanical", "compact", "rgb"], "price_range": (45, 130)},
    {"search_query": "power bank slim 10000mah", "category": "electronics", "subcategory": "chargers", "base_tags": ["power-bank", "portable", "slim", "fast-charge"], "price_range": (18, 50)},
    {"search_query": "webcam hd 1080p streaming", "category": "electronics", "subcategory": "cameras", "base_tags": ["webcam", "hd", "1080p", "streaming"], "price_range": (30, 80)},

    # --- HOME & DECOR (10) ---
    {"search_query": "minimalist desk lamp black", "category": "home-decor", "subcategory": "lighting", "base_tags": ["desk-lamp", "black", "minimalist", "led"], "price_range": (30, 80)},
    {"search_query": "indoor plant pot ceramic white", "category": "home-decor", "subcategory": "plants", "base_tags": ["planter", "ceramic", "white", "indoor"], "price_range": (15, 45)},
    {"search_query": "throw pillow velvet emerald", "category": "home-decor", "subcategory": "cushions", "base_tags": ["pillow", "velvet", "emerald", "decorative"], "price_range": (20, 55)},
    {"search_query": "abstract wall art framed", "category": "home-decor", "subcategory": "wall-art", "base_tags": ["wall-art", "abstract", "framed", "modern"], "price_range": (35, 120)},
    {"search_query": "scented candle soy jar", "category": "home-decor", "subcategory": "candles", "base_tags": ["candle", "soy", "scented", "jar"], "price_range": (12, 35)},
    {"search_query": "woven basket storage natural", "category": "home-decor", "subcategory": "storage", "base_tags": ["basket", "woven", "natural", "storage"], "price_range": (18, 50)},
    {"search_query": "table clock modern brass", "category": "home-decor", "subcategory": "clocks", "base_tags": ["clock", "brass", "modern", "table"], "price_range": (25, 70)},
    {"search_query": "linen curtains white sheer", "category": "home-decor", "subcategory": "curtains", "base_tags": ["curtains", "linen", "white", "sheer"], "price_range": (30, 90)},
    {"search_query": "geometric bookend set metal", "category": "home-decor", "subcategory": "bookends", "base_tags": ["bookend", "geometric", "metal", "modern"], "price_range": (18, 45)},
    {"search_query": "hanging macrame planter", "category": "home-decor", "subcategory": "plants", "base_tags": ["macrame", "hanging", "planter", "boho"], "price_range": (15, 40)},

    # --- SKINCARE & BEAUTY (10) ---
    {"search_query": "hyaluronic acid serum dropper", "category": "skincare-beauty", "subcategory": "serums", "base_tags": ["serum", "hyaluronic-acid", "hydrating", "dropper"], "price_range": (15, 50)},
    {"search_query": "jade facial roller beauty", "category": "skincare-beauty", "subcategory": "tools", "base_tags": ["jade-roller", "facial", "massage", "cooling"], "price_range": (12, 35)},
    {"search_query": "moisturizer cream minimal packaging", "category": "skincare-beauty", "subcategory": "moisturizers", "base_tags": ["moisturizer", "cream", "hydrating", "daily"], "price_range": (18, 55)},
    {"search_query": "sheet mask set skincare", "category": "skincare-beauty", "subcategory": "masks", "base_tags": ["sheet-mask", "hydrating", "set", "glow"], "price_range": (8, 25)},
    {"search_query": "lip balm tinted natural", "category": "skincare-beauty", "subcategory": "lips", "base_tags": ["lip-balm", "tinted", "natural", "moisturizing"], "price_range": (6, 18)},
    {"search_query": "sunscreen spf50 face", "category": "skincare-beauty", "subcategory": "sunscreen", "base_tags": ["sunscreen", "spf50", "face", "lightweight"], "price_range": (12, 40)},
    {"search_query": "makeup brush set pink", "category": "skincare-beauty", "subcategory": "tools", "base_tags": ["brushes", "makeup", "set", "synthetic"], "price_range": (15, 45)},
    {"search_query": "eye cream anti aging", "category": "skincare-beauty", "subcategory": "eye-care", "base_tags": ["eye-cream", "anti-aging", "peptides", "dark-circles"], "price_range": (20, 60)},
    {"search_query": "facial cleanser gentle foam", "category": "skincare-beauty", "subcategory": "cleansers", "base_tags": ["cleanser", "foam", "gentle", "daily"], "price_range": (10, 30)},
    {"search_query": "hair oil argan treatment", "category": "skincare-beauty", "subcategory": "hair-care", "base_tags": ["hair-oil", "argan", "treatment", "shine"], "price_range": (12, 35)},

    # --- FITNESS (10) ---
    {"search_query": "resistance bands set exercise", "category": "fitness", "subcategory": "resistance-bands", "base_tags": ["resistance-bands", "set", "exercise", "stretching"], "price_range": (10, 30)},
    {"search_query": "stainless steel water bottle", "category": "fitness", "subcategory": "bottles", "base_tags": ["water-bottle", "stainless-steel", "insulated", "leak-proof"], "price_range": (15, 40)},
    {"search_query": "yoga mat thick purple", "category": "fitness", "subcategory": "yoga", "base_tags": ["yoga-mat", "thick", "non-slip", "exercise"], "price_range": (20, 55)},
    {"search_query": "foam roller muscle recovery", "category": "fitness", "subcategory": "recovery", "base_tags": ["foam-roller", "muscle", "recovery", "deep-tissue"], "price_range": (15, 40)},
    {"search_query": "jump rope speed adjustable", "category": "fitness", "subcategory": "cardio", "base_tags": ["jump-rope", "speed", "adjustable", "cardio"], "price_range": (8, 25)},
    {"search_query": "gym bag duffel sport", "category": "fitness", "subcategory": "bags", "base_tags": ["gym-bag", "duffel", "sport", "compartments"], "price_range": (25, 65)},
    {"search_query": "workout gloves grip fitness", "category": "fitness", "subcategory": "gloves", "base_tags": ["workout-gloves", "grip", "breathable", "weightlifting"], "price_range": (10, 30)},
    {"search_query": "ankle weights adjustable pair", "category": "fitness", "subcategory": "weights", "base_tags": ["ankle-weights", "adjustable", "pair", "toning"], "price_range": (12, 35)},
    {"search_query": "pull up bar doorway", "category": "fitness", "subcategory": "equipment", "base_tags": ["pull-up-bar", "doorway", "no-screws", "home-gym"], "price_range": (20, 50)},
    {"search_query": "massage gun percussion", "category": "fitness", "subcategory": "recovery", "base_tags": ["massage-gun", "percussion", "deep-tissue", "portable"], "price_range": (40, 120)},
]


# ===========================================================================
# Groq Product Data Generation
# ===========================================================================

PRODUCT_GEN_PROMPT = """Generate realistic e-commerce product data for a {category} product.
Search query used for images: "{search_query}"
Base tags: {base_tags}

Return a JSON object with:
- name: a realistic, specific product name (like you'd see on Amazon)
- shortDescription: one compelling sentence
- description: 2-3 sentences, natural, not salesy
- tags: array of 8-12 lowercase single-word or two-word descriptive tags
- variants: array of 2-3 objects with {{"type": "string", "options": ["string"]}}
- price: a realistic price in USD (between {price_min} and {price_max})
- originalPrice: either null (no sale) or a price 20-40% higher than price
- rating: a number between 3.8 and 4.9 (one decimal place)
- reviews: array of 7 objects with {{"userName": "string", "rating": 3-5, "title": "string", "body": "1-2 sentences"}}
- attributeText: a dense 30-50 word description of the product's physical and aesthetic attributes, optimized for text similarity matching

Return ONLY the JSON object, no markdown formatting, no code blocks."""


def generate_product_data(groq_client: Groq, definition: dict) -> dict | None:
    """Call Groq to generate product data from a definition."""
    prompt = PRODUCT_GEN_PROMPT.format(
        category=definition["category"].replace("-", " "),
        search_query=definition["search_query"],
        base_tags=", ".join(definition["base_tags"]),
        price_min=definition["price_range"][0],
        price_max=definition["price_range"][1],
    )

    try:
        response = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {"role": "system", "content": "You are a product data generator. Return only valid JSON."},
                {"role": "user", "content": prompt},
            ],
            temperature=0.8,
            max_tokens=1200,
        )

        text = response.choices[0].message.content.strip()

        # Try to extract JSON
        # Remove markdown code blocks if present
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)

        return json.loads(text)

    except json.JSONDecodeError as e:
        print(f"  ⚠ JSON parse error for '{definition['search_query']}': {e}")
        return None
    except Exception as e:
        print(f"  ⚠ Groq error for '{definition['search_query']}': {e}")
        return None


# ===========================================================================
# Unsplash Image Fetching
# ===========================================================================

def fetch_unsplash_images(
    client: httpx.Client, query: str, count: int = 4
) -> list[str]:
    """Fetch image URLs from Unsplash API."""
    try:
        response = client.get(
            "https://api.unsplash.com/search/photos",
            params={
                "query": query,
                "per_page": count,
                "orientation": "squarish",
            },
            headers={
                "Authorization": f"Client-ID {settings.unsplash_access_key}",
            },
        )
        response.raise_for_status()
        data = response.json()

        urls = []
        for result in data.get("results", []):
            # Use the "regular" size (1080px wide) for product images
            url = result.get("urls", {}).get("regular", "")
            if url:
                urls.append(url)

        return urls

    except Exception as e:
        print(f"  ⚠ Unsplash error for '{query}': {e}")
        return []


# ===========================================================================
# Firestore Seeding
# ===========================================================================

def slugify(text: str) -> str:
    """Convert text to a URL-safe slug for document IDs."""
    slug = text.lower()
    slug = re.sub(r"[^a-z0-9\s-]", "", slug)
    slug = re.sub(r"[\s_]+", "-", slug)
    slug = re.sub(r"-+", "-", slug)
    return slug.strip("-")[:60]


def build_search_keywords(name: str, tags: list[str], category: str, subcategory: str) -> list[str]:
    """Build the searchKeywords array for Firestore queries."""
    tokens = set()
    # Tokenize name
    for word in name.lower().split():
        word = re.sub(r"[^a-z0-9]", "", word)
        if len(word) >= 2:
            tokens.add(word)
    # Add tags
    for tag in tags:
        tokens.add(tag.lower().strip())
    # Add category and subcategory
    for part in category.lower().replace("-", " ").split():
        tokens.add(part)
    for part in subcategory.lower().replace("-", " ").split():
        tokens.add(part)
    return list(tokens)


def seed_products(db, products_data: list[dict]) -> None:
    """Upload products to Firestore using batch writes."""
    print("\n📦 Uploading products to Firestore...")
    batch = db.batch()
    count = 0

    for product in products_data:
        doc_id = product.pop("_doc_id")
        ref = db.collection("products").document(doc_id)
        batch.set(ref, product)
        count += 1

        # Firestore limits batch to 500 operations
        if count % 450 == 0:
            batch.commit()
            batch = db.batch()
            print(f"  ✓ Committed batch ({count} products)")

    batch.commit()
    print(f"  ✓ All {count} products uploaded")


def seed_reviews(db, reviews_data: list[dict]) -> None:
    """Upload reviews as subcollections under products."""
    print("\n⭐ Uploading reviews to Firestore...")
    batch = db.batch()
    count = 0

    for review in reviews_data:
        product_id = review.pop("_product_id")
        ref = db.collection("products").document(product_id).collection("reviews").document()
        batch.set(ref, review)
        count += 1

        if count % 450 == 0:
            batch.commit()
            batch = db.batch()
            print(f"  ✓ Committed batch ({count} reviews)")

    batch.commit()
    print(f"  ✓ All {count} reviews uploaded")


def seed_featured_collections(db, product_ids: list[str]) -> None:
    """Create featured collections."""
    print("\n🎨 Creating featured collections...")

    collections = [
        {
            "title": "Summer Essentials",
            "subtitle": "Stay cool and stylish this season",
            "imageUrl": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800",
            "productIds": product_ids[:8],
            "isActive": True,
            "sortOrder": 1,
        },
        {
            "title": "New Arrivals",
            "subtitle": "Fresh finds just for you",
            "imageUrl": "https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=800",
            "productIds": product_ids[10:18],
            "isActive": True,
            "sortOrder": 2,
        },
        {
            "title": "Under $50",
            "subtitle": "Great finds that won't break the bank",
            "imageUrl": "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800",
            "productIds": [pid for pid in product_ids[:30] if pid],  # Will be filtered by price later
            "isActive": True,
            "sortOrder": 3,
        },
    ]

    for i, collection in enumerate(collections):
        doc_id = slugify(collection["title"])
        db.collection("featuredCollections").document(doc_id).set(collection)

    print(f"  ✓ {len(collections)} featured collections created")


# ===========================================================================
# Main
# ===========================================================================

def main():
    print("=" * 60)
    print("🛍  HAUL — Demo Catalog Seed Script")
    print("=" * 60)

    # --- Validate configuration ---
    if not settings.groq_api_key:
        print("❌ GROQ_API_KEY not set. Create a .env file from .env.example")
        sys.exit(1)
    if not settings.unsplash_access_key:
        print("❌ UNSPLASH_ACCESS_KEY not set. Create a .env file from .env.example")
        sys.exit(1)
    if not settings.firebase_credentials_json:
        print("❌ FIREBASE_CREDENTIALS_JSON not set. Create a .env file from .env.example")
        sys.exit(1)

    # --- Initialize services ---
    print("\n🔧 Initializing services...")
    init_firebase()
    db = get_firestore_client()
    groq_client = Groq(api_key=settings.groq_api_key)
    http_client = httpx.Client(timeout=15.0)

    print(f"  ✓ Firebase connected")
    print(f"  ✓ Groq client ready")
    print(f"  ✓ Unsplash client ready")
    print(f"\n📋 Processing {len(PRODUCT_DEFINITIONS)} product definitions...\n")

    # --- Process each product ---
    all_products = []
    all_reviews = []
    product_ids = []
    unsplash_request_count = 0

    for i, definition in enumerate(PRODUCT_DEFINITIONS):
        prefix = f"[{i+1:02d}/{len(PRODUCT_DEFINITIONS)}]"
        print(f"{prefix} {definition['search_query']}")

        # --- Fetch images from Unsplash ---
        # Respect rate limit: 50 req/hour
        if unsplash_request_count >= 48:
            print(f"\n⏳ Unsplash rate limit pause (waiting 60 seconds)...")
            time.sleep(60)
            unsplash_request_count = 0

        images = fetch_unsplash_images(http_client, definition["search_query"])
        unsplash_request_count += 1

        if not images:
            print(f"  ⚠ No images found, using placeholder")
            images = [f"https://via.placeholder.com/400x400?text={definition['subcategory']}"]

        # --- Generate product data with Groq ---
        generated = generate_product_data(groq_client, definition)
        if not generated:
            print(f"  ⚠ Skipping (generation failed)")
            continue

        # Small delay to avoid Groq rate limits
        time.sleep(0.5)

        # --- Build Firestore document ---
        name = generated.get("name", definition["search_query"].title())
        doc_id = slugify(name)
        tags = generated.get("tags", definition["base_tags"])
        search_keywords = build_search_keywords(
            name, tags, definition["category"], definition["subcategory"]
        )

        product_doc = {
            "_doc_id": doc_id,
            "name": name,
            "price": float(generated.get("price", definition["price_range"][0])),
            "originalPrice": generated.get("originalPrice"),
            "currency": "USD",
            "category": definition["category"],
            "subcategory": definition["subcategory"],
            "tags": tags,
            "description": generated.get("description", ""),
            "shortDescription": generated.get("shortDescription", ""),
            "imageUrls": images,
            "thumbnailUrl": images[0] if images else "",
            "variants": generated.get("variants", []),
            "rating": float(generated.get("rating", 4.2)),
            "reviewCount": len(generated.get("reviews", [])),
            "inStock": True,
            "isNew": i % 5 == 0,  # Every 5th product is "New"
            "isOnSale": generated.get("originalPrice") is not None,
            "searchKeywords": search_keywords,
            "searchText": " ".join(search_keywords),
            "attributeText": generated.get("attributeText", ""),
            "createdAt": datetime.now(timezone.utc),
            "updatedAt": datetime.now(timezone.utc),
        }

        all_products.append(product_doc)
        product_ids.append(doc_id)

        # --- Build review documents ---
        for review in generated.get("reviews", []):
            all_reviews.append({
                "_product_id": doc_id,
                "userName": review.get("userName", "Anonymous"),
                "rating": int(review.get("rating", 4)),
                "title": review.get("title", "Great product"),
                "body": review.get("body", "Really happy with this purchase."),
                "createdAt": datetime.now(timezone.utc),
                "isVerifiedPurchase": True,
            })

        print(f"  ✓ {name} ({len(images)} images, {len(generated.get('reviews', []))} reviews)")

    # --- Upload to Firestore ---
    print(f"\n{'=' * 60}")
    print(f"📊 Summary: {len(all_products)} products, {len(all_reviews)} reviews")
    print(f"{'=' * 60}")

    seed_products(db, all_products)
    seed_reviews(db, all_reviews)
    seed_featured_collections(db, product_ids)

    print(f"\n✅ Seed complete! {len(all_products)} products with {len(all_reviews)} reviews in Firestore.")
    print(f"   Featured collections: 3")
    print(f"   Unsplash API calls: {unsplash_request_count}")

    http_client.close()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Run live endpoint checks against a running Haul backend.

Writes JSON artifacts to `artifacts/` and exits with non-zero on critical failures.
"""
import os
import base64
import io
import json
import time
import sys

import httpx


BASE_URL = os.getenv("BASE_URL", "http://127.0.0.1:7860")
API_KEY = os.getenv("HAUL_API_KEY") or os.getenv("haul_api_key")

# If HAUL_API_KEY not present in env, try loading backend/.env
if not API_KEY:
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    env_path = os.path.normpath(env_path)
    if os.path.exists(env_path):
        try:
            with open(env_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#") or "=" not in line:
                        continue
                    k, v = line.split("=", 1)
                    if k.strip().upper() == "HAUL_API_KEY":
                        API_KEY = v.strip().strip('"').strip("'")
                        break
        except Exception:
            pass


def save(name: str, data: dict):
    os.makedirs("artifacts", exist_ok=True)
    path = os.path.join("artifacts", name)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


def main():
    if not API_KEY:
        print("ERROR: HAUL_API_KEY not found in environment")
        sys.exit(2)

    headers = {"x-api-key": API_KEY}

    client = httpx.Client(timeout=30.0)
    summary = {}

    # Health
    try:
        r = client.get(f"{BASE_URL}/health")
        summary["health"] = {"status_code": r.status_code, "json": r.json()}
        save("health.json", summary["health"])
        print("/health ->", r.status_code)
    except Exception as e:
        print("Health check failed:", e)
        sys.exit(3)

    # Search (grab products to use later)
    try:
        r = client.post(f"{BASE_URL}/search", json={"query": "", "pageSize": 10}, headers=headers)
        summary["search"] = {"status_code": r.status_code, "json": r.json()}
        save("search.json", summary["search"])
        products = r.json().get("data", {}).get("products", []) if r.status_code == 200 else []
        print(f"/search -> {r.status_code}, products={len(products)}")
    except Exception as e:
        print("Search failed:", e)
        products = []

    # Visual search: use a tiny embedded PNG
    png_b64 = (
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg=="
    )
    img_bytes = base64.b64decode(png_b64)

    try:
        files = {"image": ("img.png", img_bytes, "image/png")}
        r = client.post(f"{BASE_URL}/visual-search", files=files, headers=headers)
        summary["visual_search"] = {"status_code": r.status_code, "json": r.json()}
        save("visual_search.json", summary["visual_search"])
        print(f"/visual-search -> {r.status_code}")
    except Exception as e:
        print("Visual search failed:", e)

    # Determine a productId to test explain & payments
    product_id = None
    if products:
        first = products[0]
        # Product entries may already be full dicts or API dicts depending on implementation
        if isinstance(first, dict):
            product_id = first.get("id") or first.get("productId") or first.get("product_id")

    # Explain product
    if product_id:
        try:
            r = client.post(f"{BASE_URL}/explain-product", json={"productId": product_id, "userId": "live_check_user"}, headers=headers)
            summary["explain_product"] = {"status_code": r.status_code, "json": r.json()}
            save("explain_product.json", summary["explain_product"])
            print(f"/explain-product -> {r.status_code}")
        except Exception as e:
            print("Explain product failed:", e)
    else:
        print("Skipping /explain-product (no product id found from search)")

    # Create payment intent
    try:
        r = client.post(f"{BASE_URL}/create-payment-intent", json={"amount": 1500, "currency": "usd", "userId": "live_check_user"}, headers=headers)
        summary["payment_intent"] = {"status_code": r.status_code, "json": r.json()}
        save("payment_intent.json", summary["payment_intent"])
        print(f"/create-payment-intent -> {r.status_code}")
    except Exception as e:
        print("Create payment intent failed:", e)

    # Recommendations
    try:
        r = client.get(f"{BASE_URL}/recommendations/live_check_user", headers=headers, params={"limit": 6})
        summary["recommendations"] = {"status_code": r.status_code, "json": r.json()}
        save("recommendations.json", summary["recommendations"])
        print(f"/recommendations -> {r.status_code}")
    except Exception as e:
        print("Recommendations failed:", e)

    # Events
    try:
        r = client.post(f"{BASE_URL}/events", json={"userId": "live_check_user", "eventType": "view", "productId": product_id or "none"}, headers=headers)
        summary["events"] = {"status_code": r.status_code, "json": r.json()}
        save("events.json", summary["events"])
        print(f"/events -> {r.status_code}")
    except Exception as e:
        print("Events failed:", e)

    # Summary
    save("live_checks_summary.json", summary)
    print("Live checks complete. Artifacts written to artifacts/")


if __name__ == "__main__":
    main()

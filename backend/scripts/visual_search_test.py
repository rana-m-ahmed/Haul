#!/usr/bin/env python3
"""Fetch a sample product image and POST it to /visual-search to validate visual matching.
"""
import os
import httpx
import json

API_KEY = os.getenv("HAUL_API_KEY") or "test_key_123"
BASE_URL = os.getenv("BASE_URL", "http://127.0.0.1:7860")

SAMPLE_URLS = [
    "https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=1200&q=80&auto=format&fit=crop",
    "https://picsum.photos/800/600",
]

def main():
    client = httpx.Client(timeout=60.0)
    # download sample image
    r = None
    for url in SAMPLE_URLS:
        r = client.get(url)
        if r.status_code == 200:
            print("Downloaded sample image from", url)
            break
        else:
            print("Failed to download from", url, "status", r.status_code)

    if r is None or r.status_code != 200:
        print("Failed to download any sample image")
        return

    files = {"image": ("sample.jpg", r.content, "image/jpeg")}
    headers = {"x-api-key": API_KEY}

    resp = client.post(f"{BASE_URL}/visual-search", files=files, headers=headers)
    print("Status:", resp.status_code)
    try:
        data = resp.json()
        print(json.dumps(data, indent=2)[:1000])
        os.makedirs("artifacts", exist_ok=True)
        with open("artifacts/visual_search_real.json", "w", encoding="utf-8") as f:
            json.dump({"status_code": resp.status_code, "json": data}, f, indent=2)
    except Exception as e:
        print("Non-JSON response", e)


if __name__ == "__main__":
    main()

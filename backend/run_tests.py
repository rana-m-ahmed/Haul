import asyncio
from fastapi.testclient import TestClient
from app.main import app
from app.config import settings
import json

def run_tests():
    print("🚀 Starting rigorous backend tests...\n")
    
    # Use a dummy API key for tests if none is configured
    test_api_key = settings.haul_api_key or "test_key_123"
    settings.haul_api_key = test_api_key
    
    headers = {"x-api-key": test_api_key}

    with TestClient(app) as client:
        # 1. Test Health
        print("Testing GET /health...")
        resp = client.get("/health")
        assert resp.status_code == 200, f"Health check failed: {resp.text}"
        print("✅ GET /health passed")
        
        # 1.5 Test Unauthorized API Key
        print("\nTesting Unauthorized API Key...")
        resp = client.post("/search", json={"query": "test"})
        assert resp.status_code == 401, f"Expected 401: {resp.text}"
        print("✅ Unauthorized check passed")

        # 2. Test Search (Empty or populated DB)
        print("\nTesting POST /search...")
        resp = client.post("/search", json={
            "query": "test query",
            "sortBy": "price_asc",
            "pageSize": 10
        }, headers=headers)
        assert resp.status_code == 200, f"Search failed: {resp.text}"
        data = resp.json()
        assert data["success"] is True, f"Search success=False: {data}"
        print(f"✅ POST /search passed (found {data['data']['totalEstimate']} products)")

        # 3. Test Explain Product (Mocked or real)
        print("\nTesting POST /explain-product (with fake product)...")
        resp = client.post("/explain-product", json={
            "productId": "fake_product_id_123",
            "userId": "test_user"
        }, headers=headers)
        data = resp.json()
        if not data["success"]:
            assert data["error"]["code"] == "PRODUCT_NOT_FOUND", f"Unexpected error: {data}"
            print("✅ POST /explain-product correctly handled PRODUCT_NOT_FOUND")
        else:
            print("✅ POST /explain-product succeeded (unexpected with fake ID, but okay if mocked)")

        # 4. Test Payment Intent
        print("\nTesting POST /create-payment-intent...")
        resp = client.post("/create-payment-intent", json={
            "amount": 1500,
            "currency": "usd",
            "userId": "test_user_payment"
        }, headers=headers)
        assert resp.status_code == 200, f"Payment intent failed: {resp.text}"
        data = resp.json()
        assert data["success"] is True
        assert "clientSecret" in data["data"]
        print("✅ POST /create-payment-intent passed (Stripe integration working)")
        
        print("\nTesting POST /create-payment-intent with invalid amount...")
        resp = client.post("/create-payment-intent", json={
            "amount": 40,
            "currency": "usd",
            "userId": "test_user_payment"
        }, headers=headers)
        assert resp.status_code == 422, f"Payment intent validation failed: {resp.text}"
        print("✅ POST /create-payment-intent invalid amount check passed")

        # 5. Test Recommendations
        print("\nTesting GET /recommendations/test_user...")
        resp = client.get("/recommendations/test_user", headers=headers)
        assert resp.status_code == 200, f"Recommendations failed: {resp.text}"
        data = resp.json()
        assert data["success"] is True
        print(f"✅ GET /recommendations passed (returned {len(data['data']['recommendations'])} items)")
        
        # 6. Test Products API
        print("\nTesting GET /products/fake_id...")
        resp = client.get("/products/fake_id", headers=headers)
        assert resp.json()["success"] is False
        assert resp.json()["error"]["code"] == "PRODUCT_NOT_FOUND"
        print("✅ GET /products/{id} passed (not found handled)")
        
        print("\nTesting POST /products/batch...")
        resp = client.post("/products/batch", json={"productIds": ["fake_1", "fake_2"]}, headers=headers)
        assert resp.status_code == 200
        assert len(resp.json()["data"]["products"]) == 0
        print("✅ POST /products/batch passed")
        
        # 7. Test Events API
        print("\nTesting POST /events...")
        resp = client.post("/events", json={
            "userId": "test_user",
            "eventType": "view",
            "productId": "some_product"
        }, headers=headers)
        assert resp.status_code == 200
        assert resp.json()["data"]["recorded"] is True
        print("✅ POST /events passed")

        print("\n🎉 All backend integration tests passed successfully!")

if __name__ == "__main__":
    run_tests()

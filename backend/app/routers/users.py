from fastapi import APIRouter, HTTPException
from app.models.requests import PreferencesRequest
from app.models.responses import ApiResponse
from app.dependencies import get_firestore_client

router = APIRouter(prefix="/users", tags=["users"])

from pydantic import BaseModel

class WishlistRequest(BaseModel):
    product_ids: list[str]

@router.get("/{uid}/profile")
async def get_profile(uid: str):
    """Retrieves user profile from Firestore."""
    try:
        db = get_firestore_client()
        doc = db.collection("users").document(uid).get()
        if doc.exists:
            return ApiResponse.success(data=doc.to_dict())
        return ApiResponse.success(data={"email": "", "displayName": ""})
    except RuntimeError:
        return ApiResponse.success(data={"email": "mock@example.com", "displayName": "Mock User"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{uid}/wishlist")
async def get_wishlist(uid: str):
    """Retrieves user wishlist from Firestore."""
    try:
        db = get_firestore_client()
        doc = db.collection("users").document(uid).collection("settings").document("wishlist").get()
        if doc.exists:
            return ApiResponse.success(data=doc.to_dict())
        return ApiResponse.success(data={"product_ids": []})
    except RuntimeError:
        return ApiResponse.success(data={"product_ids": []})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{uid}/wishlist")
async def save_wishlist(uid: str, request: WishlistRequest):
    """Saves user wishlist to Firestore."""
    try:
        db = get_firestore_client()
        db.collection("users").document(uid).collection("settings").document("wishlist").set({
            "product_ids": request.product_ids
        })
        return ApiResponse.success(data={"status": "saved"})
    except RuntimeError:
        return ApiResponse.success(data={"status": "mock-saved"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{uid}/preferences")
async def save_preferences(uid: str, request: PreferencesRequest):
    """Saves user preferences to Firestore."""
    try:
        db = get_firestore_client()
        doc_ref = db.collection("users").document(uid).collection("settings").document("preferences")
        doc_ref.set({"categories": request.categories})
        return ApiResponse.success(data={"status": "saved"})
    except RuntimeError:
        # Fallback for dev mode
        return ApiResponse.success(data={"status": "mock-saved"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{uid}/preferences")
async def get_preferences(uid: str):
    """Retrieves user preferences from Firestore."""
    try:
        db = get_firestore_client()
        doc_ref = db.collection("users").document(uid).collection("settings").document("preferences")
        doc = doc_ref.get()
        if doc.exists:
            return ApiResponse.success(data=doc.to_dict())
        return ApiResponse.success(data={"categories": []})
    except RuntimeError:
        return ApiResponse.success(data={"categories": []})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

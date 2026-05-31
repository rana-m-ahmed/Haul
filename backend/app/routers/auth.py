from fastapi import APIRouter, HTTPException
import uuid
import firebase_admin.auth as auth
from app.models.requests import SignupRequest
from app.models.responses import ApiResponse
from app.dependencies import get_firebase_app

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/signup")
async def signup(request: SignupRequest):
    """Creates a new user via Firebase Admin and returns their UID."""
    if not get_firebase_app():
        # Fallback for dev mode without Firebase
        return ApiResponse.success(data={"uid": f"mock-uid-{uuid.uuid4()}"})
    
    try:
        user_record = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=request.name
        )
        
        # Save profile to firestore
        from app.dependencies import get_firestore_client
        from datetime import datetime, timezone
        db = get_firestore_client()
        db.collection("users").document(user_record.uid).set({
            "email": request.email,
            "displayName": request.name or "",
            "createdAt": datetime.now(timezone.utc)
        }, merge=True)

        return ApiResponse.success(data={"uid": user_record.uid})
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/guest")
async def guest_login():
    """Creates an anonymous user via Firebase Admin and returns their UID."""
    guest_uid = str(uuid.uuid4())
    if not get_firebase_app():
        return ApiResponse.success(data={"uid": guest_uid})
        
    try:
        user_record = auth.create_user(uid=guest_uid)
        return ApiResponse.success(data={"uid": user_record.uid})
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

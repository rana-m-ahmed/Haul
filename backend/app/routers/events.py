"""
Events endpoint: record user behavior events for recommendations.
"""

from __future__ import annotations

from fastapi import APIRouter, Request

from app.models.requests import UserEventRequest
from app.models.responses import ApiResponse
from app.services.firestore_service import firestore_service
from app.utils.logging_config import get_logger

logger = get_logger("events")
router = APIRouter(tags=["events"])


@router.post("/events")
async def record_event(body: UserEventRequest, request: Request):
    """
    Record a user behavior event to Firestore.
    """
    request_id = getattr(request.state, "request_id", "")
    
    metadata_dict = body.metadata.model_dump(by_alias=True, exclude_none=True) if body.metadata else None
    
    success = firestore_service.record_event(
        user_id=body.user_id,
        event_type=body.event_type,
        product_id=body.product_id,
        metadata=metadata_dict,
    )

    if not success:
        return ApiResponse.fail(
            code="EVENT_RECORD_FAILED",
            message="Failed to record event.",
            request_id=request_id,
        ).model_dump(by_alias=True)

    return ApiResponse.ok(
        data={"recorded": True},
        request_id=request_id,
    ).model_dump(by_alias=True)

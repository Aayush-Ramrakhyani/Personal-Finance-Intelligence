from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user_id
from app.db.base import get_db
from app.schemas.common import SuccessResponse
from app.schemas.notification import MarkReadRequest, NotificationResponse
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=SuccessResponse[list[NotificationResponse]])
async def list_notifications(
    unread_only: bool = Query(False),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = NotificationService(db)
    notifs = await svc.list_notifications(user_id, unread_only, limit, offset)
    return SuccessResponse(data=notifs)


@router.get("/unread-count", response_model=SuccessResponse[dict])
async def unread_count(
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = NotificationService(db)
    count = await svc.count_unread(user_id)
    return SuccessResponse(data={"count": count})


@router.post("/mark-read", response_model=SuccessResponse[dict])
async def mark_read(
    request: MarkReadRequest,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = NotificationService(db)
    count = await svc.mark_read(request.notification_ids, user_id)
    return SuccessResponse(data={"marked_read": count})


@router.post("/mark-all-read", response_model=SuccessResponse[dict])
async def mark_all_read(
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = NotificationService(db)
    count = await svc.mark_all_read(user_id)
    return SuccessResponse(data={"marked_read": count})

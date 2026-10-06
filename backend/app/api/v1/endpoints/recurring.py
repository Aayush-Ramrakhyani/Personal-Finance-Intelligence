from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user_id
from app.db.base import get_db
from app.schemas.common import SuccessResponse
from app.schemas.recurring import RecurringSummary
from app.services.recurring_service import RecurringService

router = APIRouter(prefix="/recurring", tags=["recurring"])


@router.get("", response_model=SuccessResponse[RecurringSummary])
async def list_recurring(
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = RecurringService(db)
    # Detect and update before listing
    await svc.detect_and_update(user_id)
    summary = await svc.list_recurring(user_id)
    return SuccessResponse(data=summary)


@router.post("/{recurring_id}/confirm", response_model=SuccessResponse[dict])
async def confirm_recurring(
    recurring_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = RecurringService(db)
    await svc.update_status(recurring_id, user_id, "confirmed")
    return SuccessResponse(data={"message": "Recurring expense confirmed."})


@router.delete("/{recurring_id}", response_model=SuccessResponse[dict])
async def reject_recurring(
    recurring_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = RecurringService(db)
    await svc.update_status(recurring_id, user_id, "rejected")
    return SuccessResponse(data={"message": "Recurring expense rejected."})

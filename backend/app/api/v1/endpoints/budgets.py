from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user_id
from app.db.base import get_db
from app.schemas.budget import BudgetCreate, BudgetUpdate, BudgetWithProgress
from app.schemas.common import SuccessResponse
from app.services.budget_service import BudgetService

router = APIRouter(prefix="/budgets", tags=["budgets"])


@router.get("", response_model=SuccessResponse[list[BudgetWithProgress]])
async def list_budgets(
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = BudgetService(db)
    budgets = await svc.list_budgets(user_id)
    return SuccessResponse(data=budgets)


@router.post("", response_model=SuccessResponse[BudgetWithProgress], status_code=201)
async def create_budget(
    data: BudgetCreate,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = BudgetService(db)
    budget = await svc.create(user_id, data)
    return SuccessResponse(data=budget)


@router.get("/{budget_id}", response_model=SuccessResponse[BudgetWithProgress])
async def get_budget(
    budget_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = BudgetService(db)
    budget = await svc.get(budget_id, user_id)
    return SuccessResponse(data=budget)


@router.patch("/{budget_id}", response_model=SuccessResponse[BudgetWithProgress])
async def update_budget(
    budget_id: UUID,
    data: BudgetUpdate,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = BudgetService(db)
    budget = await svc.update(budget_id, user_id, data)
    return SuccessResponse(data=budget)


@router.delete("/{budget_id}", response_model=SuccessResponse[dict])
async def delete_budget(
    budget_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = BudgetService(db)
    await svc.delete(budget_id, user_id)
    return SuccessResponse(data={"message": "Budget deleted."})

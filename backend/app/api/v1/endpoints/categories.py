from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user_id
from app.db.base import get_db
from app.schemas.category import CategoryCreate, CategoryResponse, CategoryUpdate
from app.schemas.common import SuccessResponse
from app.services.category_service import CategoryService

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=SuccessResponse[list[CategoryResponse]])
async def list_categories(
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = CategoryService(db)
    categories = await svc.list_categories(user_id)
    return SuccessResponse(data=categories)


@router.post("", response_model=SuccessResponse[CategoryResponse], status_code=201)
async def create_category(
    data: CategoryCreate,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = CategoryService(db)
    category = await svc.create_category(user_id, data)
    return SuccessResponse(data=category)


@router.patch("/{category_id}", response_model=SuccessResponse[CategoryResponse])
async def update_category(
    category_id: UUID,
    data: CategoryUpdate,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = CategoryService(db)
    category = await svc.update_category(category_id, user_id, data)
    return SuccessResponse(data=category)


@router.delete("/{category_id}", response_model=SuccessResponse[dict])
async def delete_category(
    category_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = CategoryService(db)
    await svc.delete_category(category_id, user_id)
    return SuccessResponse(data={"message": "Category deleted."})

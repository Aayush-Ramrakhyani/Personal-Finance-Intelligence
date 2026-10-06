from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user_id
from app.db.base import get_db
from app.schemas.account import AccountCreate, AccountResponse, AccountUpdate
from app.schemas.common import SuccessResponse
from app.services.account_service import AccountService

router = APIRouter(prefix="/accounts", tags=["accounts"])


@router.get("", response_model=SuccessResponse[list[AccountResponse]])
async def list_accounts(
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = AccountService(db)
    accounts = await svc.list_accounts(user_id)
    return SuccessResponse(data=accounts)


@router.post("", response_model=SuccessResponse[AccountResponse], status_code=201)
async def create_account(
    data: AccountCreate,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = AccountService(db)
    account = await svc.create(user_id, data)
    return SuccessResponse(data=account)


@router.get("/{account_id}", response_model=SuccessResponse[AccountResponse])
async def get_account(
    account_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = AccountService(db)
    account = await svc.get(account_id, user_id)
    return SuccessResponse(data=account)


@router.patch("/{account_id}", response_model=SuccessResponse[AccountResponse])
async def update_account(
    account_id: UUID,
    data: AccountUpdate,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = AccountService(db)
    account = await svc.update(account_id, user_id, data)
    return SuccessResponse(data=account)


@router.delete("/{account_id}", response_model=SuccessResponse[dict])
async def delete_account(
    account_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = AccountService(db)
    await svc.delete(account_id, user_id)
    return SuccessResponse(data={"message": "Account archived."})

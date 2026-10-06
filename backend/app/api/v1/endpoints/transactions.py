import math
from datetime import date
from decimal import Decimal
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user_id
from app.db.base import get_db
from app.schemas.common import PaginatedResponse, SuccessResponse
from app.schemas.transaction import (
    TransactionCreate,
    TransactionFilter,
    TransactionResponse,
    TransactionUpdate,
    TransferCreate,
)
from app.services.transaction_service import TransactionService

router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.get("", response_model=PaginatedResponse[TransactionResponse])
async def list_transactions(
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    category_id: Optional[UUID] = Query(None),
    account_id: Optional[UUID] = Query(None),
    type: Optional[str] = Query(None),
    merchant: Optional[str] = Query(None),
    min_amount: Optional[Decimal] = Query(None),
    max_amount: Optional[Decimal] = Query(None),
    payment_method: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    sort_by: str = Query("transaction_date"),
    sort_order: str = Query("desc"),
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    filters = TransactionFilter(
        start_date=start_date,
        end_date=end_date,
        category_id=category_id,
        account_id=account_id,
        type=type,
        merchant=merchant,
        min_amount=min_amount,
        max_amount=max_amount,
        payment_method=payment_method,
        search=search,
        page=page,
        limit=limit,
        sort_by=sort_by,
        sort_order=sort_order,
    )
    svc = TransactionService(db)
    txns, total = await svc.list(user_id, filters)
    return PaginatedResponse(
        data=txns,
        total=total,
        page=page,
        limit=limit,
        pages=math.ceil(total / limit) if limit > 0 else 1,
    )


@router.post("", response_model=SuccessResponse[TransactionResponse], status_code=201)
async def create_transaction(
    data: TransactionCreate,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = TransactionService(db)
    txn = await svc.create(user_id, data)
    return SuccessResponse(data=txn)


@router.post("/transfers", response_model=SuccessResponse[dict], status_code=201)
async def create_transfer(
    data: TransferCreate,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = TransactionService(db)
    from_txn, to_txn = await svc.create_transfer(user_id, data)
    return SuccessResponse(data={"from_transaction": from_txn.model_dump(mode="json"),
                                  "to_transaction": to_txn.model_dump(mode="json")})


@router.get("/{transaction_id}", response_model=SuccessResponse[TransactionResponse])
async def get_transaction(
    transaction_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = TransactionService(db)
    txn = await svc.get(transaction_id, user_id)
    return SuccessResponse(data=txn)


@router.patch("/{transaction_id}", response_model=SuccessResponse[TransactionResponse])
async def update_transaction(
    transaction_id: UUID,
    data: TransactionUpdate,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = TransactionService(db)
    txn = await svc.update(transaction_id, user_id, data)
    return SuccessResponse(data=txn)


@router.delete("/{transaction_id}", response_model=SuccessResponse[dict])
async def delete_transaction(
    transaction_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = TransactionService(db)
    await svc.delete(transaction_id, user_id)
    return SuccessResponse(data={"message": "Transaction deleted."})

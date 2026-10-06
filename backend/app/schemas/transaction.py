import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, field_validator

VALID_TYPES = {"income", "expense", "transfer"}
VALID_PAYMENT_METHODS = {"cash", "upi", "card", "netbanking", "other"}


class TransactionCreate(BaseModel):
    account_id: uuid.UUID
    category_id: Optional[uuid.UUID] = None
    type: str
    amount: Decimal
    currency: str = "INR"
    merchant: Optional[str] = None
    description: Optional[str] = None
    transaction_date: date
    payment_method: Optional[str] = None
    notes: Optional[str] = None

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        if v not in VALID_TYPES:
            raise ValueError(f"Type must be one of: {', '.join(VALID_TYPES)}")
        return v

    @field_validator("amount")
    @classmethod
    def validate_amount(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Amount must be positive.")
        return round(v, 2)

    @field_validator("payment_method")
    @classmethod
    def validate_payment_method(cls, v: Optional[str]) -> Optional[str]:
        if v and v not in VALID_PAYMENT_METHODS:
            raise ValueError(f"Payment method must be one of: {', '.join(VALID_PAYMENT_METHODS)}")
        return v


class TransferCreate(BaseModel):
    from_account_id: uuid.UUID
    to_account_id: uuid.UUID
    amount: Decimal
    description: Optional[str] = None
    transfer_date: date
    currency: str = "INR"

    @field_validator("amount")
    @classmethod
    def validate_amount(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Amount must be positive.")
        return round(v, 2)


class TransactionUpdate(BaseModel):
    category_id: Optional[uuid.UUID] = None
    merchant: Optional[str] = None
    description: Optional[str] = None
    transaction_date: Optional[date] = None
    payment_method: Optional[str] = None
    notes: Optional[str] = None
    amount: Optional[Decimal] = None

    @field_validator("amount")
    @classmethod
    def validate_amount(cls, v: Optional[Decimal]) -> Optional[Decimal]:
        if v is not None:
            if v <= 0:
                raise ValueError("Amount must be positive.")
            return round(v, 2)
        return v


class CategorySummary(BaseModel):
    id: uuid.UUID
    name: str
    type: str
    icon: Optional[str]
    color: Optional[str]
    model_config = {"from_attributes": True}


class TransactionResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    account_id: uuid.UUID
    category_id: Optional[uuid.UUID]
    category: Optional[CategorySummary]
    type: str
    amount: Decimal
    currency: str
    merchant: Optional[str]
    description: Optional[str]
    transaction_date: date
    payment_method: Optional[str]
    notes: Optional[str]
    source: str
    external_reference: Optional[str]
    is_recurring: bool
    category_source: Optional[str]
    category_confidence: Optional[Decimal]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class TransactionFilter(BaseModel):
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    category_id: Optional[uuid.UUID] = None
    account_id: Optional[uuid.UUID] = None
    type: Optional[str] = None
    merchant: Optional[str] = None
    min_amount: Optional[Decimal] = None
    max_amount: Optional[Decimal] = None
    payment_method: Optional[str] = None
    search: Optional[str] = None
    page: int = 1
    limit: int = 20
    sort_by: str = "transaction_date"
    sort_order: str = "desc"

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, field_validator

VALID_ACCOUNT_TYPES = {"cash", "bank", "credit_card", "savings", "wallet", "other"}


class AccountCreate(BaseModel):
    name: str
    account_type: str
    institution_name: Optional[str] = None
    currency: str = "INR"
    opening_balance: Decimal = Decimal("0.00")
    color: Optional[str] = None

    @field_validator("account_type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        if v not in VALID_ACCOUNT_TYPES:
            raise ValueError(f"Account type must be one of: {', '.join(VALID_ACCOUNT_TYPES)}")
        return v

    @field_validator("opening_balance")
    @classmethod
    def validate_balance(cls, v: Decimal) -> Decimal:
        return round(v, 2)


class AccountUpdate(BaseModel):
    name: Optional[str] = None
    institution_name: Optional[str] = None
    color: Optional[str] = None
    is_active: Optional[bool] = None


class AccountResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    name: str
    account_type: str
    institution_name: Optional[str]
    currency: str
    opening_balance: Decimal
    current_balance: Decimal
    color: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

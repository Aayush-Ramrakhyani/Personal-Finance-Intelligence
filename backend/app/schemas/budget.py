import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, field_validator

VALID_PERIODS = {"monthly", "weekly", "yearly", "custom"}


class BudgetCreate(BaseModel):
    category_id: uuid.UUID
    amount: Decimal
    period: str = "monthly"
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    alert_thresholds: list[int] = [75, 90, 100]

    @field_validator("period")
    @classmethod
    def validate_period(cls, v: str) -> str:
        if v not in VALID_PERIODS:
            raise ValueError(f"Period must be one of: {', '.join(VALID_PERIODS)}")
        return v

    @field_validator("amount")
    @classmethod
    def validate_amount(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Budget amount must be positive.")
        return round(v, 2)


class BudgetUpdate(BaseModel):
    amount: Optional[Decimal] = None
    alert_thresholds: Optional[list[int]] = None
    is_active: Optional[bool] = None


class BudgetResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    category_id: uuid.UUID
    category_name: Optional[str] = None
    category_icon: Optional[str] = None
    amount: Decimal
    period: str
    start_date: Optional[date]
    end_date: Optional[date]
    alert_thresholds: list[int]
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class BudgetWithProgress(BudgetResponse):
    spent: Decimal
    remaining: Decimal
    percentage_used: Decimal
    is_over_budget: bool
    alert_level: Optional[int]  # Which threshold was triggered (e.g., 90)

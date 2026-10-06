import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel


class RecurringTransactionResponse(BaseModel):
    id: uuid.UUID
    merchant: str
    amount: Decimal
    currency: str
    frequency: str
    next_expected_date: Optional[date]
    last_occurrence: Optional[date]
    confidence: Decimal
    status: str
    occurrence_count: int
    category_name: Optional[str] = None
    annual_cost: Optional[Decimal] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class RecurringSummary(BaseModel):
    total_monthly_cost: Decimal
    total_annual_cost: Decimal
    confirmed_count: int
    detected_count: int
    items: list[RecurringTransactionResponse]

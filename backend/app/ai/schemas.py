from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field, field_validator


class TransactionClassification(BaseModel):
    merchant: str
    category: str
    subcategory: Optional[str] = None
    confidence: float = Field(ge=0.0, le=1.0)
    reasoning: Optional[str] = None

    @field_validator("confidence")
    @classmethod
    def round_confidence(cls, v: float) -> float:
        return round(v, 3)


class FinancialQueryIntent(BaseModel):
    intent: str
    period: Optional[str] = None
    category: Optional[str] = None
    account: Optional[str] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None


class FinancialInsightOutput(BaseModel):
    title: str
    body: str
    insight_type: str
    priority: str = "medium"
    category: Optional[str] = None
    amount: Optional[Decimal] = None


class MonthlySummaryOutput(BaseModel):
    overview: str
    positive_observations: list[str]
    concerning_changes: list[str]
    spending_patterns: list[str]
    areas_to_review: list[str]


class BudgetRecommendation(BaseModel):
    category: str
    recommended_amount: Decimal
    current_spending: Decimal
    reasoning: str

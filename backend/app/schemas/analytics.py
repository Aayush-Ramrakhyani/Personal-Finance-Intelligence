from datetime import date
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel


class AccountBalance(BaseModel):
    account_id: str
    account_name: str
    account_type: str
    balance: Decimal


class OverviewResponse(BaseModel):
    total_income: Decimal
    total_expenses: Decimal
    net_cash_flow: Decimal
    savings: Decimal
    savings_rate: Decimal
    transaction_count: int
    account_balances: list[AccountBalance]
    start_date: date
    end_date: date


class CategoryBreakdown(BaseModel):
    category_id: str
    category_name: str
    category_icon: Optional[str]
    type: str
    amount: Decimal
    percentage: Decimal
    transaction_count: int


class CashFlowMonth(BaseModel):
    year: int
    month: int
    month_label: str
    income: Decimal
    expenses: Decimal
    net: Decimal


class TrendData(BaseModel):
    months: list[CashFlowMonth]
    avg_monthly_income: Decimal
    avg_monthly_expenses: Decimal
    avg_daily_expenses: Decimal
    income_trend: str  # "up", "down", "stable"
    expense_trend: str


class Anomaly(BaseModel):
    category_name: str
    category_id: str
    current_amount: Decimal
    average_amount: Decimal
    deviation_percentage: Decimal
    severity: str  # "mild", "moderate", "significant"


class BudgetPerformance(BaseModel):
    budget_id: str
    category_name: str
    budget_amount: Decimal
    actual_amount: Decimal
    percentage_used: Decimal
    remaining: Decimal
    is_over_budget: bool

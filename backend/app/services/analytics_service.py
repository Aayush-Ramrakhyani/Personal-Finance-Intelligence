"""All financial calculations are deterministic SQL queries. AI never computes totals."""

import calendar
from datetime import date
from decimal import Decimal
from typing import Optional
from uuid import UUID

import sqlalchemy as sa
from dateutil.relativedelta import relativedelta
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.repositories.account_repository import AccountRepository
from app.db.repositories.transaction_repository import TransactionRepository
from app.models.transaction import Transaction
from app.models.category import Category
from app.schemas.analytics import (
    AccountBalance,
    Anomaly,
    BudgetPerformance,
    CashFlowMonth,
    CategoryBreakdown,
    OverviewResponse,
    TrendData,
)

MONTH_NAMES = [
    "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
]


class AnalyticsService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.txn_repo = TransactionRepository(db)
        self.acc_repo = AccountRepository(db)

    async def get_overview(
        self, user_id: UUID, start_date: date, end_date: date
    ) -> OverviewResponse:
        # Income total (excluding transfers)
        income = await self._sum_type(user_id, "income", start_date, end_date)
        # Expense total (excluding transfers)
        expenses = await self._sum_type(user_id, "expense", start_date, end_date)
        net = income - expenses
        savings = net
        savings_rate = (
            (savings / income * 100).quantize(Decimal("0.01"))
            if income > 0
            else Decimal("0.00")
        )

        # Transaction count
        count_result = await self.db.execute(
            sa.select(sa.func.count(Transaction.id)).where(
                Transaction.user_id == user_id,
                Transaction.is_deleted == False,
                Transaction.transaction_date >= start_date,
                Transaction.transaction_date <= end_date,
            )
        )
        txn_count = count_result.scalar_one()

        # Account balances
        from app.models.account import Account
        acc_result = await self.db.execute(
            sa.select(Account).where(
                Account.user_id == user_id, Account.is_active == True
            )
        )
        accounts = acc_result.scalars().all()
        balances = [
            AccountBalance(
                account_id=str(a.id),
                account_name=a.name,
                account_type=a.account_type,
                balance=a.current_balance,
            )
            for a in accounts
        ]

        return OverviewResponse(
            total_income=income,
            total_expenses=expenses,
            net_cash_flow=net,
            savings=savings,
            savings_rate=savings_rate,
            transaction_count=txn_count,
            account_balances=balances,
            start_date=start_date,
            end_date=end_date,
        )

    async def get_category_breakdown(
        self,
        user_id: UUID,
        start_date: date,
        end_date: date,
        txn_type: Optional[str] = None,
    ) -> list[CategoryBreakdown]:
        rows = await self.txn_repo.get_category_totals(
            user_id, start_date, end_date, txn_type
        )
        if not rows:
            return []

        total = sum(r["total"] for r in rows) or Decimal("1")
        result = []
        for row in rows:
            pct = (row["total"] / total * 100).quantize(Decimal("0.01"))
            result.append(
                CategoryBreakdown(
                    category_id=str(row["category_id"]) if row["category_id"] else "uncategorized",
                    category_name=row["category_name"] or "Uncategorized",
                    category_icon=row.get("category_icon"),
                    type=row.get("category_type") or txn_type or "expense",
                    amount=row["total"],
                    percentage=pct,
                    transaction_count=row["count"],
                )
            )
        return result

    async def get_cash_flow(self, user_id: UUID, months: int = 6) -> list[CashFlowMonth]:
        today = date.today()
        result = []
        for i in range(months - 1, -1, -1):
            period = today - relativedelta(months=i)
            m_start = period.replace(day=1)
            _, last_day = calendar.monthrange(period.year, period.month)
            m_end = period.replace(day=last_day)

            income = await self._sum_type(user_id, "income", m_start, m_end)
            expenses = await self._sum_type(user_id, "expense", m_start, m_end)
            result.append(
                CashFlowMonth(
                    year=period.year,
                    month=period.month,
                    month_label=f"{MONTH_NAMES[period.month]} {period.year}",
                    income=income,
                    expenses=expenses,
                    net=income - expenses,
                )
            )
        return result

    async def get_trends(self, user_id: UUID, months: int = 6) -> TrendData:
        cash_flow = await self.get_cash_flow(user_id, months)
        if not cash_flow:
            return TrendData(
                months=[],
                avg_monthly_income=Decimal("0"),
                avg_monthly_expenses=Decimal("0"),
                avg_daily_expenses=Decimal("0"),
                income_trend="stable",
                expense_trend="stable",
            )

        incomes = [m.income for m in cash_flow]
        expenses = [m.expenses for m in cash_flow]

        avg_income = sum(incomes) / len(incomes)
        avg_expense = sum(expenses) / len(expenses)
        avg_daily = avg_expense / Decimal("30")

        # Simple trend: compare last month vs average of prior months
        def classify_trend(values: list[Decimal]) -> str:
            if len(values) < 2:
                return "stable"
            recent = values[-1]
            prior_avg = sum(values[:-1]) / len(values[:-1]) if len(values) > 1 else recent
            if prior_avg == 0:
                return "stable"
            change_pct = (recent - prior_avg) / prior_avg * 100
            if change_pct > 10:
                return "up"
            elif change_pct < -10:
                return "down"
            return "stable"

        return TrendData(
            months=cash_flow,
            avg_monthly_income=avg_income.quantize(Decimal("0.01")),
            avg_monthly_expenses=avg_expense.quantize(Decimal("0.01")),
            avg_daily_expenses=avg_daily.quantize(Decimal("0.01")),
            income_trend=classify_trend(incomes),
            expense_trend=classify_trend(expenses),
        )

    async def get_anomalies(self, user_id: UUID) -> list[Anomaly]:
        """Detect unusual spending statistically (no AI for number crunching)."""
        today = date.today()
        # Current month
        curr_start = today.replace(day=1)
        _, last_day = calendar.monthrange(today.year, today.month)
        curr_end = today.replace(day=last_day)

        # Past 3 months for baseline
        baseline_end = (curr_start - relativedelta(days=1))
        baseline_start = (baseline_end - relativedelta(months=3)).replace(day=1)

        curr_cats = await self.txn_repo.get_category_totals(
            user_id, curr_start, curr_end, "expense"
        )
        baseline_cats = await self.txn_repo.get_category_totals(
            user_id, baseline_start, baseline_end, "expense"
        )

        baseline_map = {
            str(r["category_id"]): r["total"] / 3
            for r in baseline_cats
            if r["category_id"]
        }

        anomalies = []
        for row in curr_cats:
            if not row["category_id"]:
                continue
            cat_key = str(row["category_id"])
            avg = baseline_map.get(cat_key, Decimal("0"))
            current = row["total"]
            if avg == 0:
                continue
            deviation_pct = ((current - avg) / avg * 100).quantize(Decimal("0.01"))
            if deviation_pct > 30:
                severity = (
                    "significant" if deviation_pct > 100
                    else "moderate" if deviation_pct > 50
                    else "mild"
                )
                anomalies.append(
                    Anomaly(
                        category_name=row["category_name"] or "Uncategorized",
                        category_id=cat_key,
                        current_amount=current,
                        average_amount=avg.quantize(Decimal("0.01")),
                        deviation_percentage=deviation_pct,
                        severity=severity,
                    )
                )
        return sorted(anomalies, key=lambda a: a.deviation_percentage, reverse=True)

    async def _sum_type(
        self,
        user_id: UUID,
        txn_type: str,
        start_date: date,
        end_date: date,
    ) -> Decimal:
        result = await self.db.execute(
            sa.select(sa.func.coalesce(sa.func.sum(Transaction.amount), 0)).where(
                Transaction.user_id == user_id,
                Transaction.type == txn_type,
                Transaction.transaction_date >= start_date,
                Transaction.transaction_date <= end_date,
                Transaction.is_deleted == False,
                Transaction.transfer_id == None,
            )
        )
        return result.scalar_one() or Decimal("0.00")

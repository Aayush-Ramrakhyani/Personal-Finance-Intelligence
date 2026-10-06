from calendar import monthrange
from datetime import date
from decimal import Decimal
from typing import Optional
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.db.repositories.budget_repository import BudgetRepository
from app.db.repositories.category_repository import CategoryRepository
from app.db.repositories.transaction_repository import TransactionRepository
from app.schemas.budget import BudgetCreate, BudgetResponse, BudgetUpdate, BudgetWithProgress


class BudgetService:
    def __init__(self, db: AsyncSession):
        self.budget_repo = BudgetRepository(db)
        self.cat_repo = CategoryRepository(db)
        self.txn_repo = TransactionRepository(db)

    async def create(self, user_id: UUID, data: BudgetCreate) -> BudgetResponse:
        cat = await self.cat_repo.get(data.category_id)
        if not cat:
            raise NotFoundError("Category")
        budget = await self.budget_repo.create({
            "user_id": user_id,
            "category_id": data.category_id,
            "amount": data.amount,
            "period": data.period,
            "start_date": data.start_date,
            "end_date": data.end_date,
            "alert_thresholds": data.alert_thresholds,
        })
        budget = await self.budget_repo.get_with_category(budget.id, user_id)
        return self._to_response(budget)

    async def list_budgets(self, user_id: UUID) -> list[BudgetWithProgress]:
        budgets = await self.budget_repo.list_active(user_id)
        today = date.today()
        results = []
        for b in budgets:
            start, end = self._get_period_dates(b, today)
            spent = await self._get_spent(user_id, b.category_id, start, end)
            results.append(self._with_progress(b, spent))
        return results

    async def get(self, budget_id: UUID, user_id: UUID) -> BudgetWithProgress:
        budget = await self.budget_repo.get_with_category(budget_id, user_id)
        if not budget:
            raise NotFoundError("Budget")
        today = date.today()
        start, end = self._get_period_dates(budget, today)
        spent = await self._get_spent(user_id, budget.category_id, start, end)
        return self._with_progress(budget, spent)

    async def update(
        self, budget_id: UUID, user_id: UUID, data: BudgetUpdate
    ) -> BudgetWithProgress:
        budget = await self.budget_repo.get_with_category(budget_id, user_id)
        if not budget:
            raise NotFoundError("Budget")
        await self.budget_repo.update(budget, data.model_dump(exclude_none=True))
        return await self.get(budget_id, user_id)

    async def delete(self, budget_id: UUID, user_id: UUID) -> None:
        budget = await self.budget_repo.get_by_user(budget_id, user_id)
        if not budget:
            raise NotFoundError("Budget")
        await self.budget_repo.update(budget, {"is_active": False})

    def _get_period_dates(self, budget, today: date) -> tuple[date, date]:
        if budget.period == "monthly":
            start = today.replace(day=1)
            _, last_day = monthrange(today.year, today.month)
            end = today.replace(day=last_day)
        elif budget.period == "weekly":
            start = today - __import__("datetime").timedelta(days=today.weekday())
            end = start + __import__("datetime").timedelta(days=6)
        elif budget.period == "yearly":
            start = today.replace(month=1, day=1)
            end = today.replace(month=12, day=31)
        elif budget.start_date and budget.end_date:
            start = budget.start_date
            end = budget.end_date
        else:
            start = today.replace(day=1)
            _, last_day = monthrange(today.year, today.month)
            end = today.replace(day=last_day)
        return start, end

    async def _get_spent(
        self, user_id: UUID, category_id: UUID, start: date, end: date
    ) -> Decimal:
        from app.models.transaction import Transaction
        result = await self.txn_repo.db.execute(
            sa.select(sa.func.coalesce(sa.func.sum(Transaction.amount), 0)).where(
                Transaction.user_id == user_id,
                Transaction.category_id == category_id,
                Transaction.type == "expense",
                Transaction.transaction_date >= start,
                Transaction.transaction_date <= end,
                Transaction.is_deleted == False,
            )
        )
        return result.scalar_one() or Decimal("0.00")

    def _to_response(self, budget) -> BudgetResponse:
        resp = BudgetResponse.model_validate(budget)
        if budget.category:
            resp.category_name = budget.category.name
            resp.category_icon = budget.category.icon
        return resp

    def _with_progress(self, budget, spent: Decimal) -> BudgetWithProgress:
        remaining = budget.amount - spent
        if budget.amount > 0:
            pct = (spent / budget.amount * 100).quantize(Decimal("0.01"))
        else:
            pct = Decimal("0.00")

        alert_level = None
        for threshold in sorted(budget.alert_thresholds or [], reverse=True):
            if pct >= threshold:
                alert_level = threshold
                break

        cat_name = budget.category.name if budget.category else None
        cat_icon = budget.category.icon if budget.category else None

        return BudgetWithProgress(
            **{
                "id": budget.id,
                "user_id": budget.user_id,
                "category_id": budget.category_id,
                "category_name": cat_name,
                "category_icon": cat_icon,
                "amount": budget.amount,
                "period": budget.period,
                "start_date": budget.start_date,
                "end_date": budget.end_date,
                "alert_thresholds": budget.alert_thresholds or [],
                "is_active": budget.is_active,
                "created_at": budget.created_at,
                "spent": spent,
                "remaining": remaining,
                "percentage_used": pct,
                "is_over_budget": spent > budget.amount,
                "alert_level": alert_level,
            }
        )

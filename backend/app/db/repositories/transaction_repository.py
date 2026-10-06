from datetime import date
from decimal import Decimal
from typing import Optional
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.transaction import Transaction
from app.models.category import Category
from app.db.repositories.base import BaseRepository
from app.schemas.transaction import TransactionFilter


class TransactionRepository(BaseRepository[Transaction]):
    def __init__(self, db: AsyncSession):
        super().__init__(Transaction, db)

    async def get_with_category(self, id: UUID, user_id: UUID) -> Optional[Transaction]:
        result = await self.db.execute(
            sa.select(Transaction)
            .options(selectinload(Transaction.category))
            .where(
                Transaction.id == id,
                Transaction.user_id == user_id,
                Transaction.is_deleted == False,
            )
        )
        return result.scalar_one_or_none()

    def _apply_filters(self, stmt, user_id: UUID, filters: TransactionFilter):
        stmt = stmt.where(
            Transaction.user_id == user_id,
            Transaction.is_deleted == False,
        )
        if filters.start_date:
            stmt = stmt.where(Transaction.transaction_date >= filters.start_date)
        if filters.end_date:
            stmt = stmt.where(Transaction.transaction_date <= filters.end_date)
        if filters.category_id:
            stmt = stmt.where(Transaction.category_id == filters.category_id)
        if filters.account_id:
            stmt = stmt.where(Transaction.account_id == filters.account_id)
        if filters.type:
            stmt = stmt.where(Transaction.type == filters.type)
        if filters.min_amount is not None:
            stmt = stmt.where(Transaction.amount >= filters.min_amount)
        if filters.max_amount is not None:
            stmt = stmt.where(Transaction.amount <= filters.max_amount)
        if filters.payment_method:
            stmt = stmt.where(Transaction.payment_method == filters.payment_method)
        if filters.search:
            search_term = f"%{filters.search}%"
            stmt = stmt.where(
                sa.or_(
                    Transaction.merchant.ilike(search_term),
                    Transaction.description.ilike(search_term),
                )
            )
        if filters.merchant:
            stmt = stmt.where(Transaction.merchant.ilike(f"%{filters.merchant}%"))
        return stmt

    async def list_filtered(
        self, user_id: UUID, filters: TransactionFilter
    ) -> tuple[list[Transaction], int]:
        # Count query
        count_stmt = sa.select(sa.func.count(Transaction.id))
        count_stmt = self._apply_filters(count_stmt, user_id, filters)
        count_result = await self.db.execute(count_stmt)
        total = count_result.scalar_one()

        # Data query
        sort_col = getattr(Transaction, filters.sort_by, Transaction.transaction_date)
        sort_fn = sort_col.desc() if filters.sort_order == "desc" else sort_col.asc()

        stmt = (
            sa.select(Transaction)
            .options(selectinload(Transaction.category))
            .order_by(sort_fn, Transaction.created_at.desc())
            .limit(filters.limit)
            .offset((filters.page - 1) * filters.limit)
        )
        stmt = self._apply_filters(stmt, user_id, filters)
        result = await self.db.execute(stmt)
        return list(result.scalars().all()), total

    async def get_sum_by_type(
        self,
        user_id: UUID,
        transaction_type: str,
        start_date: date,
        end_date: date,
        exclude_transfers: bool = True,
    ) -> Decimal:
        stmt = sa.select(sa.func.coalesce(sa.func.sum(Transaction.amount), 0)).where(
            Transaction.user_id == user_id,
            Transaction.type == transaction_type,
            Transaction.transaction_date >= start_date,
            Transaction.transaction_date <= end_date,
            Transaction.is_deleted == False,
        )
        if exclude_transfers:
            stmt = stmt.where(Transaction.transfer_id == None)
        result = await self.db.execute(stmt)
        return result.scalar_one() or Decimal("0.00")

    async def get_category_totals(
        self,
        user_id: UUID,
        start_date: date,
        end_date: date,
        transaction_type: Optional[str] = None,
    ) -> list[dict]:
        stmt = (
            sa.select(
                Transaction.category_id,
                Category.name.label("category_name"),
                Category.icon.label("category_icon"),
                Category.type.label("category_type"),
                sa.func.sum(Transaction.amount).label("total"),
                sa.func.count(Transaction.id).label("count"),
            )
            .join(Category, Transaction.category_id == Category.id, isouter=True)
            .where(
                Transaction.user_id == user_id,
                Transaction.transaction_date >= start_date,
                Transaction.transaction_date <= end_date,
                Transaction.is_deleted == False,
                Transaction.transfer_id == None,
            )
            .group_by(
                Transaction.category_id,
                Category.name,
                Category.icon,
                Category.type,
            )
            .order_by(sa.desc("total"))
        )
        if transaction_type:
            stmt = stmt.where(Transaction.type == transaction_type)

        result = await self.db.execute(stmt)
        return [dict(row._mapping) for row in result.all()]

    async def get_monthly_totals(
        self,
        user_id: UUID,
        months: int = 6,
    ) -> list[dict]:
        stmt = sa.text("""
            SELECT
                EXTRACT(YEAR FROM transaction_date)::int AS year,
                EXTRACT(MONTH FROM transaction_date)::int AS month,
                SUM(CASE WHEN type = 'income' AND transfer_id IS NULL THEN amount ELSE 0 END) AS income,
                SUM(CASE WHEN type = 'expense' AND transfer_id IS NULL THEN amount ELSE 0 END) AS expenses
            FROM transactions
            WHERE user_id = :user_id
                AND is_deleted = FALSE
                AND transaction_date >= (CURRENT_DATE - INTERVAL ':months months')
            GROUP BY year, month
            ORDER BY year, month
        """)
        # Use a proper parameterized approach
        from datetime import date
        from dateutil.relativedelta import relativedelta

        cutoff = date.today().replace(day=1)
        for _ in range(months - 1):
            cutoff -= relativedelta(months=1)

        stmt2 = sa.select(
            sa.extract("year", Transaction.transaction_date).label("year"),
            sa.extract("month", Transaction.transaction_date).label("month"),
            sa.func.sum(
                sa.case(
                    (sa.and_(Transaction.type == "income", Transaction.transfer_id == None), Transaction.amount),
                    else_=Decimal("0"),
                )
            ).label("income"),
            sa.func.sum(
                sa.case(
                    (sa.and_(Transaction.type == "expense", Transaction.transfer_id == None), Transaction.amount),
                    else_=Decimal("0"),
                )
            ).label("expenses"),
        ).where(
            Transaction.user_id == user_id,
            Transaction.is_deleted == False,
            Transaction.transaction_date >= cutoff,
        ).group_by("year", "month").order_by("year", "month")

        result = await self.db.execute(stmt2)
        return [dict(row._mapping) for row in result.all()]

    async def check_duplicate(
        self,
        user_id: UUID,
        account_id: UUID,
        amount: Decimal,
        txn_date: date,
        external_ref: Optional[str] = None,
        description: Optional[str] = None,
    ) -> Optional[dict]:
        """Check if a transaction likely exists already. Returns confidence dict."""
        # Exact external reference match
        if external_ref:
            result = await self.db.execute(
                sa.select(Transaction.id).where(
                    Transaction.user_id == user_id,
                    Transaction.external_reference == external_ref,
                    Transaction.is_deleted == False,
                )
            )
            if result.scalar_one_or_none():
                return {"confidence": 1.0, "reason": "exact_reference"}

        # Same account + amount + same date
        from datetime import timedelta
        result = await self.db.execute(
            sa.select(Transaction.id, Transaction.description).where(
                Transaction.user_id == user_id,
                Transaction.account_id == account_id,
                Transaction.amount == amount,
                Transaction.transaction_date.between(
                    txn_date - timedelta(days=1), txn_date + timedelta(days=1)
                ),
                Transaction.is_deleted == False,
            )
        )
        rows = result.all()
        if rows:
            return {"confidence": 0.90, "reason": "amount_date_match"}

        return None

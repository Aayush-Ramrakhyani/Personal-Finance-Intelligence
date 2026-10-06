"""Statistical recurring expense detection - no AI for number crunching."""
import calendar
from datetime import date, timedelta
from decimal import Decimal
from statistics import mean, stdev
from typing import Optional
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.repositories.category_repository import CategoryRepository
from app.models.recurring_transaction import RecurringTransaction
from app.models.transaction import Transaction
from app.schemas.recurring import RecurringTransactionResponse, RecurringSummary

FREQUENCY_INTERVALS = {
    "weekly": (5, 9),
    "monthly": (26, 33),
    "quarterly": (85, 97),
    "yearly": (355, 375),
}


class RecurringService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def detect_and_update(self, user_id: UUID) -> list[RecurringTransaction]:
        # Get all non-transfer, non-deleted expenses grouped by merchant
        stmt = (
            sa.select(
                Transaction.merchant,
                Transaction.amount,
                Transaction.transaction_date,
                Transaction.category_id,
            )
            .where(
                Transaction.user_id == user_id,
                Transaction.type == "expense",
                Transaction.is_deleted == False,
                Transaction.merchant != None,
                Transaction.transfer_id == None,
            )
            .order_by(Transaction.merchant, Transaction.transaction_date)
        )
        result = await self.db.execute(stmt)
        rows = result.all()

        # Group by merchant + approximate amount (±10%)
        groups: dict[str, list] = {}
        for row in rows:
            merchant = (row.merchant or "").strip().lower()
            if not merchant:
                continue
            amount = row.amount
            # Find existing group or create new
            matched = False
            for key, grp in groups.items():
                key_amount = grp[0]["amount"]
                if merchant == key.split("|")[0]:
                    if abs(amount - key_amount) / max(key_amount, Decimal("1")) <= 0.10:
                        grp.append({
                            "merchant": row.merchant,
                            "amount": amount,
                            "date": row.transaction_date,
                            "category_id": row.category_id,
                        })
                        matched = True
                        break
            if not matched:
                key = f"{merchant}|{amount}"
                groups[key] = [{
                    "merchant": row.merchant,
                    "amount": amount,
                    "date": row.transaction_date,
                    "category_id": row.category_id,
                }]

        recurring_records = []
        for key, occurrences in groups.items():
            if len(occurrences) < 2:
                continue

            dates = sorted(occ["date"] for occ in occurrences)
            intervals = [(dates[i + 1] - dates[i]).days for i in range(len(dates) - 1)]
            if not intervals:
                continue

            frequency, confidence = self._classify_frequency(intervals)
            if confidence < 0.5:
                continue

            avg_amount = mean(occ["amount"] for occ in occurrences)
            last_date = max(dates)
            next_date = self._estimate_next(last_date, frequency)
            category_id = occurrences[-1].get("category_id")
            merchant_display = occurrences[-1]["merchant"]

            # Upsert recurring record
            existing = await self.db.execute(
                sa.select(RecurringTransaction).where(
                    RecurringTransaction.user_id == user_id,
                    sa.func.lower(RecurringTransaction.merchant)
                    == merchant_display.lower(),
                )
            )
            rec = existing.scalar_one_or_none()

            if rec:
                if rec.status != "rejected":
                    await self.db.execute(
                        sa.update(RecurringTransaction)
                        .where(RecurringTransaction.id == rec.id)
                        .values(
                            amount=Decimal(str(avg_amount)).quantize(Decimal("0.01")),
                            frequency=frequency,
                            confidence=Decimal(str(confidence)).quantize(Decimal("0.001")),
                            last_occurrence=last_date,
                            next_expected_date=next_date,
                            occurrence_count=len(occurrences),
                        )
                    )
                    recurring_records.append(rec)
            else:
                new_rec = RecurringTransaction(
                    user_id=user_id,
                    merchant=merchant_display,
                    amount=Decimal(str(avg_amount)).quantize(Decimal("0.01")),
                    frequency=frequency,
                    next_expected_date=next_date,
                    last_occurrence=last_date,
                    confidence=Decimal(str(confidence)).quantize(Decimal("0.001")),
                    status="detected",
                    occurrence_count=len(occurrences),
                    category_id=category_id,
                )
                self.db.add(new_rec)
                await self.db.flush()
                recurring_records.append(new_rec)

        return recurring_records

    def _classify_frequency(self, intervals: list[int]) -> tuple[str, float]:
        if not intervals:
            return "monthly", 0.0
        avg_interval = mean(intervals)
        for freq, (low, high) in FREQUENCY_INTERVALS.items():
            if low <= avg_interval <= high:
                # Confidence based on consistency
                if len(intervals) == 1:
                    consistency = 0.7
                else:
                    try:
                        std = stdev(intervals)
                        consistency = max(0.0, 1.0 - std / max(avg_interval, 1))
                    except Exception:
                        consistency = 0.6
                count_bonus = min(0.2, len(intervals) * 0.05)
                confidence = min(1.0, consistency * 0.8 + count_bonus)
                return freq, confidence
        return "monthly", 0.3

    def _estimate_next(self, last_date: date, frequency: str) -> date:
        from dateutil.relativedelta import relativedelta
        if frequency == "weekly":
            return last_date + timedelta(days=7)
        elif frequency == "monthly":
            return last_date + relativedelta(months=1)
        elif frequency == "quarterly":
            return last_date + relativedelta(months=3)
        elif frequency == "yearly":
            return last_date + relativedelta(years=1)
        return last_date + relativedelta(months=1)

    async def list_recurring(self, user_id: UUID) -> RecurringSummary:
        result = await self.db.execute(
            sa.select(RecurringTransaction)
            .where(
                RecurringTransaction.user_id == user_id,
                RecurringTransaction.status != "rejected",
            )
            .order_by(RecurringTransaction.amount.desc())
        )
        recs = result.scalars().all()

        monthly_total = Decimal("0.00")
        for r in recs:
            if r.frequency == "weekly":
                monthly_cost = r.amount * Decimal("4.33")
            elif r.frequency == "monthly":
                monthly_cost = r.amount
            elif r.frequency == "quarterly":
                monthly_cost = r.amount / Decimal("3")
            elif r.frequency == "yearly":
                monthly_cost = r.amount / Decimal("12")
            else:
                monthly_cost = r.amount
            monthly_total += monthly_cost

        items = [RecurringTransactionResponse(
            id=r.id,
            merchant=r.merchant,
            amount=r.amount,
            currency=r.currency,
            frequency=r.frequency,
            next_expected_date=r.next_expected_date,
            last_occurrence=r.last_occurrence,
            confidence=r.confidence,
            status=r.status,
            occurrence_count=r.occurrence_count,
            annual_cost=r.amount * (
                Decimal("52") if r.frequency == "weekly"
                else Decimal("12") if r.frequency == "monthly"
                else Decimal("4") if r.frequency == "quarterly"
                else Decimal("1")
            ),
            created_at=r.created_at,
        ) for r in recs]

        return RecurringSummary(
            total_monthly_cost=monthly_total.quantize(Decimal("0.01")),
            total_annual_cost=(monthly_total * 12).quantize(Decimal("0.01")),
            confirmed_count=sum(1 for r in recs if r.status == "confirmed"),
            detected_count=sum(1 for r in recs if r.status == "detected"),
            items=items,
        )

    async def update_status(
        self, recurring_id: UUID, user_id: UUID, status: str
    ) -> Optional[RecurringTransaction]:
        result = await self.db.execute(
            sa.select(RecurringTransaction).where(
                RecurringTransaction.id == recurring_id,
                RecurringTransaction.user_id == user_id,
            )
        )
        rec = result.scalar_one_or_none()
        if rec:
            await self.db.execute(
                sa.update(RecurringTransaction)
                .where(RecurringTransaction.id == recurring_id)
                .values(status=status)
            )
        return rec

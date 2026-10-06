import uuid
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Optional

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class RecurringTransaction(Base):
    __tablename__ = "recurring_transactions"

    id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    category_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("categories.id", ondelete="SET NULL"),
        nullable=True,
    )
    merchant: Mapped[str] = mapped_column(sa.String(200), nullable=False)
    amount: Mapped[Decimal] = mapped_column(sa.Numeric(15, 2), nullable=False)
    currency: Mapped[str] = mapped_column(sa.String(10), nullable=False, default="INR")
    frequency: Mapped[str] = mapped_column(
        sa.String(20), nullable=False
    )  # weekly, monthly, quarterly, yearly
    next_expected_date: Mapped[Optional[date]] = mapped_column(sa.Date, nullable=True)
    last_occurrence: Mapped[Optional[date]] = mapped_column(sa.Date, nullable=True)
    confidence: Mapped[Decimal] = mapped_column(
        sa.Numeric(4, 3), nullable=False, default=Decimal("0.0")
    )
    status: Mapped[str] = mapped_column(
        sa.String(20), nullable=False, default="detected"
    )  # detected, confirmed, rejected
    occurrence_count: Mapped[int] = mapped_column(sa.Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    updated_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    __table_args__ = (
        sa.CheckConstraint(
            "frequency IN ('weekly','monthly','quarterly','yearly')",
            name="ck_recurring_frequency",
        ),
        sa.CheckConstraint(
            "status IN ('detected','confirmed','rejected')", name="ck_recurring_status"
        ),
    )

    # Relationships
    user: Mapped["User"] = relationship("User")
    category: Mapped[Optional["Category"]] = relationship("Category")

    def __repr__(self) -> str:
        return f"<RecurringTransaction {self.merchant} {self.frequency}>"

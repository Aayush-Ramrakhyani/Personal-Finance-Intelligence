import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Optional

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class FinancialInsight(Base):
    __tablename__ = "financial_insights"

    id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    insight_type: Mapped[str] = mapped_column(
        sa.String(50), nullable=False
    )  # spending_increase, budget_alert, saving_opportunity, anomaly, recurring_detected
    title: Mapped[str] = mapped_column(sa.String(300), nullable=False)
    body: Mapped[str] = mapped_column(sa.Text, nullable=False)
    priority: Mapped[str] = mapped_column(
        sa.String(20), nullable=False, default="medium"
    )  # high, medium, low
    category: Mapped[Optional[str]] = mapped_column(sa.String(100), nullable=True)
    amount: Mapped[Optional[Decimal]] = mapped_column(sa.Numeric(15, 2), nullable=True)
    extra_data: Mapped[Optional[dict]] = mapped_column(sa.JSON, nullable=True)
    is_read: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, default=False)
    period_month: Mapped[Optional[int]] = mapped_column(sa.Integer, nullable=True)
    period_year: Mapped[Optional[int]] = mapped_column(sa.Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="insights")

    def __repr__(self) -> str:
        return f"<FinancialInsight {self.insight_type}: {self.title[:50]}>"

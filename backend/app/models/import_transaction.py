import uuid
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Optional

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class ImportTransaction(Base):
    """Staging table for CSV import transactions before user confirmation."""

    __tablename__ = "import_transactions"

    id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    import_job_id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("import_jobs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    account_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("accounts.id", ondelete="SET NULL"),
        nullable=True,
    )
    suggested_category_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("categories.id", ondelete="SET NULL"),
        nullable=True,
    )
    type: Mapped[str] = mapped_column(sa.String(20), nullable=False)  # income, expense
    amount: Mapped[Decimal] = mapped_column(sa.Numeric(15, 2), nullable=False)
    currency: Mapped[str] = mapped_column(sa.String(10), nullable=False, default="INR")
    merchant: Mapped[Optional[str]] = mapped_column(sa.String(200), nullable=True)
    description: Mapped[Optional[str]] = mapped_column(sa.String(500), nullable=True)
    transaction_date: Mapped[date] = mapped_column(sa.Date, nullable=False)
    external_reference: Mapped[Optional[str]] = mapped_column(sa.String(200), nullable=True)
    raw_data: Mapped[dict] = mapped_column(sa.JSON, nullable=False, default=dict)
    # Duplicate detection
    is_duplicate: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, default=False)
    duplicate_confidence: Mapped[Decimal] = mapped_column(
        sa.Numeric(4, 3), nullable=False, default=Decimal("0.0")
    )
    duplicate_of_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        sa.UUID(as_uuid=True), nullable=True
    )
    # Categorization
    category_source: Mapped[Optional[str]] = mapped_column(sa.String(50), nullable=True)
    category_confidence: Mapped[Optional[Decimal]] = mapped_column(
        sa.Numeric(4, 3), nullable=True
    )
    # Status: pending, included, excluded
    status: Mapped[str] = mapped_column(sa.String(20), nullable=False, default="pending")
    row_number: Mapped[int] = mapped_column(sa.Integer, nullable=False, default=0)
    parse_error: Mapped[Optional[str]] = mapped_column(sa.String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    import_job: Mapped["ImportJob"] = relationship(
        "ImportJob", back_populates="staged_transactions"
    )

    def __repr__(self) -> str:
        return f"<ImportTransaction {self.merchant} {self.amount}>"

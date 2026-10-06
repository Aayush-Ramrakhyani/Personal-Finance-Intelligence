import uuid
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Optional

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    account_id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("accounts.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    category_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("categories.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    type: Mapped[str] = mapped_column(
        sa.String(20), nullable=False
    )  # income, expense, transfer
    amount: Mapped[Decimal] = mapped_column(sa.Numeric(15, 2), nullable=False)
    currency: Mapped[str] = mapped_column(sa.String(10), nullable=False, default="INR")
    merchant: Mapped[Optional[str]] = mapped_column(sa.String(200), nullable=True, index=True)
    description: Mapped[Optional[str]] = mapped_column(sa.String(500), nullable=True)
    transaction_date: Mapped[date] = mapped_column(sa.Date, nullable=False, index=True)
    payment_method: Mapped[Optional[str]] = mapped_column(
        sa.String(50), nullable=True
    )  # cash, upi, card, netbanking, other
    notes: Mapped[Optional[str]] = mapped_column(sa.Text, nullable=True)
    # Source: manual, csv_import, api
    source: Mapped[str] = mapped_column(sa.String(50), nullable=False, default="manual")
    external_reference: Mapped[Optional[str]] = mapped_column(
        sa.String(200), nullable=True, index=True
    )
    is_recurring: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, default=False)
    # Categorization metadata
    category_source: Mapped[Optional[str]] = mapped_column(
        sa.String(50), nullable=True
    )  # manual, rule_based, ai
    category_confidence: Mapped[Optional[Decimal]] = mapped_column(
        sa.Numeric(4, 3), nullable=True
    )
    # Transfer link
    transfer_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("transfers.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    is_deleted: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, default=False)
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
            "type IN ('income','expense','transfer')", name="ck_transaction_type"
        ),
        sa.CheckConstraint("amount > 0", name="ck_transaction_amount_positive"),
        sa.Index("ix_transactions_user_date", "user_id", "transaction_date"),
        sa.Index("ix_transactions_user_type", "user_id", "type"),
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="transactions")
    account: Mapped["Account"] = relationship("Account", back_populates="transactions")
    category: Mapped[Optional["Category"]] = relationship(
        "Category", back_populates="transactions"
    )
    transfer: Mapped[Optional["Transfer"]] = relationship(
        "Transfer",
        foreign_keys=[transfer_id],
        back_populates="transactions",
    )

    def __repr__(self) -> str:
        return f"<Transaction {self.type} {self.amount} on {self.transaction_date}>"

import uuid
from datetime import datetime, timezone
from decimal import Decimal

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Account(Base):
    __tablename__ = "accounts"

    id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name: Mapped[str] = mapped_column(sa.String(200), nullable=False)
    account_type: Mapped[str] = mapped_column(
        sa.String(50), nullable=False
    )  # cash, bank, credit_card, savings, wallet, other
    institution_name: Mapped[str] = mapped_column(sa.String(200), nullable=True)
    currency: Mapped[str] = mapped_column(sa.String(10), nullable=False, default="INR")
    opening_balance: Mapped[Decimal] = mapped_column(
        sa.Numeric(15, 2), nullable=False, default=Decimal("0.00")
    )
    current_balance: Mapped[Decimal] = mapped_column(
        sa.Numeric(15, 2), nullable=False, default=Decimal("0.00")
    )
    color: Mapped[str] = mapped_column(sa.String(20), nullable=True)
    is_active: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, default=True)
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
            "account_type IN ('cash','bank','credit_card','savings','wallet','other')",
            name="ck_account_type",
        ),
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="accounts")
    transactions: Mapped[list["Transaction"]] = relationship(
        "Transaction", back_populates="account", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Account {self.name} ({self.account_type})>"

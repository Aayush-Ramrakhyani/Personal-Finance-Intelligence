import uuid
from datetime import datetime, timezone
from decimal import Decimal

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Transfer(Base):
    """Links two transactions (expense + income) for account-to-account transfers."""

    __tablename__ = "transfers"

    id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    from_account_id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("accounts.id", ondelete="CASCADE"),
        nullable=False,
    )
    to_account_id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("accounts.id", ondelete="CASCADE"),
        nullable=False,
    )
    amount: Mapped[Decimal] = mapped_column(sa.Numeric(15, 2), nullable=False)
    currency: Mapped[str] = mapped_column(sa.String(10), nullable=False, default="INR")
    description: Mapped[str] = mapped_column(sa.String(500), nullable=True)
    transfer_date: Mapped[datetime] = mapped_column(sa.Date, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    transactions: Mapped[list["Transaction"]] = relationship(
        "Transaction",
        foreign_keys="Transaction.transfer_id",
        back_populates="transfer",
    )
    from_account: Mapped["Account"] = relationship(
        "Account", foreign_keys=[from_account_id]
    )
    to_account: Mapped["Account"] = relationship(
        "Account", foreign_keys=[to_account_id]
    )

    def __repr__(self) -> str:
        return f"<Transfer {self.amount} from {self.from_account_id} to {self.to_account_id}>"

from decimal import Decimal
from typing import Optional
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.account import Account
from app.db.repositories.base import BaseRepository


class AccountRepository(BaseRepository[Account]):
    def __init__(self, db: AsyncSession):
        super().__init__(Account, db)

    async def list_active(self, user_id: UUID) -> list[Account]:
        result = await self.db.execute(
            sa.select(Account)
            .where(Account.user_id == user_id, Account.is_active == True)
            .order_by(Account.created_at.asc())
        )
        return list(result.scalars().all())

    async def update_balance(self, account_id: UUID, delta: Decimal) -> Optional[Account]:
        """Atomically update balance by a delta amount."""
        result = await self.db.execute(
            sa.update(Account)
            .where(Account.id == account_id)
            .values(current_balance=Account.current_balance + delta)
            .returning(Account)
        )
        return result.scalar_one_or_none()

    async def set_balance(self, account_id: UUID, balance: Decimal) -> Optional[Account]:
        result = await self.db.execute(
            sa.update(Account)
            .where(Account.id == account_id)
            .values(current_balance=balance)
            .returning(Account)
        )
        return result.scalar_one_or_none()

    async def get_total_balance(self, user_id: UUID) -> Decimal:
        result = await self.db.execute(
            sa.select(sa.func.sum(Account.current_balance))
            .where(Account.user_id == user_id, Account.is_active == True)
        )
        total = result.scalar_one_or_none()
        return total or Decimal("0.00")

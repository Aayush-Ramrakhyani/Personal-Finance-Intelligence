from typing import Optional
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.budget import Budget
from app.models.category import Category
from app.db.repositories.base import BaseRepository


class BudgetRepository(BaseRepository[Budget]):
    def __init__(self, db: AsyncSession):
        super().__init__(Budget, db)

    async def list_active(self, user_id: UUID) -> list[Budget]:
        result = await self.db.execute(
            sa.select(Budget)
            .options(selectinload(Budget.category))
            .where(Budget.user_id == user_id, Budget.is_active == True)
            .order_by(Budget.created_at.asc())
        )
        return list(result.scalars().all())

    async def get_with_category(self, id: UUID, user_id: UUID) -> Optional[Budget]:
        result = await self.db.execute(
            sa.select(Budget)
            .options(selectinload(Budget.category))
            .where(Budget.id == id, Budget.user_id == user_id)
        )
        return result.scalar_one_or_none()

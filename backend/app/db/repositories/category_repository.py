from typing import Optional
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.category import Category
from app.db.repositories.base import BaseRepository


class CategoryRepository(BaseRepository[Category]):
    def __init__(self, db: AsyncSession):
        super().__init__(Category, db)

    async def list_for_user(self, user_id: UUID) -> list[Category]:
        """Return system categories + user's own categories."""
        result = await self.db.execute(
            sa.select(Category)
            .options(selectinload(Category.children))
            .where(
                sa.or_(Category.user_id == user_id, Category.user_id == None),
                Category.is_active == True,
            )
            .order_by(Category.sort_order.asc(), Category.name.asc())
        )
        return list(result.scalars().all())

    async def get_roots_for_user(self, user_id: UUID) -> list[Category]:
        """Return top-level categories only."""
        result = await self.db.execute(
            sa.select(Category)
            .options(selectinload(Category.children))
            .where(
                sa.or_(Category.user_id == user_id, Category.user_id == None),
                Category.parent_id == None,
                Category.is_active == True,
            )
            .order_by(Category.sort_order.asc(), Category.name.asc())
        )
        return list(result.scalars().all())

    async def get_by_name(
        self, name: str, user_id: Optional[UUID] = None
    ) -> Optional[Category]:
        conditions = [
            sa.func.lower(Category.name) == name.lower(),
            Category.is_active == True,
        ]
        if user_id:
            conditions.append(
                sa.or_(Category.user_id == user_id, Category.user_id == None)
            )
        result = await self.db.execute(
            sa.select(Category).where(*conditions).limit(1)
        )
        return result.scalar_one_or_none()

    async def count_system_categories(self) -> int:
        result = await self.db.execute(
            sa.select(sa.func.count(Category.id)).where(Category.is_system == True)
        )
        return result.scalar_one()

from typing import Any, Generic, Optional, Type, TypeVar
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import Base

ModelType = TypeVar("ModelType", bound=Base)


class BaseRepository(Generic[ModelType]):
    def __init__(self, model: Type[ModelType], db: AsyncSession):
        self.model = model
        self.db = db

    async def get(self, id: UUID) -> Optional[ModelType]:
        result = await self.db.execute(
            sa.select(self.model).where(self.model.id == id)
        )
        return result.scalar_one_or_none()

    async def get_by_user(self, id: UUID, user_id: UUID) -> Optional[ModelType]:
        result = await self.db.execute(
            sa.select(self.model).where(
                self.model.id == id,
                self.model.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()

    async def create(self, obj_in: dict) -> ModelType:
        obj = self.model(**obj_in)
        self.db.add(obj)
        await self.db.flush()
        await self.db.refresh(obj)
        return obj

    async def update(self, obj: ModelType, updates: dict) -> ModelType:
        for key, value in updates.items():
            setattr(obj, key, value)
        self.db.add(obj)
        await self.db.flush()
        await self.db.refresh(obj)
        return obj

    async def delete(self, obj: ModelType) -> None:
        await self.db.delete(obj)
        await self.db.flush()

    async def list_by_user(
        self,
        user_id: UUID,
        limit: int = 100,
        offset: int = 0,
    ) -> list[ModelType]:
        result = await self.db.execute(
            sa.select(self.model)
            .where(self.model.user_id == user_id)
            .limit(limit)
            .offset(offset)
        )
        return list(result.scalars().all())

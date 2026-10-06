from typing import Optional
from uuid import UUID
from datetime import datetime, timezone

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification
from app.db.repositories.base import BaseRepository


class NotificationRepository(BaseRepository[Notification]):
    def __init__(self, db: AsyncSession):
        super().__init__(Notification, db)

    async def list_for_user(
        self, user_id: UUID, unread_only: bool = False, limit: int = 50, offset: int = 0
    ) -> list[Notification]:
        stmt = (
            sa.select(Notification)
            .where(Notification.user_id == user_id)
            .order_by(Notification.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        if unread_only:
            stmt = stmt.where(Notification.is_read == False)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def count_unread(self, user_id: UUID) -> int:
        result = await self.db.execute(
            sa.select(sa.func.count(Notification.id)).where(
                Notification.user_id == user_id, Notification.is_read == False
            )
        )
        return result.scalar_one()

    async def mark_read(self, notification_ids: list[UUID], user_id: UUID) -> int:
        result = await self.db.execute(
            sa.update(Notification)
            .where(
                Notification.id.in_(notification_ids),
                Notification.user_id == user_id,
            )
            .values(is_read=True, read_at=datetime.now(timezone.utc))
        )
        return result.rowcount

    async def mark_all_read(self, user_id: UUID) -> int:
        result = await self.db.execute(
            sa.update(Notification)
            .where(Notification.user_id == user_id, Notification.is_read == False)
            .values(is_read=True, read_at=datetime.now(timezone.utc))
        )
        return result.rowcount

from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.repositories.notification_repository import NotificationRepository
from app.models.notification import Notification
from app.schemas.notification import NotificationResponse


class NotificationService:
    def __init__(self, db: AsyncSession):
        self.repo = NotificationRepository(db)

    async def create(
        self,
        user_id: UUID,
        notification_type: str,
        title: str,
        message: str,
        metadata: Optional[dict] = None,
    ) -> Notification:
        return await self.repo.create({
            "user_id": user_id,
            "type": notification_type,
            "title": title,
            "message": message,
            "metadata": metadata,
        })

    async def list_notifications(
        self, user_id: UUID, unread_only: bool = False, limit: int = 50, offset: int = 0
    ) -> list[NotificationResponse]:
        notifs = await self.repo.list_for_user(user_id, unread_only, limit, offset)
        return [NotificationResponse.model_validate(n) for n in notifs]

    async def mark_read(
        self, notification_ids: list[UUID], user_id: UUID
    ) -> int:
        return await self.repo.mark_read(notification_ids, user_id)

    async def mark_all_read(self, user_id: UUID) -> int:
        return await self.repo.mark_all_read(user_id)

    async def count_unread(self, user_id: UUID) -> int:
        return await self.repo.count_unread(user_id)

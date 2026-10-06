from typing import Optional
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.db.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    def __init__(self, db: AsyncSession):
        super().__init__(User, db)

    async def get_by_email(self, email: str) -> Optional[User]:
        result = await self.db.execute(
            sa.select(User).where(User.email == email.lower().strip())
        )
        return result.scalar_one_or_none()

    async def create_user(self, email: str, password_hash: str, first_name: str, last_name: str,
                          currency: str = "INR", timezone: str = "Asia/Kolkata") -> User:
        return await self.create({
            "email": email.lower().strip(),
            "password_hash": password_hash,
            "first_name": first_name.strip(),
            "last_name": last_name.strip(),
            "currency": currency,
            "timezone": timezone,
        })

    async def update_user(self, user_id: UUID, updates: dict) -> Optional[User]:
        user = await self.get(user_id)
        if not user:
            return None
        return await self.update(user, updates)

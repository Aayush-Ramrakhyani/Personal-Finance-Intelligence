from typing import Optional
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.ai_conversation import AIConversation
from app.models.ai_message import AIMessage
from app.models.financial_insight import FinancialInsight
from app.db.repositories.base import BaseRepository


class AIRepository(BaseRepository[AIConversation]):
    def __init__(self, db: AsyncSession):
        super().__init__(AIConversation, db)

    async def list_conversations(self, user_id: UUID, limit: int = 20) -> list[AIConversation]:
        result = await self.db.execute(
            sa.select(AIConversation)
            .where(AIConversation.user_id == user_id, AIConversation.is_active == True)
            .order_by(AIConversation.updated_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())

    async def get_conversation_with_messages(
        self, conversation_id: UUID, user_id: UUID
    ) -> Optional[AIConversation]:
        result = await self.db.execute(
            sa.select(AIConversation)
            .options(selectinload(AIConversation.messages))
            .where(
                AIConversation.id == conversation_id,
                AIConversation.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()

    async def add_message(
        self,
        conversation_id: UUID,
        role: str,
        content: str,
        metadata: Optional[dict] = None,
    ) -> AIMessage:
        msg = AIMessage(
            conversation_id=conversation_id,
            role=role,
            content=content,
            metadata=metadata,
        )
        self.db.add(msg)
        await self.db.flush()

        # Update conversation message count and timestamp
        await self.db.execute(
            sa.update(AIConversation)
            .where(AIConversation.id == conversation_id)
            .values(message_count=AIConversation.message_count + 1)
        )
        await self.db.refresh(msg)
        return msg

    async def get_recent_messages(
        self, conversation_id: UUID, limit: int = 10
    ) -> list[AIMessage]:
        result = await self.db.execute(
            sa.select(AIMessage)
            .where(AIMessage.conversation_id == conversation_id)
            .order_by(AIMessage.created_at.desc())
            .limit(limit)
        )
        msgs = list(result.scalars().all())
        return list(reversed(msgs))


class InsightRepository(BaseRepository[FinancialInsight]):
    def __init__(self, db: AsyncSession):
        super().__init__(FinancialInsight, db)

    async def list_for_user(
        self,
        user_id: UUID,
        unread_only: bool = False,
        limit: int = 20,
    ) -> list[FinancialInsight]:
        stmt = (
            sa.select(FinancialInsight)
            .where(FinancialInsight.user_id == user_id)
            .order_by(FinancialInsight.created_at.desc())
            .limit(limit)
        )
        if unread_only:
            stmt = stmt.where(FinancialInsight.is_read == False)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def mark_read(self, insight_id: UUID, user_id: UUID) -> bool:
        result = await self.db.execute(
            sa.update(FinancialInsight)
            .where(
                FinancialInsight.id == insight_id,
                FinancialInsight.user_id == user_id,
            )
            .values(is_read=True)
        )
        return result.rowcount > 0

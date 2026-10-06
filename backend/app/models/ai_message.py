import uuid
from datetime import datetime, timezone
from typing import Optional

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class AIMessage(Base):
    __tablename__ = "ai_messages"

    id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    conversation_id: Mapped[uuid.UUID] = mapped_column(
        sa.UUID(as_uuid=True),
        sa.ForeignKey("ai_conversations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    role: Mapped[str] = mapped_column(sa.String(20), nullable=False)  # user or assistant
    content: Mapped[str] = mapped_column(sa.Text, nullable=False)
    extra_data: Mapped[Optional[dict]] = mapped_column(sa.JSON, nullable=True)
    token_count: Mapped[Optional[int]] = mapped_column(sa.Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    __table_args__ = (
        sa.CheckConstraint("role IN ('user','assistant')", name="ck_message_role"),
    )

    # Relationships
    conversation: Mapped["AIConversation"] = relationship(
        "AIConversation", back_populates="messages"
    )

    def __repr__(self) -> str:
        return f"<AIMessage {self.role}: {self.content[:50]}>"

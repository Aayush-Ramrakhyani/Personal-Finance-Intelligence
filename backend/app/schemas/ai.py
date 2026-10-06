import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel


class ConversationCreate(BaseModel):
    title: Optional[str] = None


class MessageCreate(BaseModel):
    content: str


class MessageResponse(BaseModel):
    id: uuid.UUID
    conversation_id: uuid.UUID
    role: str
    content: str
    metadata: Optional[dict]
    created_at: datetime

    model_config = {"from_attributes": True}


class ConversationResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: Optional[str]
    message_count: int
    created_at: datetime
    updated_at: datetime
    messages: list[MessageResponse] = []

    model_config = {"from_attributes": True}


class InsightResponse(BaseModel):
    id: uuid.UUID
    insight_type: str
    title: str
    body: str
    priority: str
    category: Optional[str]
    amount: Optional[Decimal]
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class GenerateInsightsRequest(BaseModel):
    month: Optional[int] = None
    year: Optional[int] = None
    force_regenerate: bool = False

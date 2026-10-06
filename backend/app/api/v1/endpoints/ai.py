from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AIProviderError
from app.core.security import get_current_user_id
from app.db.base import get_db
from app.db.repositories.ai_repository import AIRepository, InsightRepository
from app.schemas.ai import (
    ConversationCreate,
    ConversationResponse,
    GenerateInsightsRequest,
    InsightResponse,
    MessageCreate,
    MessageResponse,
)
from app.schemas.common import SuccessResponse

router = APIRouter(prefix="/ai", tags=["ai"])


def _get_ai_provider():
    try:
        from app.ai.factory import get_ai_provider
        return get_ai_provider()
    except AIProviderError:
        return None


@router.get("/conversations", response_model=SuccessResponse[list[ConversationResponse]])
async def list_conversations(
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    repo = AIRepository(db)
    conversations = await repo.list_conversations(user_id)
    return SuccessResponse(data=[ConversationResponse.model_validate(c) for c in conversations])


@router.post("/conversations", response_model=SuccessResponse[ConversationResponse], status_code=201)
async def create_conversation(
    data: ConversationCreate,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    repo = AIRepository(db)
    conversation = await repo.create({
        "user_id": user_id,
        "title": data.title or "New Conversation",
    })
    return SuccessResponse(data=ConversationResponse.model_validate(conversation))


@router.get("/conversations/{conversation_id}", response_model=SuccessResponse[ConversationResponse])
async def get_conversation(
    conversation_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    repo = AIRepository(db)
    conversation = await repo.get_conversation_with_messages(conversation_id, user_id)
    if not conversation:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Conversation")
    return SuccessResponse(data=ConversationResponse.model_validate(conversation))


@router.post(
    "/conversations/{conversation_id}/messages",
    response_model=SuccessResponse[MessageResponse],
    status_code=201,
)
async def send_message(
    conversation_id: UUID,
    request: MessageCreate,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    repo = AIRepository(db)
    conversation = await repo.get_conversation_with_messages(conversation_id, user_id)
    if not conversation:
        from app.core.exceptions import NotFoundError
        raise NotFoundError("Conversation")

    # Store user message
    user_msg = await repo.add_message(conversation_id, "user", request.content)

    # Get AI response
    ai_provider = _get_ai_provider()
    if not ai_provider:
        ai_response = (
            "AI assistant is not configured. Please set your API key in the environment."
        )
    else:
        from app.ai.base import AIProviderMessage
        from app.ai.financial_assistant import FinancialAssistant

        assistant = FinancialAssistant(ai_provider, db)
        history = await repo.get_recent_messages(conversation_id, limit=8)
        history_msgs = [
            AIProviderMessage(role=m.role, content=m.content)
            for m in history[:-1]  # exclude latest user message
        ]
        try:
            ai_response = await assistant.process_message(
                request.content, user_id, history_msgs
            )
        except AIProviderError as e:
            ai_response = f"I'm unable to respond right now: {str(e)}"

    # Store assistant message
    assistant_msg = await repo.add_message(conversation_id, "assistant", ai_response)

    # Auto-set title from first message
    if conversation.message_count <= 2 and not conversation.title:
        import sqlalchemy as sa
        from app.models.ai_conversation import AIConversation
        title = request.content[:100]
        await db.execute(
            sa.update(AIConversation)
            .where(AIConversation.id == conversation_id)
            .values(title=title)
        )

    return SuccessResponse(data=MessageResponse.model_validate(assistant_msg))


@router.get("/insights", response_model=SuccessResponse[list[InsightResponse]])
async def list_insights(
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    repo = InsightRepository(db)
    insights = await repo.list_for_user(user_id)
    return SuccessResponse(data=[InsightResponse.model_validate(i) for i in insights])


@router.post("/insights/generate", response_model=SuccessResponse[dict])
async def generate_insights(
    request: GenerateInsightsRequest,
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Trigger insight generation for a given month."""
    from datetime import date

    month = request.month or date.today().month
    year = request.year or date.today().year

    ai_provider = _get_ai_provider()
    if not ai_provider:
        return SuccessResponse(data={"message": "AI provider not configured. Insights require an AI API key."})

    from app.ai.insight_service import InsightService
    insight_svc = InsightService(db)
    insights = await insight_svc.generate_monthly_insights(user_id, month, year)
    return SuccessResponse(data={"generated": len(insights)})

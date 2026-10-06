from functools import lru_cache

from app.ai.base import AIProvider
from app.core.config import settings
from app.core.exceptions import AIProviderError
from app.core.logging import get_logger

logger = get_logger(__name__)

_provider_instance: AIProvider | None = None


def get_ai_provider() -> AIProvider:
    global _provider_instance
    if _provider_instance is not None:
        return _provider_instance

    provider_name = settings.AI_PROVIDER.lower()

    if provider_name == "openai":
        from app.ai.openai_provider import OpenAIProvider
        _provider_instance = OpenAIProvider()
    elif provider_name == "gemini":
        from app.ai.gemini_provider import GeminiProvider
        _provider_instance = GeminiProvider()
    else:
        raise AIProviderError(
            f"Unknown AI provider '{provider_name}'. Set AI_PROVIDER to 'openai' or 'gemini'."
        )

    logger.info("ai_provider_initialized", provider=provider_name)
    return _provider_instance


def reset_provider() -> None:
    """Reset cached provider (useful for testing)."""
    global _provider_instance
    _provider_instance = None

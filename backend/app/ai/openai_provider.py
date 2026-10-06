import json
from typing import Type

from pydantic import BaseModel

from app.ai.base import AIProvider, AIProviderMessage
from app.core.config import settings
from app.core.exceptions import AIProviderError
from app.core.logging import get_logger

logger = get_logger(__name__)


class OpenAIProvider(AIProvider):
    def __init__(self):
        if not settings.OPENAI_API_KEY:
            raise AIProviderError(
                "OpenAI API key is not configured. Set OPENAI_API_KEY in your .env file."
            )
        try:
            from openai import AsyncOpenAI
            self._client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
            self._model = settings.OPENAI_MODEL
        except ImportError:
            raise AIProviderError("openai package is not installed.")

    @property
    def name(self) -> str:
        return "openai"

    async def complete(
        self,
        messages: list[AIProviderMessage],
        system_prompt: str = "",
        temperature: float = 0.3,
    ) -> str:
        api_messages = []
        if system_prompt:
            api_messages.append({"role": "system", "content": system_prompt})
        api_messages.extend({"role": m.role, "content": m.content} for m in messages)

        for attempt in range(3):
            try:
                response = await self._client.chat.completions.create(
                    model=self._model,
                    messages=api_messages,
                    temperature=temperature,
                    max_tokens=2048,
                )
                return response.choices[0].message.content or ""
            except Exception as e:
                if attempt == 2:
                    logger.error("openai_completion_failed", error=str(e), attempt=attempt)
                    raise AIProviderError(f"OpenAI request failed: {str(e)}")

        return ""

    async def complete_structured(
        self,
        messages: list[AIProviderMessage],
        output_schema: Type[BaseModel],
        system_prompt: str = "",
    ) -> dict:
        schema = output_schema.model_json_schema()
        enhanced_system = (
            f"{system_prompt}\n\nRespond ONLY with valid JSON matching this schema:\n"
            f"{json.dumps(schema, indent=2)}\n\nDo not include any other text."
        )

        api_messages = []
        if enhanced_system:
            api_messages.append({"role": "system", "content": enhanced_system})
        api_messages.extend({"role": m.role, "content": m.content} for m in messages)

        for attempt in range(3):
            try:
                response = await self._client.chat.completions.create(
                    model=self._model,
                    messages=api_messages,
                    temperature=0.1,
                    max_tokens=1024,
                    response_format={"type": "json_object"},
                )
                content = response.choices[0].message.content or "{}"
                return json.loads(content)
            except json.JSONDecodeError:
                if attempt == 2:
                    raise AIProviderError("Failed to parse structured AI response as JSON.")
            except Exception as e:
                if attempt == 2:
                    raise AIProviderError(f"OpenAI structured request failed: {str(e)}")

        return {}

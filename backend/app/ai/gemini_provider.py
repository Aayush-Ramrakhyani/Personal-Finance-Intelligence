import json
from typing import Type

from pydantic import BaseModel

from app.ai.base import AIProvider, AIProviderMessage
from app.core.config import settings
from app.core.exceptions import AIProviderError
from app.core.logging import get_logger

logger = get_logger(__name__)


class GeminiProvider(AIProvider):
    def __init__(self):
        if not settings.GEMINI_API_KEY:
            raise AIProviderError(
                "Gemini API key is not configured. Set GEMINI_API_KEY in your .env file."
            )
        try:
            import google.generativeai as genai
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self._genai = genai
            self._model_name = settings.GEMINI_MODEL
        except ImportError:
            raise AIProviderError("google-generativeai package is not installed.")

    @property
    def name(self) -> str:
        return "gemini"

    def _build_prompt(
        self, messages: list[AIProviderMessage], system_prompt: str = ""
    ) -> str:
        parts = []
        if system_prompt:
            parts.append(f"[System Instructions]\n{system_prompt}\n")
        for m in messages:
            role = "User" if m.role == "user" else "Assistant"
            parts.append(f"{role}: {m.content}")
        return "\n".join(parts)

    async def complete(
        self,
        messages: list[AIProviderMessage],
        system_prompt: str = "",
        temperature: float = 0.3,
    ) -> str:
        prompt = self._build_prompt(messages, system_prompt)
        for attempt in range(3):
            try:
                model = self._genai.GenerativeModel(
                    self._model_name,
                    generation_config={"temperature": temperature, "max_output_tokens": 2048},
                )
                response = model.generate_content(prompt)
                return response.text or ""
            except Exception as e:
                if attempt == 2:
                    logger.error("gemini_completion_failed", error=str(e))
                    raise AIProviderError(f"Gemini request failed: {str(e)}")
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
        prompt = self._build_prompt(messages, enhanced_system)
        for attempt in range(3):
            try:
                model = self._genai.GenerativeModel(
                    self._model_name,
                    generation_config={"temperature": 0.1, "max_output_tokens": 1024},
                )
                response = model.generate_content(prompt)
                text = response.text or "{}"
                # Clean markdown code blocks if present
                text = text.strip()
                if text.startswith("```"):
                    text = text.split("```")[1]
                    if text.startswith("json"):
                        text = text[4:]
                return json.loads(text.strip())
            except json.JSONDecodeError:
                if attempt == 2:
                    raise AIProviderError("Failed to parse Gemini structured response as JSON.")
            except Exception as e:
                if attempt == 2:
                    raise AIProviderError(f"Gemini structured request failed: {str(e)}")
        return {}

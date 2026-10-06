from abc import ABC, abstractmethod
from typing import Type

from pydantic import BaseModel


class AIProviderMessage(BaseModel):
    role: str  # "user" or "assistant"
    content: str


class AIProvider(ABC):
    @abstractmethod
    async def complete(
        self,
        messages: list[AIProviderMessage],
        system_prompt: str = "",
        temperature: float = 0.3,
    ) -> str:
        pass

    @abstractmethod
    async def complete_structured(
        self,
        messages: list[AIProviderMessage],
        output_schema: Type[BaseModel],
        system_prompt: str = "",
    ) -> dict:
        pass

    @property
    @abstractmethod
    def name(self) -> str:
        pass

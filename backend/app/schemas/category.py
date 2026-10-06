import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, field_validator

VALID_TYPES = {"income", "expense"}


class CategoryCreate(BaseModel):
    name: str
    type: str
    parent_id: Optional[uuid.UUID] = None
    icon: Optional[str] = None
    color: Optional[str] = None

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        if v not in VALID_TYPES:
            raise ValueError("Category type must be 'income' or 'expense'.")
        return v


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    is_active: Optional[bool] = None


class CategoryResponse(BaseModel):
    id: uuid.UUID
    user_id: Optional[uuid.UUID]
    parent_id: Optional[uuid.UUID]
    name: str
    type: str
    icon: Optional[str]
    color: Optional[str]
    is_system: bool
    is_active: bool
    sort_order: int
    children: list["CategoryResponse"] = []

    model_config = {"from_attributes": True}


CategoryResponse.model_rebuild()

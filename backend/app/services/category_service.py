from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AuthorizationError, NotFoundError
from app.db.repositories.category_repository import CategoryRepository
from app.models.category import Category
from app.schemas.category import CategoryCreate, CategoryResponse, CategoryUpdate

SYSTEM_CATEGORIES = [
    # Income
    {"name": "Salary", "type": "income", "icon": "💼", "color": "#4CAF50", "sort_order": 1},
    {"name": "Freelance", "type": "income", "icon": "💻", "color": "#8BC34A", "sort_order": 2},
    {"name": "Business", "type": "income", "icon": "🏢", "color": "#CDDC39", "sort_order": 3},
    {"name": "Interest", "type": "income", "icon": "🏦", "color": "#00BCD4", "sort_order": 4},
    {"name": "Other Income", "type": "income", "icon": "💰", "color": "#009688", "sort_order": 5},
    # Expense
    {"name": "Food", "type": "expense", "icon": "🍽️", "color": "#FF5722", "sort_order": 10},
    {"name": "Groceries", "type": "expense", "icon": "🛒", "color": "#FF9800", "sort_order": 11},
    {"name": "Transportation", "type": "expense", "icon": "🚗", "color": "#2196F3", "sort_order": 12},
    {"name": "Rent", "type": "expense", "icon": "🏠", "color": "#9C27B0", "sort_order": 13},
    {"name": "Utilities", "type": "expense", "icon": "💡", "color": "#FFEB3B", "sort_order": 14},
    {"name": "Shopping", "type": "expense", "icon": "🛍️", "color": "#E91E63", "sort_order": 15},
    {"name": "Healthcare", "type": "expense", "icon": "🏥", "color": "#F44336", "sort_order": 16},
    {"name": "Education", "type": "expense", "icon": "📚", "color": "#3F51B5", "sort_order": 17},
    {"name": "Entertainment", "type": "expense", "icon": "🎬", "color": "#673AB7", "sort_order": 18},
    {"name": "Travel", "type": "expense", "icon": "✈️", "color": "#00BCD4", "sort_order": 19},
    {"name": "Insurance", "type": "expense", "icon": "🛡️", "color": "#607D8B", "sort_order": 20},
    {"name": "Subscriptions", "type": "expense", "icon": "🔄", "color": "#795548", "sort_order": 21},
    {"name": "Bills", "type": "expense", "icon": "📄", "color": "#9E9E9E", "sort_order": 22},
    {"name": "Personal Care", "type": "expense", "icon": "💅", "color": "#FF4081", "sort_order": 23},
    {"name": "Family", "type": "expense", "icon": "👨‍👩‍👧", "color": "#66BB6A", "sort_order": 24},
    {"name": "Other Expense", "type": "expense", "icon": "💸", "color": "#78909C", "sort_order": 25},
]

SYSTEM_SUBCATEGORIES = {
    "Food": [
        {"name": "Dining", "type": "expense", "icon": "🍜", "color": "#FF7043"},
        {"name": "Cafe", "type": "expense", "icon": "☕", "color": "#A1887F"},
    ],
    "Transportation": [
        {"name": "Fuel", "type": "expense", "icon": "⛽", "color": "#42A5F5"},
        {"name": "Ride-sharing", "type": "expense", "icon": "🚕", "color": "#26C6DA"},
        {"name": "Public Transit", "type": "expense", "icon": "🚌", "color": "#AB47BC"},
    ],
    "Entertainment": [
        {"name": "Streaming", "type": "expense", "icon": "📺", "color": "#7E57C2"},
        {"name": "Music", "type": "expense", "icon": "🎵", "color": "#EC407A"},
        {"name": "Gaming", "type": "expense", "icon": "🎮", "color": "#42A5F5"},
    ],
    "Shopping": [
        {"name": "Online", "type": "expense", "icon": "🛍️", "color": "#FF7043"},
        {"name": "Clothing", "type": "expense", "icon": "👗", "color": "#EC407A"},
    ],
    "Healthcare": [
        {"name": "Pharmacy", "type": "expense", "icon": "💊", "color": "#EF5350"},
        {"name": "Consultation", "type": "expense", "icon": "👨‍⚕️", "color": "#EF9A9A"},
    ],
    "Travel": [
        {"name": "Flights", "type": "expense", "icon": "✈️", "color": "#29B6F6"},
        {"name": "Hotels", "type": "expense", "icon": "🏨", "color": "#FFA726"},
        {"name": "Train", "type": "expense", "icon": "🚂", "color": "#66BB6A"},
    ],
    "Utilities": [
        {"name": "Electricity", "type": "expense", "icon": "⚡", "color": "#FFCA28"},
        {"name": "Water", "type": "expense", "icon": "💧", "color": "#29B6F6"},
        {"name": "Gas", "type": "expense", "icon": "🔥", "color": "#FF7043"},
        {"name": "Internet", "type": "expense", "icon": "📶", "color": "#26C6DA"},
        {"name": "Mobile", "type": "expense", "icon": "📱", "color": "#66BB6A"},
    ],
    "Bills": [
        {"name": "Banking", "type": "expense", "icon": "🏦", "color": "#78909C"},
    ],
    "Education": [
        {"name": "Online Learning", "type": "expense", "icon": "💻", "color": "#5C6BC0"},
        {"name": "Books", "type": "expense", "icon": "📖", "color": "#8D6E63"},
    ],
}


class CategoryService:
    def __init__(self, db: AsyncSession):
        self.repo = CategoryRepository(db)

    async def ensure_system_categories(self) -> None:
        count = await self.repo.count_system_categories()
        if count > 0:
            return  # Already seeded

        # Create parent categories
        parent_map: dict[str, UUID] = {}
        for cat_data in SYSTEM_CATEGORIES:
            cat = await self.repo.create({
                **cat_data,
                "user_id": None,
                "is_system": True,
            })
            parent_map[cat_data["name"]] = cat.id

        # Create subcategories
        for parent_name, subcats in SYSTEM_SUBCATEGORIES.items():
            parent_id = parent_map.get(parent_name)
            if not parent_id:
                continue
            for sub_data in subcats:
                await self.repo.create({
                    **sub_data,
                    "user_id": None,
                    "parent_id": parent_id,
                    "is_system": True,
                    "sort_order": 0,
                })

    async def list_categories(self, user_id: UUID) -> list[CategoryResponse]:
        cats = await self.repo.get_roots_for_user(user_id)
        return [CategoryResponse.model_validate(c) for c in cats]

    async def create_category(self, user_id: UUID, data: CategoryCreate) -> CategoryResponse:
        parent_id = data.parent_id
        if parent_id:
            parent = await self.repo.get(parent_id)
            if not parent:
                raise NotFoundError("Parent category")
        cat = await self.repo.create({
            "user_id": user_id,
            "name": data.name,
            "type": data.type,
            "parent_id": data.parent_id,
            "icon": data.icon,
            "color": data.color,
            "is_system": False,
        })
        return CategoryResponse.model_validate(cat)

    async def update_category(
        self, category_id: UUID, user_id: UUID, data: CategoryUpdate
    ) -> CategoryResponse:
        cat = await self.repo.get(category_id)
        if not cat:
            raise NotFoundError("Category")
        if cat.user_id and cat.user_id != user_id:
            raise AuthorizationError()
        if cat.is_system:
            raise AuthorizationError("Cannot modify system categories.")
        updated = await self.repo.update(cat, data.model_dump(exclude_none=True))
        return CategoryResponse.model_validate(updated)

    async def delete_category(self, category_id: UUID, user_id: UUID) -> None:
        cat = await self.repo.get(category_id)
        if not cat:
            raise NotFoundError("Category")
        if cat.is_system or (cat.user_id and cat.user_id != user_id):
            raise AuthorizationError()
        await self.repo.update(cat, {"is_active": False})

"""Hybrid categorization: rule-based first, then AI."""
import json
import re
from decimal import Decimal
from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.base import AIProvider, AIProviderMessage
from app.ai.prompts import CATEGORIZATION_SYSTEM
from app.ai.schemas import TransactionClassification
from app.core.config import settings
from app.core.logging import get_logger
from app.db.repositories.category_repository import CategoryRepository

logger = get_logger(__name__)

# (pattern, {category, subcategory, type})
MERCHANT_RULES: list[tuple[str, dict]] = [
    # Food - Delivery
    (r"swiggy", {"category": "Food", "subcategory": "Dining", "type": "expense"}),
    (r"zomato", {"category": "Food", "subcategory": "Dining", "type": "expense"}),
    (r"uber\s*eats", {"category": "Food", "subcategory": "Dining", "type": "expense"}),
    # Cafes
    (r"starbucks|ccd|cafe\s*coffee|barista", {"category": "Food", "subcategory": "Cafe", "type": "expense"}),
    # Dining
    (r"haldiram|mcdonalds|kfc|subway|pizza\s*hut|dominos|burger\s*king|barbeque\s*nation",
     {"category": "Food", "subcategory": "Dining", "type": "expense"}),
    # Groceries
    (r"bigbasket|blinkit|grofers|d\s*mart|reliance\s*(fresh|smart)|more\s*supermarket|star\s*bazaar",
     {"category": "Groceries", "type": "expense"}),
    # Transportation - Rides
    (r"^uber(?!\s*eats)", {"category": "Transportation", "subcategory": "Ride-sharing", "type": "expense"}),
    (r"ola\s*(cabs)?", {"category": "Transportation", "subcategory": "Ride-sharing", "type": "expense"}),
    (r"rapido", {"category": "Transportation", "subcategory": "Ride-sharing", "type": "expense"}),
    # Transportation - Fuel
    (r"petrol|hp\s*petrol|indian\s*oil|iocl|bharat\s*petrol|bpcl|shell",
     {"category": "Transportation", "subcategory": "Fuel", "type": "expense"}),
    # Public Transit
    (r"dmrc|delhi\s*metro|bmtc|best\s*bus|ktcl",
     {"category": "Transportation", "subcategory": "Public Transit", "type": "expense"}),
    # Flights & Travel
    (r"indigo|spicejet|air\s*india|vistara|air\s*asia|go\s*air",
     {"category": "Travel", "subcategory": "Flights", "type": "expense"}),
    (r"irctc", {"category": "Travel", "subcategory": "Train", "type": "expense"}),
    (r"oyo|treebo|fabhotels|taj\s*hotels|itc\s*hotels",
     {"category": "Travel", "subcategory": "Hotels", "type": "expense"}),
    (r"makemytrip|goibibo|yatra|cleartrip",
     {"category": "Travel", "type": "expense"}),
    # Entertainment
    (r"netflix", {"category": "Entertainment", "subcategory": "Streaming", "type": "expense"}),
    (r"spotify", {"category": "Entertainment", "subcategory": "Music", "type": "expense"}),
    (r"prime\s*video|amazon\s*prime",
     {"category": "Entertainment", "subcategory": "Streaming", "type": "expense"}),
    (r"hotstar|disney", {"category": "Entertainment", "subcategory": "Streaming", "type": "expense"}),
    (r"youtube\s*premium", {"category": "Entertainment", "subcategory": "Streaming", "type": "expense"}),
    (r"bookmyshow|pvr|inox", {"category": "Entertainment", "type": "expense"}),
    (r"steam|epic\s*games|playstation|xbox",
     {"category": "Entertainment", "subcategory": "Gaming", "type": "expense"}),
    # Shopping
    (r"amazon(?!\s*prime)", {"category": "Shopping", "subcategory": "Online", "type": "expense"}),
    (r"flipkart", {"category": "Shopping", "subcategory": "Online", "type": "expense"}),
    (r"myntra|ajio|nykaa", {"category": "Shopping", "subcategory": "Clothing", "type": "expense"}),
    # Healthcare
    (r"apollo\s*(pharmacy)?|medplus|1mg|pharmeasy",
     {"category": "Healthcare", "subcategory": "Pharmacy", "type": "expense"}),
    (r"practo|lybrate|max\s*hospital|fortis\s*hospital|aiims",
     {"category": "Healthcare", "subcategory": "Consultation", "type": "expense"}),
    # Bills - Mobile/Internet
    (r"jio", {"category": "Bills", "subcategory": "Mobile", "type": "expense"}),
    (r"airtel", {"category": "Bills", "subcategory": "Mobile", "type": "expense"}),
    (r"bsnl|vi\s*(vodafone)?|idea", {"category": "Bills", "subcategory": "Mobile", "type": "expense"}),
    # Utilities - Electricity
    (r"bescom|tata\s*power|adani\s*electricity|mseb|bses|cesc",
     {"category": "Utilities", "subcategory": "Electricity", "type": "expense"}),
    # Utilities - Gas
    (r"indane|hp\s*gas|bharat\s*gas|mahanagar\s*gas",
     {"category": "Utilities", "subcategory": "Gas", "type": "expense"}),
    # Insurance
    (r"lic|star\s*health|hdfc\s*life|sbi\s*life|bajaj\s*allianz|icici\s*lombard",
     {"category": "Insurance", "type": "expense"}),
    # Education
    (r"byju|unacademy|coursera|udemy|skillshare",
     {"category": "Education", "subcategory": "Online Learning", "type": "expense"}),
    # Income patterns
    (r"salary|payroll|stipend|ctc", {"category": "Salary", "type": "income"}),
    (r"freelance|consulting|project\s*payment", {"category": "Freelance", "type": "income"}),
    (r"interest\s*(income|credit)|dividend", {"category": "Interest", "type": "income"}),
    (r"refund|cashback", {"category": "Other Income", "type": "income"}),
    # Rent
    (r"rent|housing\s*society|maintenance", {"category": "Rent", "type": "expense"}),
]


class CategorizationService:
    def __init__(self, db: AsyncSession, ai_provider: Optional[AIProvider] = None):
        self.db = db
        self.ai_provider = ai_provider
        self.cat_repo = CategoryRepository(db)

    def _rule_based_categorize(self, merchant: str, description: str) -> Optional[dict]:
        text = f"{merchant} {description}".lower().strip()
        for pattern, result in MERCHANT_RULES:
            if re.search(pattern, text, re.IGNORECASE):
                return {**result, "confidence": 0.95, "source": "rule_based"}
        return None

    async def categorize(
        self,
        merchant: str,
        description: str,
        amount: Decimal,
        transaction_type: str,
        user_id: UUID,
    ) -> Optional[TransactionClassification]:
        # Try rule-based first
        rule_result = self._rule_based_categorize(merchant, description)
        if rule_result:
            return TransactionClassification(
                merchant=merchant,
                category=rule_result["category"],
                subcategory=rule_result.get("subcategory"),
                confidence=rule_result["confidence"],
                reasoning="rule_based",
            )

        # Try AI if available
        if not self.ai_provider:
            return None

        try:
            categories = await self.cat_repo.list_for_user(user_id)
            cat_names = [c.name for c in categories]

            messages = [
                AIProviderMessage(
                    role="user",
                    content=json.dumps({
                        "merchant": merchant,
                        "description": description,
                        "amount": str(amount),
                        "type": transaction_type,
                        "available_categories": cat_names,
                    })
                )
            ]
            raw = await self.ai_provider.complete_structured(
                messages, TransactionClassification, CATEGORIZATION_SYSTEM
            )
            result = TransactionClassification(**raw)

            # Validate that category exists
            if result.category not in cat_names:
                result.category = (
                    "Other Income" if transaction_type == "income" else "Other Expense"
                )
                result.confidence = 0.3

            return result
        except Exception as e:
            logger.warning("ai_categorization_failed", error=str(e))
            return None

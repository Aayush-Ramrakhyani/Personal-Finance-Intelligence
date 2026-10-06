"""AI financial assistant - AI explains verified backend data, never computes totals."""
import calendar
import json
from datetime import date
from decimal import Decimal
from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.base import AIProvider, AIProviderMessage
from app.ai.prompts import FINANCIAL_ASSISTANT_SYSTEM, QUERY_INTENT_SYSTEM
from app.ai.schemas import FinancialQueryIntent
from app.core.exceptions import AIProviderError
from app.core.logging import get_logger
from app.services.analytics_service import AnalyticsService

logger = get_logger(__name__)


class FinancialAssistant:
    def __init__(self, ai_provider: AIProvider, db: AsyncSession):
        self.ai = ai_provider
        self.db = db
        self.analytics = AnalyticsService(db)

    async def process_message(
        self,
        user_message: str,
        user_id: UUID,
        conversation_history: list[AIProviderMessage],
    ) -> str:
        # Step 1: Parse intent from user question
        intent = await self._parse_intent(user_message)

        # Step 2: Fetch verified financial data based on intent
        context = await self._get_financial_context(intent, user_id)

        # Step 3: Build messages with verified context
        system = FINANCIAL_ASSISTANT_SYSTEM
        if context:
            system += (
                f"\n\n[VERIFIED FINANCIAL DATA]\n{json.dumps(context, default=str, indent=2)}"
                f"\n\nUse these exact figures in your response. Do not compute differently."
            )

        messages = list(conversation_history) + [
            AIProviderMessage(role="user", content=user_message)
        ]

        # Step 4: AI generates natural language response
        response = await self.ai.complete(messages, system_prompt=system, temperature=0.4)
        return response

    async def _parse_intent(self, user_message: str) -> FinancialQueryIntent:
        try:
            messages = [AIProviderMessage(role="user", content=user_message)]
            raw = await self.ai.complete_structured(
                messages, FinancialQueryIntent, QUERY_INTENT_SYSTEM
            )
            return FinancialQueryIntent(**raw)
        except Exception:
            return FinancialQueryIntent(intent="general")

    async def _get_financial_context(
        self, intent: FinancialQueryIntent, user_id: UUID
    ) -> Optional[dict]:
        today = date.today()
        try:
            start, end = self._period_to_dates(intent.period, today)
            if intent.intent in (
                "total_spending", "income", "savings", "comparison", "general"
            ):
                overview = await self.analytics.get_overview(user_id, start, end)
                return {
                    "period": f"{start} to {end}",
                    "total_income": str(overview.total_income),
                    "total_expenses": str(overview.total_expenses),
                    "net_cash_flow": str(overview.net_cash_flow),
                    "savings": str(overview.savings),
                    "savings_rate_percent": str(overview.savings_rate),
                }
            elif intent.intent == "category_spending":
                cats = await self.analytics.get_category_breakdown(user_id, start, end, "expense")
                if intent.category:
                    cats = [c for c in cats if intent.category.lower() in c.category_name.lower()]
                return {
                    "period": f"{start} to {end}",
                    "category_breakdown": [
                        {
                            "category": c.category_name,
                            "amount": str(c.amount),
                            "percentage": str(c.percentage),
                        }
                        for c in cats[:10]
                    ],
                }
            elif intent.intent == "recurring":
                from app.services.recurring_service import RecurringService
                rec_svc = RecurringService(self.db)
                summary = await rec_svc.list_recurring(user_id)
                return {
                    "total_monthly_recurring": str(summary.total_monthly_cost),
                    "total_annual_recurring": str(summary.total_annual_cost),
                    "recurring_items": [
                        {"merchant": r.merchant, "amount": str(r.amount), "frequency": r.frequency}
                        for r in summary.items[:10]
                    ],
                }
            elif intent.intent == "anomaly":
                anomalies = await self.analytics.get_anomalies(user_id)
                return {
                    "anomalies": [
                        {
                            "category": a.category_name,
                            "current": str(a.current_amount),
                            "average": str(a.average_amount),
                            "increase_percent": str(a.deviation_percentage),
                        }
                        for a in anomalies
                    ]
                }
        except Exception as e:
            logger.warning("context_fetch_failed", error=str(e))
        return None

    def _period_to_dates(self, period: Optional[str], today: date) -> tuple[date, date]:
        from dateutil.relativedelta import relativedelta

        if period == "current_month" or period is None:
            start = today.replace(day=1)
            _, last_day = calendar.monthrange(today.year, today.month)
            end = today.replace(day=last_day)
        elif period == "previous_month":
            first_of_current = today.replace(day=1)
            last_prev = first_of_current - relativedelta(days=1)
            start = last_prev.replace(day=1)
            end = last_prev
        elif period == "last_3_months":
            end = today
            start = (today - relativedelta(months=3)).replace(day=1)
        elif period == "last_6_months":
            end = today
            start = (today - relativedelta(months=6)).replace(day=1)
        elif period == "last_year":
            end = today
            start = today.replace(year=today.year - 1)
        elif period == "all_time":
            start = date(2000, 1, 1)
            end = today
        else:
            start = today.replace(day=1)
            _, last_day = calendar.monthrange(today.year, today.month)
            end = today.replace(day=last_day)

        return start, end

"""Generate financial insights from verified backend calculations."""
import calendar
from datetime import date
from decimal import Decimal
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.base import AIProvider, AIProviderMessage
from app.ai.prompts import INSIGHT_GENERATION_SYSTEM, MONTHLY_SUMMARY_SYSTEM
from app.ai.schemas import FinancialInsightOutput, MonthlySummaryOutput
from app.core.logging import get_logger
from app.models.financial_insight import FinancialInsight
from app.services.analytics_service import AnalyticsService

logger = get_logger(__name__)

MONTH_NAMES = [
    "", "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
]


class InsightService:
    def __init__(self, db: AsyncSession, ai_provider: AIProvider = None):
        self.db = db
        self.ai = ai_provider
        self.analytics = AnalyticsService(db)

    async def generate_monthly_insights(
        self, user_id: UUID, month: int, year: int
    ) -> list[FinancialInsight]:
        # Backend calculates all verified metrics
        _, last_day = calendar.monthrange(year, month)
        start = date(year, month, 1)
        end = date(year, month, last_day)

        overview = await self.analytics.get_overview(user_id, start, end)
        categories = await self.analytics.get_category_breakdown(user_id, start, end, "expense")
        anomalies = await self.analytics.get_anomalies(user_id)
        cash_flow = await self.analytics.get_cash_flow(user_id, 2)

        # Build verified context for AI
        context = {
            "month": f"{MONTH_NAMES[month]} {year}",
            "total_income": str(overview.total_income),
            "total_expenses": str(overview.total_expenses),
            "net_cash_flow": str(overview.net_cash_flow),
            "savings_rate_percent": str(overview.savings_rate),
            "top_categories": [
                {"name": c.category_name, "amount": str(c.amount), "percentage": str(c.percentage)}
                for c in categories[:5]
            ],
            "anomalies": [
                {
                    "category": a.category_name,
                    "current": str(a.current_amount),
                    "average": str(a.average_amount),
                    "increase_pct": str(a.deviation_percentage),
                }
                for a in anomalies[:3]
            ],
        }

        insights = []

        if self.ai:
            import json
            try:
                messages = [
                    AIProviderMessage(
                        role="user",
                        content=f"Generate financial insights for this data:\n{json.dumps(context, indent=2)}",
                    )
                ]
                raw = await self.ai.complete_structured(
                    messages, MonthlySummaryOutput, MONTHLY_SUMMARY_SYSTEM
                )
                summary = MonthlySummaryOutput(**raw)

                # Store as insight record
                insight = FinancialInsight(
                    user_id=user_id,
                    insight_type="monthly_summary",
                    title=f"Monthly Summary: {MONTH_NAMES[month]} {year}",
                    body=summary.overview,
                    priority="high",
                    period_month=month,
                    period_year=year,
                    metadata={
                        "positive": summary.positive_observations,
                        "concerning": summary.concerning_changes,
                        "patterns": summary.spending_patterns,
                        "review": summary.areas_to_review,
                    },
                )
                self.db.add(insight)
                await self.db.flush()
                insights.append(insight)
            except Exception as e:
                logger.warning("monthly_insight_failed", error=str(e))

        # Always generate rule-based anomaly insights
        for anomaly in anomalies[:3]:
            if anomaly.deviation_percentage > 30:
                body = (
                    f"Based on your recorded transactions, you spent ₹{anomaly.current_amount:,.2f} "
                    f"on {anomaly.category_name} this month, which is {anomaly.deviation_percentage:.0f}% "
                    f"higher than your 3-month average of ₹{anomaly.average_amount:,.2f}."
                )
                insight = FinancialInsight(
                    user_id=user_id,
                    insight_type="anomaly",
                    title=f"Unusual spending on {anomaly.category_name}",
                    body=body,
                    priority="high" if anomaly.deviation_percentage > 100 else "medium",
                    category=anomaly.category_name,
                    amount=anomaly.current_amount,
                    period_month=month,
                    period_year=year,
                )
                self.db.add(insight)
                await self.db.flush()
                insights.append(insight)

        return insights

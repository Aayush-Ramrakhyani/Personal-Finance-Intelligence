import calendar
from datetime import date
from decimal import Decimal
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user_id
from app.db.base import get_db
from app.schemas.common import SuccessResponse
from app.services.analytics_service import AnalyticsService
from app.services.recurring_service import RecurringService

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/monthly", response_model=SuccessResponse[dict])
async def monthly_report(
    month: Optional[int] = Query(None, ge=1, le=12),
    year: Optional[int] = Query(None),
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    m = month or today.month
    y = year or today.year

    _, last_day = calendar.monthrange(y, m)
    start = date(y, m, 1)
    end = date(y, m, last_day)

    # Previous month for comparison
    if m == 1:
        prev_m, prev_y = 12, y - 1
    else:
        prev_m, prev_y = m - 1, y
    _, prev_last = calendar.monthrange(prev_y, prev_m)
    prev_start = date(prev_y, prev_m, 1)
    prev_end = date(prev_y, prev_m, prev_last)

    analytics = AnalyticsService(db)
    overview = await analytics.get_overview(user_id, start, end)
    prev_overview = await analytics.get_overview(user_id, prev_start, prev_end)
    categories = await analytics.get_category_breakdown(user_id, start, end, "expense")
    anomalies = await analytics.get_anomalies(user_id)

    rec_svc = RecurringService(db)
    recurring = await rec_svc.list_recurring(user_id)

    def pct_change(current, previous):
        if previous == 0:
            return None
        return float(((current - previous) / previous) * 100)

    return SuccessResponse(data={
        "period": {"month": m, "year": y, "start": str(start), "end": str(end)},
        "summary": {
            "income": str(overview.total_income),
            "expenses": str(overview.total_expenses),
            "savings": str(overview.savings),
            "savings_rate": str(overview.savings_rate),
            "transaction_count": overview.transaction_count,
        },
        "vs_previous_month": {
            "income_change_pct": pct_change(overview.total_income, prev_overview.total_income),
            "expense_change_pct": pct_change(overview.total_expenses, prev_overview.total_expenses),
            "savings_change_pct": pct_change(overview.savings, prev_overview.savings),
        },
        "top_categories": [
            {
                "name": c.category_name,
                "amount": str(c.amount),
                "percentage": str(c.percentage),
                "count": c.transaction_count,
            }
            for c in categories[:10]
        ],
        "anomalies": [
            {
                "category": a.category_name,
                "current": str(a.current_amount),
                "average": str(a.average_amount),
                "deviation_pct": str(a.deviation_percentage),
                "severity": a.severity,
            }
            for a in anomalies
        ],
        "recurring_summary": {
            "total_monthly": str(recurring.total_monthly_cost),
            "total_annual": str(recurring.total_annual_cost),
            "item_count": len(recurring.items),
        },
    })

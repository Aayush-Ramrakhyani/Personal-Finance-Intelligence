import calendar
from datetime import date
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user_id
from app.db.base import get_db
from app.schemas.analytics import Anomaly, CategoryBreakdown, CashFlowMonth, OverviewResponse, TrendData
from app.schemas.common import SuccessResponse
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/analytics", tags=["analytics"])


def _current_month_dates():
    today = date.today()
    _, last_day = calendar.monthrange(today.year, today.month)
    return today.replace(day=1), today.replace(day=last_day)


@router.get("/overview", response_model=SuccessResponse[OverviewResponse])
async def get_overview(
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    if not start_date or not end_date:
        start_date, end_date = _current_month_dates()
    svc = AnalyticsService(db)
    overview = await svc.get_overview(user_id, start_date, end_date)
    return SuccessResponse(data=overview)


@router.get("/categories", response_model=SuccessResponse[list[CategoryBreakdown]])
async def get_categories(
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    type: Optional[str] = Query(None),
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    if not start_date or not end_date:
        start_date, end_date = _current_month_dates()
    svc = AnalyticsService(db)
    cats = await svc.get_category_breakdown(user_id, start_date, end_date, type)
    return SuccessResponse(data=cats)


@router.get("/cash-flow", response_model=SuccessResponse[list[CashFlowMonth]])
async def get_cash_flow(
    months: int = Query(6, ge=1, le=24),
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = AnalyticsService(db)
    cash_flow = await svc.get_cash_flow(user_id, months)
    return SuccessResponse(data=cash_flow)


@router.get("/trends", response_model=SuccessResponse[TrendData])
async def get_trends(
    months: int = Query(6, ge=1, le=24),
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = AnalyticsService(db)
    trends = await svc.get_trends(user_id, months)
    return SuccessResponse(data=trends)


@router.get("/anomalies", response_model=SuccessResponse[list[Anomaly]])
async def get_anomalies(
    user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    svc = AnalyticsService(db)
    anomalies = await svc.get_anomalies(user_id)
    return SuccessResponse(data=anomalies)

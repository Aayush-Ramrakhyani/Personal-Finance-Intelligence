"""
Tests for BudgetService's progress calculation logic.

Covers: period date resolution, percentage calculation,
remaining balance, over-budget detection, alert thresholds.
"""
import datetime
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

import pytest

from app.services.budget_service import BudgetService


def _make_budget(
    period="monthly",
    amount=Decimal("5000.00"),
    alert_thresholds=None,
    start_date=None,
    end_date=None,
):
    """Create a mock budget object for unit-testing pure methods."""
    b = MagicMock()
    b.id = uuid4()
    b.user_id = uuid4()
    b.category_id = uuid4()
    b.period = period
    b.amount = amount
    b.alert_thresholds = alert_thresholds or [50, 80, 100]
    b.start_date = start_date
    b.end_date = end_date
    b.is_active = True
    b.created_at = datetime.datetime.utcnow()
    b.category = MagicMock()
    b.category.name = "Food"
    b.category.icon = "🍽️"
    return b


@pytest.fixture
def svc():
    return BudgetService(db=MagicMock())


# ── Period date resolution ───────────────────────────────────────────────────

class TestGetPeriodDates:
    def test_monthly_period_starts_on_first(self, svc):
        today = datetime.date(2026, 10, 15)
        budget = _make_budget(period="monthly")
        start, end = svc._get_period_dates(budget, today)
        assert start == datetime.date(2026, 10, 1)

    def test_monthly_period_ends_on_last_day(self, svc):
        today = datetime.date(2026, 10, 15)
        budget = _make_budget(period="monthly")
        start, end = svc._get_period_dates(budget, today)
        assert end == datetime.date(2026, 10, 31)

    def test_february_end_day_non_leap(self, svc):
        today = datetime.date(2025, 2, 10)
        budget = _make_budget(period="monthly")
        _, end = svc._get_period_dates(budget, today)
        assert end == datetime.date(2025, 2, 28)

    def test_february_end_day_leap_year(self, svc):
        today = datetime.date(2024, 2, 5)
        budget = _make_budget(period="monthly")
        _, end = svc._get_period_dates(budget, today)
        assert end == datetime.date(2024, 2, 29)

    def test_yearly_starts_jan_1(self, svc):
        today = datetime.date(2026, 6, 20)
        budget = _make_budget(period="yearly")
        start, end = svc._get_period_dates(budget, today)
        assert start == datetime.date(2026, 1, 1)
        assert end == datetime.date(2026, 12, 31)

    def test_custom_period_uses_budget_dates(self, svc):
        start_date = datetime.date(2026, 10, 1)
        end_date = datetime.date(2026, 10, 31)
        budget = _make_budget(
            period="custom", start_date=start_date, end_date=end_date
        )
        today = datetime.date(2026, 10, 15)
        start, end = svc._get_period_dates(budget, today)
        assert start == start_date
        assert end == end_date


# ── Progress calculation ────────────────────────────────────────────────────

class TestWithProgress:
    def test_percentage_under_budget(self, svc):
        budget = _make_budget(amount=Decimal("5000.00"))
        result = svc._with_progress(budget, spent=Decimal("2500.00"))
        assert result.percentage_used == Decimal("50.00")
        assert result.remaining == Decimal("2500.00")
        assert result.is_over_budget is False

    def test_percentage_exactly_100(self, svc):
        budget = _make_budget(amount=Decimal("5000.00"))
        result = svc._with_progress(budget, spent=Decimal("5000.00"))
        assert result.percentage_used == Decimal("100.00")
        assert result.remaining == Decimal("0.00")
        assert result.is_over_budget is False

    def test_over_budget(self, svc):
        budget = _make_budget(amount=Decimal("5000.00"))
        result = svc._with_progress(budget, spent=Decimal("6000.00"))
        assert result.is_over_budget is True
        assert result.remaining == Decimal("-1000.00")
        assert result.percentage_used == Decimal("120.00")

    def test_zero_spent(self, svc):
        budget = _make_budget(amount=Decimal("5000.00"))
        result = svc._with_progress(budget, spent=Decimal("0.00"))
        assert result.percentage_used == Decimal("0.00")
        assert result.remaining == Decimal("5000.00")
        assert result.is_over_budget is False

    def test_alert_level_triggered_at_80_percent(self, svc):
        budget = _make_budget(
            amount=Decimal("5000.00"),
            alert_thresholds=[50, 80, 100],
        )
        # 4100 / 5000 = 82% → should trigger the 80 threshold
        result = svc._with_progress(budget, spent=Decimal("4100.00"))
        assert result.alert_level == 80

    def test_alert_level_triggered_at_100_percent(self, svc):
        budget = _make_budget(
            amount=Decimal("5000.00"),
            alert_thresholds=[50, 80, 100],
        )
        result = svc._with_progress(budget, spent=Decimal("5000.00"))
        assert result.alert_level == 100

    def test_no_alert_below_first_threshold(self, svc):
        budget = _make_budget(
            amount=Decimal("5000.00"),
            alert_thresholds=[50, 80, 100],
        )
        # 40% — below first threshold of 50
        result = svc._with_progress(budget, spent=Decimal("2000.00"))
        assert result.alert_level is None

    def test_zero_budget_amount_returns_zero_percent(self, svc):
        budget = _make_budget(amount=Decimal("0.00"))
        result = svc._with_progress(budget, spent=Decimal("100.00"))
        assert result.percentage_used == Decimal("0.00")

    def test_category_name_and_icon_propagated(self, svc):
        budget = _make_budget(amount=Decimal("3000.00"))
        result = svc._with_progress(budget, spent=Decimal("1000.00"))
        assert result.category_name == "Food"
        assert result.category_icon == "🍽️"

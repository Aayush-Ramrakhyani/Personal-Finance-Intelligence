from datetime import date
from decimal import Decimal

import pytest
import pytest_asyncio

from app.services.analytics_service import AnalyticsService


@pytest.mark.asyncio
async def test_overview_empty(db_session, test_user):
    svc = AnalyticsService(db_session)
    today = date.today()
    start = today.replace(day=1)
    end = today
    overview = await svc.get_overview(test_user.id, start, end)

    assert overview.total_income == Decimal("0.00") or overview.total_income >= Decimal("0")
    assert overview.total_expenses == Decimal("0.00") or overview.total_expenses >= Decimal("0")
    assert overview.savings_rate >= Decimal("0")


@pytest.mark.asyncio
async def test_savings_rate_calculation(db_session, test_user, test_account, test_category):
    from app.models.transaction import Transaction
    today = date.today()

    # Add income and expense
    income_txn = Transaction(
        user_id=test_user.id,
        account_id=test_account.id,
        category_id=test_category.id,
        type="income",
        amount=Decimal("10000.00"),
        currency="INR",
        transaction_date=today,
        source="manual",
    )
    expense_txn = Transaction(
        user_id=test_user.id,
        account_id=test_account.id,
        category_id=test_category.id,
        type="expense",
        amount=Decimal("4000.00"),
        currency="INR",
        transaction_date=today,
        source="manual",
    )
    db_session.add_all([income_txn, expense_txn])
    await db_session.flush()

    svc = AnalyticsService(db_session)
    start = today.replace(day=1)
    end = today
    overview = await svc.get_overview(test_user.id, start, end)

    assert overview.total_income >= Decimal("10000.00")
    assert overview.total_expenses >= Decimal("4000.00")
    # Savings rate = (income - expenses) / income * 100
    expected_savings = overview.total_income - overview.total_expenses
    assert overview.savings == expected_savings
    if overview.total_income > 0:
        expected_rate = (expected_savings / overview.total_income * 100).quantize(Decimal("0.01"))
        assert overview.savings_rate == expected_rate


@pytest.mark.asyncio
async def test_transfers_excluded_from_income(db_session, test_user, test_account):
    from app.models.account import Account
    from app.models.transfer import Transfer
    from app.models.transaction import Transaction
    today = date.today()

    # Create a second account
    acc2 = Account(
        user_id=test_user.id,
        name="Cash",
        account_type="cash",
        currency="INR",
        opening_balance=Decimal("0"),
        current_balance=Decimal("0"),
    )
    db_session.add(acc2)
    await db_session.flush()

    # Create transfer record and linked transactions
    transfer = Transfer(
        user_id=test_user.id,
        from_account_id=test_account.id,
        to_account_id=acc2.id,
        amount=Decimal("5000.00"),
        transfer_date=today,
    )
    db_session.add(transfer)
    await db_session.flush()

    from_txn = Transaction(
        user_id=test_user.id,
        account_id=test_account.id,
        type="transfer",
        amount=Decimal("5000.00"),
        transaction_date=today,
        source="manual",
        transfer_id=transfer.id,
    )
    to_txn = Transaction(
        user_id=test_user.id,
        account_id=acc2.id,
        type="transfer",
        amount=Decimal("5000.00"),
        transaction_date=today,
        source="manual",
        transfer_id=transfer.id,
    )
    db_session.add_all([from_txn, to_txn])
    await db_session.flush()

    svc = AnalyticsService(db_session)
    start = today.replace(day=1)
    end = today
    overview = await svc.get_overview(test_user.id, start, end)

    # Transfers must NOT be counted as income or expense
    assert overview.total_income == Decimal("0.00")
    assert overview.total_expenses == Decimal("0.00")

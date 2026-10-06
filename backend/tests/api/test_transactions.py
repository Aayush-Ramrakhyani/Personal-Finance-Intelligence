from datetime import date
from decimal import Decimal

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_expense(client: AsyncClient, auth_headers, test_account, test_category):
    resp = await client.post("/api/v1/transactions", headers=auth_headers, json={
        "account_id": str(test_account.id),
        "category_id": str(test_category.id),
        "type": "expense",
        "amount": "500.00",
        "currency": "INR",
        "merchant": "Swiggy",
        "description": "Food delivery",
        "transaction_date": str(date.today()),
    })
    assert resp.status_code == 201
    data = resp.json()
    assert data["success"] is True
    assert data["data"]["amount"] == "500.00"
    assert data["data"]["type"] == "expense"


@pytest.mark.asyncio
async def test_create_income(client: AsyncClient, auth_headers, test_account):
    resp = await client.post("/api/v1/transactions", headers=auth_headers, json={
        "account_id": str(test_account.id),
        "type": "income",
        "amount": "85000.00",
        "currency": "INR",
        "merchant": "Employer",
        "description": "Monthly salary",
        "transaction_date": str(date.today()),
    })
    assert resp.status_code == 201
    assert resp.json()["data"]["type"] == "income"


@pytest.mark.asyncio
async def test_balance_updated_on_expense(client, auth_headers, test_account, test_category, db_session):
    """Account balance decreases when expense is created."""
    initial_balance = test_account.current_balance
    amount = Decimal("1000.00")

    await client.post("/api/v1/transactions", headers=auth_headers, json={
        "account_id": str(test_account.id),
        "category_id": str(test_category.id),
        "type": "expense",
        "amount": str(amount),
        "transaction_date": str(date.today()),
    })

    from app.models.account import Account
    import sqlalchemy as sa
    result = await db_session.execute(
        sa.select(Account).where(Account.id == test_account.id)
    )
    updated_acc = result.scalar_one()
    assert updated_acc.current_balance == initial_balance - amount


@pytest.mark.asyncio
async def test_invalid_amount(client: AsyncClient, auth_headers, test_account):
    resp = await client.post("/api/v1/transactions", headers=auth_headers, json={
        "account_id": str(test_account.id),
        "type": "expense",
        "amount": "-100.00",
        "transaction_date": str(date.today()),
    })
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_list_transactions(client: AsyncClient, auth_headers, test_account, test_category):
    # Create a transaction first
    await client.post("/api/v1/transactions", headers=auth_headers, json={
        "account_id": str(test_account.id),
        "type": "expense",
        "amount": "250.00",
        "merchant": "Test Merchant",
        "transaction_date": str(date.today()),
    })
    resp = await client.get("/api/v1/transactions", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "data" in data
    assert "total" in data
    assert data["total"] >= 1


@pytest.mark.asyncio
async def test_user_isolation(client: AsyncClient, db_session):
    """User A cannot see User B's transactions."""
    # Register user B
    resp_b = await client.post("/api/v1/auth/register", json={
        "email": "userb@example.com",
        "password": "UserB@1234",
        "first_name": "User",
        "last_name": "B",
    })
    token_b = resp_b.json()["data"]["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # User B lists transactions - should be empty
    resp = await client.get("/api/v1/transactions", headers=headers_b)
    assert resp.status_code == 200
    assert resp.json()["total"] == 0


@pytest.mark.asyncio
async def test_delete_transaction(client: AsyncClient, auth_headers, test_account):
    # Create
    create_resp = await client.post("/api/v1/transactions", headers=auth_headers, json={
        "account_id": str(test_account.id),
        "type": "expense",
        "amount": "300.00",
        "transaction_date": str(date.today()),
    })
    txn_id = create_resp.json()["data"]["id"]

    # Delete
    del_resp = await client.delete(f"/api/v1/transactions/{txn_id}", headers=auth_headers)
    assert del_resp.status_code == 200

    # Verify gone
    get_resp = await client.get(f"/api/v1/transactions/{txn_id}", headers=auth_headers)
    assert get_resp.status_code == 404

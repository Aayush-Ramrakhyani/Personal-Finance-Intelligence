"""
Development seed script.
Creates demo data for local development. NOT for production use.
Run: python seed.py
"""
import asyncio
import random
from datetime import date, timedelta
from decimal import Decimal
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import hash_password
from app.db.base import AsyncSessionLocal, engine
from app.models import *  # noqa: F401,F403 - import all models
from app.services.category_service import CategoryService


DEMO_EMAIL = "demo@finance.local"
DEMO_PASSWORD = "Demo@1234"


async def seed(db: AsyncSession) -> None:
    import sqlalchemy as sa
    from app.models.user import User
    from app.models.account import Account
    from app.models.transaction import Transaction
    from app.models.budget import Budget
    from app.db.repositories.category_repository import CategoryRepository

    print("Seeding system categories...")
    cat_svc = CategoryService(db)
    await cat_svc.ensure_system_categories()
    await db.commit()

    # Check if demo user exists
    result = await db.execute(
        sa.select(User).where(User.email == DEMO_EMAIL)
    )
    demo_user = result.scalar_one_or_none()

    if demo_user:
        print(f"Demo user already exists: {DEMO_EMAIL}")
        return

    print(f"Creating demo user: {DEMO_EMAIL} / {DEMO_PASSWORD}")
    demo_user = User(
        email=DEMO_EMAIL,
        password_hash=hash_password(DEMO_PASSWORD),
        first_name="Demo",
        last_name="User",
        currency="INR",
        timezone="Asia/Kolkata",
        is_active=True,
        is_verified=True,
        onboarding_completed=True,
    )
    db.add(demo_user)
    await db.flush()

    # Create accounts
    savings_acc = Account(
        user_id=demo_user.id,
        name="HDFC Savings",
        account_type="bank",
        institution_name="HDFC Bank",
        currency="INR",
        opening_balance=Decimal("100000.00"),
        current_balance=Decimal("100000.00"),
        color="#1E88E5",
    )
    credit_acc = Account(
        user_id=demo_user.id,
        name="HDFC Credit Card",
        account_type="credit_card",
        institution_name="HDFC Bank",
        currency="INR",
        opening_balance=Decimal("0.00"),
        current_balance=Decimal("0.00"),
        color="#E53935",
    )
    cash_acc = Account(
        user_id=demo_user.id,
        name="Cash Wallet",
        account_type="cash",
        currency="INR",
        opening_balance=Decimal("5000.00"),
        current_balance=Decimal("5000.00"),
        color="#43A047",
    )
    db.add_all([savings_acc, credit_acc, cash_acc])
    await db.flush()
    print("Created accounts.")

    # Get categories
    cat_repo = CategoryRepository(db)
    all_cats = await cat_repo.list_for_user(demo_user.id)
    cat_map = {c.name: c.id for c in all_cats}

    # Generate 60 days of transactions
    today = date.today()
    balance_delta = Decimal("0.00")

    # Salary (1st of each of past 2 months)
    for i in range(2):
        sal_date = (today.replace(day=1) - timedelta(days=30 * i))
        txn = Transaction(
            user_id=demo_user.id,
            account_id=savings_acc.id,
            category_id=cat_map.get("Salary"),
            type="income",
            amount=Decimal("85000.00"),
            currency="INR",
            merchant="Employer Corp",
            description="Monthly Salary",
            transaction_date=sal_date,
            source="manual",
            category_source="manual",
        )
        db.add(txn)
        balance_delta += Decimal("85000.00")

    # Regular expenses over past 60 days
    expenses = [
        # Food
        ("Swiggy", "Food delivery", Decimal("450.00"), "expense", "Food", 5),
        ("Zomato", "Food delivery", Decimal("380.00"), "expense", "Food", 4),
        ("Starbucks", "Coffee", Decimal("580.00"), "expense", "Food", 3),
        # Transport
        ("Uber", "Cab to office", Decimal("280.00"), "expense", "Transportation", 8),
        ("Ola", "Cab ride", Decimal("220.00"), "expense", "Transportation", 5),
        ("DMRC", "Metro card recharge", Decimal("500.00"), "expense", "Transportation", 2),
        # Groceries
        ("BigBasket", "Grocery order", Decimal("2200.00"), "expense", "Groceries", 4),
        ("Blinkit", "Quick grocery", Decimal("600.00"), "expense", "Groceries", 3),
        # Entertainment/Subscriptions
        ("Netflix", "Monthly subscription", Decimal("649.00"), "expense", "Entertainment", 1),
        ("Spotify", "Premium subscription", Decimal("119.00"), "expense", "Entertainment", 1),
        ("Amazon Prime", "Annual subscription", Decimal("299.00"), "expense", "Entertainment", 1),
        # Utilities/Bills
        ("Jio", "Mobile bill", Decimal("399.00"), "expense", "Bills", 1),
        ("BESCOM", "Electricity bill", Decimal("1800.00"), "expense", "Utilities", 1),
        # Shopping
        ("Amazon", "Online shopping", Decimal("1200.00"), "expense", "Shopping", 3),
        ("Myntra", "Clothing", Decimal("2500.00"), "expense", "Shopping", 2),
        # Healthcare
        ("Apollo Pharmacy", "Medicines", Decimal("450.00"), "expense", "Healthcare", 2),
        # Personal care
        ("Salon", "Hair cut", Decimal("500.00"), "expense", "Personal Care", 2),
    ]

    random.seed(42)
    for merchant, desc, amount, txn_type, cat_name, count in expenses:
        for _ in range(count):
            days_ago = random.randint(1, 60)
            txn_date = today - timedelta(days=days_ago)
            txn = Transaction(
                user_id=demo_user.id,
                account_id=credit_acc.id if "subscription" in desc.lower() or cat_name == "Shopping" else savings_acc.id,
                category_id=cat_map.get(cat_name),
                type=txn_type,
                amount=amount * Decimal(str(random.uniform(0.9, 1.1))).quantize(Decimal("0.01")),
                currency="INR",
                merchant=merchant,
                description=desc,
                transaction_date=txn_date,
                source="manual",
                category_source="rule_based",
                category_confidence=Decimal("0.95"),
            )
            db.add(txn)
            if txn_type == "expense":
                balance_delta -= amount
            else:
                balance_delta += amount

    await db.flush()

    # Update savings account balance
    savings_acc.current_balance = Decimal("100000.00") + balance_delta
    db.add(savings_acc)

    # Create budgets
    budget_configs = [
        ("Food", Decimal("8000.00")),
        ("Transportation", Decimal("4000.00")),
        ("Entertainment", Decimal("3000.00")),
        ("Groceries", Decimal("6000.00")),
        ("Shopping", Decimal("5000.00")),
    ]
    for cat_name, amount in budget_configs:
        if cat_name in cat_map:
            budget = Budget(
                user_id=demo_user.id,
                category_id=cat_map[cat_name],
                amount=amount,
                period="monthly",
                alert_thresholds=[75, 90, 100],
            )
            db.add(budget)

    await db.commit()
    print(f"\n✅ Seed complete!")
    print(f"   Demo User: {DEMO_EMAIL}")
    print(f"   Password:  {DEMO_PASSWORD}")
    print(f"   Accounts:  HDFC Savings, HDFC Credit Card, Cash Wallet")
    print(f"   Budgets:   Food, Transportation, Entertainment, Groceries, Shopping")
    print(f"\nLog in and explore the demo data.")


async def main():
    print(f"Connecting to: {settings.DATABASE_URL}")
    async with AsyncSessionLocal() as db:
        await seed(db)


if __name__ == "__main__":
    asyncio.run(main())

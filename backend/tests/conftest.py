import asyncio
import uuid
from decimal import Decimal
from typing import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.security import hash_password
from app.db.base import Base, get_db
from app.main import app

# Use in-memory SQLite for tests
TEST_DB_URL = "sqlite+aiosqlite:///:memory:"


@pytest_asyncio.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session")
async def test_engine():
    engine = create_async_engine(TEST_DB_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest_asyncio.fixture
async def db_session(test_engine) -> AsyncGenerator[AsyncSession, None]:
    session_factory = async_sessionmaker(
        test_engine, class_=AsyncSession, expire_on_commit=False
    )
    async with session_factory() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession):
    from app.models.user import User
    user = User(
        email="test@example.com",
        password_hash=hash_password("Test@1234"),
        first_name="Test",
        last_name="User",
        currency="INR",
        timezone="Asia/Kolkata",
        is_active=True,
        is_verified=True,
    )
    db_session.add(user)
    await db_session.flush()
    await db_session.refresh(user)
    return user


@pytest_asyncio.fixture
async def auth_headers(client: AsyncClient, test_user):
    resp = await client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "Test@1234",
    })
    data = resp.json()
    token = data["data"]["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def test_account(db_session: AsyncSession, test_user):
    from app.models.account import Account
    acc = Account(
        user_id=test_user.id,
        name="Test Bank",
        account_type="bank",
        currency="INR",
        opening_balance=Decimal("50000.00"),
        current_balance=Decimal("50000.00"),
    )
    db_session.add(acc)
    await db_session.flush()
    await db_session.refresh(acc)
    return acc


@pytest_asyncio.fixture
async def test_category(db_session: AsyncSession):
    from app.models.category import Category
    cat = Category(
        user_id=None,
        name="Food",
        type="expense",
        icon="🍽️",
        is_system=True,
    )
    db_session.add(cat)
    await db_session.flush()
    await db_session.refresh(cat)
    return cat

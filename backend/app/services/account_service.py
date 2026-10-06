from decimal import Decimal
from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AuthorizationError, NotFoundError
from app.db.repositories.account_repository import AccountRepository
from app.models.account import Account
from app.schemas.account import AccountCreate, AccountResponse, AccountUpdate


class AccountService:
    def __init__(self, db: AsyncSession):
        self.repo = AccountRepository(db)

    async def create(self, user_id: UUID, data: AccountCreate) -> AccountResponse:
        account = await self.repo.create({
            "user_id": user_id,
            "name": data.name,
            "account_type": data.account_type,
            "institution_name": data.institution_name,
            "currency": data.currency,
            "opening_balance": data.opening_balance,
            "current_balance": data.opening_balance,  # starts at opening balance
            "color": data.color,
        })
        return AccountResponse.model_validate(account)

    async def get(self, account_id: UUID, user_id: UUID) -> AccountResponse:
        account = await self.repo.get_by_user(account_id, user_id)
        if not account:
            raise NotFoundError("Account")
        return AccountResponse.model_validate(account)

    async def list_accounts(self, user_id: UUID) -> list[AccountResponse]:
        accounts = await self.repo.list_active(user_id)
        return [AccountResponse.model_validate(a) for a in accounts]

    async def update(
        self, account_id: UUID, user_id: UUID, data: AccountUpdate
    ) -> AccountResponse:
        account = await self.repo.get_by_user(account_id, user_id)
        if not account:
            raise NotFoundError("Account")
        updates = data.model_dump(exclude_none=True)
        account = await self.repo.update(account, updates)
        return AccountResponse.model_validate(account)

    async def delete(self, account_id: UUID, user_id: UUID) -> None:
        account = await self.repo.get_by_user(account_id, user_id)
        if not account:
            raise NotFoundError("Account")
        # Soft delete: archive
        await self.repo.update(account, {"is_active": False})

    async def apply_transaction_to_balance(
        self,
        account_id: UUID,
        amount: Decimal,
        transaction_type: str,
        reverse: bool = False,
    ) -> None:
        """Update account balance when a transaction is created, updated, or deleted."""
        if transaction_type == "income":
            delta = -amount if reverse else amount
        elif transaction_type == "expense":
            delta = amount if reverse else -amount
        else:  # transfer handled separately
            return
        await self.repo.update_balance(account_id, delta)

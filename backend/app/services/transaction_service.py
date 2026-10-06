from decimal import Decimal
from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AuthorizationError, NotFoundError
from app.db.repositories.account_repository import AccountRepository
from app.db.repositories.transaction_repository import TransactionRepository
from app.models.transfer import Transfer
from app.schemas.transaction import (
    TransactionCreate,
    TransactionFilter,
    TransactionResponse,
    TransactionUpdate,
    TransferCreate,
)


class TransactionService:
    def __init__(self, db: AsyncSession):
        self.txn_repo = TransactionRepository(db)
        self.acc_repo = AccountRepository(db)
        self.db = db

    async def create(
        self, user_id: UUID, data: TransactionCreate
    ) -> TransactionResponse:
        # Verify account belongs to user
        account = await self.acc_repo.get_by_user(data.account_id, user_id)
        if not account:
            raise NotFoundError("Account")

        txn = await self.txn_repo.create({
            "user_id": user_id,
            "account_id": data.account_id,
            "category_id": data.category_id,
            "type": data.type,
            "amount": data.amount,
            "currency": data.currency,
            "merchant": data.merchant,
            "description": data.description,
            "transaction_date": data.transaction_date,
            "payment_method": data.payment_method,
            "notes": data.notes,
            "source": "manual",
        })

        # Update account balance
        await self._apply_balance_delta(data.account_id, data.amount, data.type, reverse=False)

        return await self._get_with_category(txn.id, user_id)

    async def create_transfer(
        self, user_id: UUID, data: TransferCreate
    ) -> tuple[TransactionResponse, TransactionResponse]:
        from_account = await self.acc_repo.get_by_user(data.from_account_id, user_id)
        to_account = await self.acc_repo.get_by_user(data.to_account_id, user_id)
        if not from_account or not to_account:
            raise NotFoundError("Account")

        # Create Transfer record
        transfer = Transfer(
            user_id=user_id,
            from_account_id=data.from_account_id,
            to_account_id=data.to_account_id,
            amount=data.amount,
            currency=data.currency,
            description=data.description,
            transfer_date=data.transfer_date,
        )
        self.db.add(transfer)
        await self.db.flush()
        await self.db.refresh(transfer)

        desc = data.description or f"Transfer to {to_account.name}"

        # Expense on source account (marked as transfer)
        from_txn = await self.txn_repo.create({
            "user_id": user_id,
            "account_id": data.from_account_id,
            "type": "transfer",
            "amount": data.amount,
            "currency": data.currency,
            "description": desc,
            "transaction_date": data.transfer_date,
            "source": "manual",
            "transfer_id": transfer.id,
        })
        # Income on dest account (marked as transfer)
        to_txn = await self.txn_repo.create({
            "user_id": user_id,
            "account_id": data.to_account_id,
            "type": "transfer",
            "amount": data.amount,
            "currency": data.currency,
            "description": f"Transfer from {from_account.name}",
            "transaction_date": data.transfer_date,
            "source": "manual",
            "transfer_id": transfer.id,
        })

        # Update balances
        await self.acc_repo.update_balance(data.from_account_id, -data.amount)
        await self.acc_repo.update_balance(data.to_account_id, data.amount)

        return (
            await self._get_with_category(from_txn.id, user_id),
            await self._get_with_category(to_txn.id, user_id),
        )

    async def get(self, txn_id: UUID, user_id: UUID) -> TransactionResponse:
        txn = await self.txn_repo.get_with_category(txn_id, user_id)
        if not txn:
            raise NotFoundError("Transaction")
        return TransactionResponse.model_validate(txn)

    async def list(
        self, user_id: UUID, filters: TransactionFilter
    ) -> tuple[list[TransactionResponse], int]:
        txns, total = await self.txn_repo.list_filtered(user_id, filters)
        return [TransactionResponse.model_validate(t) for t in txns], total

    async def update(
        self, txn_id: UUID, user_id: UUID, data: TransactionUpdate
    ) -> TransactionResponse:
        txn = await self.txn_repo.get_with_category(txn_id, user_id)
        if not txn:
            raise NotFoundError("Transaction")

        # Handle amount change: reverse old balance effect, apply new
        old_amount = txn.amount
        new_amount = data.amount if data.amount is not None else old_amount

        if new_amount != old_amount and txn.type in ("income", "expense"):
            # Reverse old
            await self._apply_balance_delta(txn.account_id, old_amount, txn.type, reverse=True)
            # Apply new
            await self._apply_balance_delta(txn.account_id, new_amount, txn.type, reverse=False)

        updates = data.model_dump(exclude_none=True)
        updated = await self.txn_repo.update(txn, updates)
        return await self._get_with_category(updated.id, user_id)

    async def delete(self, txn_id: UUID, user_id: UUID) -> None:
        txn = await self.txn_repo.get_with_category(txn_id, user_id)
        if not txn:
            raise NotFoundError("Transaction")

        # Reverse balance
        if txn.type in ("income", "expense"):
            await self._apply_balance_delta(txn.account_id, txn.amount, txn.type, reverse=True)

        await self.txn_repo.update(txn, {"is_deleted": True})

    async def _apply_balance_delta(
        self,
        account_id: UUID,
        amount: Decimal,
        txn_type: str,
        reverse: bool,
    ) -> None:
        if txn_type == "income":
            delta = -amount if reverse else amount
        elif txn_type == "expense":
            delta = amount if reverse else -amount
        else:
            return
        await self.acc_repo.update_balance(account_id, delta)

    async def _get_with_category(self, txn_id: UUID, user_id: UUID) -> TransactionResponse:
        txn = await self.txn_repo.get_with_category(txn_id, user_id)
        return TransactionResponse.model_validate(txn)

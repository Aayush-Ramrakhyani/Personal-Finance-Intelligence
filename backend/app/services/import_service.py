"""CSV import pipeline - parse, normalize, deduplicate, stage, confirm."""
import io
import os
import re
import uuid
from datetime import date, datetime
from decimal import Decimal, InvalidOperation
from typing import Optional
from uuid import UUID

import chardet
import pandas as pd
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import FileValidationError, ImportProcessingError
from app.core.logging import get_logger
from app.db.repositories.transaction_repository import TransactionRepository
from app.models.import_job import ImportJob
from app.models.import_transaction import ImportTransaction
from app.schemas.import_job import (
    ColumnMappingRequest,
    DetectedColumns,
    ImportJobResponse,
    ImportPreviewResponse,
    StagedTransactionPreview,
)

logger = get_logger(__name__)

DATE_FORMATS = [
    "%d/%m/%Y", "%m/%d/%Y", "%Y-%m-%d", "%d-%m-%Y",
    "%d-%b-%Y", "%b %d, %Y", "%Y/%m/%d", "%d.%m.%Y",
    "%d %b %Y", "%d %B %Y",
]

COLUMN_PATTERNS = {
    "date": [r"date", r"txn\s*date", r"transaction\s*date", r"value\s*date", r"post\s*date"],
    "description": [r"description", r"narration", r"particulars", r"remarks", r"details", r"memo"],
    "amount": [r"^amount$", r"txn\s*amount", r"transaction\s*amount"],
    "debit": [r"debit", r"withdrawal", r"dr\.?", r"debit\s*amount"],
    "credit": [r"credit", r"deposit", r"cr\.?", r"credit\s*amount"],
    "reference": [r"reference", r"ref\s*no", r"cheque\s*no", r"transaction\s*id", r"utr"],
    "merchant": [r"merchant", r"beneficiary", r"payee", r"vendor"],
    "balance": [r"balance", r"closing\s*balance", r"available\s*balance"],
}


class ImportService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.txn_repo = TransactionRepository(db)

    async def create_import_job(
        self, user_id: UUID, file_path: str, filename: str
    ) -> ImportJobResponse:
        import sqlalchemy as sa
        job = ImportJob(
            user_id=user_id,
            filename=filename,
            file_path=file_path,
            status="pending",
        )
        self.db.add(job)
        await self.db.flush()
        await self.db.refresh(job)
        return ImportJobResponse.model_validate(job)

    async def detect_columns(self, file_path: str) -> DetectedColumns:
        df = self._read_csv(file_path)
        columns = list(df.columns)
        suggested = {}
        for field, patterns in COLUMN_PATTERNS.items():
            for col in columns:
                for pattern in patterns:
                    if re.search(pattern, col, re.IGNORECASE):
                        suggested[field] = col
                        break
                if field in suggested:
                    break

        sample_rows = df.head(3).fillna("").to_dict(orient="records")
        return DetectedColumns(
            columns=columns, suggested_mapping=suggested, sample_rows=sample_rows
        )

    async def preview_import(
        self,
        job_id: UUID,
        mapping: ColumnMappingRequest,
        user_id: UUID,
    ) -> ImportPreviewResponse:
        import sqlalchemy as sa

        # Get job
        result = await self.db.execute(
            sa.select(ImportJob).where(
                ImportJob.id == job_id, ImportJob.user_id == user_id
            )
        )
        job = result.scalar_one_or_none()
        if not job:
            from app.core.exceptions import NotFoundError
            raise NotFoundError("Import job")

        # Delete previous staged transactions for this job
        await self.db.execute(
            sa.delete(ImportTransaction).where(ImportTransaction.import_job_id == job_id)
        )

        df = self._read_csv(job.file_path)
        staged: list[ImportTransaction] = []
        error_count = 0

        for idx, row in df.iterrows():
            try:
                staged_txn = await self._parse_row(
                    row=row,
                    mapping=mapping,
                    job_id=job_id,
                    user_id=user_id,
                    row_number=int(idx) + 1,
                )
                if staged_txn:
                    # Check for duplicates
                    dup = await self.txn_repo.check_duplicate(
                        user_id=user_id,
                        account_id=mapping.account_id,
                        amount=staged_txn.amount,
                        txn_date=staged_txn.transaction_date,
                        external_ref=staged_txn.external_reference,
                        description=staged_txn.description,
                    )
                    if dup:
                        staged_txn.is_duplicate = True
                        staged_txn.duplicate_confidence = Decimal(str(dup["confidence"]))

                    self.db.add(staged_txn)
                    staged.append(staged_txn)
            except Exception as e:
                error_count += 1
                logger.warning("row_parse_error", row=idx, error=str(e))

        await self.db.flush()

        # Update job
        await self.db.execute(
            sa.update(ImportJob)
            .where(ImportJob.id == job_id)
            .values(
                status="preview_ready",
                total_rows=len(df),
                processed_rows=len(staged),
                duplicate_rows=sum(1 for s in staged if s.is_duplicate),
                failed_rows=error_count,
                column_mapping=mapping.model_dump(mode="json"),
            )
        )

        for s in staged:
            await self.db.refresh(s)

        previews = [
            StagedTransactionPreview(
                id=s.id,
                row_number=s.row_number,
                type=s.type,
                amount=s.amount,
                merchant=s.merchant,
                description=s.description,
                transaction_date=s.transaction_date,
                external_reference=s.external_reference,
                is_duplicate=s.is_duplicate,
                duplicate_confidence=s.duplicate_confidence,
                suggested_category_name=None,
                category_confidence=s.category_confidence,
                parse_error=s.parse_error,
                status=s.status,
            )
            for s in staged
        ]

        return ImportPreviewResponse(
            job_id=job_id,
            total_rows=len(df),
            valid_rows=len([s for s in staged if not s.parse_error]),
            duplicate_rows=sum(1 for s in staged if s.is_duplicate),
            error_rows=error_count,
            transactions=previews,
        )

    async def confirm_import(
        self,
        job_id: UUID,
        user_id: UUID,
        exclude_ids: list[UUID],
    ) -> dict:
        import sqlalchemy as sa
        from app.db.repositories.account_repository import AccountRepository

        result = await self.db.execute(
            sa.select(ImportJob).where(
                ImportJob.id == job_id, ImportJob.user_id == user_id
            )
        )
        job = result.scalar_one_or_none()
        if not job:
            from app.core.exceptions import NotFoundError
            raise NotFoundError("Import job")

        mapping = job.column_mapping or {}
        account_id = UUID(str(mapping.get("account_id"))) if mapping.get("account_id") else None

        # Get staged transactions to import
        stmt = sa.select(ImportTransaction).where(
            ImportTransaction.import_job_id == job_id,
            ImportTransaction.user_id == user_id,
            ImportTransaction.is_duplicate == False,
            ImportTransaction.parse_error == None,
        )
        if exclude_ids:
            stmt = stmt.where(ImportTransaction.id.notin_(exclude_ids))

        staged_result = await self.db.execute(stmt)
        staged = staged_result.scalars().all()

        from app.models.transaction import Transaction
        from app.db.repositories.account_repository import AccountRepository

        acc_repo = AccountRepository(self.db)
        imported = 0
        balance_delta: dict[UUID, Decimal] = {}

        for s in staged:
            txn = Transaction(
                user_id=user_id,
                account_id=account_id or s.account_id,
                category_id=s.suggested_category_id,
                type=s.type,
                amount=s.amount,
                currency=s.currency,
                merchant=s.merchant,
                description=s.description,
                transaction_date=s.transaction_date,
                external_reference=s.external_reference,
                source="csv_import",
                category_source=s.category_source,
                category_confidence=s.category_confidence,
                is_deleted=False,
            )
            self.db.add(txn)

            # Track balance changes
            acc = account_id or s.account_id
            if acc:
                if s.type == "income":
                    balance_delta[acc] = balance_delta.get(acc, Decimal("0")) + s.amount
                elif s.type == "expense":
                    balance_delta[acc] = balance_delta.get(acc, Decimal("0")) - s.amount
            imported += 1

        # Apply balance changes
        for acc_id, delta in balance_delta.items():
            await acc_repo.update_balance(acc_id, delta)

        await self.db.flush()

        # Update job status
        await self.db.execute(
            sa.update(ImportJob)
            .where(ImportJob.id == job_id)
            .values(
                status="completed",
                imported_rows=imported,
                completed_at=datetime.utcnow(),
            )
        )

        return {
            "imported": imported,
            "duplicates_skipped": sum(1 for s in staged if s.is_duplicate),
            "excluded": len(exclude_ids),
        }

    def _read_csv(self, file_path: str) -> pd.DataFrame:
        # Detect encoding
        with open(file_path, "rb") as f:
            raw = f.read()
        detected = chardet.detect(raw)
        encoding = detected.get("encoding") or "utf-8"
        try:
            df = pd.read_csv(file_path, encoding=encoding, skip_blank_lines=True)
        except Exception:
            df = pd.read_csv(file_path, encoding="latin-1", skip_blank_lines=True)
        # Strip column names
        df.columns = [str(c).strip() for c in df.columns]
        return df.dropna(how="all")

    async def _parse_row(
        self,
        row: pd.Series,
        mapping: ColumnMappingRequest,
        job_id: UUID,
        user_id: UUID,
        row_number: int,
    ) -> Optional[ImportTransaction]:
        def get_col(col_name: Optional[str]) -> Optional[str]:
            if not col_name:
                return None
            val = row.get(col_name)
            if pd.isna(val):
                return None
            return str(val).strip()

        raw_date = get_col(mapping.date_column)
        if not raw_date:
            return None

        try:
            txn_date = self._parse_date(raw_date, mapping.date_format)
        except Exception:
            return ImportTransaction(
                import_job_id=job_id,
                user_id=user_id,
                account_id=mapping.account_id,
                type="expense",
                amount=Decimal("0"),
                currency=mapping.default_currency,
                transaction_date=date.today(),
                raw_data=row.to_dict(),
                row_number=row_number,
                parse_error=f"Could not parse date: {raw_date}",
                status="error",
            )

        # Parse amount
        try:
            if mapping.debit_column and mapping.credit_column:
                debit_str = get_col(mapping.debit_column)
                credit_str = get_col(mapping.credit_column)
                debit = self._parse_amount(debit_str) if debit_str else Decimal("0")
                credit = self._parse_amount(credit_str) if credit_str else Decimal("0")
                if debit > 0:
                    txn_type = "expense"
                    amount = debit
                elif credit > 0:
                    txn_type = "income"
                    amount = credit
                else:
                    return None
            elif mapping.amount_column:
                raw_amt = get_col(mapping.amount_column)
                if not raw_amt:
                    return None
                amount = self._parse_amount(raw_amt)
                txn_type = "expense" if amount < 0 else "income"
                amount = abs(amount)
            else:
                return None
        except Exception as e:
            return ImportTransaction(
                import_job_id=job_id,
                user_id=user_id,
                account_id=mapping.account_id,
                type="expense",
                amount=Decimal("0"),
                currency=mapping.default_currency,
                transaction_date=txn_date,
                raw_data=row.to_dict(),
                row_number=row_number,
                parse_error=f"Could not parse amount: {str(e)}",
                status="error",
            )

        if amount == 0:
            return None

        description = get_col(mapping.description_column) or ""
        merchant_raw = get_col(mapping.merchant_column) or description
        from app.ai.merchant_normalizer import normalize_merchant
        merchant = normalize_merchant(merchant_raw)

        ref = get_col(mapping.reference_column)

        return ImportTransaction(
            import_job_id=job_id,
            user_id=user_id,
            account_id=mapping.account_id,
            type=txn_type,
            amount=amount,
            currency=mapping.default_currency,
            merchant=merchant,
            description=description[:500] if description else None,
            transaction_date=txn_date,
            external_reference=ref[:200] if ref else None,
            raw_data={},
            row_number=row_number,
            status="pending",
        )

    def _parse_amount(self, value: str) -> Decimal:
        if not value:
            raise ValueError("Empty amount")
        cleaned = re.sub(r"[₹$€£,\s]", "", str(value).strip())
        try:
            return Decimal(cleaned)
        except InvalidOperation:
            raise ValueError(f"Cannot parse amount: {value}")

    def _parse_date(self, value: str, fmt: Optional[str] = None) -> date:
        value = str(value).strip()
        if fmt:
            try:
                return datetime.strptime(value, fmt).date()
            except ValueError:
                pass
        for fmt in DATE_FORMATS:
            try:
                return datetime.strptime(value, fmt).date()
            except ValueError:
                continue
        # Try pandas
        try:
            return pd.to_datetime(value).date()
        except Exception:
            raise ValueError(f"Cannot parse date: {value}")

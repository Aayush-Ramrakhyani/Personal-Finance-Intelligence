import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel


class ColumnMappingRequest(BaseModel):
    date_column: str
    amount_column: Optional[str] = None
    debit_column: Optional[str] = None
    credit_column: Optional[str] = None
    description_column: Optional[str] = None
    merchant_column: Optional[str] = None
    reference_column: Optional[str] = None
    type_column: Optional[str] = None
    account_id: uuid.UUID
    date_format: Optional[str] = None  # e.g. "%d/%m/%Y"
    default_currency: str = "INR"


class StagedTransactionPreview(BaseModel):
    id: uuid.UUID
    row_number: int
    type: str
    amount: Decimal
    merchant: Optional[str]
    description: Optional[str]
    transaction_date: date
    external_reference: Optional[str]
    is_duplicate: bool
    duplicate_confidence: Decimal
    suggested_category_name: Optional[str]
    category_confidence: Optional[Decimal]
    parse_error: Optional[str]
    status: str

    model_config = {"from_attributes": True}


class ImportPreviewResponse(BaseModel):
    job_id: uuid.UUID
    total_rows: int
    valid_rows: int
    duplicate_rows: int
    error_rows: int
    transactions: list[StagedTransactionPreview]


class ConfirmImportRequest(BaseModel):
    exclude_ids: list[uuid.UUID] = []


class ImportJobResponse(BaseModel):
    id: uuid.UUID
    filename: str
    status: str
    total_rows: int
    processed_rows: int
    imported_rows: int
    duplicate_rows: int
    failed_rows: int
    error_message: Optional[str]
    created_at: datetime
    completed_at: Optional[datetime]

    model_config = {"from_attributes": True}


class DetectedColumns(BaseModel):
    columns: list[str]
    suggested_mapping: dict
    sample_rows: list[dict]

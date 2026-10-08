"""
Tests for ImportService's pure parsing methods.

These cover the most interview-critical business logic:
- Amount parsing across currency formats
- Date parsing across common bank formats
- Column auto-detection from header names
"""
from decimal import Decimal
from unittest.mock import MagicMock

import pytest

from app.services.import_service import ImportService


@pytest.fixture
def svc():
    """ImportService with a dummy db — we only test pure methods here."""
    return ImportService(db=MagicMock())


# ── Amount parsing ──────────────────────────────────────────────────────────

class TestParseAmount:
    def test_plain_integer(self, svc):
        assert svc._parse_amount("500") == Decimal("500")

    def test_decimal(self, svc):
        assert svc._parse_amount("1234.56") == Decimal("1234.56")

    def test_comma_thousands_separator(self, svc):
        assert svc._parse_amount("1,234.56") == Decimal("1234.56")

    def test_rupee_symbol(self, svc):
        assert svc._parse_amount("₹1,500.00") == Decimal("1500.00")

    def test_dollar_symbol(self, svc):
        assert svc._parse_amount("$99.99") == Decimal("99.99")

    def test_euro_symbol(self, svc):
        assert svc._parse_amount("€250") == Decimal("250")

    def test_negative_amount(self, svc):
        assert svc._parse_amount("-750.00") == Decimal("-750.00")

    def test_amount_with_spaces(self, svc):
        assert svc._parse_amount("  500.00  ") == Decimal("500.00")

    def test_zero(self, svc):
        assert svc._parse_amount("0") == Decimal("0")

    def test_large_amount(self, svc):
        assert svc._parse_amount("1,00,000.00") == Decimal("100000.00")

    def test_empty_string_raises(self, svc):
        with pytest.raises(ValueError):
            svc._parse_amount("")

    def test_non_numeric_raises(self, svc):
        with pytest.raises(ValueError):
            svc._parse_amount("N/A")

    def test_text_raises(self, svc):
        with pytest.raises(ValueError):
            svc._parse_amount("ABCD")


# ── Date parsing ────────────────────────────────────────────────────────────

class TestParseDate:
    def test_ddmmyyyy_slash(self, svc):
        from datetime import date
        assert svc._parse_date("15/06/2024") == date(2024, 6, 15)

    def test_yyyymmdd_dash(self, svc):
        from datetime import date
        assert svc._parse_date("2024-06-15") == date(2024, 6, 15)

    def test_ddmmyyyy_dash(self, svc):
        from datetime import date
        assert svc._parse_date("15-06-2024") == date(2024, 6, 15)

    def test_dd_mon_yyyy(self, svc):
        from datetime import date
        assert svc._parse_date("15-Jun-2024") == date(2024, 6, 15)

    def test_dd_space_mon_yyyy(self, svc):
        from datetime import date
        assert svc._parse_date("15 Jun 2024") == date(2024, 6, 15)

    def test_explicit_format_override(self, svc):
        from datetime import date
        # Explicit format takes priority
        assert svc._parse_date("06/15/2024", fmt="%m/%d/%Y") == date(2024, 6, 15)

    def test_invalid_date_raises(self, svc):
        with pytest.raises(ValueError):
            svc._parse_date("not-a-date")

    def test_empty_raises(self, svc):
        with pytest.raises(ValueError):
            svc._parse_date("")


# ── Column auto-detection ───────────────────────────────────────────────────

class TestColumnDetection:
    """
    The column detection regex patterns match common bank CSV headers.
    We test the logic by checking the COLUMN_PATTERNS dict directly.
    """
    def test_date_pattern_matches_txn_date(self):
        import re
        from app.services.import_service import COLUMN_PATTERNS
        patterns = COLUMN_PATTERNS["date"]
        assert any(re.search(p, "Txn Date", re.IGNORECASE) for p in patterns)

    def test_date_pattern_matches_value_date(self):
        import re
        from app.services.import_service import COLUMN_PATTERNS
        patterns = COLUMN_PATTERNS["date"]
        assert any(re.search(p, "Value Date", re.IGNORECASE) for p in patterns)

    def test_description_matches_narration(self):
        import re
        from app.services.import_service import COLUMN_PATTERNS
        patterns = COLUMN_PATTERNS["description"]
        assert any(re.search(p, "Narration", re.IGNORECASE) for p in patterns)

    def test_description_matches_particulars(self):
        import re
        from app.services.import_service import COLUMN_PATTERNS
        patterns = COLUMN_PATTERNS["description"]
        assert any(re.search(p, "Particulars", re.IGNORECASE) for p in patterns)

    def test_debit_matches_withdrawal(self):
        import re
        from app.services.import_service import COLUMN_PATTERNS
        patterns = COLUMN_PATTERNS["debit"]
        assert any(re.search(p, "Withdrawal Amt.", re.IGNORECASE) for p in patterns)

    def test_credit_matches_deposit(self):
        import re
        from app.services.import_service import COLUMN_PATTERNS
        patterns = COLUMN_PATTERNS["credit"]
        assert any(re.search(p, "Deposit Amt.", re.IGNORECASE) for p in patterns)

    def test_reference_matches_utr(self):
        import re
        from app.services.import_service import COLUMN_PATTERNS
        patterns = COLUMN_PATTERNS["reference"]
        assert any(re.search(p, "UTR No", re.IGNORECASE) for p in patterns)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance_intelligence/core/theme/app_theme.dart';

class CurrencyFormatter {
  static final _fullFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _compactFormatter = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static String format(num amount) {
    return _fullFormatter.format(amount);
  }

  static String formatCompact(num amount) {
    if (amount.abs() >= 100000) {
      return _compactFormatter.format(amount);
    }
    return format(amount);
  }

  static String formatSigned(num amount) {
    final formatted = format(amount.abs());
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }

  static Color getAmountColor(num amount) {
    if (amount > 0) return AppTheme.incomeColor;
    if (amount < 0) return AppTheme.expenseColor;
    return AppTheme.textSecondary;
  }

  static Color getTransactionColor(String type) {
    switch (type) {
      case 'income':
        return AppTheme.incomeColor;
      case 'expense':
        return AppTheme.expenseColor;
      case 'transfer':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:personal_finance_intelligence/core/theme/app_theme.dart';
import 'package:personal_finance_intelligence/core/utils/currency_formatter.dart';
import 'package:personal_finance_intelligence/core/utils/date_formatter.dart';
import 'package:personal_finance_intelligence/features/transactions/data/transaction_models.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  IconData get _icon {
    if (transaction.isTransfer) return Icons.swap_horiz;
    if (transaction.type == 'income') return Icons.arrow_downward;
    return Icons.arrow_upward;
  }

  Color get _iconColor {
    if (transaction.isTransfer) return AppTheme.accentColor;
    return CurrencyFormatter.getTransactionColor(transaction.type);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorColor.withOpacity(0.15),
        child: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
      ),
      confirmDismiss: (_) async {
        if (onDelete == null) return false;
        return await _confirmDelete(context);
      },
      onDismissed: (_) => onDelete?.call(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: _iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.displayName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.categoryName ??
                          (transaction.isTransfer ? 'Transfer' : 'Uncategorized'),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatSigned(
                        transaction.type == 'expense'
                            ? -transaction.amount
                            : transaction.amount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _iconColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatRelative(transaction.transactionDate),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('This will also reverse the account balance. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_finance_intelligence/core/theme/app_theme.dart';
import 'package:personal_finance_intelligence/core/utils/currency_formatter.dart';
import 'package:personal_finance_intelligence/core/utils/date_formatter.dart';
import 'package:personal_finance_intelligence/features/transactions/data/transaction_models.dart';
import 'package:personal_finance_intelligence/features/transactions/data/transaction_provider.dart';

final _txDetailProvider =
    FutureProvider.autoDispose.family<Transaction, String>((ref, id) async {
  return ref.read(transactionRepositoryProvider).getById(id);
});

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(_txDetailProvider(transactionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail'),
        actions: [
          txAsync.whenOrNull(
            data: (tx) => IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              onPressed: () => _delete(context, ref, tx.id),
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: txAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (tx) => _DetailBody(tx: tx),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('This reverses the account balance. Continue?'),
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
    if (confirmed == true && context.mounted) {
      await ref.read(transactionListProvider.notifier).deleteTransaction(id);
      if (context.mounted) context.pop();
    }
  }
}

class _DetailBody extends StatelessWidget {
  final Transaction tx;

  const _DetailBody({required this.tx});

  @override
  Widget build(BuildContext context) {
    final color = tx.isTransfer
        ? AppTheme.accentColor
        : CurrencyFormatter.getTransactionColor(tx.type);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tx.isTransfer
                      ? Icons.swap_horiz
                      : tx.type == 'income'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tx.type == 'expense'
                    ? '-${CurrencyFormatter.format(tx.amount)}'
                    : CurrencyFormatter.format(tx.amount),
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              const SizedBox(height: 4),
              Text(tx.displayName,
                  style: const TextStyle(
                      fontSize: 18, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _Row(label: 'Date', value: DateFormatter.format(tx.transactionDate)),
        _Row(label: 'Type', value: tx.type.toUpperCase()),
        if (tx.accountName != null)
          _Row(label: 'Account', value: tx.accountName!),
        if (tx.categoryName != null)
          _Row(label: 'Category', value: tx.categoryName!),
        if (tx.description != null)
          _Row(label: 'Description', value: tx.description!),
        if (tx.referenceNumber != null)
          _Row(label: 'Reference', value: tx.referenceNumber!),
        if (tx.isTransfer)
          _Row(label: 'Transfer ID', value: tx.transferId ?? 'N/A'),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

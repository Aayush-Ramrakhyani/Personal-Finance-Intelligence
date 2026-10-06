import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_intelligence/core/theme/app_theme.dart';
import 'package:personal_finance_intelligence/core/utils/currency_formatter.dart';
import 'package:personal_finance_intelligence/features/accounts/data/account_models.dart';
import 'package:personal_finance_intelligence/features/accounts/data/account_provider.dart';
import 'package:personal_finance_intelligence/shared/widgets/finance_card.dart';

class AccountDetailScreen extends ConsumerWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountDetailProvider(accountId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        actions: [
          accountAsync.whenOrNull(
            data: (account) => PopupMenuButton<String>(
              onSelected: (action) => _handleAction(context, ref, action, account),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'delete',
                  child: const Text('Delete',
                      style: TextStyle(color: AppTheme.errorColor)),
                ),
              ],
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: accountAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (account) => _AccountDetailBody(account: account),
      ),
    );
  }

  void _handleAction(
      BuildContext context, WidgetRef ref, String action, Account account) async {
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete Account'),
          content: Text(
              'Delete "${account.name}"? All transactions will also be deleted.'),
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
        await ref.read(accountRepositoryProvider).delete(account.id);
        ref.invalidate(accountListProvider);
        if (context.mounted) Navigator.pop(context);
      }
    }
  }
}

class _AccountDetailBody extends StatelessWidget {
  final Account account;

  const _AccountDetailBody({required this.account});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, Color(0xFF1E2845)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(account.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                account.accountType
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map((w) => w[0].toUpperCase() + w.substring(1))
                    .join(' '),
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              const Text('Current Balance',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(account.currentBalance),
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FinanceCard(
          child: Column(
            children: [
              _Row(label: 'Opening Balance',
                  value: CurrencyFormatter.format(account.openingBalance)),
              const Divider(),
              _Row(label: 'Currency', value: account.currency),
              if (account.bankName != null) ...[
                const Divider(),
                _Row(label: 'Bank', value: account.bankName!),
              ],
              if (account.lastFour != null) ...[
                const Divider(),
                _Row(label: 'Last 4 digits', value: '****${account.lastFour}'),
              ],
              const Divider(),
              _Row(
                label: 'Status',
                value: account.isActive ? 'Active' : 'Inactive',
                valueColor: account.isActive
                    ? AppTheme.incomeColor
                    : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

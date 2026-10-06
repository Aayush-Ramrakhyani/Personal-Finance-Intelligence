import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_finance_intelligence/core/theme/app_theme.dart';
import 'package:personal_finance_intelligence/core/utils/currency_formatter.dart';
import 'package:personal_finance_intelligence/features/accounts/data/account_models.dart';
import 'package:personal_finance_intelligence/features/accounts/data/account_provider.dart';
import 'package:personal_finance_intelligence/features/accounts/data/account_repository.dart';
import 'package:personal_finance_intelligence/shared/widgets/empty_state_widget.dart';
import 'package:personal_finance_intelligence/shared/widgets/finance_card.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccount(context, ref),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
      body: accountsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (accounts) {
          if (accounts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.account_balance_outlined,
              title: 'No accounts yet',
              message: 'Add your bank accounts, credit cards, and wallets.',
              actionLabel: 'Add Account',
              onAction: () => _showAddAccount(context, ref),
            );
          }

          final totalBalance =
              accounts.fold(0.0, (sum, a) => sum + a.currentBalance);

          return RefreshIndicator(
            color: AppTheme.accentColor,
            onRefresh: () async => ref.invalidate(accountListProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Total balance header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, Color(0xFF1E2845)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Net Worth',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(totalBalance),
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${accounts.length} account${accounts.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...accounts.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AccountCard(account: a),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddAccount(BuildContext context, WidgetRef ref) {
    final repo = ref.read(accountRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddAccountSheet(
        repo: repo,
        onSaved: () => ref.invalidate(accountListProvider),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;

  const _AccountCard({required this.account});

  IconData get _icon {
    switch (account.accountType) {
      case 'bank':
      case 'savings':
        return Icons.account_balance_outlined;
      case 'credit_card':
        return Icons.credit_card_outlined;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'cash':
        return Icons.money_outlined;
      default:
        return Icons.account_circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = account.accountType == 'credit_card';
    final color = isCredit
        ? AppTheme.expenseColor
        : account.currentBalance >= 0
            ? AppTheme.textPrimary
            : AppTheme.errorColor;

    return FinanceCard(
      onTap: () => context.push('/accounts/${account.id}'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: AppTheme.accentColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  account.accountType
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((w) => w[0].toUpperCase() + w.substring(1))
                      .join(' '),
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(account.currentBalance),
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _AddAccountSheet extends StatefulWidget {
  final AccountRepository repo;
  final VoidCallback onSaved;

  const _AddAccountSheet({required this.repo, required this.onSaved});

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  String _type = 'bank';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.repo.create(
        name: _nameCtrl.text.trim(),
        accountType: _type,
        openingBalance:
            double.tryParse(_balanceCtrl.text.replaceAll(',', '')) ?? 0,
        bankName: _bankCtrl.text.trim().isNotEmpty ? _bankCtrl.text.trim() : null,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.errorColor),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Account Type'),
              items: const [
                DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                DropdownMenuItem(value: 'savings', child: Text('Savings Account')),
                DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'wallet', child: Text('Digital Wallet')),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Account Name'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _balanceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Opening Balance (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bankCtrl,
              decoration: const InputDecoration(
                  labelText: 'Bank Name (optional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Add Account'),
            ),
          ],
        ),
      ),
    );
  }
}

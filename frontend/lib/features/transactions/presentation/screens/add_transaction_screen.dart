import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_finance_intelligence/core/theme/app_theme.dart';
import 'package:personal_finance_intelligence/features/accounts/data/account_provider.dart';
import 'package:personal_finance_intelligence/features/transactions/data/transaction_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? initialType;

  const AddTransactionScreen({super.key, this.initialType});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  String? _accountId;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'expense';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _merchantCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      setState(() => _error = 'Please select an account');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(transactionRepositoryProvider).create(
        accountId: _accountId!,
        type: _type,
        amount: double.parse(_amountCtrl.text.replaceAll(',', '')),
        date: _date,
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        merchant: _merchantCtrl.text.trim().isNotEmpty ? _merchantCtrl.text.trim() : null,
      );
      ref.invalidate(accountListProvider);
      if (mounted) {
        ref.read(transactionListProvider.notifier).refresh();
        context.pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type toggle
              Row(
                children: ['expense', 'income'].map((t) {
                  final selected = _type == t;
                  final color = t == 'expense'
                      ? AppTheme.expenseColor
                      : AppTheme.incomeColor;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: Container(
                        margin: EdgeInsets.only(
                            right: t == 'expense' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.15)
                              : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? color : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          t[0].toUpperCase() + t.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? color : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AppTheme.errorColor)),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount is required';
                  final d = double.tryParse(v.replaceAll(',', ''));
                  if (d == null || d <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              accountsAsync.when(
                data: (accounts) => DropdownButtonFormField<String>(
                  value: _accountId,
                  decoration: const InputDecoration(
                    labelText: 'Account',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  items: accounts
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _accountId = v),
                  validator: (v) => v == null ? 'Select an account' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Failed to load accounts'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _merchantCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Merchant (optional)',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    '${_date.day}/${_date.month}/${_date.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

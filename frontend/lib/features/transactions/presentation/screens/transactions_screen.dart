import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_finance_intelligence/core/theme/app_theme.dart';
import 'package:personal_finance_intelligence/core/utils/date_formatter.dart';
import 'package:personal_finance_intelligence/features/transactions/data/transaction_models.dart';
import 'package:personal_finance_intelligence/features/transactions/data/transaction_provider.dart';
import 'package:personal_finance_intelligence/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:personal_finance_intelligence/shared/widgets/empty_state_widget.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(transactionListProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
      body: txState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.accentColor)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(),
                  style: const TextStyle(color: AppTheme.textSecondary)),
              TextButton(
                onPressed: () =>
                    ref.read(transactionListProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (transactions) {
          if (transactions.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              message: 'Add your first transaction to get started.',
              actionLabel: 'Add Transaction',
              onAction: () => context.push('/transactions/add'),
            );
          }
          return RefreshIndicator(
            color: AppTheme.accentColor,
            onRefresh: () =>
                ref.read(transactionListProvider.notifier).refresh(),
            child: _GroupedList(
              transactions: transactions,
              scrollCtrl: _scrollCtrl,
              onDelete: (id) => ref
                  .read(transactionListProvider.notifier)
                  .deleteTransaction(id),
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _GroupedList extends StatelessWidget {
  final List<Transaction> transactions;
  final ScrollController scrollCtrl;
  final void Function(String id) onDelete;

  const _GroupedList({
    required this.transactions,
    required this.scrollCtrl,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(transactions);
    final entries = grouped.entries.toList();

    return ListView.builder(
      controller: scrollCtrl,
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...entry.value.map((tx) => TransactionListItem(
                  transaction: tx,
                  onTap: () => context.push('/transactions/${tx.id}'),
                  onDelete: () => onDelete(tx.id),
                )),
            const Divider(height: 1, indent: 70),
          ],
        );
      },
    );
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> txs) {
    final map = <String, List<Transaction>>{};
    for (final tx in txs) {
      final key = DateFormatter.groupHeader(tx.transactionDate);
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Filter Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Type', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _TypeChip(
                label: 'All',
                selected: filter.type == null,
                onTap: () => ref
                    .read(transactionFilterProvider.notifier)
                    .state = const TransactionFilter(),
              ),
              _TypeChip(
                label: 'Expenses',
                selected: filter.type == 'expense',
                onTap: () => ref
                    .read(transactionFilterProvider.notifier)
                    .state = const TransactionFilter(type: 'expense'),
              ),
              _TypeChip(
                label: 'Income',
                selected: filter.type == 'income',
                onTap: () => ref
                    .read(transactionFilterProvider.notifier)
                    .state = const TransactionFilter(type: 'income'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.accentColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected ? AppTheme.accentColor : AppTheme.textSecondary,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/recurring_provider.dart';
import '../../data/recurring_models.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      final s = amount.toStringAsFixed(0);
      final len = s.length;
      if (len <= 3) return '₹$s';
      return '₹${s.substring(0, len - 3)},${s.substring(len - 3)}';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F36),
        title: const Text(
          'Recurring',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => ref.invalidate(recurringNotifierProvider),
          ),
        ],
      ),
      body: recurringAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C896)),
        ),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(recurringNotifierProvider),
        ),
        data: (items) {
          final confirmed =
              items.where((i) => i.isConfirmed).toList();
          final unconfirmed =
              items.where((i) => i.isUnconfirmed).toList();
          final totalMonthly =
              confirmed.fold(0.0, (s, i) => s + i.monthlyCost);
          final totalAnnual =
              confirmed.fold(0.0, (s, i) => s + i.annualCost);

          if (items.isEmpty) {
            return const _EmptyState();
          }

          return CustomScrollView(
            slivers: [
              // Summary card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _SummaryCard(
                    totalMonthly: totalMonthly,
                    totalAnnual: totalAnnual,
                    confirmedCount: confirmed.length,
                    formatAmount: _formatAmount,
                  ),
                ),
              ),

              // Unconfirmed section
              if (unconfirmed.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.pending_rounded,
                            color: Color(0xFFFFC107), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Needs confirmation',
                          style: TextStyle(
                            color: Color(0xFFFFC107),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecurringCard(
                          item: unconfirmed[i],
                          formatAmount: _formatAmount,
                          onConfirm: () => ref
                              .read(recurringNotifierProvider.notifier)
                              .confirm(unconfirmed[i].id),
                          onReject: () => ref
                              .read(recurringNotifierProvider.notifier)
                              .reject(unconfirmed[i].id),
                        ),
                      ),
                      childCount: unconfirmed.length,
                    ),
                  ),
                ),
              ],

              // Confirmed section
              if (confirmed.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Color(0xFF00C896), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Confirmed recurring',
                          style: TextStyle(
                            color: Color(0xFF00C896),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecurringCard(
                          item: confirmed[i],
                          formatAmount: _formatAmount,
                          onDelete: () => ref
                              .read(recurringNotifierProvider.notifier)
                              .delete(confirmed[i].id),
                        ),
                      ),
                      childCount: confirmed.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary Card
// ---------------------------------------------------------------------------
class _SummaryCard extends StatelessWidget {
  final double totalMonthly;
  final double totalAnnual;
  final int confirmedCount;
  final String Function(double) formatAmount;

  const _SummaryCard({
    required this.totalMonthly,
    required this.totalAnnual,
    required this.confirmedCount,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F36), Color(0xFF252B45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recurring Summary',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatAmount(totalMonthly),
                      style: const TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                  width: 1, height: 40, color: Colors.white12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Annual estimate',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatAmount(totalAnnual),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$confirmedCount confirmed subscriptions/services',
            style: const TextStyle(
                color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recurring Card
// ---------------------------------------------------------------------------
class _RecurringCard extends StatelessWidget {
  final RecurringTransactionModel item;
  final String Function(double) formatAmount;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;

  const _RecurringCard({
    required this.item,
    required this.formatAmount,
    this.onConfirm,
    this.onReject,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUnconfirmed = item.isUnconfirmed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnconfirmed
              ? const Color(0xFFFFC107).withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.repeat_rounded,
                  color: Color(0xFF00C896),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.merchantName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF40C4FF)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF40C4FF)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            item.frequencyLabel,
                            style: const TextStyle(
                              color: Color(0xFF40C4FF),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (item.category != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.category!,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatAmount(item.amount),
                    style: const TextStyle(
                      color: Color(0xFFFF5252),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'per ${item.frequency.name}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white24, size: 18),
                  onPressed: onDelete,
                  padding: const EdgeInsets.only(left: 8),
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Text(
                'Next: ${DateFormat('MMM dd, yyyy').format(item.nextExpectedDate)}',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(width: 12),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: item.confidenceColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${item.confidence.name.capitalize()} confidence',
                style: TextStyle(
                    color: item.confidenceColor, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${formatAmount(item.annualCost)}/yr',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          if (isUnconfirmed) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFFF5252)),
                      foregroundColor: const Color(0xFFFF5252),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Not Recurring',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C896),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Confirm',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.repeat_rounded, color: Colors.white24, size: 56),
          SizedBox(height: 16),
          Text(
            'No recurring transactions detected',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Add more transactions and we\'ll detect\npatterns automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFF5252), size: 48),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C896),
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

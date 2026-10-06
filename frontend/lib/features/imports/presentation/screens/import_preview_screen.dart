import 'package:flutter/material.dart';
import '../../data/import_models.dart';

class ImportPreviewScreen extends StatelessWidget {
  final ImportPreviewModel preview;
  final Set<String> excludedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onConfirm;

  const ImportPreviewScreen({
    super.key,
    required this.preview,
    required this.excludedIds,
    required this.onToggle,
    required this.onConfirm,
  });

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      final s = amount.toStringAsFixed(0);
      final len = s.length;
      if (len <= 3) return '₹$s';
      return '₹${s.substring(0, len - 3)},${s.substring(len - 3)}';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final toImport = preview.transactions
        .where((t) => !excludedIds.contains(t.id) && !t.isDuplicate)
        .length;

    return Column(
      children: [
        // Summary stats bar
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          color: const Color(0xFF1A1F36),
          child: Row(
            children: [
              _StatChip(
                label: 'Total',
                value: '${preview.totalRows}',
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'New',
                value: '$toImport',
                color: const Color(0xFF00C896),
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Dupes',
                value: '${preview.duplicates}',
                color: const Color(0xFFFFC107),
              ),
              if (preview.errors > 0) ...[
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Errors',
                  value: '${preview.errors}',
                  color: const Color(0xFFFF5252),
                ),
              ],
            ],
          ),
        ),

        // Transactions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: preview.transactions.length,
            itemBuilder: (context, index) {
              final tx = preview.transactions[index];
              final isExcluded = excludedIds.contains(tx.id);
              return _TransactionPreviewCard(
                tx: tx,
                isExcluded: isExcluded,
                onToggle: () => onToggle(tx.id),
                formatAmount: _formatAmount,
              );
            },
          ),
        ),

        // Confirm button
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F36),
            border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.06))),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: toImport > 0 ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue with $toImport transactions',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionPreviewCard extends StatelessWidget {
  final StagedTransactionModel tx;
  final bool isExcluded;
  final VoidCallback onToggle;
  final String Function(double) formatAmount;

  const _TransactionPreviewCard({
    required this.tx,
    required this.isExcluded,
    required this.onToggle,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    Color? borderColor;
    if (tx.isDuplicate) {
      borderColor = const Color(0xFFFFC107).withOpacity(0.4);
    } else if (tx.isError) {
      borderColor = const Color(0xFFFF5252).withOpacity(0.4);
    }

    return Opacity(
      opacity: isExcluded || tx.isDuplicate ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F36),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.06),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 4),
          leading: Checkbox(
            value: !isExcluded && !tx.isDuplicate && !tx.isError,
            onChanged:
                tx.isDuplicate || tx.isError ? null : (_) => onToggle(),
            activeColor: const Color(0xFF00C896),
            checkColor: Colors.black,
            side: const BorderSide(color: Colors.white38),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  tx.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tx.isDuplicate)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: const Color(0xFFFFC107).withOpacity(0.4)),
                  ),
                  child: const Text(
                    'Duplicate',
                    style: TextStyle(
                      color: Color(0xFFFFC107),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (tx.isError)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: const Color(0xFFFF5252).withOpacity(0.4)),
                  ),
                  child: const Text(
                    'Error',
                    style: TextStyle(
                      color: Color(0xFFFF5252),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Text(
                tx.date,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11),
              ),
              if (tx.category != null) ...[
                const Text(' • ',
                    style:
                        TextStyle(color: Colors.white24, fontSize: 11)),
                Text(
                  tx.category!,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ],
          ),
          trailing: Text(
            formatAmount(tx.amount),
            style: TextStyle(
              color: tx.isExpense
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF00C896),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

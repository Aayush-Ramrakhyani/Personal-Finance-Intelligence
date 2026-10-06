import 'package:flutter/material.dart';
import 'package:personal_finance_intelligence/core/utils/currency_formatter.dart';

class AmountText extends StatelessWidget {
  final num amount;
  final String? transactionType;
  final TextStyle? style;
  final bool compact;
  final bool showSign;

  const AmountText({
    super.key,
    required this.amount,
    this.transactionType,
    this.style,
    this.compact = false,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = transactionType != null
        ? CurrencyFormatter.getTransactionColor(transactionType!)
        : CurrencyFormatter.getAmountColor(amount);

    final text = compact
        ? CurrencyFormatter.formatCompact(amount)
        : showSign
            ? CurrencyFormatter.formatSigned(amount)
            : CurrencyFormatter.format(amount);

    return Text(
      text,
      style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

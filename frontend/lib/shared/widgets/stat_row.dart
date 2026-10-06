import 'package:flutter/material.dart';

enum TrendDirection { up, down, neutral }

class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final TrendDirection? trend;
  final double? trendPercent;
  final Color? valueColor;
  final bool isLabelBold;
  final bool isValueBold;
  final Widget? trailing;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.trendPercent,
    this.valueColor,
    this.isLabelBold = false,
    this.isValueBold = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight:
                    isLabelBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (trend != null && trendPercent != null) ...[
            _TrendBadge(
              direction: trend!,
              percent: trendPercent!,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? theme.colorScheme.onSurface,
              fontWeight:
                  isValueBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final TrendDirection direction;
  final double percent;

  const _TrendBadge({required this.direction, required this.percent});

  @override
  Widget build(BuildContext context) {
    final isUp = direction == TrendDirection.up;
    final isNeutral = direction == TrendDirection.neutral;
    final color = isNeutral
        ? const Color(0xFF9E9E9E)
        : isUp
            ? const Color(0xFF00C896)
            : const Color(0xFFFF5252);
    final icon = isNeutral
        ? Icons.remove
        : isUp
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '${percent.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A card containing multiple StatRow widgets with a title
class StatCard extends StatelessWidget {
  final String? title;
  final List<Widget> stats;
  final EdgeInsetsGeometry? padding;

  const StatCard({
    super.key,
    this.title,
    required this.stats,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...stats,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

enum AnalyticsPeriod {
  thisMonth,
  lastMonth,
  threeMonths,
  sixMonths,
  year,
}

extension AnalyticsPeriodExt on AnalyticsPeriod {
  String get label {
    switch (this) {
      case AnalyticsPeriod.thisMonth:
        return 'This Month';
      case AnalyticsPeriod.lastMonth:
        return 'Last Month';
      case AnalyticsPeriod.threeMonths:
        return '3 Months';
      case AnalyticsPeriod.sixMonths:
        return '6 Months';
      case AnalyticsPeriod.year:
        return 'Year';
    }
  }

  int get months {
    switch (this) {
      case AnalyticsPeriod.thisMonth:
        return 1;
      case AnalyticsPeriod.lastMonth:
        return 1;
      case AnalyticsPeriod.threeMonths:
        return 3;
      case AnalyticsPeriod.sixMonths:
        return 6;
      case AnalyticsPeriod.year:
        return 12;
    }
  }

  DateTimeRange get dateRange {
    final now = DateTime.now();
    switch (this) {
      case AnalyticsPeriod.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case AnalyticsPeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return DateTimeRange(
          start: lastMonth,
          end: DateTime(lastMonth.year, lastMonth.month + 1, 0),
        );
      case AnalyticsPeriod.threeMonths:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case AnalyticsPeriod.sixMonths:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 5, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case AnalyticsPeriod.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
    }
  }
}

class PeriodSelector extends StatelessWidget {
  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onChanged;
  final List<AnalyticsPeriod> periods;

  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.periods = AnalyticsPeriod.values,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: periods.map((period) {
          final isSelected = period == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ChoiceChip(
                label: Text(
                  period.label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.black
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onChanged(period),
                selectedColor: const Color(0xFF00C896),
                backgroundColor:
                    Theme.of(context).colorScheme.surface,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF00C896)
                      : Theme.of(context).dividerColor,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                showCheckmark: false,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

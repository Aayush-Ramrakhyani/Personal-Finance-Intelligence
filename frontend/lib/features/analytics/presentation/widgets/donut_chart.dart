import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/analytics_models.dart';

class DonutChart extends StatefulWidget {
  final List<CategoryAnalyticsModel> categories;
  final String Function(double) formatAmount;

  const DonutChart({
    super.key,
    required this.categories,
    required this.formatAmount,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int _touchedIndex = -1;

  static const List<Color> _colors = [
    Color(0xFF00C896),
    Color(0xFF40C4FF),
    Color(0xFFFF7043),
    Color(0xFFAB47BC),
    Color(0xFFFFCA28),
    Color(0xFF66BB6A),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF78909C),
    Color(0xFF26C6DA),
  ];

  Color _colorAt(int index) => _colors[index % _colors.length];

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const Center(
        child: Text(
          'No data for this period',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback:
                        (FlTouchEvent event, PieTouchResponse? response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        setState(() => _touchedIndex = -1);
                        return;
                      }
                      setState(() => _touchedIndex =
                          response.touchedSection!.touchedSectionIndex);
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 70,
                  sections:
                      widget.categories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final cat = entry.value;
                    final isTouched = index == _touchedIndex;
                    return PieChartSectionData(
                      color: _colorAt(index),
                      value: cat.amount,
                      title: isTouched
                          ? '${cat.percentage.toStringAsFixed(1)}%'
                          : '',
                      radius: isTouched ? 30 : 24,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Center label
              if (_touchedIndex >= 0 &&
                  _touchedIndex < widget.categories.length)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.categories[_touchedIndex].category,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.formatAmount(
                          widget.categories[_touchedIndex].amount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total Spent',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.formatAmount(
                        widget.categories
                            .fold(0.0, (s, c) => s + c.amount),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children:
              widget.categories.asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value;
            return _LegendItem(
              color: _colorAt(index),
              label: cat.category,
              value: widget.formatAmount(cat.amount),
              isHighlighted: index == _touchedIndex,
              onTap: () => setState(() => _touchedIndex =
                  _touchedIndex == index ? -1 : index),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlighted
              ? color.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isHighlighted
              ? Border.all(color: color.withOpacity(0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$label • $value',
              style: TextStyle(
                color: isHighlighted ? color : Colors.white54,
                fontSize: 12,
                fontWeight: isHighlighted
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

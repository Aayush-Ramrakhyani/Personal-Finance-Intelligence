import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/analytics_models.dart';

class TrendChart extends StatelessWidget {
  final List<CashFlowModel> cashFlow;
  final String Function(double) formatAmount;

  const TrendChart({
    super.key,
    required this.cashFlow,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (cashFlow.isEmpty) {
      return const Center(
        child: Text(
          'No trend data available',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final maxY = cashFlow
        .expand((c) => [c.income, c.expense])
        .fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _LegendDot(
                color: const Color(0xFF00C896), label: 'Income'),
            const SizedBox(width: 16),
            _LegendDot(
                color: const Color(0xFFFF5252), label: 'Expense'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox();
                      return Text(
                        _compact(value),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= cashFlow.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          cashFlow[index].monthLabel.substring(0, 3),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (cashFlow.length - 1).toDouble(),
              minY: 0,
              maxY: maxY * 1.15,
              lineBarsData: [
                // Income line
                LineChartBarData(
                  spots: cashFlow
                      .asMap()
                      .entries
                      .map((e) => FlSpot(
                            e.key.toDouble(),
                            e.value.income,
                          ))
                      .toList(),
                  isCurved: true,
                  color: const Color(0xFF00C896),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFF00C896),
                      strokeWidth: 2,
                      strokeColor: const Color(0xFF0D1117),
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color:
                        const Color(0xFF00C896).withOpacity(0.08),
                  ),
                ),
                // Expense line
                LineChartBarData(
                  spots: cashFlow
                      .asMap()
                      .entries
                      .map((e) => FlSpot(
                            e.key.toDouble(),
                            e.value.expense,
                          ))
                      .toList(),
                  isCurved: true,
                  color: const Color(0xFFFF5252),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFFFF5252),
                      strokeWidth: 2,
                      strokeColor: const Color(0xFF0D1117),
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color:
                        const Color(0xFFFF5252).withOpacity(0.08),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF252B45),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isIncome = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${isIncome ? "Income" : "Expense"}\n${formatAmount(spot.y)}',
                        TextStyle(
                          color: isIncome
                              ? const Color(0xFF00C896)
                              : const Color(0xFFFF5252),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _compact(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(0)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style:
              const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

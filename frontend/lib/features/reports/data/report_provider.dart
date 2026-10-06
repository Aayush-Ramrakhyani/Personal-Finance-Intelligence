import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'report_models.dart';
import 'report_repository.dart';

final _reportDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(_reportDioProvider));
});

/// Selected month/year for reports
class ReportPeriod {
  final int year;
  final int month;

  const ReportPeriod({required this.year, required this.month});

  ReportPeriod copyWith({int? year, int? month}) {
    return ReportPeriod(
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}

final selectedReportPeriodProvider =
    StateProvider<ReportPeriod>((ref) {
  final now = DateTime.now();
  return ReportPeriod(year: now.year, month: now.month);
});

final monthlyReportProvider =
    FutureProvider.autoDispose<MonthlyReportModel>((ref) async {
  final period = ref.watch(selectedReportPeriodProvider);
  return ref
      .watch(reportRepositoryProvider)
      .getMonthlyReport(period.year, period.month);
});

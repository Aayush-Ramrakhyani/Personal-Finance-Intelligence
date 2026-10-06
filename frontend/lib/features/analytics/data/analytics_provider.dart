import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'analytics_models.dart';
import 'analytics_repository.dart';
import '../../../../shared/widgets/period_selector.dart';

// ---------------------------------------------------------------------------
// Repository provider (reuse Dio from budget_provider or redeclare locally)
// ---------------------------------------------------------------------------

final _analyticsDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
});

final analyticsRepositoryProvider =
    Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(_analyticsDioProvider));
});

// ---------------------------------------------------------------------------
// Selected period state
// ---------------------------------------------------------------------------

final selectedPeriodProvider =
    StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.thisMonth);

// ---------------------------------------------------------------------------
// Overview
// ---------------------------------------------------------------------------

final overviewProvider =
    FutureProvider.autoDispose<OverviewModel>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = period.dateRange;
  return repo.getOverview(range.start, range.end);
});

// ---------------------------------------------------------------------------
// Category breakdown
// ---------------------------------------------------------------------------

final categoryBreakdownProvider =
    FutureProvider.autoDispose<List<CategoryAnalyticsModel>>(
        (ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = period.dateRange;
  return repo.getCategoryBreakdown(range.start, range.end);
});

// ---------------------------------------------------------------------------
// Cash flow
// ---------------------------------------------------------------------------

final cashFlowProvider =
    FutureProvider.autoDispose<List<CashFlowModel>>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getCashFlow(period.months);
});

// ---------------------------------------------------------------------------
// Trends
// ---------------------------------------------------------------------------

final trendsProvider =
    FutureProvider.autoDispose<TrendsModel>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getTrends(period.months);
});

// ---------------------------------------------------------------------------
// Month comparison
// ---------------------------------------------------------------------------

final monthComparisonProvider =
    FutureProvider.autoDispose<List<MonthComparisonModel>>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getMonthComparison(period.months);
});

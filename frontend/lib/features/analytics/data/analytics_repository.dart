import 'package:dio/dio.dart';
import 'analytics_models.dart';

class AnalyticsRepository {
  final Dio _dio;

  AnalyticsRepository(this._dio);

  Future<OverviewModel> getOverview(
      DateTime? start, DateTime? end) async {
    final params = <String, dynamic>{};
    if (start != null) params['start'] = start.toIso8601String();
    if (end != null) params['end'] = end.toIso8601String();
    final response = await _dio.get(
      '/analytics/overview',
      queryParameters: params,
    );
    return OverviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CategoryAnalyticsModel>> getCategoryBreakdown(
      DateTime start, DateTime end) async {
    final response = await _dio.get(
      '/analytics/categories',
      queryParameters: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) =>
            CategoryAnalyticsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CashFlowModel>> getCashFlow(int months) async {
    final response = await _dio.get(
      '/analytics/cashflow',
      queryParameters: {'months': months},
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => CashFlowModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TrendsModel> getTrends(int months) async {
    final response = await _dio.get(
      '/analytics/trends',
      queryParameters: {'months': months},
    );
    return TrendsModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MonthComparisonModel>> getMonthComparison(
      int months) async {
    final response = await _dio.get(
      '/analytics/comparison',
      queryParameters: {'months': months},
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) =>
            MonthComparisonModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

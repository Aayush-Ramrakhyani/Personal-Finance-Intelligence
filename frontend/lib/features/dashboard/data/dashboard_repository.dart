import 'package:personal_finance_intelligence/core/network/api_client.dart';
import 'package:personal_finance_intelligence/features/dashboard/data/dashboard_models.dart';

class DashboardRepository {
  final ApiClient _api;

  DashboardRepository(this._api);

  Future<OverviewData> getOverview({String period = 'month'}) async {
    final res = await _api.get('/analytics/overview', params: {'period': period});
    return OverviewData.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<List<CashFlowMonth>> getCashFlow({int months = 6}) async {
    final res = await _api.get('/analytics/cash-flow', params: {'months': months});
    final list = res['data'] as List<dynamic>;
    return list.map((e) => CashFlowMonth.fromJson(e as Map<String, dynamic>)).toList();
  }
}

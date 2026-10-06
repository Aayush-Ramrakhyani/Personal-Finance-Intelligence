import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_intelligence/core/network/api_client.dart';
import 'package:personal_finance_intelligence/features/dashboard/data/dashboard_models.dart';
import 'package:personal_finance_intelligence/features/dashboard/data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.read(apiClientProvider)),
);

final overviewProvider = FutureProvider.autoDispose<OverviewData>((ref) async {
  return ref.read(dashboardRepositoryProvider).getOverview();
});

final cashFlowProvider = FutureProvider.autoDispose<List<CashFlowMonth>>((ref) async {
  return ref.read(dashboardRepositoryProvider).getCashFlow();
});

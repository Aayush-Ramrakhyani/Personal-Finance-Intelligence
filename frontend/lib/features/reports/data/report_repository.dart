import 'package:dio/dio.dart';
import 'report_models.dart';

class ReportRepository {
  final Dio _dio;

  ReportRepository(this._dio);

  Future<MonthlyReportModel> getMonthlyReport(
      int year, int month) async {
    final response = await _dio.get(
      '/reports/monthly',
      queryParameters: {'year': year, 'month': month},
    );
    return MonthlyReportModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<String> downloadReport(int year, int month) async {
    // Returns a download URL
    final response = await _dio.get(
      '/reports/monthly/download',
      queryParameters: {'year': year, 'month': month},
    );
    return response.data['url'] as String;
  }
}

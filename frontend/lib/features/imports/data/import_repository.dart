import 'dart:io';
import 'package:dio/dio.dart';
import 'import_models.dart';

class ImportRepository {
  final Dio _dio;

  ImportRepository(this._dio);

  Future<ImportJobModel> uploadCSV(
      String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });
    final response = await _dio.post(
      '/imports/upload',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );
    return ImportJobModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<ImportPreviewModel> getPreview(
      String jobId, Map<String, String> columnMapping) async {
    final response = await _dio.post(
      '/imports/$jobId/preview',
      data: {'column_mapping': columnMapping},
    );
    return ImportPreviewModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<ImportResultModel> confirmImport(
      String jobId, List<String> excludeIds) async {
    final response = await _dio.post(
      '/imports/$jobId/confirm',
      data: {'exclude_ids': excludeIds},
    );
    return ImportResultModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<ImportJobModel> getImportJob(String jobId) async {
    final response = await _dio.get('/imports/$jobId');
    return ImportJobModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<ImportJobModel>> getImportHistory() async {
    final response = await _dio.get('/imports');
    final data = response.data as List<dynamic>;
    return data
        .map((e) =>
            ImportJobModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

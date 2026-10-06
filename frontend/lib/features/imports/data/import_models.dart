enum ImportJobStatus {
  pending,
  processing,
  awaitingMapping,
  awaitingConfirmation,
  importing,
  completed,
  failed,
}

class ImportJobModel {
  final String id;
  final String userId;
  final String fileName;
  final ImportJobStatus status;
  final String? errorMessage;
  final int? totalRows;
  final int? processedRows;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? detectedColumns;

  const ImportJobModel({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.status,
    this.errorMessage,
    this.totalRows,
    this.processedRows,
    required this.createdAt,
    required this.updatedAt,
    this.detectedColumns,
  });

  factory ImportJobModel.fromJson(Map<String, dynamic> json) {
    return ImportJobModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fileName: json['file_name'] as String,
      status: _parseStatus(json['status'] as String),
      errorMessage: json['error_message'] as String?,
      totalRows: json['total_rows'] as int?,
      processedRows: json['processed_rows'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      detectedColumns: (json['detected_columns'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  static ImportJobStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return ImportJobStatus.pending;
      case 'processing':
        return ImportJobStatus.processing;
      case 'awaiting_mapping':
        return ImportJobStatus.awaitingMapping;
      case 'awaiting_confirmation':
        return ImportJobStatus.awaitingConfirmation;
      case 'importing':
        return ImportJobStatus.importing;
      case 'completed':
        return ImportJobStatus.completed;
      case 'failed':
        return ImportJobStatus.failed;
      default:
        return ImportJobStatus.pending;
    }
  }

  double get progressPercent {
    if (totalRows == null || totalRows == 0) return 0.0;
    return (processedRows ?? 0) / totalRows! * 100;
  }
}

class ImportPreviewModel {
  final String jobId;
  final int totalRows;
  final int newTransactions;
  final int duplicates;
  final int errors;
  final List<StagedTransactionModel> transactions;

  const ImportPreviewModel({
    required this.jobId,
    required this.totalRows,
    required this.newTransactions,
    required this.duplicates,
    required this.errors,
    required this.transactions,
  });

  factory ImportPreviewModel.fromJson(Map<String, dynamic> json) {
    return ImportPreviewModel(
      jobId: json['job_id'] as String,
      totalRows: json['total_rows'] as int,
      newTransactions: json['new_transactions'] as int,
      duplicates: json['duplicates'] as int,
      errors: json['errors'] as int,
      transactions: (json['transactions'] as List<dynamic>)
          .map((e) =>
              StagedTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

enum StagedTransactionStatus { new_, duplicate, error }

class StagedTransactionModel {
  final String id;
  final String date;
  final String description;
  final double amount;
  final String type; // income or expense
  final String? category;
  final StagedTransactionStatus status;
  final String? errorMessage;
  final bool selected;

  const StagedTransactionModel({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    this.category,
    required this.status,
    this.errorMessage,
    this.selected = true,
  });

  factory StagedTransactionModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'new';
    StagedTransactionStatus status;
    switch (statusStr) {
      case 'duplicate':
        status = StagedTransactionStatus.duplicate;
        break;
      case 'error':
        status = StagedTransactionStatus.error;
        break;
      default:
        status = StagedTransactionStatus.new_;
    }

    return StagedTransactionModel(
      id: json['id'] as String,
      date: json['date'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: json['category'] as String?,
      status: status,
      errorMessage: json['error_message'] as String?,
      selected: json['selected'] as bool? ?? true,
    );
  }

  StagedTransactionModel copyWith({bool? selected}) {
    return StagedTransactionModel(
      id: id,
      date: date,
      description: description,
      amount: amount,
      type: type,
      category: category,
      status: status,
      errorMessage: errorMessage,
      selected: selected ?? this.selected,
    );
  }

  bool get isDuplicate => status == StagedTransactionStatus.duplicate;
  bool get isError => status == StagedTransactionStatus.error;
  bool get isNew => status == StagedTransactionStatus.new_;
  bool get isExpense => type == 'expense';
}

class ImportResultModel {
  final String jobId;
  final int imported;
  final int skipped;
  final int failed;
  final String message;

  const ImportResultModel({
    required this.jobId,
    required this.imported,
    required this.skipped,
    required this.failed,
    required this.message,
  });

  factory ImportResultModel.fromJson(Map<String, dynamic> json) {
    return ImportResultModel(
      jobId: json['job_id'] as String,
      imported: json['imported'] as int,
      skipped: json['skipped'] as int,
      failed: json['failed'] as int? ?? 0,
      message: json['message'] as String? ?? 'Import complete',
    );
  }
}

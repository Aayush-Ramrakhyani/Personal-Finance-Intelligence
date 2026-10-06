import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String userId;
  final String accountId;
  final String? categoryId;
  final String type;
  final double amount;
  final String? description;
  final String? merchant;
  final DateTime transactionDate;
  final String? referenceNumber;
  final String? categoryName;
  final String? accountName;
  final String? transferId;

  const Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.description,
    this.merchant,
    required this.transactionDate,
    this.referenceNumber,
    this.categoryName,
    this.accountName,
    this.transferId,
  });

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        accountId: j['account_id'] as String,
        categoryId: j['category_id'] as String?,
        type: j['type'] as String,
        amount: (j['amount'] as num).toDouble(),
        description: j['description'] as String?,
        merchant: j['merchant'] as String?,
        transactionDate: DateTime.parse(j['transaction_date'] as String),
        referenceNumber: j['reference_number'] as String?,
        categoryName: j['category_name'] as String?,
        accountName: j['account_name'] as String?,
        transferId: j['transfer_id'] as String?,
      );

  bool get isTransfer => transferId != null || type == 'transfer';
  String get displayName => merchant ?? description ?? 'Unknown';

  @override
  List<Object?> get props => [id, amount, type, transactionDate];
}

class PaginatedTransactions extends Equatable {
  final List<Transaction> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PaginatedTransactions({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory PaginatedTransactions.fromJson(Map<String, dynamic> j) {
    final data = j['data'] as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedTransactions(
      items: items,
      total: data['total'] as int,
      page: data['page'] as int,
      pageSize: data['page_size'] as int,
      hasMore: data['has_more'] as bool,
    );
  }

  @override
  List<Object?> get props => [items, total, page];
}

class TransactionFilter {
  final String? type;
  final String? categoryId;
  final String? accountId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? search;

  const TransactionFilter({
    this.type,
    this.categoryId,
    this.accountId,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.search,
  });

  Map<String, dynamic> toQuery(int page) {
    return {
      'page': page,
      'page_size': 20,
      if (type != null) 'type': type,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (startDate != null)
        'start_date': startDate!.toIso8601String().substring(0, 10),
      if (endDate != null)
        'end_date': endDate!.toIso8601String().substring(0, 10),
      if (minAmount != null) 'min_amount': minAmount,
      if (maxAmount != null) 'max_amount': maxAmount,
      if (search != null && search!.isNotEmpty) 'search': search,
    };
  }
}

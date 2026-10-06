import 'package:equatable/equatable.dart';

class Account extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String accountType;
  final double currentBalance;
  final double openingBalance;
  final String currency;
  final bool isActive;
  final String? bankName;
  final String? lastFour;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.accountType,
    required this.currentBalance,
    required this.openingBalance,
    required this.currency,
    required this.isActive,
    this.bankName,
    this.lastFour,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        name: j['name'] as String,
        accountType: j['account_type'] as String,
        currentBalance: (j['current_balance'] as num).toDouble(),
        openingBalance: (j['opening_balance'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'INR',
        isActive: j['is_active'] as bool? ?? true,
        bankName: j['bank_name'] as String?,
        lastFour: j['last_four'] as String?,
      );

  @override
  List<Object?> get props => [id, name, currentBalance, accountType];
}

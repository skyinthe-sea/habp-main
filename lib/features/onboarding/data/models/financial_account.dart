// lib/features/onboarding/domain/models/financial_account.dart

enum AccountType {
  BANK,
  STOCK,
  INVESTMENT,
  LOAN,
}

class FinancialAccount {
  final int? id;
  final int? userId;
  final String name;
  final AccountType type;
  final double balance;
  final double? interestRate;
  final DateTime? maturityDate;
  final bool isFixed;
  final DateTime createdAt;
  final DateTime updatedAt;

  FinancialAccount({
    this.id,
    this.userId,
    required this.name,
    required this.type,
    required this.balance,
    this.interestRate,
    this.maturityDate,
    required this.isFixed,
    required this.createdAt,
    required this.updatedAt,
  });

  // 객체를 Map으로 변환 (DB 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.toString().split('.').last,
      'balance': balance,
      'interest_rate': interestRate,
      'maturity_date': maturityDate?.toIso8601String(),
      'is_fixed': isFixed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Map에서 객체로 변환 (DB 조회용)
  factory FinancialAccount.fromMap(Map<String, dynamic> map) {
    return FinancialAccount(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      type: AccountType.values.firstWhere(
            (e) => e.toString().split('.').last == map['type'],
        orElse: () => AccountType.BANK,
      ),
      balance: map['balance'],
      interestRate: map['interest_rate'],
      maturityDate: map['maturity_date'] != null
          ? DateTime.parse(map['maturity_date'])
          : null,
      isFixed: map['is_fixed'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // 업데이트된 객체 생성
  FinancialAccount copyWith({
    int? id,
    int? userId,
    String? name,
    AccountType? type,
    double? balance,
    double? interestRate,
    DateTime? maturityDate,
    bool? isFixed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      interestRate: interestRate ?? this.interestRate,
      maturityDate: maturityDate ?? this.maturityDate,
      isFixed: isFixed ?? this.isFixed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
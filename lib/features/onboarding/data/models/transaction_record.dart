// lib/features/onboarding/domain/models/transaction_record.dart

// 파일명과 클래스 이름을 Transaction에서 TransactionRecord로 변경

class TransactionRecord {
  final int? id;
  final int? userId;
  final int categoryId;
  final double amount;
  final String? description;
  final String? transactionNum;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionRecord({
    this.id,
    this.userId,
    required this.categoryId,
    required this.amount,
    this.description,
    this.transactionNum,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // 객체를 Map으로 변환 (DB 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'transaction_num': transactionNum,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Map에서 객체로 변환 (DB 조회용)
  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      id: map['id'],
      userId: map['user_id'],
      categoryId: map['category_id'],
      amount: map['amount'],
      description: map['description'],
      transactionNum: map['transactionNum'],
      transactionDate: DateTime.parse(map['transaction_date']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // 업데이트된 객체 생성
  TransactionRecord copyWith({
    int? id,
    int? userId,
    int? categoryId,
    double? amount,
    String? description,
    String? transactionNum,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      transactionNum: transactionNum ?? this.transactionNum,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
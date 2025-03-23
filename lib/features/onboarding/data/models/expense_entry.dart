// lib/features/onboarding/models/expense_entry.dart

class ExpenseEntry {
  final String id;
  final int amount;
  final String incomeType; // 월급, 용돈, 이자
  final String frequency; // 매월, 매주, 매일
  final int day; // 1~31일
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ExpenseEntry({
    required this.id,
    required this.amount,
    required this.incomeType,
    required this.frequency,
    required this.day,
    required this.createdAt,
    this.updatedAt,
  });

  // JSON 직렬화 (DB 저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'incomeType': incomeType,
      'frequency': frequency,
      'day': day,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // JSON 역직렬화 (DB 불러오기용)
  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseEntry(
      id: json['id'],
      amount: json['amount'],
      incomeType: json['incomeType'],
      frequency: json['frequency'],
      day: json['day'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // 복사본 생성 (업데이트용)
  ExpenseEntry copyWith({
    String? id,
    int? amount,
    String? incomeType,
    String? frequency,
    int? day,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseEntry(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      incomeType: incomeType ?? this.incomeType,
      frequency: frequency ?? this.frequency,
      day: day ?? this.day,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 표시 문자열 생성
  String getDisplayText() {
    final formattedAmount = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );

    // 빈도에 따라 다른 표시 형식 사용
    String dayText = '';
    if (frequency == '매월') {
      dayText = '$day일';
    } else if (frequency == '매주') {
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final weekdayIndex = (day - 1) % 7;
      dayText = '${weekdays[weekdayIndex]}요일';
    }

    // 매일인 경우에는 일자 표시하지 않음
    if (frequency == '매일') {
      return '$incomeType $frequency ₩$formattedAmount';
    } else {
      return '$incomeType $frequency $dayText ₩$formattedAmount';
    }
  }
}
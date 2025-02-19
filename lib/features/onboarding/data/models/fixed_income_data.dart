// lib/features/onboarding/data/models/fixed_income_data.dart

class FixedIncomeData {
  final String type;        // 소득 종류 (예: 월급)
  final String cycle;       // 주기 (예: 매월)
  final String day;         // 일자 (예: 1일)
  final int amount;         // 금액

  FixedIncomeData({
    required this.type,
    required this.cycle,
    required this.day,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'cycle': cycle,
      'day': day,
      'amount': amount,
    };
  }

  static FixedIncomeData fromMap(Map<String, dynamic> map) {
    return FixedIncomeData(
      type: map['type'],
      cycle: map['cycle'],
      day: map['day'],
      amount: map['amount'],
    );
  }
}
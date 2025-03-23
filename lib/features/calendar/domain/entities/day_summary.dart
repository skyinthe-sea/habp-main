import 'calendar_transaction.dart';

class DaySummary {
  final DateTime date;
  final double income;
  final double expense;
  final List<CalendarTransaction> transactions;

  DaySummary({
    required this.date,
    this.income = 0.0,
    this.expense = 0.0,
    this.transactions = const [],
  });
}
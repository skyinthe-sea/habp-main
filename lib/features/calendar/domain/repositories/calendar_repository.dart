import '../entities/calendar_transaction.dart';
import '../entities/day_summary.dart';

abstract class CalendarRepository {
  Future<List<CalendarTransaction>> getMonthTransactions(DateTime month);
  Future<Map<DateTime, List<CalendarTransaction>>> getMonthTransactionsGroupedByDay(DateTime month);
  Future<DaySummary> getDaySummary(DateTime date);
}
import '../entities/calendar_transaction.dart';
import '../repositories/calendar_repository.dart';

class GetMonthTransactions {
  final CalendarRepository repository;

  GetMonthTransactions(this.repository);

  Future<Map<DateTime, List<CalendarTransaction>>> execute(DateTime month) async {
    return await repository.getMonthTransactionsGroupedByDay(month);
  }
}
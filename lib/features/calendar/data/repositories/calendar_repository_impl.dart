import '../../domain/entities/calendar_transaction.dart';
import '../../domain/entities/day_summary.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_local_data_source.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarLocalDataSource localDataSource;

  CalendarRepositoryImpl({required this.localDataSource});

  @override
  Future<List<CalendarTransaction>> getMonthTransactions(DateTime month) async {
    return await localDataSource.getMonthTransactions(month);
  }

  @override
  Future<Map<DateTime, List<CalendarTransaction>>> getMonthTransactionsGroupedByDay(DateTime month) async {
    return await localDataSource.getMonthTransactionsGroupedByDay(month);
  }

  @override
  Future<DaySummary> getDaySummary(DateTime date) async {
    return await localDataSource.getDaySummary(date);
  }

  @override
  Future<void> updateTransaction(CalendarTransaction transaction) async {
    return await localDataSource.updateTransaction(transaction);
  }
}
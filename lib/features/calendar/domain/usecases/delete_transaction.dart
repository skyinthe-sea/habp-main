import '../entities/calendar_transaction.dart';
import '../repositories/calendar_repository.dart';

class DeleteTransaction {
  final CalendarRepository repository;

  DeleteTransaction(this.repository);

  Future<void> call(CalendarTransaction transaction) async {
    return await repository.deleteTransaction(transaction);
  }
}
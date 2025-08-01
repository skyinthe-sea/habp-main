import '../entities/calendar_transaction.dart';
import '../repositories/calendar_repository.dart';

class UpdateTransaction {
  final CalendarRepository repository;

  UpdateTransaction(this.repository);

  Future<void> call(CalendarTransaction transaction) async {
    return await repository.updateTransaction(transaction);
  }
}
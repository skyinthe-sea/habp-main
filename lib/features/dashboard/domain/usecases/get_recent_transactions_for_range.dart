import '../../data/entities/transaction_with_category.dart';
import '../repositories/transaction_repository.dart';

class GetRecentTransactionsForRange {
  final TransactionRepository repository;

  GetRecentTransactionsForRange(this.repository);

  Future<List<TransactionWithCategory>> execute(DateTime startDate, DateTime endDate, int limit) async {
    return await repository.getRecentTransactionsForRange(startDate, endDate, limit);
  }
}
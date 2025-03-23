import '../../data/entities/transaction_with_category.dart';
import '../repositories/transaction_repository.dart';

class GetRecentTransactions {
  final TransactionRepository repository;

  GetRecentTransactions(this.repository);

  Future<List<TransactionWithCategory>> execute(int limit) async {
    return await repository.getRecentTransactions(limit);
  }
}
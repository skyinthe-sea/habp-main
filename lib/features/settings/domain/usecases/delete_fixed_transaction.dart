import '../repositories/fixed_transaction_repository.dart';

class DeleteFixedTransaction {
  final FixedTransactionRepository repository;

  DeleteFixedTransaction(this.repository);

  Future<bool> execute(int categoryId) async {
    return await repository.deleteFixedTransaction(categoryId);
  }
}
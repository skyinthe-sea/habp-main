import '../repositories/fixed_transaction_repository.dart';

class CreateFixedTransaction {
  final FixedTransactionRepository repository;

  CreateFixedTransaction(this.repository);

  Future<bool> execute({
    required String name,
    required String type,
    required double amount,
    required DateTime effectiveFrom,
  }) async {
    return await repository.createFixedTransaction(
      name: name,
      type: type,
      amount: amount,
      effectiveFrom: effectiveFrom,
    );
  }
}
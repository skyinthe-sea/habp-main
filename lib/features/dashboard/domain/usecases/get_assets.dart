import '../repositories/transaction_repository.dart';

class GetAssets {
  final TransactionRepository repository;

  GetAssets(this.repository);

  Future<double> execute() async {
    return await repository.getAssets();
  }
}
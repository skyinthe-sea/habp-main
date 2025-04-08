import '../repositories/transaction_repository.dart';

class GetAssets {
  final TransactionRepository repository;

  GetAssets(this.repository);

  Future<double> execute(int year, int month) async {
    return await repository.getAssets(year, month);
  }
}
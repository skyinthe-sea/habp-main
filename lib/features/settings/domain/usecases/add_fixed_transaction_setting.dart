import '../repositories/fixed_transaction_repository.dart';
import '../../data/datasources/fixed_transaction_local_data_source.dart';

class AddFixedTransactionSetting {
  final FixedTransactionRepository repository;

  AddFixedTransactionSetting(this.repository);

  Future<bool> execute(FixedTransactionSetting setting) async {
    return await repository.addSetting(setting);
  }
}
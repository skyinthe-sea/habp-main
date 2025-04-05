import '../repositories/fixed_transaction_repository.dart';
import '../../data/datasources/fixed_transaction_local_data_source.dart';

class GetFixedCategories {
  final FixedTransactionRepository repository;

  GetFixedCategories(this.repository);

  Future<List<CategoryWithSettings>> execute() async {
    return await repository.getFixedCategories();
  }
}
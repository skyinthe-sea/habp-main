import '../repositories/fixed_transaction_repository.dart';
import '../../data/datasources/fixed_transaction_local_data_source.dart';

class GetFixedCategoriesByType {
  final FixedTransactionRepository repository;

  GetFixedCategoriesByType(this.repository);

  Future<List<CategoryWithSettings>> execute(String type) async {
    return await repository.getFixedCategoriesByType(type);
  }
}
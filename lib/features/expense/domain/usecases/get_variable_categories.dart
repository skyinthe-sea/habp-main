import '../../data/models/category_model.dart';
import '../repositories/expense_repository.dart';

class GetVariableCategories {
  final ExpenseRepository repository;

  GetVariableCategories(this.repository);

  Future<List<CategoryModel>> call() async {
    return await repository.getVariableExpenseCategories();
  }
}
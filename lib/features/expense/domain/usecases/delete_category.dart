import '../repositories/expense_repository.dart';

class DeleteCategory {
  final ExpenseRepository repository;

  DeleteCategory(this.repository);

  Future<bool> call(int categoryId) async {
    return await repository.deleteCategory(categoryId);
  }
}
import '../repositories/expense_repository.dart';

class UpdateCategory {
  final ExpenseRepository repository;

  UpdateCategory(this.repository);

  Future<bool> call({
    required int categoryId,
    required String name,
  }) async {
    return await repository.updateCategory(
      categoryId: categoryId,
      name: name,
    );
  }
}
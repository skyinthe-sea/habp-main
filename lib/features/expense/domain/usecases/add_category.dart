import '../../data/models/category_model.dart';
import '../repositories/expense_repository.dart';

class AddCategory {
  final ExpenseRepository repository;

  AddCategory(this.repository);

  Future<CategoryModel?> call({
    required String name,
    required String type,
    required int isFixed,
  }) async {
    return await repository.addCategory(
      name: name,
      type: type,
      isFixed: isFixed,
    );
  }
}
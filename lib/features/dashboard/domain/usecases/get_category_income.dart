// lib/features/dashboard/domain/usecases/get_category_income.dart
import '../../data/entities/category_expense.dart';
import '../repositories/transaction_repository.dart';

class GetCategoryIncome {
  final TransactionRepository repository;

  GetCategoryIncome(this.repository);

  Future<List<CategoryExpense>> execute(int year, int month) async {
    return await repository.getCategoryIncome(year, month);
  }
}
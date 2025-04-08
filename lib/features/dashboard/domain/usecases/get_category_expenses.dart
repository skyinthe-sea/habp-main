import '../../data/entities/category_expense.dart';
import '../repositories/transaction_repository.dart';

class GetCategoryExpenses {
  final TransactionRepository repository;

  GetCategoryExpenses(this.repository);

  Future<List<CategoryExpense>> execute(int year, int month) async {
    return await repository.getCategoryExpenses(year, month);
  }
}
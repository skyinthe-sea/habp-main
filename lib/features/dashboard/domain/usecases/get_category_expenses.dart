import '../../data/entities/category_expense.dart';
import '../repositories/transaction_repository.dart';

class GetCategoryExpenses {
  final TransactionRepository repository;

  GetCategoryExpenses(this.repository);

  Future<List<CategoryExpense>> execute() async {
    return await repository.getCategoryExpenses();
  }
}
// lib/features/dashboard/domain/usecases/get_category_finance.dart
import '../../data/entities/category_expense.dart';
import '../repositories/transaction_repository.dart';

class GetCategoryFinance {
  final TransactionRepository repository;

  GetCategoryFinance(this.repository);

  Future<List<CategoryExpense>> execute(int year, int month) async {
    return await repository.getCategoryFinance(year, month);
  }
}
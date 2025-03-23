import '../entities/budget_status.dart';
import '../repositories/expense_repository.dart';

class GetBudgetStatus {
  final ExpenseRepository repository;

  GetBudgetStatus(this.repository);

  Future<List<BudgetStatus>> call(int userId, String period) async {
    return await repository.getBudgetStatus(userId, period);
  }
}
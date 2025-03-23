import '../../data/entities/monthly_expense.dart';
import '../repositories/transaction_repository.dart';

class GetMonthlyExpensesTrend {
  final TransactionRepository repository;

  GetMonthlyExpensesTrend(this.repository);

  Future<List<MonthlyExpense>> execute(int months) async {
    return await repository.getMonthlyExpenses(months);
  }
}
// lib/features/dashboard/domain/repositories/transaction_repository.dart
import '../../data/entities/category.dart';
import '../../data/entities/category_expense.dart';
import '../../data/entities/monthly_expense.dart';
import '../../data/entities/transaction.dart';
import '../../data/entities/transaction_with_category.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions();
  Future<List<Category>> getCategories();
  Future<List<MonthlyExpense>> getMonthlyExpenses(int months);
  Future<List<CategoryExpense>> getCategoryExpenses(int year, int month);
  Future<List<CategoryExpense>> getCategoryIncome(int year, int month);
  Future<List<CategoryExpense>> getCategoryFinance(int year, int month);
  Future<List<TransactionWithCategory>> getRecentTransactions(int limit);
  Future<List<Transaction>> getTransactionsByDateRange(DateTime start, DateTime end);
  Future<double> getAssets(int year, int month);
  Future<Map<String, dynamic>> getMonthlySummary(int year, int month);
  Future<List<TransactionWithCategory>> getRecentTransactionsForRange(
      DateTime startDate, DateTime endDate, int limit);
}
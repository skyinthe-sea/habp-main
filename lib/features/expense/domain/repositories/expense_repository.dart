import '../entities/budget_status.dart';
import '../../data/models/category_model.dart';

abstract class ExpenseRepository {
  Future<List<BudgetStatus>> getBudgetStatus(int userId, String period);
  Future<List<CategoryModel>> getVariableExpenseCategories();
  Future<bool> addBudget({
    required int userId,
    required int categoryId,
    required double amount,
    required String periodStart,
    required String periodEnd,
  });
  Future<CategoryModel?> addCategory({
    required String name,
    required String type,
    required int isFixed,
  });
  Future<bool> deleteCategory(int categoryId);
  Future<bool> addExpense({
    required int userId,
    required int categoryId,
    required double amount,
    required String description,
    required String transactionDate,
  });
}
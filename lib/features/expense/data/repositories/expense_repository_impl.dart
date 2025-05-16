import '../../domain/entities/budget_status.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_data_source.dart';
import '../models/category_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;

  ExpenseRepositoryImpl({required this.localDataSource});

  @override
  Future<List<BudgetStatus>> getBudgetStatus(int userId, String period) async {
    final result = await localDataSource.getBudgetStatus(userId, period);
    return result;
  }

  @override
  Future<List<CategoryModel>> getVariableExpenseCategories() async {
    return await localDataSource.getVariableExpenseCategories();
  }

  @override
  Future<bool> addBudget({
    required int userId,
    required int categoryId,
    required double amount,
    required String periodStart,
    required String periodEnd,
  }) async {
    return await localDataSource.addBudget(
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  @override
  Future<CategoryModel?> addCategory({
    required String name,
    required String type,
    required int isFixed,
  }) async {
    return await localDataSource.addCategory(
      name: name,
      type: type,
      isFixed: isFixed,
    );
  }

  @override
  Future<bool> deleteCategory(int categoryId) async {
    return await localDataSource.deleteCategory(categoryId);
  }

  @override
  Future<bool> addExpense({
    required int userId,
    required int categoryId,
    required double amount,
    required String description,
    required String transactionDate,
  }) async {
    return await localDataSource.addExpense(
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      description: description,
      transactionDate: transactionDate,
    );
  }

  @override
  Future<bool> updateBudget({
    required int userId,
    required int categoryId,
    required double amount,
    required String periodStart,
    required String periodEnd,
  }) async {
    return await localDataSource.updateBudget(
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  @override
  Future<bool> updateCategory({
    required int categoryId,
    required String name,
  }) async {
    return await localDataSource.updateCategory(
      categoryId: categoryId,
      name: name,
    );
  }
}
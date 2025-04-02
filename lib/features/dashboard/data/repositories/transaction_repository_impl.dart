// lib/features/dashboard/data/repositories/transaction_repository_impl.dart
import 'package:habp/features/dashboard/data/entities/category_expense.dart';

import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_data_source.dart';
import '../entities/category.dart';
import '../entities/monthly_expense.dart';
import '../entities/transaction.dart';
import '../entities/transaction_with_category.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;

  TransactionRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Transaction>> getTransactions() async {
    return await localDataSource.getTransactions();
  }

  @override
  Future<List<Category>> getCategories() async {
    return await localDataSource.getCategories();
  }

  @override
  Future<List<MonthlyExpense>> getMonthlyExpenses(int months) async {
    return await localDataSource.getMonthlyExpenses(months);
  }

  @override
  Future<List<CategoryExpense>> getCategoryExpenses() async {
    return await localDataSource.getCategoryExpenses();
  }

  @override
  Future<List<CategoryExpense>> getCategoryIncome() async {
    return await localDataSource.getCategoryIncome();
  }

  @override
  Future<List<CategoryExpense>> getCategoryFinance() async {
    return await localDataSource.getCategoryFinance();
  }

  @override
  Future<List<TransactionWithCategory>> getRecentTransactions(int limit) async {
    return await localDataSource.getRecentTransactions(limit);
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    return await localDataSource.getTransactionsByDateRange(start, end);
  }

  @override
  Future<double> getAssets() async {
    return await localDataSource.getAssets();
  }
}
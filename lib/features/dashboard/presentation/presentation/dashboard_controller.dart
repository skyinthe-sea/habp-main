import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/entities/category_expense.dart';
import '../../data/entities/monthly_expense.dart';
import '../../data/entities/transaction_with_category.dart';
import '../../domain/usecases/get_category_expenses.dart';
import '../../domain/usecases/get_monthly_summary.dart';
import '../../domain/usecases/get_monthly_expenses_trend.dart';
import '../../domain/usecases/get_recent_transactions.dart';

class DashboardController extends GetxController {
  final GetMonthlySummary getMonthlySummary;
  final GetMonthlyExpensesTrend getMonthlyExpensesTrend;
  final GetCategoryExpenses getCategoryExpenses;
  final GetRecentTransactions getRecentTransactions;

  DashboardController({
    required this.getMonthlySummary,
    required this.getMonthlyExpensesTrend,
    required this.getCategoryExpenses,
    required this.getRecentTransactions,
  });

  final RxDouble monthlyIncome = 0.0.obs;
  final RxDouble monthlyExpense = 0.0.obs;
  final RxDouble monthlyBalance = 0.0.obs;
  final RxBool isLoading = false.obs;
  final RxList<MonthlyExpense> monthlyExpenses = <MonthlyExpense>[].obs;
  final RxBool isExpenseTrendLoading = false.obs;
  final RxList<CategoryExpense> categoryExpenses = <CategoryExpense>[].obs;
  final RxBool isCategoryExpenseLoading = false.obs;
  final RxList<TransactionWithCategory> recentTransactions = <TransactionWithCategory>[].obs;
  final RxBool isRecentTransactionsLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMonthlySummary();
    fetchMonthlyExpensesTrend();
    fetchCategoryExpenses();
    fetchRecentTransactions();
  }

  Future<void> fetchRecentTransactions() async {
    isRecentTransactionsLoading.value = true;
    try {
      final result = await getRecentTransactions.execute(5); // 최근 5개 거래
      recentTransactions.value = result;
    } catch (e) {
      debugPrint('최근 거래 내역 가져오기 오류: $e');
    } finally {
      isRecentTransactionsLoading.value = false;
    }
  }

  Future<void> fetchCategoryExpenses() async {
    isCategoryExpenseLoading.value = true;
    try {
      final result = await getCategoryExpenses.execute();
      categoryExpenses.value = result;
      debugPrint('카테고리별 지출 개수: ${result.length}');
    } catch (e) {
      debugPrint('카테고리별 지출 가져오기 오류: $e');
    } finally {
      isCategoryExpenseLoading.value = false;
    }
  }

  Future<void> fetchMonthlySummary() async {
    isLoading.value = true;
    try {
      final result = await getMonthlySummary.execute();
      monthlyIncome.value = result['income'] ?? 0.0;
      monthlyExpense.value = result['expense'] ?? 0.0;
      monthlyBalance.value = result['balance'] ?? 0.0;
    } catch (e) {
      debugPrint('월간 요약 정보 가져오기 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMonthlyExpensesTrend() async {
    isExpenseTrendLoading.value = true;
    try {
      final result = await getMonthlyExpensesTrend.execute(6); // 최대 6개월
      monthlyExpenses.value = result;
    } catch (e) {
      debugPrint('월별 지출 추이 가져오기 오류: $e');
    } finally {
      isExpenseTrendLoading.value = false;
    }
  }
}
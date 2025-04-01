import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/event_bus_service.dart';
import '../../data/entities/category_expense.dart';
import '../../data/entities/monthly_expense.dart';
import '../../data/entities/transaction_with_category.dart';
import '../../domain/usecases/get_assets.dart';
import '../../domain/usecases/get_category_expenses.dart';
import '../../domain/usecases/get_monthly_summary.dart';
import '../../domain/usecases/get_monthly_expenses_trend.dart';
import '../../domain/usecases/get_recent_transactions.dart';

class DashboardController extends GetxController {
  final GetMonthlySummary getMonthlySummary;
  final GetMonthlyExpensesTrend getMonthlyExpensesTrend;
  final GetCategoryExpenses getCategoryExpenses;
  final GetRecentTransactions getRecentTransactions;
  final GetAssets getAssets;

  DashboardController({
    required this.getMonthlySummary,
    required this.getMonthlyExpensesTrend,
    required this.getCategoryExpenses,
    required this.getRecentTransactions,
    required this.getAssets,
  });

  // 기존 상태 변수
  final RxDouble monthlyIncome = 0.0.obs;
  final RxDouble monthlyExpense = 0.0.obs;
  final RxDouble monthlyBalance = 0.0.obs;
  final RxDouble monthlyAssets = 0.0.obs;

  // 새로운 상태 변수 - 지난달 대비 증감율
  final RxDouble incomeChangePercentage = 0.0.obs;
  final RxDouble expenseChangePercentage = 0.0.obs;

  final RxBool isLoading = false.obs;
  final RxBool isAssetsLoading = false.obs;
  final RxList<MonthlyExpense> monthlyExpenses = <MonthlyExpense>[].obs;
  final RxBool isExpenseTrendLoading = false.obs;
  final RxList<CategoryExpense> categoryExpenses = <CategoryExpense>[].obs;
  final RxBool isCategoryExpenseLoading = false.obs;
  final RxList<TransactionWithCategory> recentTransactions = <TransactionWithCategory>[].obs;
  final RxBool isRecentTransactionsLoading = false.obs;

  // EventBusService 인스턴스
  late final EventBusService _eventBusService;

  @override
  void onInit() {
    super.onInit();

    // EventBusService 가져오기
    _eventBusService = Get.find<EventBusService>();

    // 트랜잭션 변경 이벤트 구독
    ever(_eventBusService.transactionChanged, (_) {
      debugPrint('거래 변경 이벤트 감지됨: 대시보드 데이터 새로고침');
      _refreshAllData();
    });

    // 초기 데이터 로드
    _refreshAllData();
  }

  // 모든 데이터를 새로고침하는 메서드
  void _refreshAllData() {
    fetchMonthlySummary();
    fetchMonthlyExpensesTrend();
    fetchCategoryExpenses();
    fetchRecentTransactions();
    fetchAssets();
  }

  Future<void> fetchAssets() async {
    isAssetsLoading.value = true;
    try {
      final result = await getAssets.execute();
      monthlyAssets.value = result;
      debugPrint('월간 재테크 정보 로드 완료: ${monthlyAssets.value}');
    } catch (e) {
      debugPrint('월간 재테크 정보 가져오기 오류: $e');
    } finally {
      isAssetsLoading.value = false;
    }
  }

  Future<List<TransactionWithCategory>> getAllCurrentMonthTransactions() async {
    try {
      // Set loading state
      isRecentTransactionsLoading.value = true;

      // Get current month date range
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      // Get all transactions with a large limit
      final allTransactions = await getRecentTransactions.execute(1000); // Using a large limit

      // Filter for current month only
      final currentMonthTransactions = allTransactions
          .where((tx) => tx.transactionDate.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))))
          .toList();

      debugPrint('이번 달 전체 거래 내역 개수: ${currentMonthTransactions.length}');
      return currentMonthTransactions;
    } catch (e) {
      debugPrint('이번 달 전체 거래 내역 가져오기 오류: $e');
      return [];
    } finally {
      isRecentTransactionsLoading.value = false;
    }
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

      // 월간 요약 정보
      monthlyIncome.value = result['income'] ?? 0.0;
      monthlyExpense.value = result['expense'] ?? 0.0;
      monthlyBalance.value = result['balance'] ?? 0.0;

      // 지난달 대비 증감율
      incomeChangePercentage.value = result['incomeChangePercentage'] ?? 0.0;
      expenseChangePercentage.value = result['expenseChangePercentage'] ?? 0.0;

      debugPrint('월간 요약 정보 로드 완료: 수입 ${monthlyIncome.value}, 지출 ${monthlyExpense.value}, 증감율(수입): ${incomeChangePercentage.value.toStringAsFixed(1)}%');
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

  // 퍼센트 변화 부호 가져오기
  String getPercentageSign(double value) {
    return value >= 0 ? '+' : '';
  }
}
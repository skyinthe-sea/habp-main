// lib/features/dashboard/presentation/presentation/dashboard_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/event_bus_service.dart';
import '../../data/entities/category_expense.dart';
import '../../data/entities/monthly_expense.dart';
import '../../data/entities/transaction_with_category.dart';
import '../../domain/usecases/get_assets.dart';
import '../../domain/usecases/get_category_expenses.dart';
import '../../domain/usecases/get_category_income.dart';
import '../../domain/usecases/get_category_finance.dart';
import '../../domain/usecases/get_monthly_summary.dart';
import '../../domain/usecases/get_monthly_expenses_trend.dart';
import '../../domain/usecases/get_recent_transactions.dart';

class DashboardController extends GetxController {
  final GetMonthlySummary getMonthlySummary;
  final GetMonthlyExpensesTrend getMonthlyExpensesTrend;
  final GetCategoryExpenses getCategoryExpenses;
  final GetCategoryIncome getCategoryIncome;
  final GetCategoryFinance getCategoryFinance;
  final GetRecentTransactions getRecentTransactions;
  final GetAssets getAssets;

  DashboardController({
    required this.getMonthlySummary,
    required this.getMonthlyExpensesTrend,
    required this.getCategoryExpenses,
    required this.getCategoryIncome,
    required this.getCategoryFinance,
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

  // 카테고리별 지출 데이터
  final RxList<CategoryExpense> categoryExpenses = <CategoryExpense>[].obs;
  final RxBool isCategoryExpenseLoading = false.obs;

  // 카테고리별 수입 데이터 (신규)
  final RxList<CategoryExpense> categoryIncome = <CategoryExpense>[].obs;
  final RxBool isCategoryIncomeLoading = false.obs;

  // 카테고리별 재테크 데이터 (신규)
  final RxList<CategoryExpense> categoryFinance = <CategoryExpense>[].obs;
  final RxBool isCategoryFinanceLoading = false.obs;

  final RxList<TransactionWithCategory> recentTransactions = <TransactionWithCategory>[].obs;
  final RxBool isRecentTransactionsLoading = false.obs;

  // 월 탐색을 위한 새 변수들
  final Rx<DateTime> selectedMonth = DateTime.now().obs;
  final RxInt monthRange = 6.obs; // 기본 6개월 표시

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

    // 선택된 월 변경 이벤트 구독
    ever(selectedMonth, (_) {
      debugPrint('선택된 월 변경됨: ${getMonthYearString()}');
      _refreshAllData();
    });

    // 월 범위 변경 이벤트 구독
    ever(monthRange, (_) {
      debugPrint('월 범위 변경됨: ${monthRange.value}개월');
      fetchMonthlyExpensesTrend();
    });

    // 초기 데이터 로드
    _refreshAllData();
  }

  // 이전 달로 이동
  void goToPreviousMonth() {
    final prevMonth = DateTime(selectedMonth.value.year, selectedMonth.value.month - 1, 1);
    selectedMonth.value = prevMonth;
  }

  // 다음 달로 이동
  void goToNextMonth() {
    final nextMonth = DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 1);
    // 미래 달로는 이동 제한
    if (nextMonth.isBefore(DateTime.now()) ||
        (nextMonth.year == DateTime.now().year && nextMonth.month == DateTime.now().month)) {
      selectedMonth.value = nextMonth;
    }
  }

  // 현재 달로 이동
  void goToCurrentMonth() {
    selectedMonth.value = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  // 월 범위 설정
  void setMonthRange(int range) {
    if (range >= 3 && range <= 12) {
      monthRange.value = range;
    }
  }

  // 현재 선택된 월의 연월 문자열 반환 (예: 2025년 4월)
  String getMonthYearString() {
    return '${selectedMonth.value.year}년 ${selectedMonth.value.month}월';
  }

  // 모든 데이터를 새로고침하는 메서드
  void _refreshAllData() {
    fetchMonthlySummary();
    fetchMonthlyExpensesTrend();
    fetchCategoryExpenses();
    fetchCategoryIncome();
    fetchCategoryFinance();
    fetchRecentTransactions();
    fetchAssets();
  }

  Future<void> fetchAssets() async {
    isAssetsLoading.value = true;
    try {
      // 이 메서드를 수정하여 선택된 월에 대한 자산 정보를 가져오도록
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

      // Get selected month date range
      final firstDayOfMonth = DateTime(selectedMonth.value.year, selectedMonth.value.month, 1);
      final lastDayOfMonth = DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0);

      // Get all transactions with a large limit
      final allTransactions = await getRecentTransactions.execute(1000); // Using a large limit

      // Filter for selected month only
      final selectedMonthTransactions = allTransactions
          .where((tx) =>
      tx.transactionDate.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
          tx.transactionDate.isBefore(lastDayOfMonth.add(const Duration(days: 1))))
          .toList();

      debugPrint('선택된 달 전체 거래 내역 개수: ${selectedMonthTransactions.length}');
      return selectedMonthTransactions;
    } catch (e) {
      debugPrint('선택된 달 전체 거래 내역 가져오기 오류: $e');
      return [];
    } finally {
      isRecentTransactionsLoading.value = false;
    }
  }

  Future<void> fetchRecentTransactions() async {
    isRecentTransactionsLoading.value = true;
    try {
      // 선택된 월의 최근 거래 내역을 가져오기
      final result = await getRecentTransactions.execute(10); // 최근 10개 거래

      // 선택된 월에 해당하는 거래만 필터링
      final firstDayOfMonth = DateTime(selectedMonth.value.year, selectedMonth.value.month, 1);
      final lastDayOfMonth = DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0);

      final filteredResult = result.where((tx) =>
      tx.transactionDate.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
          tx.transactionDate.isBefore(lastDayOfMonth.add(const Duration(days: 1))))
          .toList();

      recentTransactions.value = filteredResult;
    } catch (e) {
      debugPrint('최근 거래 내역 가져오기 오류: $e');
    } finally {
      isRecentTransactionsLoading.value = false;
    }
  }

  Future<void> fetchCategoryExpenses() async {
    isCategoryExpenseLoading.value = true;
    try {
      // 선택된 월의 카테고리별 지출 정보를 가져오도록 수정 필요
      final result = await getCategoryExpenses.execute();
      categoryExpenses.value = result;
      debugPrint('카테고리별 지출 개수: ${result.length}');
    } catch (e) {
      debugPrint('카테고리별 지출 가져오기 오류: $e');
    } finally {
      isCategoryExpenseLoading.value = false;
    }
  }

  Future<void> fetchCategoryIncome() async {
    isCategoryIncomeLoading.value = true;
    try {
      // 선택된 월의 카테고리별 수입 정보를 가져오도록 수정 필요
      final result = await getCategoryIncome.execute();
      categoryIncome.value = result;
      debugPrint('카테고리별 수입 개수: ${result.length}');
    } catch (e) {
      debugPrint('카테고리별 수입 가져오기 오류: $e');
    } finally {
      isCategoryIncomeLoading.value = false;
    }
  }

  Future<void> fetchCategoryFinance() async {
    isCategoryFinanceLoading.value = true;
    try {
      // 선택된 월의 카테고리별 재테크 정보를 가져오도록 수정 필요
      final result = await getCategoryFinance.execute();
      categoryFinance.value = result;
      debugPrint('카테고리별 재테크 개수: ${result.length}');
    } catch (e) {
      debugPrint('카테고리별 재테크 가져오기 오류: $e');
    } finally {
      isCategoryFinanceLoading.value = false;
    }
  }

  Future<void> fetchMonthlySummary() async {
    isLoading.value = true;
    try {
      // 선택된 월의 요약 정보를 가져오도록 수정 필요
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
      // 설정된 범위만큼의 월별 지출 추이 데이터 가져오기
      final result = await getMonthlyExpensesTrend.execute(monthRange.value);
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
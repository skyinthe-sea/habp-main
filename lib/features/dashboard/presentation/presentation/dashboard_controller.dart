// lib/features/dashboard/presentation/presentation/dashboard_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/db_helper.dart';
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
import '../../domain/usecases/get_recent_transactions_for_range.dart';

class DashboardController extends GetxController {
  final GetMonthlySummary getMonthlySummary;
  final GetMonthlyExpensesTrend getMonthlyExpensesTrend;
  final GetCategoryExpenses getCategoryExpenses;
  final GetCategoryIncome getCategoryIncome;
  final GetCategoryFinance getCategoryFinance;
  final GetRecentTransactions getRecentTransactions;
  final GetAssets getAssets;
  final GetRecentTransactionsForRange getRecentTransactionsForRange;

  DashboardController({
    required this.getMonthlySummary,
    required this.getMonthlyExpensesTrend,
    required this.getCategoryExpenses,
    required this.getCategoryIncome,
    required this.getCategoryFinance,
    required this.getRecentTransactions,
    required this.getRecentTransactionsForRange, // 새로운 필드 추가
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

  // 새로 추가: 전체 월 데이터 저장 (최대 12개월)
  final RxList<MonthlyExpense> allMonthlyExpenses = <MonthlyExpense>[].obs;

  // 새로 추가: 애니메이션 상태 관리
  final RxBool isChartAnimating = false.obs;

  // 새로 추가: 압축된 월별 데이터 관리
  final RxBool isCompressedData = true.obs; // 기본값으로 압축 활성화

  // EventBusService 인스턴스
  late final EventBusService _eventBusService;

  // 변경: 실시간 슬라이더 값을 위한 새로운 변수 (임시 범위)
  final RxDouble sliderMonthRange = 6.0.obs;

  // 변경: 데이터 검색 없이 즉시 UI 업데이트를 위한 플래그
  final RxBool isSliding = false.obs;

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
      isChartAnimating.value = true; // 애니메이션 상태 활성화
      _refreshAllData();
    });

    // 월 범위 변경 이벤트 구독 (수정)
    ever(monthRange, (_) {
      debugPrint('월 범위 변경됨: ${monthRange.value}개월');
      // 변경: 슬라이딩 중이 아닐 때만 새로운 데이터 페칭
      if (!isSliding.value) {
        fetchMonthlyExpensesTrend();
      }
    });

    // 추가: 슬라이더 실시간 값 변경 구독
    ever(sliderMonthRange, (_) {
      // 슬라이딩 중에 실시간 UI 업데이트
      if (isSliding.value) {
        // 필터링된 데이터로 monthlyExpenses 업데이트
        monthlyExpenses.value = filteredMonthlyExpenses;
      }
    });

    // 초기 데이터 로드
    _refreshAllData();
  }

  // 새 메서드: 슬라이더 이동 시작 처리
  void onSlideStart() {
    // 단발성 터치에서도 즉시 반응하도록 플래그 설정
    isSliding.value = true;
  }

  // 새 메서드: 슬라이더 값 실시간 업데이트
  void updateSliderValue(double value) {
    if (value >= 3 && value <= 12) {
      // 슬라이딩 중으로 표시하여 단발성 터치에서도 즉시 반응하도록 함
      if (!isSliding.value) {
        isSliding.value = true;
      }
      sliderMonthRange.value = value;
    }
  }

  // 새 메서드: 슬라이더 이동 종료 처리 (수정됨)
  void onSlideEnd(double value) {
    final newRange = value.toInt();

    // 두 값을 동시에 업데이트하여 슬라이딩 종료 시 리드로우 방지
    monthRange.value = newRange;
    sliderMonthRange.value = newRange.toDouble();

    // isSliding 상태를 잠시 유지하여 애니메이션 상태 유지
    // 그 후 애니메이션이 완료되면 상태 변경
    Future.delayed(const Duration(milliseconds: 100), () {
      isSliding.value = false;
    });
  }

  String getMonthRangeString() {
    final expenses = filteredMonthlyExpenses;
    if (expenses.isEmpty) return "";

    final firstMonth = expenses.first.date;
    final lastMonth = expenses.last.date;

    final firstMonthText = DateFormat('yyyy년 M월').format(firstMonth);
    final lastMonthText = DateFormat('yyyy년 M월').format(lastMonth);

    return "$firstMonthText ~ $lastMonthText (${expenses.length}개월)";
  }

  // 새로 추가: 중복 월 데이터 압축 메서드
  List<MonthlyExpense> _compressMonthlyData(List<MonthlyExpense> expenses) {
    if (expenses.isEmpty) return [];

    // 월별로 그룹핑하기 위한 맵
    final Map<String, MonthlyExpense> monthMap = {};

    // 모든 지출 항목을 순회하며 같은 연도/월 항목 병합
    for (var expense in expenses) {
      final year = expense.date.year;
      final month = expense.date.month;
      final key = '$year-$month';

      if (monthMap.containsKey(key)) {
        // 기존 항목이 있으면 금액 합산
        final existingExpense = monthMap[key]!;
        monthMap[key] = MonthlyExpense(
            date: existingExpense.date, // 기존 날짜 유지
            amount: existingExpense.amount + expense.amount // 금액 합산
        );
      } else {
        // 처음 등장하는 연도/월 조합이면 그대로 추가
        monthMap[key] = expense;
      }
    }

    // 맵의 값들을 리스트로 변환하고 날짜순으로 정렬
    final result = monthMap.values.toList();
    result.sort((a, b) => a.date.compareTo(b.date));

    debugPrint('압축 전 데이터 개수: ${expenses.length}, 압축 후: ${result.length}');
    return result;
  }

  // 수정: 선택된 월을 기준으로 월별 지출 추이 데이터 필터링
  List<MonthlyExpense> get filteredMonthlyExpenses {
    // 압축된 전체 데이터 가져오기
    final List<MonthlyExpense> compressedData = isCompressedData.value
        ? _compressMonthlyData(allMonthlyExpenses)
        : allMonthlyExpenses;

    // 선택된 월이 존재하지 않는 경우 빈 리스트 반환
    if (compressedData.isEmpty) return [];

    // 선택된 월 기준으로 데이터 필터링
    final selectedDate = DateTime(selectedMonth.value.year, selectedMonth.value.month, 1);

    // 선택된 월의 인덱스 찾기
    int selectedMonthIndex = -1;
    for (int i = 0; i < compressedData.length; i++) {
      final expense = compressedData[i];
      if (expense.date.year == selectedDate.year && expense.date.month == selectedDate.month) {
        selectedMonthIndex = i;
        break;
      }
    }

    // 선택된 월이 데이터에 없는 경우
    if (selectedMonthIndex == -1) return [];

    // 변경: 슬라이더 이동 중에는 sliderMonthRange 사용, 그렇지 않으면 monthRange 사용
    final effectiveRange = isSliding.value
        ? sliderMonthRange.value.toInt()
        : monthRange.value;

    // 선택된 월을 끝으로 하는 범위 계산
    int startIndex = selectedMonthIndex - effectiveRange + 1;
    if (startIndex < 0) startIndex = 0;

    // 선택된 월이 마지막이 되도록 데이터 추출
    final result = compressedData.sublist(startIndex, selectedMonthIndex + 1);

    return result;
  }

  // 새로 추가: 차트 애니메이션 완료 처리
  void onChartAnimationComplete() {
    isChartAnimating.value = false;
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

  // RecentTransactionsList 위젯에서 사용하는 getAllCurrentMonthTransactions 메서드도 수정

  // 전체보기 다이얼로그에서도 미래 데이터가 표시되지 않도록 수정

  Future<List<TransactionWithCategory>> getAllCurrentMonthTransactions() async {
    try {
      // 선택된 월의 정보를 가져옵니다.
      final selectedYear = selectedMonth.value.year;
      final selectedMonthValue = selectedMonth.value.month;

      // 오늘 날짜를 가져옵니다.
      final now = DateTime.now();

      // 선택된 월의 시작 날짜를 계산합니다.
      final startOfMonth = DateTime(selectedYear, selectedMonthValue, 1);

      // 종료 날짜를 계산합니다:
      // - 선택된 월이 현재 월인 경우: 오늘 날짜까지
      // - 선택된 월이 과거 월인 경우: 해당 월의 마지막 날
      DateTime endDate;

      // 현재 월과 동일한지 확인
      if (selectedYear == now.year && selectedMonthValue == now.month) {
        // 현재 월이면 오늘 날짜까지만 조회
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        debugPrint('현재 월 전체 거래내역: 오늘(${endDate.toString()})까지의 데이터만 표시');
      } else {
        // 다른 월이면 해당 월의 마지막 날까지 조회
        endDate = DateTime(selectedYear, selectedMonthValue + 1, 0, 23, 59, 59);
        debugPrint('과거 월 전체 거래내역: 해당 월 마지막 날(${endDate.toString()})까지 표시');
      }

      // Set loading state
      isRecentTransactionsLoading.value = true;

      // 설정된 기간의 모든 거래 내역을 가져옵니다.
      final db = await DBHelper().database;

      // SQLite 쿼리에 사용할 날짜 문자열 형식으로 변환
      final startDateStr = "${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-${startOfMonth.day.toString().padLeft(2, '0')}";
      final endDateStr = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

      debugPrint('전체 거래 내역 조회 기간: $startDateStr ~ $endDateStr');

      // 변동 거래 내역
      final List<Map<String, dynamic>> variableResults = await db.rawQuery('''
      SELECT tr.*, c.name as category_name, c.type as category_type 
      FROM transaction_record tr
      JOIN category c ON tr.category_id = c.id
      WHERE date(substr(tr.transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      ORDER BY tr.transaction_date DESC
    ''', [startDateStr, endDateStr]);

      // 고정 거래 내역
      final List<Map<String, dynamic>> fixedResults = await db.rawQuery('''
      SELECT tr2.*, c.name as category_name, c.type as category_type, c.is_fixed
      FROM transaction_record2 tr2
      JOIN category c ON tr2.category_id = c.id
      WHERE c.is_fixed = 1
    ''');

      // 변동 거래 처리
      List<TransactionWithCategory> variableTransactions = variableResults.map((row) =>
          TransactionWithCategory(
            id: row['id'] as int,
            userId: row['user_id'] as int,
            categoryId: row['category_id'] as int,
            categoryName: row['category_name'] as String,
            categoryType: row['category_type'] as String,
            amount: row['amount'] as double,
            description: row['description'] as String,
            transactionDate: DateTime.parse(row['transaction_date']),
            transactionNum: row['transaction_num'].toString(),
            createdAt: DateTime.parse(row['created_at']),
            updatedAt: DateTime.parse(row['updated_at']),
          )
      ).toList();

      // 고정 거래 처리 - 선택된 월의 거래만 필터링
      List<TransactionWithCategory> fixedTransactions = [];

      for (var row in fixedResults) {
        final description = row['description'] as String;
        final categoryId = row['category_id'] as int;

        // 매월 고정 거래 처리
        if (description.contains('매월')) {
          // 기본 날짜는 transaction_num에서 가져옴
          final defaultDay = int.parse(row['transaction_num'].toString());

          // DateTime 객체를 직접 반환하는 함수로 변경
          final transactionDate = _getFixedTransactionDate(
              selectedYear,
              selectedMonthValue,
              defaultDay
          );

          // 효력 시작일 기반 날짜 조정 (필요한 경우)
          final adjustedDate = await _adjustDateBasedOnSettings(
              transactionDate,
              categoryId
          );

          // 선택된 날짜 범위에 포함되는지 확인 + 미래 날짜 제외
          if (adjustedDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              adjustedDate.isBefore(endDate.add(const Duration(days: 1)))) {

            // 해당 월에 적용할 설정 금액 가져오기
            final amount = await _getFixedTransactionAmount(categoryId, adjustedDate);

            fixedTransactions.add(TransactionWithCategory(
              id: row['id'] as int,
              userId: row['user_id'] as int,
              categoryId: categoryId,
              categoryName: row['category_name'] as String,
              categoryType: row['category_type'] as String,
              amount: amount,
              description: row['description'] as String,
              transactionDate: adjustedDate,
              transactionNum: row['transaction_num'].toString(),
              createdAt: DateTime.parse(row['created_at']),
              updatedAt: DateTime.parse(row['updated_at']),
            ));
          }
        }
        // 매주/매일 고정 거래 처리 (필요한 경우 추가 구현)
        // ...
      }

      // 모든 거래 통합하고 날짜순 정렬
      final allTransactions = [...variableTransactions, ...fixedTransactions]
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      debugPrint('전체 거래 내역 수: ${allTransactions.length}');
      return allTransactions;
    } catch (e) {
      debugPrint('전체 거래 내역 가져오기 오류: $e');
      return [];
    } finally {
      isRecentTransactionsLoading.value = false;
    }
  }

// 고정 거래의 해당 월 기본 날짜 계산 (Future<DateTime>이 아닌 DateTime 반환)
  DateTime _getFixedTransactionDate(int year, int month, int defaultDay) {
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    // 해당 월에 유효한 날짜인지 확인 (예: 30일까지 있는 달에 31일 거래 처리)
    try {
      return DateTime(year, month, defaultDay);
    } catch (e) {
      // 해당 월에 없는 날짜인 경우 말일로 조정
      return lastDayOfMonth;
    }
  }

// 설정에 따라 날짜 조정
  Future<DateTime> _adjustDateBasedOnSettings(DateTime baseDate, int categoryId) async {
    final db = await DBHelper().database;
    final firstDayOfMonth = DateTime(baseDate.year, baseDate.month, 1);

    // 카테고리에 대한 모든 설정 가져오기
    final List<Map<String, dynamic>> allSettings = await db.rawQuery('''
    SELECT * FROM fixed_transaction_setting
    WHERE category_id = ?
    ORDER BY effective_from ASC
  ''', [categoryId]);

    // 기본 날짜 유지
    int dayToUse = baseDate.day;

    // 모든 설정을 확인하여 처리 중인 달에 적용할 날짜 찾기
    for (var setting in allSettings) {
      final effectiveFrom = DateTime.parse(setting['effective_from']);

      // 효력 시작일이 현재 처리 중인 달 이전이거나 같은 달인 경우
      if (effectiveFrom.isBefore(firstDayOfMonth) ||
          (effectiveFrom.year == baseDate.year && effectiveFrom.month == baseDate.month)) {
        dayToUse = effectiveFrom.day;
      } else {
        // 효력 시작일이 현재 처리 중인 달보다 후라면 루프 종료
        break;
      }
    }

    // 해당 월에 유효한 날짜인지 확인
    try {
      return DateTime(baseDate.year, baseDate.month, dayToUse);
    } catch (e) {
      // 해당 월에 없는 날짜인 경우 말일로 조정
      return DateTime(baseDate.year, baseDate.month + 1, 0);
    }
  }

// 고정 거래의 해당 날짜 적용 금액 가져오기
  Future<double> _getFixedTransactionAmount(int categoryId, DateTime transactionDate) async {
    final db = await DBHelper().database;

    // 해당 카테고리와 날짜에 적용할 설정 가져오기
    final List<Map<String, dynamic>> settings = await db.rawQuery('''
    SELECT * FROM fixed_transaction_setting
    WHERE category_id = ? AND date(effective_from) <= date(?)
    ORDER BY effective_from DESC
    LIMIT 1
  ''', [categoryId, transactionDate.toIso8601String()]);

    // 설정이 없으면 원래 금액 가져오기
    if (settings.isEmpty) {
      final List<Map<String, dynamic>> originalTransaction = await db.rawQuery('''
      SELECT amount FROM transaction_record2
      WHERE category_id = ?
      LIMIT 1
    ''', [categoryId]);

      if (originalTransaction.isNotEmpty) {
        return originalTransaction.first['amount'] as double;
      }
      return 0.0;
    }

    // 설정이 있으면 해당 금액 반환
    return settings.first['amount'] as double;
  }


  // dashboard_controller.dart에 있는 메서드를 아래와 같이 수정

  Future<void> fetchRecentTransactions() async {
    isRecentTransactionsLoading.value = true;
    try {
      // 직접 getAllCurrentMonthTransactions 메서드를 호출하여 고정 거래를 포함한 모든 거래 가져오기
      // 이렇게 하면 가장 안정적으로 고정 거래를 포함할 수 있습니다
      final allTransactions = await getAllCurrentMonthTransactions();

      // 최대 10개까지만 가져오기 (화면에는 최대 8개만 표시됨)
      if (allTransactions.length > 10) {
        recentTransactions.value = allTransactions.sublist(0, 10);
      } else {
        recentTransactions.value = allTransactions;
      }

      debugPrint('조회된 최근 거래 내역 수: ${recentTransactions.value.length}');
    } catch (e) {
      debugPrint('최근 거래 내역 가져오기 오류: $e');
    } finally {
      isRecentTransactionsLoading.value = false;
    }
  }

  Future<void> fetchCategoryExpenses() async {
    isCategoryExpenseLoading.value = true;
    try {
      // 선택된 월의 카테고리별 지출 정보 가져오기
      final result = await getCategoryExpenses.execute(
          selectedMonth.value.year,
          selectedMonth.value.month
      );
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
      // 선택된 월의 카테고리별 수입 정보 가져오기
      final result = await getCategoryIncome.execute(
          selectedMonth.value.year,
          selectedMonth.value.month
      );
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
      // 선택된 월의 카테고리별 재테크 정보 가져오기
      final result = await getCategoryFinance.execute(
          selectedMonth.value.year,
          selectedMonth.value.month
      );
      categoryFinance.value = result;
      debugPrint('카테고리별 재테크 개수: ${result.length}');
    } catch (e) {
      debugPrint('카테고리별 재테크 가져오기 오류: $e');
    } finally {
      isCategoryFinanceLoading.value = false;
    }
  }

  Future<void> fetchAssets() async {
    isAssetsLoading.value = true;
    try {
      // 선택된 월에 대한 자산 정보 가져오기
      final result = await getAssets.execute(
          selectedMonth.value.year,
          selectedMonth.value.month
      );
      monthlyAssets.value = result;
      debugPrint('월간 재테크 정보 로드 완료: ${monthlyAssets.value}');
    } catch (e) {
      debugPrint('월간 재테크 정보 가져오기 오류: $e');
    } finally {
      isAssetsLoading.value = false;
    }
  }

  Future<void> fetchMonthlySummary() async {
    isLoading.value = true;
    try {
      // 선택된 월의 요약 정보를 가져오도록 수정
      final result = await getMonthlySummary.execute(
          selectedMonth.value.year,
          selectedMonth.value.month
      );

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
      // 설정된 범위만큼의 월별 지출 추이 데이터 가져오기 (최대 12개월)
      final result = await getMonthlyExpensesTrend.execute(12);
      allMonthlyExpenses.value = result;

      // 필터링된 데이터를 monthlyExpenses에 할당
      monthlyExpenses.value = filteredMonthlyExpenses;

      debugPrint('월별 지출 추이 데이터 로드 완료: 전체 ${allMonthlyExpenses.length}개, 필터링 ${monthlyExpenses.length}개, 압축 적용: ${isCompressedData.value}');
    } catch (e) {
      debugPrint('월별 지출 추이 가져오기 오류: $e');
    } finally {
      isExpenseTrendLoading.value = false;
    }
  }

  Future<List<TransactionWithCategory>> fetchTransactionsByDateRange(
      DateTime startDate, DateTime endDate, int limit) async {
    try {
      // 날짜를 정규화 (시간 정보 제거)
      final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      debugPrint('날짜 범위 거래 내역 조회: ${normalizedStartDate.toIso8601String()} ~ ${normalizedEndDate.toIso8601String()}');

      // 최대 건수를 제한하여 불러옴 (기본값: 500건)
      final maxLimit = limit > 0 ? limit : 500;

      // 이미 구현된 usecase 메서드를 호출
      final transactions = await getRecentTransactionsForRange.execute(
          normalizedStartDate,
          normalizedEndDate,
          maxLimit
      );

      debugPrint('조회된 거래 건수: ${transactions.length}건');
      return transactions;
    } catch (e) {
      debugPrint('날짜 범위 거래 내역 가져오기 오류: $e');
      return [];
    }
  }

  // 퍼센트 변화 부호 가져오기
  String getPercentageSign(double value) {
    return value >= 0 ? '+' : '';
  }
}
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

  Future<List<TransactionWithCategory>> getAllCurrentMonthTransactions() async {
    try {
      // Set loading state
      isRecentTransactionsLoading.value = true;

      // Get selected month date range
      final firstDayOfMonth = DateTime(selectedMonth.value.year, selectedMonth.value.month, 1);
      final lastDayOfMonth = DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0);
      final db = await DBHelper().database;

      // 변동 거래 내역
      final List<Map<String, dynamic>> variableResults = await db.rawQuery('''
      SELECT tr.*, c.name as category_name, c.type as category_type 
      FROM transaction_record tr
      JOIN category c ON tr.category_id = c.id
      WHERE date(substr(tr.transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      ORDER BY tr.transaction_date DESC
    ''', [
        firstDayOfMonth.toIso8601String().substring(0, 10),
        lastDayOfMonth.toIso8601String().substring(0, 10)
      ]);

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

      // 고정 거래 처리 (날짜 정보 업데이트)
      List<TransactionWithCategory> fixedTransactions = [];

      for (var row in fixedResults) {
        final categoryId = row['category_id'] as int;
        final description = row['description'] as String;

        if (description.contains('매월')) {
          // 기본 날짜는 transaction_num에서 가져옴
          final defaultDay = int.parse(row['transaction_num'].toString());

          // 카테고리에 대한 모든 설정 가져오기
          final List<Map<String, dynamic>> allSettings = await db.rawQuery('''
          SELECT * FROM fixed_transaction_setting
          WHERE category_id = ?
          ORDER BY effective_from ASC
        ''', [categoryId]);

          // 선택된 달에 적용할 날짜 결정
          int dayToUse = defaultDay;

          // 모든 설정을 확인하고 선택된 달에 적용할 설정 찾기
          for (var setting in allSettings) {
            final effectiveFrom = DateTime.parse(setting['effective_from']);

            // 효력 시작일이 선택된 달보다 이전이거나 같은 달인 경우
            if (effectiveFrom.isBefore(firstDayOfMonth) ||
                (effectiveFrom.year == firstDayOfMonth.year &&
                    effectiveFrom.month == firstDayOfMonth.month)) {
              dayToUse = effectiveFrom.day;
            } else {
              // 효력 시작일이 선택된 달보다 후라면 이전 설정 사용
              break;
            }
          }

          // 유효한 날짜 확인 (해당 월에 없는 날짜 처리)
          DateTime transactionDate;
          try {
            transactionDate = DateTime(selectedMonth.value.year, selectedMonth.value.month, dayToUse);
          } catch (e) {
            // 해당 월에 없는 날짜인 경우 마지막 날로 조정
            transactionDate = DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0);
          }

          // 금액 가져오기
          final List<Map<String, dynamic>> settings = await db.rawQuery('''
          SELECT * FROM fixed_transaction_setting
          WHERE category_id = ? AND date(effective_from) <= date(?)
          ORDER BY effective_from DESC
          LIMIT 1
        ''', [categoryId, lastDayOfMonth.toIso8601String()]);

          double amount = row['amount'] as double;
          if (settings.isNotEmpty) {
            amount = settings.first['amount'] as double;
          }

          fixedTransactions.add(TransactionWithCategory(
            id: row['id'] as int,
            userId: row['user_id'] as int,
            categoryId: categoryId,
            categoryName: row['category_name'] as String,
            categoryType: row['category_type'] as String,
            amount: amount,
            description: row['description'] as String,
            transactionDate: transactionDate, // 조정된 날짜 사용
            transactionNum: row['transaction_num'].toString(),
            createdAt: DateTime.parse(row['created_at']),
            updatedAt: DateTime.parse(row['updated_at']),
          ));
        }
        else if (description.contains('매주')) {
          // 매주 반복 거래
          int weekday = int.parse(row['transaction_num'].toString());
          List<DateTime> weekdaysInMonth = [];

          // 선택한 달의 모든 해당 요일 찾기
          int daysInMonth = lastDayOfMonth.day;
          for (int day = 1; day <= daysInMonth; day++) {
            final date = DateTime(selectedMonth.value.year, selectedMonth.value.month, day);
            if (date.weekday == weekday) {
              weekdaysInMonth.add(date);
            }
          }

          // 각 날짜에 대한 트랜잭션 생성
          for (final date in weekdaysInMonth) {
            // 금액 가져오기
            final List<Map<String, dynamic>> settings = await db.rawQuery('''
            SELECT * FROM fixed_transaction_setting
            WHERE category_id = ? AND date(effective_from) <= date(?)
            ORDER BY effective_from DESC
            LIMIT 1
          ''', [categoryId, date.toIso8601String()]);

            double amount = row['amount'] as double;
            if (settings.isNotEmpty) {
              amount = settings.first['amount'] as double;
            }

            fixedTransactions.add(TransactionWithCategory(
              id: row['id'] as int,
              userId: row['user_id'] as int,
              categoryId: categoryId,
              categoryName: row['category_name'] as String,
              categoryType: row['category_type'] as String,
              amount: amount,
              description: row['description'] as String,
              transactionDate: date,
              transactionNum: row['transaction_num'].toString(),
              createdAt: DateTime.parse(row['created_at']),
              updatedAt: DateTime.parse(row['updated_at']),
            ));
          }
        }
        else if (description.contains('매일')) {
          // 매일 반복 거래
          int daysInMonth = lastDayOfMonth.day;

          // 선택한 달의 매일에 대한 트랜잭션 생성
          for (int day = 1; day <= daysInMonth; day++) {
            final date = DateTime(selectedMonth.value.year, selectedMonth.value.month, day);

            // 금액 가져오기
            final List<Map<String, dynamic>> settings = await db.rawQuery('''
            SELECT * FROM fixed_transaction_setting
            WHERE category_id = ? AND date(effective_from) <= date(?)
            ORDER BY effective_from DESC
            LIMIT 1
          ''', [categoryId, date.toIso8601String()]);

            double amount = row['amount'] as double;
            if (settings.isNotEmpty) {
              amount = settings.first['amount'] as double;
            }

            fixedTransactions.add(TransactionWithCategory(
              id: row['id'] as int,
              userId: row['user_id'] as int,
              categoryId: categoryId,
              categoryName: row['category_name'] as String,
              categoryType: row['category_type'] as String,
              amount: amount,
              description: row['description'] as String,
              transactionDate: date,
              transactionNum: row['transaction_num'].toString(),
              createdAt: DateTime.parse(row['created_at']),
              updatedAt: DateTime.parse(row['updated_at']),
            ));
          }
        }
      }

      // 모든 거래 통합하고 날짜순 정렬
      final selectedMonthTransactions = [...variableTransactions, ...fixedTransactions]
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

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

  // 퍼센트 변화 부호 가져오기
  String getPercentageSign(double value) {
    return value >= 0 ? '+' : '';
  }
}
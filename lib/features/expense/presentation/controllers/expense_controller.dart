import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/db_helper.dart';
import '../../../../core/services/event_bus_service.dart';
import '../../data/models/category_model.dart';
import '../../domain/entities/budget_status.dart';
import '../../domain/usecases/add_expense.dart';
import '../../domain/usecases/get_budget_status.dart';
import '../../domain/usecases/get_variable_categories.dart';
import '../../domain/usecases/add_budget.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/update_budget.dart';
import '../../domain/usecases/update_category.dart';

class ExpenseController extends GetxController {
  final GetBudgetStatus getBudgetStatusUseCase;
  final GetVariableCategories getVariableCategoriesUseCase;
  final AddBudget addBudgetUseCase;
  final AddCategory addCategoryUseCase;
  final DeleteCategory deleteCategoryUseCase;
  final AddExpense addExpenseUseCase;
  final UpdateBudget updateBudgetUseCase;
  final UpdateCategory updateCategoryUseCase;

  ExpenseController({
    required this.getBudgetStatusUseCase,
    required this.getVariableCategoriesUseCase,
    required this.addBudgetUseCase,
    required this.addCategoryUseCase,
    required this.deleteCategoryUseCase,
    required this.addExpenseUseCase,
    required this.updateBudgetUseCase,
    required this.updateCategoryUseCase,
  });

  // 상태 변수
  final RxString selectedPeriod = DateFormat('yyyy-MM').format(DateTime.now()).obs;
  final RxList<BudgetStatus> budgetStatusList = <BudgetStatus>[].obs;
  final RxList<CategoryModel> variableCategories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxDouble totalBudget = 0.0.obs;
  final RxDouble totalSpent = 0.0.obs;
  final RxDouble totalRemaining = 0.0.obs;
  final RxDouble overallProgressPercentage = 0.0.obs;

  // 데이터 로드 상태 추적
  final RxBool dataInitialized = false.obs;

  // 사용자 ID (실제 앱에서는 인증에서 가져옴)
  final int userId = 1;

  // EventBusService 인스턴스
  late final EventBusService _eventBusService;

  @override
  void onInit() {
    super.onInit();

    // EventBusService 가져오기
    _eventBusService = Get.find<EventBusService>();

    // 트랜잭션 변경 이벤트 구독
    ever(_eventBusService.transactionChanged, (_) {
      debugPrint('거래 변경 이벤트 감지됨: 예산 데이터 새로고침');
      _loadData();
    });

    // 초기 데이터 로드
    _loadData();

    // 이후 현재 달에 예산이 없으면 이전 달에서 자동 복사 시도
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (budgetStatusList.isEmpty || budgetStatusList.every((status) => status.budgetAmount == 0)) {
        // 오늘이 월의 1-3일이면 자동 복사 시도 (월 초에만 자동 복사)
        final today = DateTime.now();
        if (today.day <= 3) {
          final copied = await copyBudgetFromPreviousMonth();
          if (copied) {
            Get.snackbar(
              '자동 예산 설정',
              '이전 달의 예산이 자동으로 복사되었습니다.',
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 3),
            );
          }
        }
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    // UI가 모두 준비된 후에 다시 한번 데이터 로드 시도
    if (!dataInitialized.value) {
      debugPrint('ExpenseController: onReady에서 데이터 다시 로드');
      _loadData();
    }
  }

  /// 이전 달의 예산을 현재 선택된 달로 복사
  Future<bool> copyBudgetFromPreviousMonth() async {
    try {
      // 현재 선택된 달
      final current = DateTime.parse('${selectedPeriod.value}-01');

      // 이전 달 계산
      final previousMonth = DateTime(current.year, current.month - 1, 1);
      final previousPeriod = DateFormat('yyyy-MM').format(previousMonth);

      // 이전 달 시작일과 종료일 계산
      final previousStartDate = DateTime(previousMonth.year, previousMonth.month, 1).toIso8601String();
      final previousEndDate = DateTime(previousMonth.year, previousMonth.month + 1, 0).toIso8601String();

      // 현재 달 시작일과 종료일 계산
      final currentStartDate = DateTime(current.year, current.month, 1).toIso8601String();
      final currentEndDate = DateTime(current.year, current.month + 1, 0).toIso8601String();

      debugPrint('이전 달 예산 데이터 복사: $previousPeriod -> ${selectedPeriod.value}');

      // 이전 달 예산 데이터 조회
      final db = await Get.find<DBHelper>().database;
      final previousBudgets = await db.query(
        'budget',
        where: 'user_id = ? AND start_date = ? AND end_date = ?',
        whereArgs: [userId, previousStartDate, previousEndDate],
      );

      if (previousBudgets.isEmpty) {
        debugPrint('복사할 이전 달 예산 데이터가 없습니다.');
        return false;
      }

      // 현재 달 기존 예산 데이터 확인 (중복 방지)
      final existingBudgets = await db.query(
        'budget',
        where: 'user_id = ? AND start_date = ? AND end_date = ?',
        whereArgs: [userId, currentStartDate, currentEndDate],
      );

      if (existingBudgets.isNotEmpty) {
        debugPrint('현재 달에 이미 예산 데이터가 있습니다. 복사를 건너뜁니다.');
        return false;
      }

      // 이전 달 예산을 현재 달로 복사
      final now = DateTime.now().toIso8601String();
      int copiedCount = 0;

      for (var budget in previousBudgets) {
        await db.insert('budget', {
          'user_id': budget['user_id'],
          'category_id': budget['category_id'],
          'amount': budget['amount'],
          'start_date': currentStartDate,
          'end_date': currentEndDate,
          'created_at': now,
          'updated_at': now,
        });
        copiedCount++;
      }

      debugPrint('$copiedCount개의 예산이 성공적으로 복사되었습니다.');

      // 예산 상태 다시 불러오기
      await fetchBudgetStatus();

      // 이벤트 버스를 통해 변경 알림
      _eventBusService.emitTransactionChanged();

      return true;
    } catch (e) {
      debugPrint('이전 달 예산 복사 중 오류: $e');
      return false;
    }
  }

  // 모든 데이터 로드 메서드
  Future<void> _loadData() async {
    debugPrint('ExpenseController: 모든 데이터 로드 시작');
    await fetchBudgetStatus();
    await fetchVariableCategories();
    dataInitialized.value = true;
    debugPrint('ExpenseController: 모든 데이터 로드 완료');
  }

  Future<void> fetchBudgetStatus() async {
    isLoading.value = true;
    debugPrint('ExpenseController: 예산 상태 가져오기 시작 - ${selectedPeriod.value}');

    try {
      final result = await getBudgetStatusUseCase(userId, selectedPeriod.value);

      // 데이터 변수에 할당
      budgetStatusList.assignAll(result);

      // 목록이 비어있는지 확인 (디버깅)
      debugPrint('ExpenseController: 예산 상태 데이터 로드 - ${result.length}개 항목');

      // 총 값 계산
      double budget = 0.0;
      double spent = 0.0;

      for (var status in result) {
        budget += status.budgetAmount;
        spent += status.spentAmount;
      }

      totalBudget.value = budget;
      totalSpent.value = spent;
      totalRemaining.value = budget + spent;
      overallProgressPercentage.value = budget > 0 ? (spent.abs() / budget) * 100 : 0.0;
      if (overallProgressPercentage.value > 100) {
        overallProgressPercentage.value = 100;
      }

      // 명시적으로 UI 업데이트 트리거
      budgetStatusList.refresh();
      update();

      // 약간의 지연 후 다시 한번 트리거
      Future.delayed(const Duration(milliseconds: 100), () {
        budgetStatusList.refresh();
        update();
      });

    } catch (e) {
      debugPrint('예산 상태 가져오는 중 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
    fetchBudgetStatus();
  }

  void previousMonth() {
    final current = DateTime.parse('${selectedPeriod.value}-01');
    final previous = DateTime(current.year, current.month - 1, 1);
    selectedPeriod.value = DateFormat('yyyy-MM').format(previous);
    fetchBudgetStatus();
  }

  void nextMonth() {
    final current = DateTime.parse('${selectedPeriod.value}-01');
    final next = DateTime(current.year, current.month + 1, 1);
    selectedPeriod.value = DateFormat('yyyy-MM').format(next);
    fetchBudgetStatus();
  }

  Future<void> fetchVariableCategories() async {
    try {
      final result = await getVariableCategoriesUseCase();
      variableCategories.assignAll(result);
      variableCategories.refresh();
      debugPrint('ExpenseController: 변동 카테고리 데이터 로드 - ${result.length}개 항목');
    } catch (e) {
      debugPrint('변동 지출 카테고리 가져오는 중 오류: $e');
    }
  }

  Future<bool> addBudget({
    required int categoryId,
    required double amount,
  }) async {
    try {
      // 기간에서 연도와 월 추출 (형식: YYYY-MM)
      final year = int.parse(selectedPeriod.value.split('-')[0]);
      final month = int.parse(selectedPeriod.value.split('-')[1]);

      // 해당 월의 시작일과 종료일 계산
      final startDate = DateTime(year, month, 1).toIso8601String();
      final endDate = DateTime(year, month + 1, 0).toIso8601String();

      final result = await addBudgetUseCase(
        userId: userId,
        categoryId: categoryId,
        amount: amount,
        periodStart: startDate,
        periodEnd: endDate,
      );

      if (result) {
        // 예산 목록 다시 불러오기
        await fetchBudgetStatus();

        // 이벤트 버스를 통해 변경 알림
        _eventBusService.emitTransactionChanged();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('예산 추가 중 오류: $e');
      return false;
    }
  }

  Future<CategoryModel?> addCategory({
    required String name,
  }) async {
    try {
      if (name.trim().isEmpty) {
        return null;
      }

      final category = await addCategoryUseCase(
        name: name.trim(),
        type: 'EXPENSE',
        isFixed: 0,
      );

      if (category != null) {
        // First fetch the categories
        await fetchVariableCategories();

        // Then also fetch budget status to ensure the UI shows the new category with its budget
        await fetchBudgetStatus();

        // Emit event to notify other screens
        _eventBusService.emitTransactionChanged();
      }

      return category;
    } catch (e) {
      debugPrint('카테고리 추가 중 오류: $e');
      return null;
    }
  }

  Future<bool> deleteCategory(int categoryId) async {
    try {
      final selectedCategories = variableCategories.where((c) => c.id == categoryId).toList();
      if (selectedCategories.isEmpty) {
        return false;
      }

      // DB에서 카테고리 삭제
      final result = await deleteCategoryUseCase(categoryId);

      if (result) {
        // 예산 상태 다시 불러오기
        await fetchBudgetStatus();

        // 변동 카테고리 목록도 다시 불러오기 (이 부분이 누락되어 있었음)
        await fetchVariableCategories();
        return true;
      } else {
        // 삭제 실패 시 카테고리 목록 복원
        await fetchVariableCategories();
        return false;
      }
    } catch (e) {
      debugPrint('카테고리 삭제 중 오류: $e');
      // 오류 발생 시 카테고리 목록 복원
      await fetchVariableCategories();
      return false;
    }
  }

  Future<bool> addExpense({
    required int categoryId,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    try {
      // ISO 8601 형식으로 날짜 변환
      final transactionDate = date.toIso8601String();

      final result = await addExpenseUseCase(
        userId: userId,
        categoryId: categoryId,
        amount: amount,
        description: description,
        transactionDate: transactionDate,
      );

      if (result) {
        // 예산 상태 다시 불러오기 (지출이 추가되었으므로 업데이트 필요)
        await fetchBudgetStatus();

        // 이벤트 버스를 통해 변경 알림
        _eventBusService.emitTransactionChanged();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('지출 추가 중 오류: $e');
      return false;
    }
  }

  Future<bool> updateBudget({
    required int categoryId,
    required double amount,
  }) async {
    try {
      // 기간에서 연도와 월 추출 (형식: YYYY-MM)
      final year = int.parse(selectedPeriod.value.split('-')[0]);
      final month = int.parse(selectedPeriod.value.split('-')[1]);

      // 해당 월의 시작일과 종료일 계산
      final startDate = DateTime(year, month, 1).toIso8601String();
      final endDate = DateTime(year, month + 1, 0).toIso8601String();

      final result = await updateBudgetUseCase(
        userId: userId,
        categoryId: categoryId,
        amount: amount,
        periodStart: startDate,
        periodEnd: endDate,
      );

      if (result) {
        // 예산 목록 다시 불러오기
        await fetchBudgetStatus();

        // 이벤트 버스를 통해 변경 알림
        _eventBusService.emitTransactionChanged();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('예산 업데이트 중 오류: $e');
      return false;
    }
  }

  Future<bool> updateCategory({
    required int categoryId,
    required String name,
  }) async {
    try {
      if (name.trim().isEmpty) {
        return false;
      }

      final result = await updateCategoryUseCase(
        categoryId: categoryId,
        name: name.trim(),
      );

      if (result) {
        // 카테고리 및 예산 목록 다시 불러오기
        await fetchVariableCategories();
        await fetchBudgetStatus();

        // 이벤트 버스를 통해 변경 알림
        _eventBusService.emitTransactionChanged();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('카테고리 업데이트 중 오류: $e');
      return false;
    }
  }
}
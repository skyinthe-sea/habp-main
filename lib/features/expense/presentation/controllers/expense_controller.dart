import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/event_bus_service.dart';
import '../../data/models/category_model.dart';
import '../../domain/entities/budget_status.dart';
import '../../domain/usecases/add_expense.dart';
import '../../domain/usecases/get_budget_status.dart';
import '../../domain/usecases/get_variable_categories.dart';
import '../../domain/usecases/add_budget.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/delete_category.dart';

class ExpenseController extends GetxController {
  final GetBudgetStatus getBudgetStatusUseCase;
  final GetVariableCategories getVariableCategoriesUseCase;
  final AddBudget addBudgetUseCase;
  final AddCategory addCategoryUseCase;
  final DeleteCategory deleteCategoryUseCase;
  final AddExpense addExpenseUseCase;

  ExpenseController({
    required this.getBudgetStatusUseCase,
    required this.getVariableCategoriesUseCase,
    required this.addBudgetUseCase,
    required this.addCategoryUseCase,
    required this.deleteCategoryUseCase,
    required this.addExpenseUseCase,
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

  // 사용자 ID (실제 앱에서는 인증에서 가져옴)
  final int userId = 1;

  @override
  void onInit() {
    super.onInit();
    fetchBudgetStatus();
    fetchVariableCategories();
  }

  Future<void> fetchBudgetStatus() async {
    isLoading.value = true;
    try {
      final result = await getBudgetStatusUseCase(userId, selectedPeriod.value);
      budgetStatusList.value = result;

      // 총 값 계산
      double budget = 0.0;
      double spent = 0.0;

      for (var status in result) {
        budget += status.budgetAmount;
        spent += status.spentAmount;
      }

      totalBudget.value = budget;
      totalSpent.value = spent;
      totalRemaining.value = budget - spent;
      overallProgressPercentage.value = budget > 0 ? (spent / budget) * 100 : 0.0;
      if (overallProgressPercentage.value > 100) {
        overallProgressPercentage.value = 100;
      }
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
      variableCategories.value = result;
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
        // 카테고리 목록 다시 불러오기
        await fetchVariableCategories();
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

      // UI에서 즉시 카테고리 제거 (애니메이션 효과를 위해)
      final tempCategories = variableCategories.toList();
      final categoryIndex = tempCategories.indexWhere((c) => c.id == categoryId);
      if (categoryIndex != -1) {
        tempCategories.removeAt(categoryIndex);
        variableCategories.value = tempCategories;
      }

      // DB에서 카테고리 삭제
      final result = await deleteCategoryUseCase(categoryId);

      if (result) {
        // 예산 상태 다시 불러오기
        await fetchBudgetStatus();
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
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('지출 추가 중 오류: $e');
      return false;
    }
  }
}
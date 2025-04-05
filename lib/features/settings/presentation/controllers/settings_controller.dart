// lib/features/settings/presentation/controllers/settings_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/event_bus_service.dart';
import '../../data/datasources/fixed_transaction_local_data_source.dart';
import '../../domain/repositories/fixed_transaction_repository.dart';
import '../../domain/usecases/get_fixed_categories_by_type.dart';
import '../../domain/usecases/add_fixed_transaction_setting.dart';

class SettingsController extends GetxController {
  final GetFixedCategoriesByType getFixedCategoriesByType;
  final AddFixedTransactionSetting addFixedTransactionSetting;

  SettingsController({
    required this.getFixedCategoriesByType,
    required this.addFixedTransactionSetting,
  });

  // 상태 변수
  final RxBool isLoadingIncome = false.obs;
  final RxBool isLoadingExpense = false.obs;
  final RxBool isLoadingFinance = false.obs;

  final RxList<CategoryWithSettings> incomeCategories = <CategoryWithSettings>[].obs;
  final RxList<CategoryWithSettings> expenseCategories = <CategoryWithSettings>[].obs;
  final RxList<CategoryWithSettings> financeCategories = <CategoryWithSettings>[].obs;

  // EventBusService 인스턴스
  late final EventBusService _eventBusService;

  @override
  void onInit() {
    super.onInit();

    // EventBusService 가져오기
    _eventBusService = Get.find<EventBusService>();

    // 초기 데이터 로드
    loadFixedIncomeCategories();
    loadFixedExpenseCategories();
    loadFixedFinanceCategories();
  }

  // 고정 소득 카테고리 로드
  Future<void> loadFixedIncomeCategories() async {
    isLoadingIncome.value = true;
    try {
      final result = await getFixedCategoriesByType.execute('INCOME');
      incomeCategories.value = result;
      debugPrint('고정 소득 카테고리 ${result.length}개 로드됨');
    } catch (e) {
      debugPrint('고정 소득 카테고리 로드 오류: $e');
    } finally {
      isLoadingIncome.value = false;
    }
  }

  // 고정 지출 카테고리 로드
  Future<void> loadFixedExpenseCategories() async {
    isLoadingExpense.value = true;
    try {
      final result = await getFixedCategoriesByType.execute('EXPENSE');
      expenseCategories.value = result;
      debugPrint('고정 지출 카테고리 ${result.length}개 로드됨');
    } catch (e) {
      debugPrint('고정 지출 카테고리 로드 오류: $e');
    } finally {
      isLoadingExpense.value = false;
    }
  }

  // 고정 재테크 카테고리 로드
  Future<void> loadFixedFinanceCategories() async {
    isLoadingFinance.value = true;
    try {
      final result = await getFixedCategoriesByType.execute('FINANCE');
      financeCategories.value = result;
      debugPrint('고정 재테크 카테고리 ${result.length}개 로드됨');
    } catch (e) {
      debugPrint('고정 재테크 카테고리 로드 오류: $e');
    } finally {
      isLoadingFinance.value = false;
    }
  }

  // 고정 거래 설정 추가/업데이트
  Future<bool> updateFixedTransactionSetting({
    required int categoryId,
    required double amount,
    required DateTime effectiveFrom,
  }) async {
    try {
      final setting = FixedTransactionSetting(
        categoryId: categoryId,
        amount: amount,
        effectiveFrom: effectiveFrom,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await addFixedTransactionSetting.execute(setting);

      if (result) {
        // 관련 모든 데이터 다시 로드
        await loadFixedIncomeCategories();
        await loadFixedExpenseCategories();
        await loadFixedFinanceCategories();

        // 이벤트 발행하여 다른 컨트롤러에게 알림
        _eventBusService.emitTransactionChanged();

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('고정 거래 설정 업데이트 오류: $e');
      return false;
    }
  }

  // 가장 최근 설정 금액 가져오기
  double? getLatestSettingAmount(int categoryId) {
    // 모든 카테고리 목록에서 검색
    for (final categories in [incomeCategories, expenseCategories, financeCategories]) {
      for (final category in categories) {
        if (category.id == categoryId && category.settings.isNotEmpty) {
          // 최신 설정 가져오기 (이미 날짜 기준 내림차순 정렬됨)
          return category.settings.first.amount;
        }
      }
    }

    return null;
  }

  // 카테고리 이름으로 ID 찾기
  int? getCategoryIdByName(String categoryName) {
    // 모든 카테고리 목록에서 검색
    for (final categories in [incomeCategories, expenseCategories, financeCategories]) {
      for (final category in categories) {
        if (category.name == categoryName) {
          return category.id;
        }
      }
    }

    return null;
  }

  // 카테고리 ID로 카테고리 찾기
  CategoryWithSettings? getCategoryById(int categoryId) {
    // 모든 카테고리 목록에서 검색
    for (final categories in [incomeCategories, expenseCategories, financeCategories]) {
      for (final category in categories) {
        if (category.id == categoryId) {
          return category;
        }
      }
    }

    return null;
  }
}
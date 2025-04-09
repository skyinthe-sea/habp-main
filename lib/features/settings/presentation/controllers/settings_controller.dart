// lib/features/settings/presentation/controllers/settings_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/event_bus_service.dart';
import '../../../../core/database/db_helper.dart';
import '../../data/datasources/fixed_transaction_local_data_source.dart';
import '../../domain/repositories/fixed_transaction_repository.dart';
import '../../domain/usecases/get_fixed_categories_by_type.dart';
import '../../domain/usecases/add_fixed_transaction_setting.dart';
import '../../domain/usecases/create_fixed_transaction.dart';
import '../../domain/usecases/delete_fixed_transaction.dart';

class SettingsController extends GetxController {
  final GetFixedCategoriesByType getFixedCategoriesByType;
  final AddFixedTransactionSetting addFixedTransactionSetting;
  final CreateFixedTransaction createFixedTransaction;
  final DeleteFixedTransaction deleteFixedTransaction;

  SettingsController({
    required this.getFixedCategoriesByType,
    required this.addFixedTransactionSetting,
    required this.createFixedTransaction,
    required this.deleteFixedTransaction,
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

  // 새 고정 거래 생성
  Future<bool> createNewFixedTransaction({
    required String name,
    required String type,
    required double amount,
    required DateTime effectiveFrom,
  }) async {
    try {
      // 1. CreateFixedTransaction 유스케이스 실행
      final success = await createFixedTransaction.execute(
        name: name,
        type: type,
        amount: amount,
        effectiveFrom: effectiveFrom,
      );

      if (!success) {
        debugPrint('카테고리 생성 실패');
        return false;
      }

      // 2. 데이터베이스에서 해당 카테고리 ID 조회
      final dbHelper = DBHelper();
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> categories = await db.query(
        'category',
        where: 'name = ? AND type = ? AND is_deleted = ?',
        whereArgs: [name, type, 0],
      );

      if (categories.isEmpty) {
        debugPrint('생성된 카테고리를 찾을 수 없음');
        return false;
      }

      final categoryId = categories.first['id'] as int;

      // 3. transaction_record2 테이블에 데이터 생성
      final now = DateTime.now().toIso8601String();

      // 설명 생성 (매월 고정 거래로 설정)
      final description = '매월 ${_getCategoryDescription(type)}';

      // transaction_num에 일자 저장 (매월 고정 거래 표시용)
      final transactionNum = '${effectiveFrom.day}';

      // 사용자 ID (기본값 1로 설정, 필요시 변경)
      const userId = 1;

      // transaction_record2 테이블에 데이터 삽입
      await db.insert('transaction_record2', {
        'user_id': userId,
        'category_id': categoryId,
        'amount': type == 'EXPENSE' || type == 'FINANCE' ? -amount : amount, // 지출/재테크는 음수, 소득은 양수
        'description': description,
        'transaction_date': DateTime(effectiveFrom.year, effectiveFrom.month, effectiveFrom.day).toIso8601String(),
        'transaction_num': transactionNum,
        'created_at': now,
        'updated_at': now,
      });

      // 4. 관련 모든 데이터 다시 로드
      await loadFixedIncomeCategories();
      await loadFixedExpenseCategories();
      await loadFixedFinanceCategories();

      // 5. 이벤트 발행하여 다른 컨트롤러에게 알림
      _eventBusService.emitTransactionChanged();

      return true;
    } catch (e) {
      debugPrint('고정 거래 생성 오류: $e');
      return false;
    }
  }

  // 고정 거래 삭제
  Future<bool> deleteFixedTransactionCategory(int categoryId) async {
    try {
      // DeleteFixedTransaction 유스케이스 실행
      final success = await deleteFixedTransaction.execute(categoryId);

      if (success) {
        // 관련 모든 데이터 다시 로드
        await loadFixedIncomeCategories();
        await loadFixedExpenseCategories();
        await loadFixedFinanceCategories();

        // 이벤트 발행하여 다른 컨트롤러에게 알림
        _eventBusService.emitTransactionChanged();
      }

      return success;
    } catch (e) {
      debugPrint('고정 거래 삭제 오류: $e');
      return false;
    }
  }

  // 고정 거래 설정 추가/업데이트 - 수정된 버전
  Future<bool> updateFixedTransactionSetting({
    required int categoryId,
    required double amount,
    required DateTime effectiveFrom,
  }) async {
    try {
      final dbHelper = DBHelper();
      final db = await dbHelper.database;

      // 1. fixed_transaction_setting 테이블에 새 설정 추가
      final setting = FixedTransactionSetting(
        categoryId: categoryId,
        amount: amount,
        effectiveFrom: effectiveFrom,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await addFixedTransactionSetting.execute(setting);

      // 2. transaction_record2 테이블에 데이터가 있는지 확인
      final List<Map<String, dynamic>> existingTransactions = await db.query(
        'transaction_record2',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );

      // 3. 해당 카테고리의 정보 가져오기
      final List<Map<String, dynamic>> categoryData = await db.query(
        'category',
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      if (categoryData.isEmpty) {
        debugPrint('카테고리 정보를 찾을 수 없음: $categoryId');
        return false;
      }

      final categoryType = categoryData.first['type'] as String;

      // 4. transaction_record2 데이터가 없으면 새로 생성
      if (existingTransactions.isEmpty) {
        debugPrint('카테고리 $categoryId에 대한 transaction_record2 데이터가 없어 생성합니다.');

        // 현재 날짜 및 시간
        final now = DateTime.now().toIso8601String();

        // 설명 생성 (매월 고정 거래로 설정)
        final description = '매월 ${_getCategoryDescription(categoryType)}';

        // transaction_num에 일자 저장 (매월 고정 거래 표시용)
        final transactionNum = '${effectiveFrom.day}';

        // 사용자 ID (기본값 1로 설정, 필요시 변경)
        const userId = 1;

        // transaction_record2 테이블에 데이터 삽입
        await db.insert('transaction_record2', {
          'user_id': userId,
          'category_id': categoryId,
          'amount': categoryType == 'EXPENSE' || categoryType == 'FINANCE' ? -amount : amount, // 지출/재테크는 음수, 소득은 양수
          'description': description,
          'transaction_date': DateTime(effectiveFrom.year, effectiveFrom.month, effectiveFrom.day).toIso8601String(),
          'transaction_num': transactionNum,
          'created_at': now,
          'updated_at': now,
        });

        debugPrint('새로운 고정 거래 생성 완료: 카테고리 $categoryId, 금액 $amount, 날짜 ${effectiveFrom.day}일');
      } else {
        debugPrint('카테고리 $categoryId에 대한 transaction_record2 데이터가 이미 존재합니다. 새 설정만 적용됩니다.');
      }

      // 관련 모든 데이터 다시 로드
      await loadFixedIncomeCategories();
      await loadFixedExpenseCategories();
      await loadFixedFinanceCategories();

      // 이벤트 발행하여 다른 컨트롤러에게 알림
      _eventBusService.emitTransactionChanged();

      return true;
    } catch (e) {
      debugPrint('고정 거래 설정 업데이트 오류: $e');
      return false;
    }
  }

  // 카테고리 타입에 따른 설명 생성 도우미 함수
  String _getCategoryDescription(String categoryType) {
    switch (categoryType) {
      case 'INCOME':
        return '소득';
      case 'EXPENSE':
        return '지출';
      case 'FINANCE':
        return '재테크';
      default:
        return '거래';
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
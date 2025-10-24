// lib/features/quick_add/presentation/controllers/quick_add_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/database/db_helper.dart';
import '../../../../core/services/event_bus_service.dart';
import '../models/quick_add_transaction.dart';
import '../services/autocomplete_service.dart';

/// Controller for the quick add transaction flow
/// Manages state and database operations across multiple dialogs
class QuickAddController extends GetxController {
  // Database helper
  final DBHelper _dbHelper = DBHelper();

  // Current transaction being created
  final Rx<QuickAddTransaction> transaction = QuickAddTransaction().obs;

  // Category list for the selected type
  final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;

  // Loading state
  final RxBool isLoading = false.obs;

  // Success state (for showing success messages/animations)
  final RxBool isSuccess = false.obs;

  // User ID - in a real app, this would come from auth
  final int userId = 1;

  late final EventBusService _eventBusService;

  // 자동완성 서비스
  final AutocompleteService autocompleteService = AutocompleteService();

  @override
  void onInit() {
    super.onInit();

    // EventBusService 가져오기
    _eventBusService = Get.find<EventBusService>();
  }

  /// Reset the transaction to default values
  void resetTransaction() {
    transaction.value = QuickAddTransaction();
  }

  /// Set the category type (INCOME, EXPENSE, FINANCE)
  void setCategoryType(String type) {
    transaction.update((val) {
      val?.categoryType = type;
    });
    // Load categories for this type
    loadCategoriesForType(type);
  }

  /// Set the selected category
  void setCategory(int categoryId, String categoryName) {
    transaction.update((val) {
      val?.categoryId = categoryId;
      val?.categoryName = categoryName;
    });
  }

  /// Set the transaction date
  void setTransactionDate(DateTime date) {
    transaction.update((val) {
      val?.transactionDate = date;
    });
  }

  /// Set the transaction amount
  void setAmount(double amount) {
    transaction.update((val) {
      val?.amount = amount;
    });
  }

  /// Set the transaction description
  void setDescription(String description) {
    transaction.update((val) {
      val?.description = description;
    });
  }

  /// Set the emotion tag
  void setEmotionTag(String? emotionTag) {
    transaction.update((val) {
      val?.emotionTag = emotionTag;
    });
  }

  /// Set the image path (영수증/사진)
  void setImagePath(String? imagePath) {
    transaction.update((val) {
      val?.imagePath = imagePath;
    });
  }

  /// Load categories from database based on type
  Future<void> loadCategoriesForType(String type) async {
    isLoading.value = true;

    try {
      final db = await _dbHelper.database;

      // Get categories where is_fixed is 0 (variable categories) AND is_deleted is 0
      final result = await db.query('category',
          where: 'type = ? AND is_fixed = ? AND is_deleted = ?',
          whereArgs: [type, 0, 0],
          orderBy: 'name ASC');

      categories.value = result;
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Save the transaction to the database
  Future<bool> saveTransaction() async {
    isLoading.value = true;

    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();

      // Determine sign based on type (negative for expenses and finance)
      double amount = transaction.value.amount;
      if (transaction.value.categoryType == 'EXPENSE' || transaction.value.categoryType == 'FINANCE') {
        amount = -amount.abs(); // Ensure negative for expenses and finance
      } else {
        amount = amount.abs(); // Ensure positive for income
      }

      // Transaction number - can be used for reference, currently just timestamp
      final transactionNum = DateTime.now().millisecondsSinceEpoch.toString();

      debugPrint('💾 [QuickAddController] Saving transaction...');
      debugPrint('💾 [QuickAddController] imagePath: ${transaction.value.imagePath}');
      debugPrint('💾 [QuickAddController] description: ${transaction.value.description}');

      await db.insert('transaction_record', {
        'user_id': userId,
        'category_id': transaction.value.categoryId,
        'amount': amount,
        'description': transaction.value.description.isEmpty
            ? transaction.value.categoryName
            : transaction.value.description,
        'transaction_date': transaction.value.transactionDate.toIso8601String(),
        'transaction_num': transactionNum,
        'emotion_tag': transaction.value.emotionTag,
        'image_path': transaction.value.imagePath,
        'created_at': now,
        'updated_at': now,
      });

      debugPrint('✅ [QuickAddController] Transaction saved successfully');

      isSuccess.value = true;
      Get.find<EventBusService>().emitTransactionChanged();

      // 설명 저장 (자동완성용)
      if (transaction.value.description.isNotEmpty) {
        await autocompleteService.saveDescription(transaction.value.description);
      }

      _eventBusService.emitTransactionChanged();
      return true;
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if the current transaction is valid and can be saved
  bool isTransactionValid() {
    return transaction.value.categoryId != null && transaction.value.amount > 0;
  }

  // 카테고리 추가 메서드
  Future<CategoryResult> addCategory({
    required String name,
    required String type,
    required int isFixed,
  }) async {
    isLoading.value = true;

    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();

      // 이미 동일한 이름의 활성 카테고리가 있는지 확인 (삭제된 것은 제외)
      final existingActiveCategory = await db.query(
        'category',
        where: 'name = ? AND type = ? AND is_deleted = ?',
        whereArgs: [name, type, 0],
        limit: 1,
      );

      if (existingActiveCategory.isNotEmpty) {
        final category = existingActiveCategory.first;
        final isFixedCategory = category['is_fixed'] as int;

        // 고정 카테고리인 경우 (is_fixed = 1)
        if (isFixedCategory == 1) {
          return CategoryResult(
            status: CategoryStatus.existingFixed,
            category: CategoryModel(
              id: category['id'] as int,
              name: category['name'] as String,
              type: category['type'] as String,
              isFixed: isFixedCategory,
            ),
          );
        }

        // 이미 존재하는 변동 카테고리인 경우
        return CategoryResult(
          status: CategoryStatus.existingVariable,
          category: CategoryModel(
            id: category['id'] as int,
            name: category['name'] as String,
            type: category['type'] as String,
            isFixed: isFixedCategory,
          ),
        );
      }

      // 삭제된 카테고리가 있는지 확인
      final existingDeletedCategory = await db.query(
        'category',
        where: 'name = ? AND type = ? AND is_deleted = ?',
        whereArgs: [name, type, 1],
        limit: 1,
      );

      // 삭제된 카테고리가 있으면 재활성화
      if (existingDeletedCategory.isNotEmpty) {
        final categoryId = existingDeletedCategory.first['id'] as int;
        
        await db.update(
          'category',
          {
            'is_deleted': 0,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [categoryId],
        );

        // 카테고리 목록 갱신
        await loadCategoriesForType(type);
        _eventBusService.emitTransactionChanged();

        return CategoryResult(
          status: CategoryStatus.created,
          category: CategoryModel(
            id: categoryId,
            name: name,
            type: type,
            isFixed: isFixed,
          ),
        );
      }

      // 새 카테고리 추가
      final id = await db.insert('category', {
        'name': name,
        'type': type,
        'is_fixed': isFixed,
        'created_at': now,
        'updated_at': now,
      });

      // 카테고리 목록 갱신
      await loadCategoriesForType(type);
      _eventBusService.emitTransactionChanged();

      return CategoryResult(
        status: CategoryStatus.created,
        category: CategoryModel(
          id: id,
          name: name,
          type: type,
          isFixed: isFixed,
        ),
      );
    } catch (e) {
      debugPrint('카테고리 추가 중 오류: $e');
      return CategoryResult(status: CategoryStatus.error);
    } finally {
      isLoading.value = false;
    }
  }

  /// 카테고리 수정 메서드
  Future<bool> updateCategory(int categoryId, String newName) async {
    isLoading.value = true;

    try {
      final db = await _dbHelper.database;

      // 카테고리 확인
      final category = await db.query(
        'category',
        where: 'id = ?',
        whereArgs: [categoryId],
        limit: 1,
      );

      if (category.isEmpty) {
        return false;
      }

      final categoryData = category.first;
      final categoryType = categoryData['type'] as String;

      // 이미 동일한 이름의 카테고리가 있는지 확인 (자기 자신 제외)
      final existingCategory = await db.query(
        'category',
        where: 'name = ? AND type = ? AND id != ? AND is_deleted = 0',
        whereArgs: [newName, categoryType, categoryId],
        limit: 1,
      );

      if (existingCategory.isNotEmpty) {
        final ThemeController themeController = Get.find<ThemeController>();
        Get.snackbar(
          '오류',
          '이미 동일한 이름의 카테고리가 존재합니다.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }

      // 카테고리 업데이트
      await db.update(
        'category',
        {
          'name': newName,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      // 카테고리 목록 갱신
      await loadCategoriesForType(categoryType);
      _eventBusService.emitTransactionChanged();
      return true;
    } catch (e) {
      debugPrint('카테고리 수정 중 오류: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 카테고리 소프트 삭제 메서드 (카테고리는 플래그 변경, 예산은 실제 삭제)
  Future<bool> deleteCategory(int categoryId) async {
    isLoading.value = true;

    try {
      final db = await _dbHelper.database;

      // 고정 카테고리인지 확인 (고정 카테고리는 삭제 불가)
      final category = await db.query(
        'category',
        where: 'id = ?',
        whereArgs: [categoryId],
        limit: 1,
      );

      if (category.isEmpty) {
        return false;
      }

      // is_fixed가 1이면 고정 카테고리로 삭제 불가
      if (category.first['is_fixed'] == 1) {
        debugPrint('고정 카테고리는 삭제할 수 없습니다.');
        return false;
      }

      // 트랜잭션으로 처리하여 원자성 보장
      await db.transaction((txn) async {
        // 1. 해당 카테고리의 예산 정보 실제 삭제
        await txn.delete(
          'budget',
          where: 'category_id = ?',
          whereArgs: [categoryId],
        );

        // 2. 카테고리 소프트 삭제 (is_deleted = 1로 업데이트)
        await txn.update(
          'category',
          {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [categoryId],
        );
      });

      // 카테고리 목록 갱신
      await loadCategoriesForType(transaction.value.categoryType);
      _eventBusService.emitTransactionChanged();
      return true;
    } catch (e) {
      debugPrint('카테고리 삭제 중 오류: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

// 카테고리 상태 열거형 추가
enum CategoryStatus {
  created,          // 새로 생성됨
  existingVariable, // 기존 변동 카테고리와 동일
  existingFixed,    // 기존 고정 카테고리와 동일
  error,            // 오류 발생
}

// 카테고리 결과 클래스 추가
class CategoryResult {
  final CategoryStatus status;
  final CategoryModel? category;

  CategoryResult({
    required this.status,
    this.category,
  });
}

// 카테고리 모델 클래스 (필요한 경우)
class CategoryModel {
  final int id;
  final String name;
  final String type;
  final int isFixed;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.isFixed,
  });
}
// lib/features/quick_add/presentation/controllers/quick_add_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/database/db_helper.dart';
import '../../../../core/services/event_bus_service.dart';
import '../models/quick_add_transaction.dart';

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

  /// Load categories from database based on type
  Future<void> loadCategoriesForType(String type) async {
    isLoading.value = true;

    try {
      final db = await _dbHelper.database;

      // Get categories where is_fixed is 0 (variable categories)
      final result = await db.query(
          'category',
          where: 'type = ? AND is_fixed = ?',
          whereArgs: [type, 0],
          orderBy: 'name ASC'
      );

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

      // Determine sign based on type (negative for expenses)
      double amount = transaction.value.amount;
      if (transaction.value.categoryType == 'EXPENSE') {
        amount = -amount.abs(); // Ensure negative for expenses
      } else {
        amount = amount.abs(); // Ensure positive for income & finance
      }

      // Transaction number - can be used for reference, currently just timestamp
      final transactionNum = DateTime.now().millisecondsSinceEpoch.toString();

      await db.insert('transaction_record', {
        'user_id': userId,
        'category_id': transaction.value.categoryId,
        'amount': amount,
        'description': transaction.value.description.isEmpty ?
        transaction.value.categoryName : transaction.value.description,
        'transaction_date': transaction.value.transactionDate.toIso8601String(),
        'transaction_num': transactionNum,
        'created_at': now,
        'updated_at': now,
      });

      isSuccess.value = true;
      Get.find<EventBusService>().emitTransactionChanged();

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
    return transaction.value.categoryId != null &&
        transaction.value.amount > 0;
  }
}
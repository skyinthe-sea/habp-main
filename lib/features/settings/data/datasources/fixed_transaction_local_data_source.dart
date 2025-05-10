// lib/features/settings/data/datasources/fixed_transaction_local_data_source.dart

import 'package:flutter/foundation.dart';
import '../../../../core/database/db_helper.dart';

class FixedTransactionSetting {
  final int id;
  final int categoryId;
  final double amount;
  final DateTime effectiveFrom;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryType; // Add categoryType as an optional parameter

  FixedTransactionSetting({
    this.id = 0,
    required this.categoryId,
    required this.amount,
    required this.effectiveFrom,
    required this.createdAt,
    required this.updatedAt,
    this.categoryType, // Optional parameter for transaction sign handling
  });

  factory FixedTransactionSetting.fromMap(Map<String, dynamic> map) {
    return FixedTransactionSetting(
      id: map['id'],
      categoryId: map['category_id'],
      amount: map['amount'],
      effectiveFrom: DateTime.parse(map['effective_from']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      categoryType: map['category_type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'effective_from': effectiveFrom.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Category {
  final int id;
  final String name;
  final String type;
  final int isFixed;
  final int isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    this.id = 0,
    required this.name,
    required this.type,
    required this.isFixed,
    this.isDeleted = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      isFixed: map['is_fixed'],
      isDeleted: map['is_deleted'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'is_fixed': isFixed,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CategoryWithSettings {
  final int id;
  final String name;
  final String type;
  final List<FixedTransactionSetting> settings;

  CategoryWithSettings({
    required this.id,
    required this.name,
    required this.type,
    required this.settings,
  });
}

abstract class FixedTransactionLocalDataSource {
  Future<List<CategoryWithSettings>> getFixedCategories();
  Future<List<CategoryWithSettings>> getFixedCategoriesByType(String type);
  Future<List<FixedTransactionSetting>> getSettingsForCategory(int categoryId);
  Future<FixedTransactionSetting?> getLatestSettingForCategory(int categoryId);
  Future<FixedTransactionSetting?> getSettingForCategoryAndDate(int categoryId, DateTime date);
  Future<int> addSetting(FixedTransactionSetting setting);

  // New methods
  Future<int> addCategory(Category category);
  Future<bool> deleteFixedTransaction(int categoryId);
  Future<bool> categoryExists(String name, String type);
}

class FixedTransactionLocalDataSourceImpl implements FixedTransactionLocalDataSource {
  final DBHelper dbHelper;

  FixedTransactionLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<CategoryWithSettings>> getFixedCategories() async {
    try {
      final db = await dbHelper.database;

      // 고정 카테고리 가져오기
      final List<Map<String, dynamic>> categories = await db.query(
        'category',
        where: 'is_fixed = ? AND is_deleted = ?',
        whereArgs: [1, 0],
      );

      List<CategoryWithSettings> result = [];

      // 각 카테고리에 대한 설정 가져오기
      for (var category in categories) {
        final settings = await getSettingsForCategory(category['id']);

        result.add(CategoryWithSettings(
          id: category['id'],
          name: category['name'],
          type: category['type'],
          settings: settings,
        ));
      }

      return result;
    } catch (e) {
      debugPrint('고정 카테고리 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<List<CategoryWithSettings>> getFixedCategoriesByType(String type) async {
    try {
      final db = await dbHelper.database;

      // 특정 타입의 고정 카테고리 가져오기
      final List<Map<String, dynamic>> categories = await db.query(
        'category',
        where: 'is_fixed = ? AND is_deleted = ? AND type = ?',
        whereArgs: [1, 0, type],
      );

      List<CategoryWithSettings> result = [];

      // 각 카테고리에 대한 설정 가져오기
      for (var category in categories) {
        int categoryId = category['id'];

        // 1. fixed_transaction_setting에서 설정 가져오기
        final List<Map<String, dynamic>> settingsData = await db.query(
          'fixed_transaction_setting',
          where: 'category_id = ?',
          whereArgs: [categoryId],
          orderBy: 'effective_from DESC',
        );

        List<FixedTransactionSetting> settings = settingsData
            .map((s) => FixedTransactionSetting.fromMap(s))
            .toList();

        // 2. 설정이 없는 경우 transaction_record2 테이블도 확인
        if (settings.isEmpty) {
          final List<Map<String, dynamic>> transactionData = await db.query(
            'transaction_record2',
            where: 'category_id = ?',
            whereArgs: [categoryId],
            orderBy: 'transaction_date DESC',
            limit: 1,
          );

          if (transactionData.isNotEmpty) {
            // transaction_record2에서 데이터를 찾았으면 설정으로 변환
            final transaction = transactionData.first;
            final now = DateTime.now();

            // 거래 날짜 추출
            final transactionDate = DateTime.parse(transaction['transaction_date']);
            // transaction_num에 일자가 저장되어 있다면 그것을 사용
            final day = int.tryParse(transaction['transaction_num'] ?? '') ?? transactionDate.day;

            // 거래 금액 (소득인 경우 양수, 지출/재테크는 음수)
            double amount = transaction['amount'];
            if (type != 'INCOME' && amount > 0) amount = -amount;
            if (type == 'INCOME' && amount < 0) amount = -amount;

            // FixedTransactionSetting 생성
            final setting = FixedTransactionSetting(
              categoryId: categoryId,
              amount: amount, // Use the signed amount instead of absolute value
              effectiveFrom: DateTime(now.year, now.month, day),
              createdAt: DateTime.parse(transaction['created_at']),
              updatedAt: DateTime.parse(transaction['updated_at']),
              categoryType: type, // Include category type
            );

            settings.add(setting);
          }
        }

        result.add(CategoryWithSettings(
          id: category['id'],
          name: category['name'],
          type: category['type'],
          settings: settings,
        ));
      }

      return result;
    } catch (e) {
      debugPrint('타입별 고정 카테고리 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<List<FixedTransactionSetting>> getSettingsForCategory(int categoryId) async {
    try {
      final db = await dbHelper.database;

      final List<Map<String, dynamic>> settings = await db.query(
        'fixed_transaction_setting',
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'effective_from DESC',
      );

      return settings.map((s) => FixedTransactionSetting.fromMap(s)).toList();
    } catch (e) {
      debugPrint('카테고리 설정 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<FixedTransactionSetting?> getLatestSettingForCategory(int categoryId) async {
    try {
      final db = await dbHelper.database;

      final List<Map<String, dynamic>> settings = await db.query(
        'fixed_transaction_setting',
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'effective_from DESC',
        limit: 1,
      );

      if (settings.isNotEmpty) {
        return FixedTransactionSetting.fromMap(settings.first);
      }

      return null;
    } catch (e) {
      debugPrint('최신 카테고리 설정 가져오기 오류: $e');
      return null;
    }
  }

  @override
  Future<FixedTransactionSetting?> getSettingForCategoryAndDate(int categoryId, DateTime date) async {
    try {
      final db = await dbHelper.database;

      // 해당 날짜 이전의 가장 최근 설정 가져오기
      final List<Map<String, dynamic>> settings = await db.query(
        'fixed_transaction_setting',
        where: 'category_id = ? AND effective_from <= ?',
        whereArgs: [categoryId, date.toIso8601String()],
        orderBy: 'effective_from DESC',
        limit: 1,
      );

      if (settings.isNotEmpty) {
        return FixedTransactionSetting.fromMap(settings.first);
      }

      return null;
    } catch (e) {
      debugPrint('날짜별 카테고리 설정 가져오기 오류: $e');
      return null;
    }
  }

  @override
  Future<int> addSetting(FixedTransactionSetting setting) async {
    try {
      final db = await dbHelper.database;

      // 현재 시간 설정
      final now = DateTime.now();
      final Map<String, dynamic> settingMap = setting.toMap();

      // id는 자동 생성되므로 제거
      if (settingMap.containsKey('id') && settingMap['id'] == 0) {
        settingMap.remove('id');
      }

      // 생성/수정 시간 업데이트
      settingMap['created_at'] = now.toIso8601String();
      settingMap['updated_at'] = now.toIso8601String();

      // Get the category type if not provided
      String? categoryType = setting.categoryType;
      if (categoryType == null) {
        final List<Map<String, dynamic>> categoryResult = await db.query(
          'category',
          columns: ['type'],
          where: 'id = ?',
          whereArgs: [setting.categoryId],
        );

        if (categoryResult.isNotEmpty) {
          categoryType = categoryResult.first['type'] as String;
        }
      }

      // Apply the correct sign based on category type
      if (categoryType == 'EXPENSE' || categoryType == 'FINANCE') {
        // If the amount is positive, make it negative for EXPENSE and FINANCE
        if (settingMap['amount'] > 0) {
          settingMap['amount'] = -settingMap['amount'];
        }
      } else if (categoryType == 'INCOME') {
        // If the amount is negative, make it positive for INCOME
        if (settingMap['amount'] < 0) {
          settingMap['amount'] = -settingMap['amount'];
        }
      }

      return await db.insert('fixed_transaction_setting', settingMap);
    } catch (e) {
      debugPrint('설정 추가 오류: $e');
      return -1;
    }
  }

  @override
  Future<int> addCategory(Category category) async {
    try {
      final db = await dbHelper.database;

      // 현재 시간 설정
      final now = DateTime.now();
      final Map<String, dynamic> categoryMap = category.toMap();

      // id는 자동 생성되므로 제거
      if (categoryMap.containsKey('id') && categoryMap['id'] == 0) {
        categoryMap.remove('id');
      }

      // 생성/수정 시간 업데이트
      categoryMap['created_at'] = now.toIso8601String();
      categoryMap['updated_at'] = now.toIso8601String();

      final categoryId = await db.insert('category', categoryMap);
      debugPrint('새 카테고리 추가: $categoryId');
      return categoryId;

    } catch (e) {
      debugPrint('카테고리 추가 오류: $e');
      return -1;
    }
  }

  @override
  Future<bool> deleteFixedTransaction(int categoryId) async {
    try {
      final db = await dbHelper.database;

      // 1. 고정 거래 설정 삭제
      await db.delete(
        'fixed_transaction_setting',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );

      // 2. 관련 거래 내역 삭제
      await db.delete(
        'transaction_record2',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );

      // 3. 카테고리 소프트 삭제 (is_deleted = 1로 설정)
      await db.update(
        'category',
        {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      debugPrint('고정 거래 삭제 완료: 카테고리 ID $categoryId');
      return true;
    } catch (e) {
      debugPrint('고정 거래 삭제 오류: $e');
      return false;
    }
  }

  @override
  Future<bool> categoryExists(String name, String type) async {
    try {
      final db = await dbHelper.database;

      final List<Map<String, dynamic>> result = await db.query(
        'category',
        where: 'name = ? AND type = ? AND is_deleted = ?',
        whereArgs: [name, type, 0],
      );

      return result.isNotEmpty;
    } catch (e) {
      debugPrint('카테고리 중복 확인 오류: $e');
      return false;
    }
  }
}
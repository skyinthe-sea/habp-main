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

  FixedTransactionSetting({
    this.id = 0,
    required this.categoryId,
    required this.amount,
    required this.effectiveFrom,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FixedTransactionSetting.fromMap(Map<String, dynamic> map) {
    return FixedTransactionSetting(
      id: map['id'],
      categoryId: map['category_id'],
      amount: map['amount'],
      effectiveFrom: DateTime.parse(map['effective_from']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
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
  Future<List<FixedTransactionSetting>> getSettingsForCategory(int categoryId);
  Future<FixedTransactionSetting?> getLatestSettingForCategory(int categoryId);
  Future<FixedTransactionSetting?> getSettingForCategoryAndDate(int categoryId, DateTime date);
  Future<int> addSetting(FixedTransactionSetting setting);
  Future<List<CategoryWithSettings>> getFixedCategoriesByType(String type);
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

      return await db.insert('fixed_transaction_setting', settingMap);
    } catch (e) {
      debugPrint('설정 추가 오류: $e');
      return -1;
    }
  }
}
// lib/features/asset/data/datasources/asset_local_data_source.dart
import 'package:flutter/foundation.dart';
import '../../../../core/database/db_helper.dart';
import '../models/asset_summary_model.dart';
import '../models/asset_model.dart';
import '../models/asset_category_model.dart';
import '../models/asset_summary_model.dart';

abstract class AssetLocalDataSource {
  Future<List<AssetModel>> getAssets(int userId);
  Future<AssetSummaryModel> getAssetSummary(int userId);
  Future<List<AssetCategoryModel>> getAssetCategories();
  Future<AssetModel?> getAssetById(int assetId);

  Future<int?> addAsset({
    required int userId,
    required int categoryId,
    required String name,
    required double currentValue,
    double? purchaseValue,
    String? purchaseDate,
    double? interestRate,
    double? loanAmount,
    String? description,
    String? location,
    String? details,
    String? iconType,
  });

  Future<bool> updateAsset({
    required int assetId,
    int? categoryId,
    String? name,
    double? currentValue,
    double? purchaseValue,
    String? purchaseDate,
    double? interestRate,
    double? loanAmount,
    String? description,
    String? location,
    String? details,
    String? iconType,
  });

  Future<bool> deleteAsset(int assetId);
}

class AssetLocalDataSourceImpl implements AssetLocalDataSource {
  final DBHelper dbHelper;

  AssetLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<AssetModel>> getAssets(int userId) async {
    final db = await dbHelper.database;

    try {
      // 자산 데이터와 카테고리 정보를 함께 가져오는 쿼리
      final result = await db.rawQuery('''
        SELECT 
          a.*, c.name as category_name, c.type as category_type
        FROM 
          asset a
        JOIN 
          category c ON a.category_id = c.id
        WHERE 
          a.user_id = ? AND a.is_active = 1
        ORDER BY 
          a.current_value DESC
      ''', [userId]);

      return result.map((map) {
        final categoryName = map['category_name'] as String;
        final categoryType = map['category_type'] as String;
        return AssetModel.fromMap(map, categoryName: categoryName, categoryType: categoryType);
      }).toList();
    } catch (e) {
      debugPrint('자산 정보 조회 중 오류: $e');
      return [];
    }
  }

  @override
  Future<AssetSummaryModel> getAssetSummary(int userId) async {
    final db = await dbHelper.database;

    try {
      // 자산 총액 쿼리
      final totalAssetResult = await db.rawQuery('''
        SELECT SUM(current_value) as total_value
        FROM asset
        WHERE user_id = ? AND is_active = 1
      ''', [userId]);

      final totalAssetValue = totalAssetResult.isNotEmpty && totalAssetResult[0]['total_value'] != null
          ? (totalAssetResult[0]['total_value'] as num).toDouble()
          : 0.0;

      // 총 대출액 쿼리
      final totalLoanResult = await db.rawQuery('''
        SELECT SUM(loan_amount) as total_loan
        FROM asset
        WHERE user_id = ? AND loan_amount IS NOT NULL AND is_active = 1
      ''', [userId]);

      final totalLoanAmount = totalLoanResult.isNotEmpty && totalLoanResult[0]['total_loan'] != null
          ? (totalLoanResult[0]['total_loan'] as num).toDouble()
          : 0.0;

      // 카테고리별 자산 가치 쿼리
      final categoryValuesResult = await db.rawQuery('''
        SELECT 
          c.name as category_name, 
          SUM(a.current_value) as category_value
        FROM 
          asset a
        JOIN 
          category c ON a.category_id = c.id
        WHERE 
          a.user_id = ? AND a.is_active = 1
        GROUP BY 
          c.id
      ''', [userId]);

      // 카테고리별 자산 값 맵 생성
      final Map<String, double> categoryValues = {};
      for (var row in categoryValuesResult) {
        final categoryName = row['category_name'] as String;
        final categoryValue = (row['category_value'] as num).toDouble();
        categoryValues[categoryName] = categoryValue;
      }

      // 순자산 = 총자산 - 총부채
      final netWorth = totalAssetValue - totalLoanAmount;

      return AssetSummaryModel(
        totalAssetValue: totalAssetValue,
        totalLoanAmount: totalLoanAmount,
        netWorth: netWorth,
        categoryValues: categoryValues,
      );
    } catch (e) {
      debugPrint('자산 요약 정보 조회 중 오류: $e');
      return AssetSummaryModel.empty();
    }
  }

  @override
  Future<List<AssetCategoryModel>> getAssetCategories() async {
    final db = await dbHelper.database;

    try {
      final result = await db.query(
        'category',
        where: 'type = ?',
        whereArgs: ['ASSET'],
        orderBy: 'name', // Keep initial alphabetical sorting
      );

      // Convert to list of models
      final categories = result.map((map) => AssetCategoryModel.fromMap(map)).toList();

      // Custom sort to ensure "기타" is always at the end
      categories.sort((a, b) {
        if (a.name == '기타') return 1;      // Move "기타" to the end
        if (b.name == '기타') return -1;     // Move "기타" to the end
        return a.name.compareTo(b.name);    // Normal alphabetical sorting for other items
      });

      return categories;
    } catch (e) {
      debugPrint('자산 카테고리 조회 중 오류: $e');
      return [];
    }
  }

  @override
  Future<AssetModel?> getAssetById(int assetId) async {
    final db = await dbHelper.database;

    try {
      final result = await db.rawQuery('''
        SELECT 
          a.*, c.name as category_name, c.type as category_type
        FROM 
          asset a
        JOIN 
          category c ON a.category_id = c.id
        WHERE 
          a.id = ?
      ''', [assetId]);

      if (result.isNotEmpty) {
        final map = result.first;
        final categoryName = map['category_name'] as String;
        final categoryType = map['category_type'] as String;
        return AssetModel.fromMap(map, categoryName: categoryName, categoryType: categoryType);
      }
      return null;
    } catch (e) {
      debugPrint('자산 상세 정보 조회 중 오류: $e');
      return null;
    }
  }

  @override
  Future<int?> addAsset({
    required int userId,
    required int categoryId,
    required String name,
    required double currentValue,
    double? purchaseValue,
    String? purchaseDate,
    double? interestRate,
    double? loanAmount,
    String? description,
    String? location,
    String? details,
    String? iconType,
  }) async {
    final db = await dbHelper.database;

    try {
      final now = DateTime.now().toIso8601String();

      // 새 자산 추가
      final id = await db.insert('asset', {
        'user_id': userId,
        'category_id': categoryId,
        'name': name,
        'current_value': currentValue,
        'purchase_value': purchaseValue,
        'purchase_date': purchaseDate,
        'interest_rate': interestRate,
        'loan_amount': loanAmount,
        'description': description,
        'location': location,
        'details': details,
        'icon_type': iconType,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });

      // 자산 가치 이력 추가
      await db.insert('asset_valuation_history', {
        'asset_id': id,
        'valuation_date': now,
        'value': currentValue,
        'created_at': now,
      });

      return id;
    } catch (e) {
      debugPrint('자산 추가 중 오류: $e');
      return null;
    }
  }

  @override
  Future<bool> updateAsset({
    required int assetId,
    int? categoryId,
    String? name,
    double? currentValue,
    double? purchaseValue,
    String? purchaseDate,
    double? interestRate,
    double? loanAmount,
    String? description,
    String? location,
    String? details,
    String? iconType,
  }) async {
    final db = await dbHelper.database;

    try {
      final now = DateTime.now().toIso8601String();

      // 업데이트할 필드만 포함하는 맵 생성
      final Map<String, dynamic> updateValues = {'updated_at': now};

      if (categoryId != null) updateValues['category_id'] = categoryId;
      if (name != null) updateValues['name'] = name;
      if (currentValue != null) updateValues['current_value'] = currentValue;
      if (purchaseValue != null) updateValues['purchase_value'] = purchaseValue;
      if (purchaseDate != null) updateValues['purchase_date'] = purchaseDate;
      if (interestRate != null) updateValues['interest_rate'] = interestRate;
      if (loanAmount != null) updateValues['loan_amount'] = loanAmount;
      if (description != null) updateValues['description'] = description;
      if (location != null) updateValues['location'] = location;
      if (details != null) updateValues['details'] = details;
      if (iconType != null) updateValues['icon_type'] = iconType;

      final count = await db.update(
        'asset',
        updateValues,
        where: 'id = ?',
        whereArgs: [assetId],
      );

      // 가치가 변경된 경우 이력 추가
      if (currentValue != null) {
        await db.insert('asset_valuation_history', {
          'asset_id': assetId,
          'valuation_date': now,
          'value': currentValue,
          'created_at': now,
        });
      }

      return count > 0;
    } catch (e) {
      debugPrint('자산 업데이트 중 오류: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAsset(int assetId) async {
    final db = await dbHelper.database;

    try {
      // 실제로 삭제하지 않고 is_active 플래그를 0으로 설정
      final count = await db.update(
        'asset',
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [assetId],
      );

      return count > 0;
    } catch (e) {
      debugPrint('자산 삭제 중 오류: $e');
      return false;
    }
  }
}
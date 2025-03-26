import 'package:flutter/foundation.dart';
import '../../../../core/database/db_helper.dart';
import '../models/budget_status_model.dart';
import '../models/category_model.dart';

abstract class ExpenseLocalDataSource {
  Future<List<BudgetStatusModel>> getBudgetStatus(int userId, String period);
  Future<List<CategoryModel>> getVariableExpenseCategories();
  Future<bool> addBudget({
    required int userId,
    required int categoryId,
    required double amount,
    required String periodStart,
    required String periodEnd,
  });
  Future<CategoryModel?> addCategory({
    required String name,
    required String type,
    required int isFixed,
  });
  Future<bool> deleteCategory(int categoryId);
  Future<bool> addExpense({
    required int userId,
    required int categoryId,
    required double amount,
    required String description,
    required String transactionDate,
  });
}

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  final DBHelper dbHelper;

  ExpenseLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<BudgetStatusModel>> getBudgetStatus(int userId, String period) async {
    final db = await dbHelper.database;

    try {
      // 기간에서 연도와 월 추출 (형식: YYYY-MM)
      final year = int.parse(period.split('-')[0]);
      final month = int.parse(period.split('-')[1]);

      // 해당 월의 시작일과 종료일 계산
      final startDate = DateTime(year, month, 1).toIso8601String();
      final endDate = DateTime(year, month + 1, 0).toIso8601String();

      // 각 지출 카테고리별 예산 상태를 가져오는 쿼리
      final result = await db.rawQuery('''
        SELECT 
          c.id as category_id, 
          c.name as category_name, 
          COALESCE(b.amount, 0) as budget_amount,
          COALESCE(SUM(t.amount), 0) as spent_amount
        FROM 
          category c
        LEFT JOIN 
          budget b ON c.id = b.category_id 
          AND b.user_id = ? 
          AND b.start_date <= ? 
          AND b.end_date >= ?
        LEFT JOIN 
          transaction_record t ON c.id = t.category_id 
          AND t.user_id = ? 
          AND t.transaction_date >= ? 
          AND t.transaction_date <= ?
        WHERE 
          c.type = 'EXPENSE' AND c.is_fixed = 0
        GROUP BY 
          c.id
        ORDER BY 
          c.name
      ''', [userId, endDate, startDate, userId, startDate, endDate]);

      return result.map((map) => BudgetStatusModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('예산 상태 정보 조회 중 오류: $e');
      return [];
    }
  }

  @override
  Future<List<CategoryModel>> getVariableExpenseCategories() async {
    final db = await dbHelper.database;

    try {
      final result = await db.query(
        'category',
        where: 'type = ? AND is_fixed = ?',
        whereArgs: ['EXPENSE', 0],
        orderBy: 'name',
      );

      return result.map((map) => CategoryModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('변동 지출 카테고리 조회 중 오류: $e');
      return [];
    }
  }

  @override
  Future<bool> addBudget({
    required int userId,
    required int categoryId,
    required double amount,
    required String periodStart,
    required String periodEnd,
  }) async {
    final db = await dbHelper.database;

    try {
      final now = DateTime.now().toIso8601String();

      // 기존 예산이 있는지 확인
      final existingBudget = await db.query(
        'budget',
        where: 'user_id = ? AND category_id = ? AND start_date = ? AND end_date = ?',
        whereArgs: [userId, categoryId, periodStart, periodEnd],
      );

      if (existingBudget.isNotEmpty) {
        // 기존 예산 업데이트
        await db.update(
          'budget',
          {
            'amount': amount,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [existingBudget.first['id']],
        );
      } else {
        // 새 예산 추가
        await db.insert('budget', {
          'user_id': userId,
          'category_id': categoryId,
          'amount': amount,
          'start_date': periodStart,
          'end_date': periodEnd,
          'created_at': now,
          'updated_at': now,
        });
      }

      return true;
    } catch (e) {
      debugPrint('예산 추가 중 오류: $e');
      return false;
    }
  }

  @override
  Future<CategoryModel?> addCategory({
    required String name,
    required String type,
    required int isFixed,
  }) async {
    final db = await dbHelper.database;

    try {
      final now = DateTime.now().toIso8601String();

      // 이미 동일한 이름의 카테고리가 있는지 확인
      final existingCategory = await db.query(
        'category',
        where: 'name = ? AND type = ?',
        whereArgs: [name, type],
        limit: 1,
      );

      if (existingCategory.isNotEmpty) {
        // 이미 존재하는 카테고리가 있으면 그것을 반환
        return CategoryModel.fromMap(existingCategory.first);
      }

      // 새 카테고리 추가
      final id = await db.insert('category', {
        'name': name,
        'type': type,
        'is_fixed': isFixed,
        'created_at': now,
        'updated_at': now,
      });

      return CategoryModel(
        id: id,
        name: name,
        type: type,
        isFixed: isFixed,
      );
    } catch (e) {
      debugPrint('카테고리 추가 중 오류: $e');
      return null;
    }
  }

  @override
  Future<bool> deleteCategory(int categoryId) async {
    final db = await dbHelper.database;

    try {
      // 트랜잭션으로 관련 데이터 함께 삭제
      await db.transaction((txn) async {
        // 먼저 해당 카테고리와 관련된 예산 삭제
        await txn.delete(
          'budget',
          where: 'category_id = ?',
          whereArgs: [categoryId],
        );

        // 해당 카테고리와 관련된 거래 내역 삭제
        // await txn.delete(
        //   'transaction_record',
        //   where: 'category_id = ?',
        //   whereArgs: [categoryId],
        // );

        // 카테고리 삭제
        // final count = await txn.delete(
        //   'category',
        //   where: 'id = ?',
        //   whereArgs: [categoryId],
        // );

        // 삭제된 행이 없으면 실패
        // if (count == 0) {
        //   throw Exception('카테고리를 찾을 수 없습니다.');
        // }
      });

      return true;
    } catch (e) {
      debugPrint('카테고리 삭제 중 오류: $e');
      return false;
    }
  }

  @override
  Future<bool> addExpense({
    required int userId,
    required int categoryId,
    required double amount,
    required String description,
    required String transactionDate,
  }) async {
    final db = await dbHelper.database;

    try {
      final now = DateTime.now().toIso8601String();
      final transactionNum = DateTime.now().microsecondsSinceEpoch % 1000;

      // 새 거래 내역 추가
      await db.insert('transaction_record', {
        'user_id': userId,
        'category_id': categoryId,
        'amount': amount,
        'description': description,
        'transaction_date': transactionDate,
        'transaction_num': transactionNum.toString(),
        'created_at': now,
        'updated_at': now,
      });

      return true;
    } catch (e) {
      debugPrint('지출 추가 중 오류: $e');
      return false;
    }
  }
}
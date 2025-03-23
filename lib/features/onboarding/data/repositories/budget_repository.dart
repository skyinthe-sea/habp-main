// lib/features/onboarding/data/repositories/budget_repository.dart

import '../../../../../core/database/db_helper.dart';
import '../models/budget.dart';

class BudgetRepository {
  final DBHelper _dbHelper = DBHelper();

  // 예산 추가
  Future<int> createBudget(Budget budget) async {
    final db = await _dbHelper.database;
    return await db.insert('budget', budget.toMap());
  }

  // 예산 조회
  Future<Budget?> getBudget(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budget',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  // 모든 예산 조회
  Future<List<Budget>> getAllBudgets() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('budget');
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  // 사용자별 예산 조회
  Future<List<Budget>> getBudgetsByUser(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budget',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  // 카테고리별 예산 조회
  Future<List<Budget>> getBudgetsByCategory(int categoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budget',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  // 기간별 예산 조회
  Future<List<Budget>> getBudgetsByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budget',
      where: 'start_date <= ? AND end_date >= ?',
      whereArgs: [end.toIso8601String(), start.toIso8601String()],
    );
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  // 활성 예산 조회 (현재 날짜에 유효한 예산)
  Future<List<Budget>> getActiveBudgets() async {
    final now = DateTime.now();
    return getBudgetsByDateRange(now, now);
  }

  // 예산 업데이트
  Future<int> updateBudget(Budget budget) async {
    final db = await _dbHelper.database;
    return await db.update(
      'budget',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  // 예산 삭제
  Future<int> deleteBudget(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'budget',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 월별 예산 생성 (해당 월에 대한 예산)
  Future<int> createMonthlyBudget(int? userId, int categoryId, double amount, int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final now = DateTime.now();
    final budget = Budget(
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      createdAt: now,
      updatedAt: now,
    );

    return createBudget(budget);
  }

  // 월별 예산 조회
  Future<List<Budget>> getMonthlyBudgets(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return getBudgetsByDateRange(startDate, endDate);
  }
}
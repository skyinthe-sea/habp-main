// lib/features/onboarding/data/repositories/category_repository.dart

import '../../../../../core/database/db_helper.dart';
import '../models/expense_category.dart';

class CategoryRepository {
  final DBHelper _dbHelper = DBHelper();

  // 카테고리 추가
  Future<int> createCategory(ExpenseCategory category) async {
    final db = await _dbHelper.database;
    return await db.insert('category', category.toMap());
  }

  // 카테고리 조회
  Future<ExpenseCategory?> getCategory(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'category',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return ExpenseCategory.fromMap(maps.first);
  }

  // 카테고리 이름으로 조회
  Future<ExpenseCategory?> getCategoryByName(String name) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'category',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (maps.isEmpty) return null;
    return ExpenseCategory.fromMap(maps.first);
  }

  // 모든 카테고리 조회
  Future<List<ExpenseCategory>> getAllCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('category');
    return List.generate(maps.length, (i) => ExpenseCategory.fromMap(maps[i]));
  }

  // 유형별 카테고리 조회
  Future<List<ExpenseCategory>> getCategoriesByType(ExpenseCategoryType type) async {
    final db = await _dbHelper.database;
    final typeStr = type.toString().split('.').last;

    final List<Map<String, dynamic>> maps = await db.query(
      'category',
      where: 'type = ?',
      whereArgs: [typeStr],
    );

    return List.generate(maps.length, (i) => ExpenseCategory.fromMap(maps[i]));
  }

  // 소득 카테고리 조회
  Future<List<ExpenseCategory>> getIncomeCategories() async {
    return getCategoriesByType(ExpenseCategoryType.INCOME);
  }

  // 지출 카테고리 조회
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    return getCategoriesByType(ExpenseCategoryType.EXPENSE);
  }

  // 재테크 카테고리 조회
  Future<List<ExpenseCategory>> getFinanceCategories() async {
    return getCategoriesByType(ExpenseCategoryType.FINANCE);
  }

  // 카테고리 업데이트
  Future<int> updateCategory(ExpenseCategory category) async {
    final db = await _dbHelper.database;
    return await db.update(
      'category',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // 카테고리 삭제
  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'category',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 사용자 정의 카테고리 추가 또는 가져오기
  Future<ExpenseCategory> getOrCreateCategory(String name, ExpenseCategoryType type, bool isFixed) async {
    // 이미 존재하는지 확인
    final existingCategory = await getCategoryByName(name);
    if (existingCategory != null) {
      return existingCategory;
    }

    // 존재하지 않으면 새로 생성
    final now = DateTime.now();
    final newCategory = ExpenseCategory(
      name: name,
      type: type,
      isFixed: isFixed,
      createdAt: now,
      updatedAt: now,
    );

    final id = await createCategory(newCategory);
    return newCategory.copyWith(id: id);
  }
}
// lib/features/onboarding/data/repositories/transaction_repository.dart

import '../../../../../core/database/db_helper.dart';
import '../models/transaction_record.dart';

class TransactionRepository {
  final DBHelper _dbHelper = DBHelper();

  // 거래 내역 추가
  Future<int> createTransaction(TransactionRecord transaction) async {
    final db = await _dbHelper.database;
    return await db.insert('transaction_record2', transaction.toMap());
  }

  // 거래 내역 조회
  Future<TransactionRecord?> getTransaction(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_record2',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return TransactionRecord.fromMap(maps.first);
  }

  // 모든 거래 내역 조회
  Future<List<TransactionRecord>> getAllTransactions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_record2',
      orderBy: 'transaction_date DESC',
    );
    return List.generate(maps.length, (i) => TransactionRecord.fromMap(maps[i]));
  }

  // 사용자별 거래 내역 조회
  Future<List<TransactionRecord>> getTransactionsByUser(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_record2',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'transaction_date DESC',
    );
    return List.generate(maps.length, (i) => TransactionRecord.fromMap(maps[i]));
  }

  // 카테고리별 거래 내역 조회
  Future<List<TransactionRecord>> getTransactionsByCategory(int categoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_record2',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'transaction_date DESC',
    );
    return List.generate(maps.length, (i) => TransactionRecord.fromMap(maps[i]));
  }

  // 기간별 거래 내역 조회
  Future<List<TransactionRecord>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_record2',
      where: 'transaction_date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'transaction_date DESC',
    );
    return List.generate(maps.length, (i) => TransactionRecord.fromMap(maps[i]));
  }

  // 거래 내역 업데이트
  Future<int> updateTransaction(TransactionRecord transaction) async {
    final db = await _dbHelper.database;
    return await db.update(
      'transaction_record2',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // 거래 내역 삭제
  Future<int> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'transaction_record2',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 카테고리별 거래 합계 조회
  Future<double> getTotalAmountByCategory(int categoryId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transaction_record2
      WHERE category_id = ?
    ''', [categoryId]);

    if (result.isEmpty || result.first['total'] == null) {
      return 0.0;
    }
    return result.first['total'] as double;
  }

  // 월별 거래 내역 조회 (해당 월의 모든 거래)
  Future<List<TransactionRecord>> getTransactionsByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getTransactionsByDateRange(start, end);
  }
}
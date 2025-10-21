import 'package:sqflite/sqflite.dart';
import '../../../../core/database/db_helper.dart';
import '../models/monthly_diary_model.dart';

/// 월별 다이어리 로컬 데이터 소스
class MonthlyDiaryLocalDataSource {
  final DBHelper _dbHelper;

  MonthlyDiaryLocalDataSource(this._dbHelper);

  /// 특정 월의 다이어리 조회
  Future<MonthlyDiaryModel?> getDiary(int year, int month) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'monthly_diary',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      limit: 1,
    );

    if (results.isEmpty) return null;

    return MonthlyDiaryModel.fromMap(results.first);
  }

  /// 모든 다이어리 조회 (최신순)
  Future<List<MonthlyDiaryModel>> getAllDiaries() async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'monthly_diary',
      orderBy: 'year DESC, month DESC',
    );

    return results.map((map) => MonthlyDiaryModel.fromMap(map)).toList();
  }

  /// 연도별 다이어리 조회
  Future<List<MonthlyDiaryModel>> getDiariesByYear(int year) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'monthly_diary',
      where: 'year = ?',
      whereArgs: [year],
      orderBy: 'month DESC',
    );

    return results.map((map) => MonthlyDiaryModel.fromMap(map)).toList();
  }

  /// 다이어리 생성
  Future<int> createDiary(MonthlyDiaryModel diary) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'monthly_diary',
      diary.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 다이어리 업데이트
  Future<void> updateDiary(MonthlyDiaryModel diary) async {
    final db = await _dbHelper.database;
    await db.update(
      'monthly_diary',
      diary.toMap(),
      where: 'id = ?',
      whereArgs: [diary.id],
    );
  }

  /// 다이어리 삭제
  Future<void> deleteDiary(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'monthly_diary',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 특정 월의 다이어리가 존재하는지 확인
  Future<bool> diaryExists(int year, int month) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'monthly_diary',
      columns: ['id'],
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  /// 현재 월의 다이어리 생성 (없을 경우)
  Future<MonthlyDiaryModel> getOrCreateCurrentMonthDiary(int userId) async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    // 기존 다이어리 조회
    final existing = await getDiary(year, month);
    if (existing != null) {
      return existing;
    }

    // 새 다이어리 생성
    final newDiary = MonthlyDiaryModel(
      userId: userId,
      year: year,
      month: month,
      createdAt: now,
      updatedAt: now,
    );

    final id = await createDiary(newDiary);

    return MonthlyDiaryModel(
      id: id,
      userId: userId,
      year: year,
      month: month,
      createdAt: now,
      updatedAt: now,
    );
  }
}

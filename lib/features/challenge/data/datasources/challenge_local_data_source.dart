import 'package:sqflite/sqflite.dart';
import '../../../../core/database/db_helper.dart';
import '../models/user_challenge_model.dart';

class ChallengeLocalDataSource {
  final DBHelper _dbHelper;

  ChallengeLocalDataSource(this._dbHelper);

  // 사용자 챌린지 조회
  Future<List<UserChallengeModel>> getUserChallenges({String? status}) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'user_challenge',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'created_at DESC',
    );

    return results.map((map) => UserChallengeModel.fromMap(map)).toList();
  }

  // 특정 챌린지 조회
  Future<UserChallengeModel?> getUserChallenge(int id) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'user_challenge',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return UserChallengeModel.fromMap(results.first);
  }

  // 챌린지 생성
  Future<int> createChallenge(UserChallengeModel challenge) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'user_challenge',
      challenge.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 챌린지 업데이트
  Future<void> updateChallenge(UserChallengeModel challenge) async {
    final db = await _dbHelper.database;
    await db.update(
      'user_challenge',
      challenge.toMap(),
      where: 'id = ?',
      whereArgs: [challenge.id],
    );
  }

  // 챌린지 삭제
  Future<void> deleteChallenge(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'user_challenge',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 챌린지 진행률 업데이트
  Future<void> updateProgress(int id, double currentAmount, double progress) async {
    final db = await _dbHelper.database;
    await db.update(
      'user_challenge',
      {
        'current_amount': currentAmount,
        'progress': progress,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 챌린지 완료 처리
  Future<void> completeChallenge(int id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'user_challenge',
      {
        'status': 'COMPLETED',
        'completed_at': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 챌린지 실패 처리
  Future<void> failChallenge(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'user_challenge',
      {
        'status': 'FAILED',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 카테고리별 지출 금액 조회 (특정 기간)
  Future<double> getCategoryExpense(int categoryId, DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT SUM(ABS(amount)) as total
      FROM transaction_record
      WHERE category_id = ?
      AND date(substr(transaction_date, 1, 10)) >= date(?)
      AND date(substr(transaction_date, 1, 10)) <= date(?)
    ''', [categoryId, startDate.toIso8601String().split('T')[0], endDate.toIso8601String().split('T')[0]]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // 완료된 챌린지 개수
  Future<int> getCompletedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM user_challenge
      WHERE status = 'COMPLETED'
    ''');
    return (result.first['count'] as int?) ?? 0;
  }

  // 연속 성공 횟수
  Future<int> getStreakCount() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'user_challenge',
      columns: ['status', 'completed_at'],
      where: 'status IN (?, ?)',
      whereArgs: ['COMPLETED', 'FAILED'],
      orderBy: 'completed_at DESC',
    );

    int streak = 0;
    for (var result in results) {
      if (result['status'] == 'COMPLETED') {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // 성공률 계산
  Future<double> getSuccessRate() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) as completed,
        COUNT(*) as total
      FROM user_challenge
      WHERE status IN ('COMPLETED', 'FAILED')
    ''');

    final completed = (result.first['completed'] as int?) ?? 0;
    final total = (result.first['total'] as int?) ?? 0;

    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }
}

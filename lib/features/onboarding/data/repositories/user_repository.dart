// lib/features/onboarding/data/repositories/user_repository.dart

import 'package:sqflite/sqflite.dart';
import '../../../../../core/database/db_helper.dart';
import '../models/user.dart';

class UserRepository {
  final DBHelper _dbHelper = DBHelper();

  // 사용자 추가
  Future<int> createUser(User user) async {
    final db = await _dbHelper.database;
    return await db.insert('user', user.toMap());
  }

  // 사용자 조회
  Future<User?> getUser(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // 모든 사용자 조회
  Future<List<User>> getAllUsers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('user');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  // 현재 활성 사용자 조회 (앱에서는 한 명만 사용)
  Future<User?> getActiveUser() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('user', limit: 1);

    if (maps.isEmpty) {
      // 사용자가 없으면 기본 사용자 생성
      final now = DateTime.now();
      final defaultUser = User(
        createdAt: now,
        updatedAt: now,
      );

      final id = await createUser(defaultUser);
      return defaultUser.copyWith(id: id);
    }

    return User.fromMap(maps.first);
  }

  // 사용자 업데이트
  Future<int> updateUser(User user) async {
    final db = await _dbHelper.database;
    return await db.update(
      'user',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // 사용자 삭제
  Future<int> deleteUser(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'user',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
import '../models/test_model.dart';
import '../../../../core/database/app_database.dart';

class TestLocalSource {
  Future<void> insertTestData(TestModel model) async {
    final db = await AppDatabase.database;
    await db.insert('test', model.toJson());
  }

  Future<TestModel?> getLatestTestData() async {
    final db = await AppDatabase.database;
    final result = await db.query(
      'test',
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return TestModel.fromJson(result.first);
  }
}
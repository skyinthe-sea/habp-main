// lib/features/test/data/datasources/test_local_source_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/providers/database_provider.dart';
import '../models/test_model.dart';

final testLocalSourceProvider = Provider((ref) {
  final databaseAsyncValue = ref.watch(databaseProvider);

  return databaseAsyncValue.when(
    data: (database) => TestLocalSource(database),
    loading: () => throw UnimplementedError(),
    error: (error, stack) => throw error,
  );
});

class TestLocalSource {
  final Database database;

  TestLocalSource(this.database);

  Future<void> insertTestData(TestModel model) async {
    await database.insert('test', model.toJson());
  }

  Future<TestModel?> getLatestTestData() async {
    final result = await database.query(
      'test',
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return TestModel.fromJson(result.first);
  }
}
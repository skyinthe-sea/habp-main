import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/test_repository.dart';
import '../../presentation/providers/test_provider.dart';
import '../datasources/test_local_source.dart';
import '../models/test_model.dart';

final testRepositoryProvider = Provider((ref) {
  final localSource = ref.watch(testLocalSourceProvider);
  return TestRepositoryImpl(localSource);
});

class TestRepositoryImpl implements TestRepository {
  final TestLocalSource _localSource;

  TestRepositoryImpl(this._localSource);

  @override
  Future<void> saveTestData(String data) async {
    final model = TestModel(
      data: data,
      createdAt: DateTime.now(),
    );
    await _localSource.insertTestData(model);
  }

  @override
  Future<String?> getLatestTestData() async {
    final model = await _localSource.getLatestTestData();
    return model?.data;
  }
}
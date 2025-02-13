// lib/features/onboarding/data/repositories/test_repository_impl.dart
import '../../data/datasources/test_local_source.dart';
import '../../data/models/test_model.dart';
import '../../domain/repositories/test_repository.dart';

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
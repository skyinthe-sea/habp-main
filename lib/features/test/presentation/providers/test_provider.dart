import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/test_local_source.dart';
import '../../data/repositories/test_repository_impl.dart';

final testLocalSourceProvider = Provider<TestLocalSource>((ref) {
  return TestLocalSource();
});

final testRepositoryProvider = Provider<TestRepositoryImpl>((ref) {
  final localSource = ref.watch(testLocalSourceProvider);
  return TestRepositoryImpl(localSource);
});

final testDataProvider = StateNotifierProvider<TestDataNotifier, String?>((ref) {
  final repository = ref.watch(testRepositoryProvider);
  return TestDataNotifier(repository);
});

class TestDataNotifier extends StateNotifier<String?> {
  final TestRepositoryImpl _repository;

  TestDataNotifier(this._repository) : super(null) {
    _loadLatestData();
  }

  Future<void> _loadLatestData() async {
    state = await _repository.getLatestTestData();
  }

  Future<void> saveData(String data) async {
    await _repository.saveTestData(data);
    state = data;
  }
}
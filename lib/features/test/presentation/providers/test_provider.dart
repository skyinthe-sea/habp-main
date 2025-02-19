import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/test_repository_provider.dart';

final testDataProvider = StateNotifierProvider<TestDataNotifier, AsyncValue<String?>>((ref) {
  final repository = ref.watch(testRepositoryProvider);
  return TestDataNotifier(repository);
});

class TestDataNotifier extends StateNotifier<AsyncValue<String?>> {
  final TestRepositoryImpl _repository;

  TestDataNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final data = await _repository.getLatestTestData();
      state = AsyncValue.data(data);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> saveData(String data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveTestData(data);
      state = AsyncValue.data(data);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}
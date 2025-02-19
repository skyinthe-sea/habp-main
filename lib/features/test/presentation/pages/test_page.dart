import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/test_provider.dart';

// lib/features/test/presentation/pages/test_page.dart
class TestPage extends ConsumerWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testDataAsync = ref.watch(testDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('테스트 페이지'),
      ),
      body: Center(
        child: testDataAsync.when(
          data: (data) => Text(
            data ?? '데이터 없음',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
        ),
      ),
    );
  }
}
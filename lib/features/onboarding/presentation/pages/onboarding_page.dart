// lib/features/onboarding/presentation/pages/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_preference_provider.dart';
import '../../../test/presentation/pages/test_page.dart';
import '../../../test/presentation/providers/test_provider.dart';

class OnboardingPage extends ConsumerWidget {
  OnboardingPage({Key? key}) : super(key: key);

  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: '데이터를 입력하세요',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final data = _controller.text;
                  if (data.isNotEmpty) {
                    await ref.read(testDataProvider.notifier).saveData(data);
                    final prefs = ref.read(sharedPreferencesProvider);
                    await prefs.setBool('isFirstLaunch', false);

                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => TestPage()),
                      );
                    }
                  }
                },
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../test/presentation/pages/test_page.dart';
import '../providers/onboarding_provider.dart';

class OnboardingPage2 extends ConsumerWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);

    return Scaffold(
      body: Column(
        children: [
          // 진행 상태 표시
          LinearProgressIndicator(
            value: (onboardingState.currentStep + 1) / 3,
          ),

          // 현재 단계에 따른 화면 표시
          Expanded(
            child: _buildStep(context, ref, onboardingState.currentStep),
          ),

          // 이전/다음 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onboardingState.currentStep > 0)
                TextButton(
                  onPressed: () {
                    ref.read(onboardingProvider.notifier).previousStep();
                  },
                  child: Text('이전'),
                ),
              TextButton(
                onPressed: () async {
                  if (onboardingState.currentStep < 2) {
                    ref.read(onboardingProvider.notifier).nextStep();
                  } else {
                    // 마지막 단계에서는 완료 처리
                    await ref.read(onboardingProvider.notifier).completeOnboarding();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => TestPage()),
                      );
                    }
                  }
                },
                child: Text(onboardingState.currentStep < 2 ? '다음' : '완료'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, WidgetRef ref, int step) {
    switch (step) {
      case 0:
        return Center(child: Text('첫 번째 단계'));
      case 1:
        return Center(child: Text('두 번째 단계'));
      case 2:
        return Center(child: Text('세 번째 단계'));
      default:
        return SizedBox.shrink();
    }
  }
}
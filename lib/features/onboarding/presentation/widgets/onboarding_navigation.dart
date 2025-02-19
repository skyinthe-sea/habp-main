import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/onboarding_provider.dart';

class OnboardingNavigation extends ConsumerWidget {
  const OnboardingNavigation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(onboardingProvider).currentStep;
    final isLastStep = currentStep == 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽 화살표 버튼
          AnimatedOpacity(
            opacity: currentStep == 0 ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              onPressed: currentStep == 0
                  ? null
                  : () => ref.read(onboardingProvider.notifier).previousStep(),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.white,
              ),
            ),
          ),

          // 없음 버튼
          TextButton(
            onPressed: () => ref.read(onboardingProvider.notifier).nextStep(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white,
              backgroundColor: AppColors.white.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('없음'),
          ),

          // 오른쪽 화살표 또는 완료 버튼
          if (!isLastStep)
            IconButton(
              onPressed: () => ref.read(onboardingProvider.notifier).nextStep(),
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.white,
              ),
            )
          else
            TextButton(
              onPressed: () {
                // 완료 로직 구현
                // ref.read(isFirstLaunchProvider.notifier).setFirstLaunch(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('완료'),
            ),
        ],
      ),
    );
  }
}
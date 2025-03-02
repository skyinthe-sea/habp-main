import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingButtons extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;
  final VoidCallback onFinish;

  const OnboardingButtons({
    Key? key,
    required this.currentPage,
    required this.pageCount,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
    required this.onFinish,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽 화살표 버튼 (첫 페이지에서는 숨김)
          AnimatedOpacity(
            opacity: currentPage > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: currentPage > 0
                ? IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_back_ios),
              color: Theme.of(context).primaryColor,
            )
                : const SizedBox(width: 48),
          ),

          // 중앙 버튼 (없음 또는 완료)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: currentPage < pageCount - 1
                ? TextButton(
              onPressed: onNext,
              child: const Text('없음'),
            )
                : TextButton(
              onPressed: onFinish,
              child: const Text('완료'),
            ),
          ),

          // 오른쪽 화살표 버튼 (마지막 페이지에서 완료로 변경)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: currentPage < pageCount - 1
                ? IconButton(
              key: const ValueKey('nextButton'),
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_ios),
              color: Theme.of(context).primaryColor,
            )
                : IconButton(
              key: const ValueKey('doneButton'),
              onPressed: onFinish,
              icon: const Icon(Icons.check),
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// 건너뛰기 버튼
class SkipButton extends StatelessWidget {
  final VoidCallback onSkip;

  const SkipButton({
    Key? key,
    required this.onSkip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 48,
      right: 16,
      child: TextButton(
        onPressed: onSkip,
        child: const Text('건너뛰기'),
      ),
    );
  }
}
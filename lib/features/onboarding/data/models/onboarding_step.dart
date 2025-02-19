class OnboardingStep {
  final String title;
  final int step;
  final bool isLastStep;

  const OnboardingStep({
    required this.title,
    required this.step,
    this.isLastStep = false,
  });

  static List<OnboardingStep> get steps => [
    OnboardingStep(
      title: '고정소득의\n 종류와 금액을\n입력해주세요',
      step: 0,
    ),
    // 나머지 5개의 스텝도 여기에 추가
  ];
}
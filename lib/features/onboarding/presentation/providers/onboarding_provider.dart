import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

class OnboardingState {
  final int currentStep;
  final bool isLoading;
  final String? error;

  OnboardingState({
    this.currentStep = 0,
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    int? currentStep,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  void nextStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }
}
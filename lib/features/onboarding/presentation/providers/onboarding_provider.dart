// lib/features/onboarding/presentation/providers/onboarding_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/shared_preference_provider.dart';

class OnboardingState {
  final int currentStep;    // 현재 온보딩 단계
  final bool isCompleted;   // 온보딩 완료 여부
  final Map<String, dynamic> userData;  // 사용자 입력 데이터

  OnboardingState({
    this.currentStep = 0,
    this.isCompleted = false,
    Map<String, dynamic>? userData,
  }) : userData = userData ?? {};
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final SharedPreferences _prefs;

  OnboardingNotifier(this._prefs) : super(OnboardingState());

  void nextStep() {
    if (state.currentStep < 2) {  // 예: 총 3단계
      state = OnboardingState(
        currentStep: state.currentStep + 1,
        userData: state.userData,
      );
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = OnboardingState(
        currentStep: state.currentStep - 1,
        userData: state.userData,
      );
    }
  }

  void updateUserData(String key, dynamic value) {
    final newUserData = Map<String, dynamic>.from(state.userData);
    newUserData[key] = value;
    state = OnboardingState(
      currentStep: state.currentStep,
      userData: newUserData,
    );
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool('isFirstLaunch', false);
    state = OnboardingState(
      currentStep: state.currentStep,
      isCompleted: true,
      userData: state.userData,
    );
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});
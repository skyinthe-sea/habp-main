import 'package:shared_preferences/shared_preferences.dart';

abstract class OnboardingRepository {
  Future<void> completeOnboarding();
  Future<bool> isOnboardingCompleted();
}

class CompleteOnboarding {
  final OnboardingRepository repository;

  CompleteOnboarding(this.repository);

  Future<void> call() async {
    await repository.completeOnboarding();
  }
}
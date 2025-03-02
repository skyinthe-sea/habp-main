import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/usecases/complete_onboarding.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  @override
  Future<void> completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTimeUser', false);
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('isFirstTimeUser') ?? true);
  }
}
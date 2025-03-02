import 'package:get/get.dart';
import '../../features/onboarding/presentation/bindings/onboarding_binding.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../home_page.dart';

class AppRoutes {
  static const String home = '/home';
  static const String onboarding = '/onboarding';

  static final routes = [
    GetPage(
      name: home,
      page: () => const HomePage(),
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingPage(),
      binding: OnboardingBinding(),
    ),
  ];
}
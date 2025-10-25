import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/presentation/pages/main_page.dart';
import 'core/services/ad_service.dart';
import 'core/services/event_bus_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/super_error_silencer.dart'; // 강력한 에러 무시 처리기 추가
import 'core/controllers/theme_controller.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';

// Global key for navigator to handle notification actions
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTimeUser = prefs.getBool('isFirstTimeUser') ?? true;

  // 에러 처리 설정 - 가장 강력한 방법으로 에러 무시
  // 개발/릴리즈 환경에 따라 자동으로 적절한 에러 처리 방식 적용
  SuperErrorSilencer().silenceAllErrors();

  // Google 모바일 광고 SDK 초기화
  await MobileAds.instance.initialize();

  // 서비스 초기화 및 등록
  await Get.putAsync(() => EventBusService().init());
  await Get.putAsync(() => AdService().init());

  // 테마 컨트롤러 초기화
  Get.put(ThemeController());

  // 알림 서비스 초기화 및 스케줄링
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.scheduleDailyNotification();

  await initializeDateFormatting('ko_KR');

  runApp(MyApp(isFirstTimeUser: isFirstTimeUser));
}

class MyApp extends StatelessWidget {
  final bool isFirstTimeUser;

  const MyApp({Key? key, required this.isFirstTimeUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return GetMaterialApp(
      title: '나의 장부',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Add navigator key for notification handling
      theme: themeController.lightTheme,
      darkTheme: themeController.darkTheme,
      themeMode: ThemeMode.system, // 시스템 설정을 따르되, 컨트롤러에서 오버라이드
      // 단순화된 라우팅 - 온보딩 또는 메인 페이지만 직접 지정
      home: isFirstTimeUser
          ? const OnboardingPage() // 온보딩 페이지 클래스로 변경
          : const MainPage(),
      // GetX 라우팅은 필요한 경우에만 추가
      getPages: [],
    );
  }
}

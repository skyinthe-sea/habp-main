import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/presentation/pages/main_page.dart';
import 'core/services/ad_service.dart';
import 'core/services/event_bus_service.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTimeUser = prefs.getBool('isFirstTimeUser') ?? true;

  // Google 모바일 광고 SDK 초기화
  await MobileAds.instance.initialize();

  // 서비스 초기화 및 등록
  await Get.putAsync(() => EventBusService().init());
  await Get.putAsync(() => AdService().init());

  await initializeDateFormatting('ko_KR');

  runApp(MyApp(isFirstTimeUser: isFirstTimeUser));
}

class MyApp extends StatelessWidget {
  final bool isFirstTimeUser;

  const MyApp({Key? key, required this.isFirstTimeUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '나의 장부',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFE495C0),
        primarySwatch: Colors.pink,
        fontFamily: 'Noto Sans JP',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 단순화된 라우팅 - 온보딩 또는 메인 페이지만 직접 지정
      home: isFirstTimeUser
          ? const OnboardingPage() // 온보딩 페이지 클래스로 변경
          : const MainPage(),
      // GetX 라우팅은 필요한 경우에만 추가
      getPages: [],
    );
  }
}

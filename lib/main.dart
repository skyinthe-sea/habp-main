import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTimeUser = prefs.getBool('isFirstTimeUser') ?? true;

  runApp(MyApp(isFirstTimeUser: isFirstTimeUser));
}

class MyApp extends StatelessWidget {
  final bool isFirstTimeUser;

  const MyApp({Key? key, required this.isFirstTimeUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '일본 장인 스타일 앱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Noto Sans JP', // 일본 스타일을 위한 폰트
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: isFirstTimeUser ? AppRoutes.onboarding : AppRoutes.home,
      getPages: AppRoutes.routes,
    );
  }
}

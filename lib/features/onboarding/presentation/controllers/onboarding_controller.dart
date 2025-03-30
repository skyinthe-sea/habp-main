import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/presentation/pages/main_page.dart';
import '../../../../core/routes/app_router.dart';

class OnboardingController extends GetxController {
  // 현재 온보딩 페이지 인덱스
  final RxInt currentPageIndex = 0.obs;

  // 총 페이지 수 (0, 1, 2, 3)
  final int totalPages = 4; // 기존 3에서 4로 변경

  // 다음 페이지로 이동
  void nextPage() {
    if (currentPageIndex.value < totalPages - 1) {
      currentPageIndex.value++;
    } else {
      completeOnboarding();
    }
  }

  // 이전 페이지로 이동
  void previousPage() {
    if (currentPageIndex.value > 0) {
      currentPageIndex.value--;
    }
  }

  // 온보딩 건너뛰기
  void skipOnboarding() {
    completeOnboarding();
  }

  // 온보딩 완료 처리
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTimeUser', false);

    // 메인 화면으로 이동 (named 라우트 대신 직접 위젯 인스턴스를 사용)
    Get.offAll(() => const MainPage());
  }
}
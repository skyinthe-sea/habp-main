// In lib/features/onboarding/presentation/controllers/onboarding_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/db_helper.dart';
import '../../../../core/presentation/pages/main_page.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';

class OnboardingController extends GetxController {
  // 현재 온보딩 페이지 인덱스
  final RxInt currentPageIndex = 0.obs;

  // 총 페이지 수 (0, 1, 2, 3)
  final int totalPages = 4; // 기존 3에서 4로 변경

  // DBHelper 인스턴스
  final DBHelper _dbHelper = DBHelper();

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

    // 미사용 카테고리 삭제
    await _deleteUnusedCategories();

    // 메인 화면으로 이동 (named 라우트 대신 직접 위젯 인스턴스를 사용)
    Get.offAll(() => const MainPage());
  }

  // 미사용 카테고리 삭제 (트랜잭션에 연결되지 않은 카테고리 제거)
  Future<void> _deleteUnusedCategories() async {
    try {
      // 데이터베이스 연결 가져오기
      final db = await _dbHelper.database;

      // 트랜잭션에 사용된 카테고리 ID 가져오기
      final List<Map<String, dynamic>> usedCategories = await db.rawQuery('''
      SELECT DISTINCT category_id FROM transaction_record2
    ''');

      // 사용된 카테고리 ID 목록 생성
      final Set<int> usedCategoryIds = usedCategories
          .map<int>((row) => row['category_id'] as int)
          .toSet();

      // 모든 카테고리 가져오기 (ASSET 유형 제외)
      final List<Map<String, dynamic>> allCategories = await db.query(
          'category',
          where: 'type != ?',
          whereArgs: ['ASSET']  // ASSET 유형의 카테고리는 항상 유지
      );

      // 카테고리 삭제 카운터
      int deletedCount = 0;

      // 사용되지 않은 카테고리 찾기 (ASSET 유형 제외)
      for (final categoryMap in allCategories) {
        final categoryId = categoryMap['id'] as int;
        final categoryType = categoryMap['type'] as String;

        // ASSET 유형이 아니고 사용되지 않는 카테고리만 삭제
        if (!usedCategoryIds.contains(categoryId)) {
          // 사용되지 않은 카테고리 삭제
          await db.delete(
            'category',
            where: 'id = ?',
            whereArgs: [categoryId],
          );
          deletedCount++;
          print('미사용 카테고리 삭제됨: ID $categoryId, 이름 ${categoryMap['name']}, 유형 $categoryType');
        }
      }

      print('미사용 카테고리 삭제 완료: $deletedCount개 항목 삭제됨');
    } catch (e) {
      debugPrint('미사용 카테고리 삭제 중 오류 발생: $e');
      // 오류가 발생해도 진행은 계속함 (치명적인 오류가 아님)
    }
  }
}
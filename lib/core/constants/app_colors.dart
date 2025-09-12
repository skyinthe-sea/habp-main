// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // 앱의 메인 색상
  static const Color primary = Color(0xFFE495C0);
  static const Color unPrimary = Color(0xFF95bfbc);

  // 보조 색상들
  static const Color primaryLight = Color(0xFFF3B8D3);
  static const Color primaryDark = Color(0xFFD87AAE);
  static const Color cardBackground = Colors.white;

  // 일반 색상들
  static const Color white = Color(0xFFf7e6ef);
  static const Color grey = Color(0xFF875671);
  static const Color black = Color(0xFF1c1117);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF616161);

  // 기능 색상들
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // 배경 색상들
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // 텍스트 색상들
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // 아이콘 색상들
  static const Color iconPrimary = Color(0xFF212121);
  static const Color iconSecondary = Color(0xFF757575);

  // 투명 배경 색상
  static Color transparentBlack(double opacity) => Colors.black.withOpacity(opacity);
  static Color transparentWhite(double opacity) => Colors.white.withOpacity(opacity);

  // 카테고리별 색상
  static const Color cate1 = Color(0xFF4990E2); // 월급 (주거비) - 파란색
  static const Color cate2 = Color(0xFFE2A949); // 용돈 - 노란색
  static const Color cate3 = Color(0xFF9B9B9B); // 이자 - 회색
  static const Color cate4 = Color(0xFFE07777); // 통신비 (식비) - 빨간색
  static const Color cate5 = Color(0xFF9177E0); // 유튜브 (의료) - 보라색
  static const Color cate6 = Color(0xFF49C5E2); // 월세 (쇼핑) - 하늘색
  static const Color cate7 = Color(0xFF7CC576); // 보험 (교통비) - 초록색
  static const Color cate8 = Color(0xFFE5A5A5); // 저축 - 연한 빨강
  static const Color cate9 = Color(0xFFE2CF49); // 투자 - 연한 노랑
  static const Color cate10 = Color(0xFF49E292); // 대출 - 민트색

  // 카테고리 ID에 따른 색상 가져오기
  static Color getCategoryColor(int categoryId) {
    switch (categoryId) {
      case 1: return cate1;
      case 2: return cate2;
      case 3: return cate3;
      case 4: return cate4;
      case 5: return cate5;
      case 6: return cate6;
      case 7: return cate7;
      case 8: return cate8;
      case 9: return cate9;
      case 10: return cate10;
      default: return primary;
    }
  }

  // 2025 트렌디한 다크모드 색상 팔레트
  // Primary - 따뜻한 언더톤의 딥 에메랄드
  static const Color darkPrimary = Color(0xFF2D7A6B);  // Deep emerald with warm undertones
  static const Color darkPrimaryLight = Color(0xFF4A9B8C);
  static const Color darkPrimaryDark = Color(0xFF1D5A4E);
  
  // 배경 색상 - 완전한 검정이 아닌 따뜻한 다크 그레이
  static const Color darkBackground = Color(0xFF1A1B1E);  // Rich charcoal
  static const Color darkSurface = Color(0xFF242529);     // Elevated surfaces
  static const Color darkCard = Color(0xFF2A2B30);        // Card backgrounds
  
  // 텍스트 색상 - 높은 대비도이지만 눈에 부담 없는
  static const Color darkTextPrimary = Color(0xFFE8E8E8);   // Soft white
  static const Color darkTextSecondary = Color(0xFFB8B8B8); // Warm gray
  static const Color darkTextHint = Color(0xFF7A7A7A);      // Muted gray
  
  // 액센트 색상들 - 2025 트렌드 컬러 (채도 낮춤)
  static const Color darkAccent1 = Color(0xFFCA6B5C);  // 차분한 코랄
  static const Color darkAccent2 = Color(0xFF5BD1A8);  // 차분한 민트  
  static const Color darkAccent3 = Color(0xFF9B7BCA);  // 차분한 라벤더
  static const Color darkAccent4 = Color(0xFFD4C274);  // 차분한 골드
  
  // 다크 모드 카테고리 색상들 - 채도 더 낮춘 어두운 색상
  static const Color darkCate1 = Color(0xFF5A7AA8);  // 더 어두운 파랑
  static const Color darkCate2 = Color(0xFFB8935F);  // 더 어두운 노랑
  static const Color darkCate3 = Color(0xFF808080);  // 더 어두운 회색
  static const Color darkCate4 = Color(0xFFA85555);  // 더 어두운 빨강
  static const Color darkCate5 = Color(0xFF7E65A8);  // 더 어두운 보라
  static const Color darkCate6 = Color(0xFF4A9BB0);  // 더 어두운 시안
  static const Color darkCate7 = Color(0xFF3D7A4F);  // 더 어두운 초록
  static const Color darkCate8 = Color(0xFFB8809B);  // 더 어두운 핑크
  static const Color darkCate9 = Color(0xFFB8A65F);  // 더 어두운 골드
  static const Color darkCate10 = Color(0xFF4AB090); // 더 어두운 민트
  
  // 기능 색상들 - 다크모드 버전 (채도 더 낮춤)
  static const Color darkSuccess = Color(0xFF3D7A4F);  // 더 어두운 초록
  static const Color darkError = Color(0xFFA85555);    // 더 어두운 빨강
  static const Color darkWarning = Color(0xFFB8935F);  // 더 어두운 주황
  static const Color darkInfo = Color(0xFF5A7AA8);     // 더 어두운 파랑
  
  // 다크모드에서 카테고리 색상 가져오기
  static Color getDarkCategoryColor(int categoryId) {
    switch (categoryId) {
      case 1: return darkCate1;
      case 2: return darkCate2;
      case 3: return darkCate3;
      case 4: return darkCate4;
      case 5: return darkCate5;
      case 6: return darkCate6;
      case 7: return darkCate7;
      case 8: return darkCate8;
      case 9: return darkCate9;
      case 10: return darkCate10;
      default: return darkPrimary;
    }
  }
}
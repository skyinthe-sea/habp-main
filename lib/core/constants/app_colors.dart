import 'package:flutter/material.dart';

// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // 앱의 메인 색상
  static const Color primary = Color(0xFFE495C0);
  static const Color unPrimary = Color(0xFF95bfbc);

  // 보조 색상들
  static const Color primaryLight = Color(0xFFF3B8D3);
  static const Color primaryDark = Color(0xFFD87AAE);

  // 일반 색상들
  static const Color white = Color(0xFFf7e6ef);
  static const Color grey = Color(0xFF875671);
  static const Color black = Colors.black;
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
}
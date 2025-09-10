// lib/core/controllers/theme_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'app_theme_mode';
  
  // Observable theme mode
  final _isDarkMode = false.obs;
  
  bool get isDarkMode => _isDarkMode.value;
  
  // Theme data getters
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: Colors.grey.shade50,
    cardColor: AppColors.card,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onBackground: AppColors.textPrimary,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
      bodySmall: TextStyle(color: AppColors.textHint),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    useMaterial3: true,
  );
  
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.darkPrimary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCard,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      secondary: AppColors.darkPrimaryLight,
      surface: AppColors.darkSurface,
      background: AppColors.darkBackground,
      error: AppColors.darkError,
      onPrimary: AppColors.darkTextPrimary,
      onSecondary: AppColors.darkTextPrimary,
      onSurface: AppColors.darkTextPrimary,
      onBackground: AppColors.darkTextPrimary,
      onError: AppColors.darkTextPrimary,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
      bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
      bodySmall: TextStyle(color: AppColors.darkTextHint),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    useMaterial3: true,
  );
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
  }
  
  // 테마 토글 함수
  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    _saveThemeToPrefs();
    
    // GetX 테마 업데이트
    Get.changeTheme(_isDarkMode.value ? darkTheme : lightTheme);
    
    // 부드러운 전환을 위한 애니메이션 (선택사항)
    update();
  }
  
  // SharedPreferences에서 테마 설정 불러오기
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode.value = prefs.getBool(_themeKey) ?? false;
      
      // 앱 시작 시 테마 설정
      Get.changeTheme(_isDarkMode.value ? darkTheme : lightTheme);
    } catch (e) {
      print('테마 설정 불러오기 실패: $e');
    }
  }
  
  // SharedPreferences에 테마 설정 저장
  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode.value);
    } catch (e) {
      print('테마 설정 저장 실패: $e');
    }
  }
  
  // 현재 테마에 맞는 색상 가져오기 헬퍼 함수들
  Color get primaryColor => _isDarkMode.value ? AppColors.darkPrimary : AppColors.primary;
  Color get backgroundColor => _isDarkMode.value ? AppColors.darkBackground : AppColors.background;
  Color get surfaceColor => _isDarkMode.value ? AppColors.darkSurface : AppColors.surface;
  Color get cardColor => _isDarkMode.value ? AppColors.darkCard : AppColors.card;
  Color get textPrimaryColor => _isDarkMode.value ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textSecondaryColor => _isDarkMode.value ? AppColors.darkTextSecondary : AppColors.textSecondary;
  
  // 카테고리 색상 가져오기
  Color getCategoryColor(int categoryId) {
    return _isDarkMode.value 
        ? AppColors.getDarkCategoryColor(categoryId)
        : AppColors.getCategoryColor(categoryId);
  }
  
  // 성공/에러/경고 색상
  Color get successColor => _isDarkMode.value ? AppColors.darkSuccess : AppColors.success;
  Color get errorColor => _isDarkMode.value ? AppColors.darkError : AppColors.error;
  Color get warningColor => _isDarkMode.value ? AppColors.darkWarning : AppColors.warning;
  Color get infoColor => _isDarkMode.value ? AppColors.darkInfo : AppColors.info;
}
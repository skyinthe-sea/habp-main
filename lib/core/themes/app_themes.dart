import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppThemes {
  // 라이트 테마
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    primarySwatch: Colors.pink,
    scaffoldBackgroundColor: Colors.white,
    brightness: Brightness.light,
    fontFamily: 'Noto Sans JP',
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      foregroundColor: AppColors.primary,
      iconTheme: IconThemeData(color: AppColors.primary),
      titleTextStyle: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey[400],
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black87),
      titleSmall: TextStyle(color: Colors.black87),
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black54),
    ),
    dividerColor: Colors.grey[300],
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: Colors.pinkAccent,
      surface: Colors.white,
      background: Colors.grey[100]!,
      onBackground: Colors.black87,
      error: Colors.redAccent,
    ),
  );

  // 다크 테마
  static final ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.primary,
    primarySwatch: Colors.pink,
    scaffoldBackgroundColor: const Color(0xFF121212),
    brightness: Brightness.dark,
    fontFamily: 'Noto Sans JP',
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 1,
      foregroundColor: AppColors.primary,
      iconTheme: IconThemeData(color: AppColors.primary),
      titleTextStyle: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey[600],
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF2A2A2A),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70),
    ),
    dividerColor: Colors.grey[800],
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: Colors.pinkAccent,
      surface: const Color(0xFF2A2A2A),
      background: const Color(0xFF1E1E1E),
      onBackground: Colors.white,
      error: Colors.redAccent,
    ),
  );
}
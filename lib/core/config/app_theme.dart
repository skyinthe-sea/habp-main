import 'package:flutter/material.dart';

/// App theme configuration
class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFFE495C0);
  static const Color accentColor = Color(0xFFFF8A80);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);
  
  // Text styles
  static const TextStyle headlineStyle = TextStyle(
    color: textColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle titleStyle = TextStyle(
    color: textColor,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    color: textColor,
    fontSize: 14,
  );
  
  static const TextStyle smallStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 12,
  );
  
  // Theme data
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      primarySwatch: Colors.pink,
      fontFamily: 'Noto Sans JP',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 1,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
      ),
      textTheme: const TextTheme(
        headlineLarge: headlineStyle,
        titleLarge: titleStyle,
        bodyLarge: bodyStyle,
        bodyMedium: bodyStyle,
        bodySmall: smallStyle,
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
      ),
    );
  }
}
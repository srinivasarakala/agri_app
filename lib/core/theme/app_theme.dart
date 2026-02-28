import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF388E3C); // Modern green
  static const Color secondaryColor = Color(0xFF81C784); // Light green
  static const Color accentColor = Color(0xFF4CAF50); // Vibrant green
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light background
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color textColor = Color(0xFF212121); // Dark text

  static ThemeData get themeData => ThemeData(
    colorScheme: ColorScheme(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      background: backgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textColor,
      onBackground: textColor,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: textColor),
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textColor),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: accentColor,
      textTheme: ButtonTextTheme.primary,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor,
    ),
  );
}

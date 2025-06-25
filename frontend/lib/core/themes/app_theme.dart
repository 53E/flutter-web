import 'package:flutter/material.dart';

class AppTheme {
  // 게임 테마 색상
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF50E3C2);
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color surfaceColor = Color(0xFF16213E);
  static const Color errorColor = Color(0xFFFF6B6B);
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: MaterialColor(0xFF6C63FF, {
      50: Color(0xFFE8E6FF),
      100: Color(0xFFD1CEFF),
      200: Color(0xFFA39DFF),
      300: Color(0xFF756CFF),
      400: Color(0xFF6C63FF),
      500: Color(0xFF5A51FF),
      600: Color(0xFF4B42E6),
      700: Color(0xFF3C33CC),
      800: Color(0xFF2D24B3),
      900: Color(0xFF1E1599),
    }),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: MaterialColor(0xFF6C63FF, {
      50: Color(0xFFE8E6FF),
      100: Color(0xFFD1CEFF),
      200: Color(0xFFA39DFF),
      300: Color(0xFF756CFF),
      400: Color(0xFF6C63FF),
      500: Color(0xFF5A51FF),
      600: Color(0xFF4B42E6),
      700: Color(0xFF3C33CC),
      800: Color(0xFF2D24B3),
      900: Color(0xFF1E1599),
    }),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Light scheme
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.light,
  );

  // Dark scheme base
  static final ColorScheme _darkSchemeBase = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.dark,
  );

  // Override dark scheme with custom bg
  static final ColorScheme _darkScheme = _darkSchemeBase.copyWith(
    background: AppColors.darkBg,
    surface: AppColors.darkBg,
    surfaceContainerHighest: AppColors.darkBg,
  );

  // LIGHT THEME
  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme,
    scaffoldBackgroundColor: _lightScheme.background,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _lightScheme.primary,
        foregroundColor: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightScheme.primary,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _lightScheme.primary,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE8F2ED), // ✅ Light mode background
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: AppColors.textcolor),
      prefixIconColor: AppColors.textcolor,
    ),
  );

  // DARK THEME
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: _darkScheme,
    scaffoldBackgroundColor: AppColors.darkBg,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _darkScheme.primary,
        foregroundColor: Colors.black,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkScheme.primary,
        foregroundColor: Colors.black,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _darkScheme.primary,
      foregroundColor: Colors.black,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF264533), // ✅ Dark mode background
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: AppColors.textcolor),
      prefixIconColor: AppColors.textcolor,
    ),
  );
}

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Light theme configuration for the app.
ThemeData lightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primaryBlue,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryBlue,
      secondary: AppColors.waterBlue,
      surface: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimaryLight,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryLight,
      ),
    ),
    canvasColor: Colors.white,
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: IconThemeData(color: AppColors.primaryBlue, size: 28),
      unselectedIconTheme: IconThemeData(color: Colors.grey, size: 24),
      selectedLabelTextStyle: TextStyle(
        color: AppColors.primaryBlue,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Colors.grey,
        fontSize: 13,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
    ),
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: Colors.grey.shade100,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryLight,
        letterSpacing: -1,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryLight,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryLight,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimaryLight,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondaryLight,
        height: 1.5,
      ),
    ),
  );
}

/// Dark theme configuration for the app.
ThemeData darkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.accentDark,
    scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentDark,
      secondary: AppColors.accentMutedDark,
      surface: Color(0xFF1E293B), // Slate 800
      onSurface: AppColors.textPrimaryDark,
      error: AppColors.error,
      outline: AppColors.borderDark,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimaryDark,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryDark,
      ),
    ),
    canvasColor: const Color(0xFF1E293B),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFF1E293B),
      selectedIconTheme: IconThemeData(color: AppColors.accentDark, size: 28),
      unselectedIconTheme: IconThemeData(color: Colors.grey, size: 24),
      selectedLabelTextStyle: TextStyle(
        color: AppColors.accentDark,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Colors.grey,
        fontSize: 13,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF334155), width: 1), // Slate 700
      ),
    ),
    dividerTheme: const DividerThemeData(
      thickness: 1,
      color: Color(0xFF334155),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryDark,
        letterSpacing: -1,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryDark,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryDark,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimaryDark,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondaryDark,
        height: 1.5,
      ),
    ),
  );
}

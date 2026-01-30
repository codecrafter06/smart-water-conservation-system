import 'package:flutter/material.dart';

/// App color palette - Consistent colors throughout the app.
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Water Theme Colors
  static const Color waterBlue = Color(0xFF00BCD4);
  static const Color waterDark = Color(0xFF0097A7);
  static const Color waterLight = Color(0xFF4DD0E1);
  static const Color waterDeep = Color(0xFF006064);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Alert Priority Colors
  static const Color alertLow = Color(0xFF8BC34A);
  static const Color alertMedium = Color(0xFFFFEB3B);
  static const Color alertHigh = Color(0xFFFF9800);
  static const Color alertCritical = Color(0xFFF44336);

  // Background Colors (Light Theme)
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Background Colors (Dark Theme)
  static const Color backgroundDark = Color(0xFF0D1117);  // Near-black, not pure black
  static const Color surfaceDark = Color(0xFF161B22);     // Elevated surface
  static const Color cardDark = Color(0xFF1C2128);        // Card background
  static const Color surfaceVariantDark = Color(0xFF21262D); // Higher elevation

  // Dark Theme Accent
  static const Color accentDark = Color(0xFF58A6FF);      // Calm blue accent
  static const Color accentMutedDark = Color(0xFF388BFD); // Slightly darker

  // Dark Theme Borders
  static const Color borderDark = Color(0xFF30363D);      // Subtle borders
  static const Color borderMutedDark = Color(0xFF21262D); // Very subtle

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFE6EDF3);   // Off-white, not pure white
  static const Color textSecondaryDark = Color(0xFF8B949E); // Muted gray

  // Gradient Colors for Tank
  static const List<Color> tankGradient = [
    Color(0xFF00BCD4),
    Color(0xFF0097A7),
    Color(0xFF006064),
  ];

  static const List<Color> tankEmptyGradient = [
    Color(0xFFE0E0E0),
    Color(0xFFBDBDBD),
    Color(0xFF9E9E9E),
  ];

  // Chart Colors
  static const Color chartLine = Color(0xFF2196F3);
  static const Color chartFill = Color(0x402196F3);
  static const Color chartGrid = Color(0xFFE0E0E0);
}

/// Get color based on water level percentage
Color getWaterLevelColor(double level) {
  if (level >= 95) return AppColors.error;
  if (level >= 85) return AppColors.warning;
  if (level <= 10) return AppColors.error;
  if (level <= 20) return AppColors.warning;
  return AppColors.success;
}

/// Get color based on alert priority
Color getAlertPriorityColor(int priority) {
  switch (priority) {
    case 1:
      return AppColors.alertLow;
    case 2:
      return AppColors.alertMedium;
    case 3:
      return AppColors.alertHigh;
    case 4:
      return AppColors.alertCritical;
    default:
      return AppColors.info;
  }
}

/// Core constants module - All magic numbers and configuration values.
/// Eliminates hardcoded values throughout the codebase.
library;

/// API Configuration
class ApiConstants {
  ApiConstants._();

  /// Base URL for the Flask API (change for production)
  static const String baseUrl = 'http://localhost:5000';

  /// API version prefix
  static const String apiPrefix = '/api/v1';

  /// Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  /// API timeout duration in seconds
  static const int timeoutSeconds = 30;

  /// Polling interval for live data in seconds
  static const int pollingIntervalSeconds = 5;
}

/// Water Level Thresholds (percentages)
class WaterLevelConstants {
  WaterLevelConstants._();

  static const double min = 0;
  static const double max = 100;
  static const double criticalLow = 10;
  static const double warningLow = 20;
  static const double warningHigh = 85;
  static const double overflowThreshold = 95;
}

/// Flow Rate Thresholds (liters per minute)
class FlowRateConstants {
  FlowRateConstants._();

  static const double min = 0;
  static const double max = 100;
  static const double normalMax = 15;
  static const double highUsage = 20;
}

/// Alert Priority Levels
class AlertPriority {
  AlertPriority._();

  static const int low = 1;
  static const int medium = 2;
  static const int high = 3;
  static const int critical = 4;
}

/// Status Labels
class StatusLabels {
  StatusLabels._();

  static const String normal = 'normal';
  static const String warning = 'warning';
  static const String critical = 'critical';
  static const String overflowRisk = 'overflow_risk';
  static const String leakageDetected = 'leakage_detected';
}

/// UI Dimension Constants
class Dimensions {
  Dimensions._();

  static const double paddingXS = 4;
  static const double paddingSM = 8;
  static const double paddingMD = 16;
  static const double paddingLG = 24;
  static const double paddingXL = 32;

  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 24;

  static const double iconSM = 20;
  static const double iconMD = 24;
  static const double iconLG = 32;
  static const double iconXL = 48;

  static const double cardHeight = 120;
  static const double tankIndicatorHeight = 200;
  static const double chartHeight = 250;
}

/// Animation Durations (milliseconds)
class AnimationDurations {
  AnimationDurations._();

  static const int fast = 200;
  static const int normal = 300;
  static const int slow = 500;
  static const int verySlow = 800;
  static const int tankFill = 1500;
}

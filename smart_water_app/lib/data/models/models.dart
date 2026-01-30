/// Data models for the Smart Water App.
/// These mirror the API response structures.
library;

/// Represents a sensor reading from the API.
class SensorReading {
  final String deviceId;
  final String tankId;
  final double waterLevelPercent;
  final double flowRateLpm;
  final String timestamp;

  const SensorReading({
    required this.deviceId,
    required this.tankId,
    required this.waterLevelPercent,
    required this.flowRateLpm,
    required this.timestamp,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      deviceId: json['device_id'] ?? '',
      tankId: json['tank_id'] ?? '',
      waterLevelPercent: (json['water_level_percent'] ?? 0).toDouble(),
      flowRateLpm: (json['flow_rate_lpm'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'tank_id': tankId,
        'water_level_percent': waterLevelPercent,
        'flow_rate_lpm': flowRateLpm,
        'timestamp': timestamp,
      };
}

/// Represents the tank status from live dashboard.
class TankStatus {
  final double waterLevelPercent;
  final double flowRateLpm;
  final bool isFilling;
  final bool isDraining;
  final String levelStatus;

  const TankStatus({
    required this.waterLevelPercent,
    required this.flowRateLpm,
    required this.isFilling,
    required this.isDraining,
    required this.levelStatus,
  });

  factory TankStatus.fromJson(Map<String, dynamic> json) {
    return TankStatus(
      waterLevelPercent: (json['water_level_percent'] ?? 0).toDouble(),
      flowRateLpm: (json['flow_rate_lpm'] ?? 0).toDouble(),
      isFilling: json['is_filling'] ?? false,
      isDraining: json['is_draining'] ?? false,
      levelStatus: json['level_status'] ?? 'Unknown',
    );
  }
}

/// Represents the live dashboard response.
class DashboardData {
  final String timestamp;
  final SensorReading? latestReading;
  final String status;
  final String statusMessage;
  final TankStatus tankStatus;
  final List<Alert> alerts;
  final int alertsCount;

  const DashboardData({
    required this.timestamp,
    this.latestReading,
    required this.status,
    required this.statusMessage,
    required this.tankStatus,
    required this.alerts,
    required this.alertsCount,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      timestamp: json['timestamp'] ?? '',
      latestReading: json['latest_reading'] != null
          ? SensorReading.fromJson(json['latest_reading'])
          : null,
      status: json['status'] ?? 'unknown',
      statusMessage: json['status_message'] ?? '',
      tankStatus: TankStatus.fromJson(json['tank_status'] ?? {}),
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((a) => Alert.fromJson(a))
              .toList() ??
          [],
      alertsCount: json['alerts_count'] ?? 0,
    );
  }
}

/// Represents an alert from the system.
class Alert {
  final String type;
  final int priority;
  final String priorityLabel;
  final String message;
  final String deviceId;
  final String tankId;
  final double detectedValue;
  final double threshold;
  final String timestamp;
  final bool acknowledged;
  final String suggestedAction;
  final String cause;

  const Alert({
    required this.type,
    required this.priority,
    required this.priorityLabel,
    required this.message,
    required this.deviceId,
    required this.tankId,
    required this.detectedValue,
    required this.threshold,
    required this.timestamp,
    required this.acknowledged,
    required this.suggestedAction,
    required this.cause,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      type: json['type'] ?? '',
      priority: json['priority'] ?? 1,
      priorityLabel: json['priority_label'] ?? 'Low',
      message: json['message'] ?? '',
      deviceId: json['device_id'] ?? '',
      tankId: json['tank_id'] ?? '',
      detectedValue: (json['detected_value'] ?? 0).toDouble(),
      threshold: (json['threshold'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
      acknowledged: json['acknowledged'] ?? false,
      suggestedAction: json['suggested_action'] ?? 'No action suggested',
      cause: json['cause'] ?? 'Unknown cause',
    );
  }
}

/// Represents daily analytics data.
class DailyData {
  final String date;
  final double averageWaterLevel;
  final double maxWaterLevel;
  final double minWaterLevel;
  final double totalFlowLiters;
  final int readingsCount;

  const DailyData({
    required this.date,
    required this.averageWaterLevel,
    required this.maxWaterLevel,
    required this.minWaterLevel,
    required this.totalFlowLiters,
    required this.readingsCount,
  });

  factory DailyData.fromJson(Map<String, dynamic> json) {
    return DailyData(
      date: json['date'] ?? '',
      averageWaterLevel: (json['average_water_level'] ?? 0).toDouble(),
      maxWaterLevel: (json['max_water_level'] ?? 0).toDouble(),
      minWaterLevel: (json['min_water_level'] ?? 0).toDouble(),
      totalFlowLiters: (json['total_flow_liters'] ?? 0).toDouble(),
      readingsCount: json['readings_count'] ?? 0,
    );
  }
}

/// Represents the full analytics response.
class AnalyticsData {
  final String startDate;
  final String endDate;
  final int days;
  final double totalWaterFlowLiters;
  final double averageDailyLevel;
  final int totalReadings;
  final List<DailyData> dailyData;

  const AnalyticsData({
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.totalWaterFlowLiters,
    required this.averageDailyLevel,
    required this.totalReadings,
    required this.dailyData,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    final period = json['period'] ?? {};
    final summary = json['summary'] ?? {};

    return AnalyticsData(
      startDate: period['start_date'] ?? '',
      endDate: period['end_date'] ?? '',
      days: period['days'] ?? 7,
      totalWaterFlowLiters: (summary['total_water_flow_liters'] ?? 0).toDouble(),
      averageDailyLevel: (summary['average_daily_level'] ?? 0).toDouble(),
      totalReadings: summary['total_readings'] ?? 0,
      dailyData: (json['daily_data'] as List<dynamic>?)
              ?.map((d) => DailyData.fromJson(d))
              .toList() ??
          [],
    );
  }
}

/// Represents water shortage prediction data.
class WaterShortagePrediction {
  final double hoursRemaining;
  final double currentLevelPercent;
  final double currentWaterLiters;
  final String usageStatus;
  final String usageMessage;
  final double usageDiffPercent;
  final String warningLevel;
  final double avgDailyConsumption;
  final double todayConsumption;
  final String timestamp;

  const WaterShortagePrediction({
    required this.hoursRemaining,
    required this.currentLevelPercent,
    required this.currentWaterLiters,
    required this.usageStatus,
    required this.usageMessage,
    required this.usageDiffPercent,
    required this.warningLevel,
    required this.avgDailyConsumption,
    required this.todayConsumption,
    required this.timestamp,
  });

  factory WaterShortagePrediction.fromJson(Map<String, dynamic> json) {
    return WaterShortagePrediction(
      hoursRemaining: (json['hours_remaining'] ?? 0).toDouble(),
      currentLevelPercent: (json['current_level_percent'] ?? 0).toDouble(),
      currentWaterLiters: (json['current_water_liters'] ?? 0).toDouble(),
      usageStatus: json['usage_status'] ?? 'unknown',
      usageMessage: json['usage_message'] ?? '',
      usageDiffPercent: (json['usage_diff_percent'] ?? 0).toDouble(),
      warningLevel: json['warning_level'] ?? 'normal',
      avgDailyConsumption: (json['avg_daily_consumption'] ?? 0).toDouble(),
      todayConsumption: (json['today_consumption'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

/// Represents control state for pumps and valves.
class ControlState {
  final bool pumpMain;
  final bool valveInlet;
  final bool valveOutlet;
  final bool autoMode;
  final String timestamp;

  const ControlState({
    required this.pumpMain,
    required this.valveInlet,
    required this.valveOutlet,
    required this.autoMode,
    required this.timestamp,
  });

  factory ControlState.fromJson(Map<String, dynamic> json) {
    final controls = json['controls'] ?? {};
    return ControlState(
      pumpMain: controls['pump_main'] ?? false,
      valveInlet: controls['valve_inlet'] ?? false,
      valveOutlet: controls['valve_outlet'] ?? true,
      autoMode: controls['auto_mode'] ?? true,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

/// Represents water conservation report.
class ConservationReport {
  final String period;
  final int days;
  final double totalUsageLiters;
  final double averageDailyLiters;
  final double waterSavedLiters;
  final double savingsPercent;
  final double efficiencyPercent;
  final List<String> insights;
  final String timestamp;

  const ConservationReport({
    required this.period,
    required this.days,
    required this.totalUsageLiters,
    required this.averageDailyLiters,
    required this.waterSavedLiters,
    required this.savingsPercent,
    required this.efficiencyPercent,
    required this.insights,
    required this.timestamp,
  });

  factory ConservationReport.fromJson(Map<String, dynamic> json) {
    return ConservationReport(
      period: json['period'] ?? 'weekly',
      days: json['days'] ?? 7,
      totalUsageLiters: (json['total_usage_liters'] ?? 0).toDouble(),
      averageDailyLiters: (json['average_daily_liters'] ?? 0).toDouble(),
      waterSavedLiters: (json['water_saved_liters'] ?? 0).toDouble(),
      savingsPercent: (json['savings_percent'] ?? 0).toDouble(),
      efficiencyPercent: (json['efficiency_percent'] ?? 0).toDouble(),
      insights: (json['insights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

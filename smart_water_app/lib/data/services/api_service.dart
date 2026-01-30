import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/models.dart';

/// Service class for making API calls to the Flask backend.
/// Handles all HTTP communication with proper error handling.
class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? ApiConstants.apiBaseUrl,
        _client = client ?? http.Client();

  /// Get live dashboard data.
  Future<DashboardData> getLiveDashboard() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/dashboard/live'))
          .timeout(const Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return DashboardData.fromJson(json);
      } else {
        throw ApiException('Failed to fetch dashboard data', response.statusCode);
      }
    } on TimeoutException {
      throw ApiException('Request timed out', 408);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Get daily analytics data.
  Future<AnalyticsData> getDailyAnalytics({int days = 7}) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/analytics/daily?days=$days'))
          .timeout(const Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return AnalyticsData.fromJson(json);
      } else {
        throw ApiException('Failed to fetch analytics', response.statusCode);
      }
    } on TimeoutException {
      throw ApiException('Request timed out', 408);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Get all alerts.
  Future<List<Alert>> getAlerts({int limit = 50, bool activeOnly = false}) async {
    try {
      final queryParams = 'limit=$limit&active_only=$activeOnly';
      final response = await _client
          .get(Uri.parse('$baseUrl/alerts?$queryParams'))
          .timeout(const Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final alerts = (json['alerts'] as List<dynamic>)
            .map((a) => Alert.fromJson(a))
            .toList();
        return alerts;
      } else {
        throw ApiException('Failed to fetch alerts', response.statusCode);
      }
    } on TimeoutException {
      throw ApiException('Request timed out', 408);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Get water shortage prediction.
  Future<WaterShortagePrediction> getWaterShortagePrediction() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/predictions/water-shortage'))
          .timeout(const Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return WaterShortagePrediction.fromJson(json);
      } else {
        throw ApiException('Failed to fetch prediction', response.statusCode);
      }
    } on TimeoutException {
      throw ApiException('Request timed out', 408);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Get control state.
  Future<ControlState> getControlState() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/controls/state'))
          .timeout(const Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ControlState.fromJson(json);
      } else {
        throw ApiException('Failed to fetch control state', response.statusCode);
      }
    } on TimeoutException {
      throw ApiException('Request timed out', 408);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Control pump.
  Future<bool> controlPump(String pumpId, bool state) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/controls/pump/$pumpId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'state': state}),
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutSeconds));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Control valve.
  Future<bool> controlValve(String valveId, bool state) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/controls/valve/$valveId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'state': state}),
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutSeconds));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Control auto mode.
  Future<bool> controlAutoMode(bool state) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/controls/auto-mode'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'state': state}),
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutSeconds));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get conservation report.
  Future<ConservationReport> getConservationReport({String period = 'weekly'}) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/reports/conservation?period=$period'))
          .timeout(const Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ConservationReport.fromJson(json);
      } else {
        throw ApiException('Failed to fetch report', response.statusCode);
      }
    } on TimeoutException {
      throw ApiException('Request timed out', 408);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Check API health.
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConstants.baseUrl}/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Dispose the HTTP client.
  void dispose() {
    _client.close();
  }
}

/// Custom exception for API errors.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

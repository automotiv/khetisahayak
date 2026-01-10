import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kheti_sahayak_app/models/weather_alert.dart';
import 'package:kheti_sahayak_app/services/local_notification_service.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';
import 'package:kheti_sahayak_app/utils/logger.dart';

/// Weather Alert Service
///
/// Handles weather alert subscriptions, fetching active alerts,
/// caching, and push notification management.
class WeatherAlertService {
  static const String _subscriptionKey = 'weather_alert_subscription';
  static const String _alertTypesKey = 'weather_alert_types';
  static const String _cachedAlertsKey = 'cached_weather_alerts';
  static const String _lastCheckedKey = 'weather_alerts_last_checked';
  static const String _notifiedAlertsKey = 'notified_weather_alerts';

  // Singleton pattern
  static final WeatherAlertService _instance = WeatherAlertService._internal();
  factory WeatherAlertService() => _instance;
  WeatherAlertService._internal();

  /// Subscribe to weather alerts for a specific location
  static Future<bool> subscribeToAlerts(
    double lat,
    double lon,
    List<String> alertTypes,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Store subscription data locally
      final subscriptionData = {
        'latitude': lat,
        'longitude': lon,
        'alert_types': alertTypes,
        'subscribed_at': DateTime.now().toIso8601String(),
        'is_subscribed': true,
      };
      
      await prefs.setString(_subscriptionKey, json.encode(subscriptionData));
      await prefs.setStringList(_alertTypesKey, alertTypes);

      // Try to register with backend (optional - works offline too)
      try {
        final token = prefs.getString('auth_token');
        if (token != null) {
          await http.post(
            Uri.parse('${Constants.baseUrl}/api/weather/alerts/subscribe'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'latitude': lat,
              'longitude': lon,
              'alert_types': alertTypes,
            }),
          );
        }
      } catch (e) {
        AppLogger.warning('Failed to sync subscription with server: $e');
      }

      AppLogger.info('Subscribed to weather alerts for location ($lat, $lon)');
      return true;
    } catch (e) {
      AppLogger.error('Error subscribing to weather alerts', e);
      return false;
    }
  }

  /// Unsubscribe from weather alerts
  static Future<bool> unsubscribeFromAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update subscription status
      final existingData = prefs.getString(_subscriptionKey);
      if (existingData != null) {
        final data = json.decode(existingData) as Map<String, dynamic>;
        data['is_subscribed'] = false;
        data['unsubscribed_at'] = DateTime.now().toIso8601String();
        await prefs.setString(_subscriptionKey, json.encode(data));
      }

      // Try to unsubscribe from backend
      try {
        final token = prefs.getString('auth_token');
        if (token != null) {
          await http.delete(
            Uri.parse('${Constants.baseUrl}/api/weather/alerts/subscribe'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
        }
      } catch (e) {
        AppLogger.warning('Failed to sync unsubscription with server: $e');
      }

      AppLogger.info('Unsubscribed from weather alerts');
      return true;
    } catch (e) {
      AppLogger.error('Error unsubscribing from weather alerts', e);
      return false;
    }
  }

  /// Check if user is subscribed to alerts
  static Future<bool> isSubscribed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_subscriptionKey);
      if (data == null) return false;
      
      final subscription = json.decode(data) as Map<String, dynamic>;
      return subscription['is_subscribed'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get subscribed alert types
  static Future<List<String>> getSubscribedAlertTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_alertTypesKey) ?? AlertType.all;
    } catch (e) {
      return AlertType.all;
    }
  }

  /// Get subscription location
  static Future<Map<String, double>?> getSubscriptionLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_subscriptionKey);
      if (data == null) return null;
      
      final subscription = json.decode(data) as Map<String, dynamic>;
      if (subscription['latitude'] != null && subscription['longitude'] != null) {
        return {
          'latitude': subscription['latitude'],
          'longitude': subscription['longitude'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get active alerts for a specific location
  static Future<List<WeatherAlert>> getActiveAlerts(double lat, double lon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      // Try to fetch from server
      try {
        final response = await http.get(
          Uri.parse('${Constants.baseUrl}/api/weather/alerts?lat=$lat&lon=$lon'),
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> alertsJson = data['alerts'] ?? data['data'] ?? [];
          final alerts = alertsJson
              .map((a) => WeatherAlert.fromJson(a))
              .where((a) => a.isActive)
              .toList();
          
          // Cache the alerts
          await _cacheAlerts(alerts);
          
          return alerts..sort((a, b) => b.severityLevel.compareTo(a.severityLevel));
        }
      } catch (e) {
        AppLogger.warning('Failed to fetch alerts from server: $e');
      }

      // Fallback to cached alerts or generate mock alerts
      final cachedAlerts = await _getCachedAlerts();
      if (cachedAlerts.isNotEmpty) {
        return cachedAlerts.where((a) => a.isActive).toList();
      }

      // Generate mock alerts for demo/offline mode
      return _generateMockAlerts(lat, lon);
    } catch (e) {
      AppLogger.error('Error fetching active alerts', e);
      return _generateMockAlerts(lat, lon);
    }
  }

  /// Check for new alerts and show notifications
  static Future<void> checkAndNotifyAlerts() async {
    try {
      final isUserSubscribed = await isSubscribed();
      if (!isUserSubscribed) return;

      final location = await getSubscriptionLocation();
      if (location == null) return;

      final lat = location['latitude']!;
      final lon = location['longitude']!;
      
      final alerts = await getActiveAlerts(lat, lon);
      final subscribedTypes = await getSubscribedAlertTypes();
      
      // Filter alerts by subscribed types
      final relevantAlerts = alerts.where(
        (a) => subscribedTypes.contains(a.type)
      ).toList();

      // Get previously notified alerts
      final prefs = await SharedPreferences.getInstance();
      final notifiedIds = prefs.getStringList(_notifiedAlertsKey) ?? [];
      
      // Find new alerts that haven't been notified
      final newAlerts = relevantAlerts.where(
        (a) => !notifiedIds.contains(a.id) && a.severityLevel >= 3 // High or Severe
      ).toList();

      // Show notifications for new severe alerts
      for (final alert in newAlerts) {
        await LocalNotificationService().showNotification(
          id: alert.id.hashCode,
          title: _getNotificationTitle(alert),
          body: alert.description,
          payload: 'weather_alert:${alert.id}',
          channelId: 'weather_alerts_channel',
          channelName: 'Weather Alerts',
          channelDescription: 'Notifications for severe weather alerts',
        );
        
        notifiedIds.add(alert.id);
      }

      // Update notified alerts list (keep only last 100)
      if (notifiedIds.length > 100) {
        notifiedIds.removeRange(0, notifiedIds.length - 100);
      }
      await prefs.setStringList(_notifiedAlertsKey, notifiedIds);
      await prefs.setString(_lastCheckedKey, DateTime.now().toIso8601String());

      AppLogger.info('Checked for new alerts: ${newAlerts.length} new notifications sent');
    } catch (e) {
      AppLogger.error('Error checking and notifying alerts', e);
    }
  }

  /// Get the count of active alerts
  static Future<int> getActiveAlertCount() async {
    try {
      final location = await getSubscriptionLocation();
      if (location == null) return 0;
      
      final alerts = await getActiveAlerts(
        location['latitude']!,
        location['longitude']!,
      );
      return alerts.length;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedAlertsKey);
      await prefs.remove(_lastCheckedKey);
      await prefs.remove(_notifiedAlertsKey);
      AppLogger.info('Weather alert cache cleared');
    } catch (e) {
      AppLogger.error('Error clearing cache', e);
    }
  }

  // Private helper methods

  static Future<void> _cacheAlerts(List<WeatherAlert> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = alerts.map((a) => a.toJson()).toList();
      await prefs.setString(_cachedAlertsKey, json.encode(alertsJson));
    } catch (e) {
      AppLogger.warning('Failed to cache alerts: $e');
    }
  }

  static Future<List<WeatherAlert>> _getCachedAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_cachedAlertsKey);
      if (data == null) return [];
      
      final List<dynamic> alertsJson = json.decode(data);
      return alertsJson.map((a) => WeatherAlert.fromJson(a)).toList();
    } catch (e) {
      return [];
    }
  }

  static String _getNotificationTitle(WeatherAlert alert) {
    final severityEmoji = _getSeverityEmoji(alert.severity);
    return '$severityEmoji ${alert.title}';
  }

  static String _getSeverityEmoji(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return '🚨';
      case 'high':
        return '⚠️';
      case 'moderate':
        return '🔔';
      case 'low':
        return 'ℹ️';
      default:
        return '📢';
    }
  }

  /// Generate mock alerts for demo/offline mode
  static List<WeatherAlert> _generateMockAlerts(double lat, double lon) {
    final now = DateTime.now();
    
    // Generate contextual mock alerts based on season/conditions
    final month = now.month;
    final List<WeatherAlert> mockAlerts = [];

    // Summer months (March-June in India) - Heat wave alerts
    if (month >= 3 && month <= 6) {
      mockAlerts.add(WeatherAlert(
        id: 'mock_heat_${now.millisecondsSinceEpoch}',
        type: AlertType.heatWave,
        severity: AlertSeverity.high,
        title: 'Heat Wave Warning',
        description: 'Temperatures expected to exceed 42°C in the next 48 hours. Stay hydrated and avoid outdoor work during peak hours.',
        startTime: now,
        endTime: now.add(const Duration(days: 2)),
        recommendation: 'Irrigate crops early morning or late evening. Provide shade for livestock. Use mulching to retain soil moisture.',
        latitude: lat,
        longitude: lon,
        affectedArea: 'Your Area',
      ));
    }

    // Monsoon months (June-September) - Heavy rain/flood alerts
    if (month >= 6 && month <= 9) {
      mockAlerts.add(WeatherAlert(
        id: 'mock_rain_${now.millisecondsSinceEpoch}',
        type: AlertType.heavyRain,
        severity: AlertSeverity.moderate,
        title: 'Heavy Rainfall Expected',
        description: 'Heavy to very heavy rainfall expected in the next 24 hours. Cumulative rainfall may exceed 100mm.',
        startTime: now,
        endTime: now.add(const Duration(hours: 36)),
        recommendation: 'Ensure proper drainage in fields. Harvest mature crops if possible. Avoid spray applications. Check for waterlogging.',
        latitude: lat,
        longitude: lon,
        affectedArea: 'Your Area',
      ));
    }

    // Winter months (November-February) - Frost alerts
    if (month >= 11 || month <= 2) {
      mockAlerts.add(WeatherAlert(
        id: 'mock_frost_${now.millisecondsSinceEpoch}',
        type: AlertType.frost,
        severity: AlertSeverity.moderate,
        title: 'Frost Advisory',
        description: 'Ground frost expected during early morning hours. Minimum temperature may drop below 4°C.',
        startTime: now.add(const Duration(hours: 6)),
        endTime: now.add(const Duration(hours: 18)),
        recommendation: 'Cover sensitive crops with straw or plastic sheets. Light irrigation in evening can help. Avoid early morning harvesting.',
        latitude: lat,
        longitude: lon,
        affectedArea: 'Your Area',
      ));
    }

    // Add a low severity informational alert
    mockAlerts.add(WeatherAlert(
      id: 'mock_wind_${now.millisecondsSinceEpoch}',
      type: AlertType.strongWind,
      severity: AlertSeverity.low,
      title: 'Windy Conditions',
      description: 'Wind speeds of 30-40 km/h expected. Generally favorable for outdoor activities but caution advised.',
      startTime: now,
      endTime: now.add(const Duration(hours: 12)),
      recommendation: 'Secure any loose structures. Good conditions for pest control spraying if temperature is favorable.',
      latitude: lat,
      longitude: lon,
      affectedArea: 'Your Area',
    ));

    return mockAlerts..sort((a, b) => b.severityLevel.compareTo(a.severityLevel));
  }
}

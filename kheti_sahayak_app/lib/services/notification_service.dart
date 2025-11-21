import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'auth_service.dart';

/// Push Notification Service for Kheti Sahayak
///
/// This service handles FCM push notifications.
/// To enable real push notifications:
/// 1. Add firebase_core and firebase_messaging to pubspec.yaml
/// 2. Configure Firebase in your Flutter project
/// 3. Add google-services.json (Android) and GoogleService-Info.plist (iOS)
///
/// For development, this uses a mock implementation.
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  NotificationService._();

  String? _fcmToken;
  bool _isInitialized = false;
  final List<void Function(Map<String, dynamic>)> _messageHandlers = [];

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if notifications are initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the notification service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Check if Firebase is available
      // For now, we use a mock token for development
      if (kDebugMode) {
        print('NotificationService: Using mock FCM token (Firebase not configured)');
        _fcmToken = 'mock-fcm-token-${DateTime.now().millisecondsSinceEpoch}';
      }

      // Load saved token
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('fcm_token');
      if (savedToken != null) {
        _fcmToken = savedToken;
      }

      _isInitialized = true;
      print('NotificationService initialized with token: ${_fcmToken?.substring(0, 20)}...');

      // Register with backend if user is logged in
      if (await AuthService.isLoggedIn() && _fcmToken != null) {
        await registerDeviceToken();
      }
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  /// Register device token with backend
  Future<bool> registerDeviceToken() async {
    if (_fcmToken == null) {
      print('No FCM token available');
      return false;
    }

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('User not logged in, skipping device registration');
        return false;
      }

      final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');

      final response = await ApiService.post(
        '/notifications/register-device',
        {
          'token': _fcmToken,
          'platform': platform,
          'device_name': '${Platform.operatingSystem} Device',
          'app_version': '1.0.0',
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true) {
        print('Device registered for push notifications');

        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);

        return true;
      }
    } catch (e) {
      print('Error registering device: $e');
    }

    return false;
  }

  /// Unregister device token from backend
  Future<bool> unregisterDeviceToken() async {
    if (_fcmToken == null) return true;

    try {
      final token = await AuthService.getToken();
      if (token == null) return true;

      await ApiService.delete(
        '/notifications/unregister-device',
        headers: {'Authorization': 'Bearer $token'},
      );

      // Clear local token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');

      return true;
    } catch (e) {
      print('Error unregistering device: $e');
      return false;
    }
  }

  /// Subscribe to a notification topic
  Future<bool> subscribeToTopic(String topic) async {
    if (_fcmToken == null) return false;

    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await ApiService.post(
        '/notifications/subscribe',
        {
          'token': _fcmToken,
          'topic': topic,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      return response['success'] == true;
    } catch (e) {
      print('Error subscribing to topic: $e');
      return false;
    }
  }

  /// Unsubscribe from a notification topic
  Future<bool> unsubscribeFromTopic(String topic) async {
    if (_fcmToken == null) return false;

    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      await ApiService.delete(
        '/notifications/unsubscribe',
        headers: {'Authorization': 'Bearer $token'},
      );

      return true;
    } catch (e) {
      print('Error unsubscribing from topic: $e');
      return false;
    }
  }

  /// Get user's topic subscriptions
  Future<List<String>> getSubscriptions() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return [];

      final response = await ApiService.get(
        '/notifications/subscriptions',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['subscriptions'] != null) {
        return (response['subscriptions'] as List)
            .map((s) => s['topic'] as String)
            .toList();
      }
    } catch (e) {
      print('Error getting subscriptions: $e');
    }

    return [];
  }

  /// Send a test notification to this device
  Future<bool> sendTestNotification() async {
    if (_fcmToken == null) return false;

    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await ApiService.post(
        '/notifications/send-test',
        {'token': _fcmToken},
        headers: {'Authorization': 'Bearer $token'},
      );

      return response['success'] == true;
    } catch (e) {
      print('Error sending test notification: $e');
      return false;
    }
  }

  /// Add a message handler for incoming notifications
  void addMessageHandler(void Function(Map<String, dynamic>) handler) {
    _messageHandlers.add(handler);
  }

  /// Remove a message handler
  void removeMessageHandler(void Function(Map<String, dynamic>) handler) {
    _messageHandlers.remove(handler);
  }

  /// Handle an incoming message (called by Firebase or for testing)
  void handleMessage(Map<String, dynamic> message) {
    for (final handler in _messageHandlers) {
      try {
        handler(message);
      } catch (e) {
        print('Error in message handler: $e');
      }
    }
  }

  /// Clear all data (call on logout)
  Future<void> clear() async {
    await unregisterDeviceToken();
    _fcmToken = null;
    _messageHandlers.clear();
    _isInitialized = false;
  }
}

/// Notification types used in the app
class NotificationTypes {
  static const String weatherAlert = 'weather_alert';
  static const String cropTip = 'crop_tip';
  static const String diagnosisComplete = 'diagnosis_complete';
  static const String orderUpdate = 'order_update';
  static const String priceAlert = 'price_alert';
  static const String expertResponse = 'expert_response';
  static const String communityReply = 'community_reply';
  static const String schemeUpdate = 'scheme_update';
}

/// Available notification topics
class NotificationTopics {
  static const String weatherAlerts = 'weather-alerts';
  static const String cropTips = 'crop-tips';
  static const String priceAlerts = 'price-alerts';
  static const String schemeUpdates = 'scheme-updates';
  static const String dailyDigest = 'daily-digest';
}

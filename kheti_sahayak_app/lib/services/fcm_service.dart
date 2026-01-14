import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kheti_sahayak_app/services/local_notification_service.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/utils/logger.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.info('Background message received: ${message.messageId}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotifications = LocalNotificationService();
  
  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info('FCM: User granted permission');
        await _setupTokenHandling();
        _setupMessageHandlers();
        _isInitialized = true;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        AppLogger.info('FCM: User granted provisional permission');
        await _setupTokenHandling();
        _setupMessageHandlers();
        _isInitialized = true;
      } else {
        AppLogger.warning('FCM: User declined permission');
      }
    } catch (e, stack) {
      AppLogger.error('FCM initialization failed', e, stack);
    }
  }

  Future<void> _setupTokenHandling() async {
    _fcmToken = await _messaging.getToken();
    AppLogger.info('FCM Token: ${_fcmToken?.substring(0, 20)}...');

    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      AppLogger.info('FCM Token refreshed');
      _registerTokenWithBackend(newToken);
    });

    if (_fcmToken != null) {
      await _registerTokenWithBackend(_fcmToken!);
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      
      await ApiService().post('/notifications/register-device', {
        'token': token,
        'platform': platform,
        'device_name': 'Flutter App',
      });
      
      AppLogger.info('FCM token registered with backend');
    } catch (e) {
      AppLogger.error('Failed to register FCM token with backend', e);
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _checkInitialMessage();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info('Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      await _localNotifications.showNotification(
        id: message.hashCode,
        title: notification.title ?? 'Kheti Sahayak',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
        channelId: _getChannelId(message.data),
        channelName: _getChannelName(message.data),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.info('Message opened app: ${message.data}');
    _navigateFromNotification(message.data);
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.info('App opened from terminated state via notification');
      _navigateFromNotification(initialMessage.data);
    }
  }

  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;

    AppLogger.info('Navigate from notification: type=$type, id=$id');
  }

  String _getChannelId(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'WEATHER_ALERT':
        return 'weather_alerts_channel';
      case 'DIAGNOSIS_COMPLETE':
        return 'diagnosis_channel';
      case 'ORDER_UPDATE':
        return 'orders_channel';
      case 'EXPERT_RESPONSE':
        return 'expert_channel';
      default:
        return 'general_channel';
    }
  }

  String _getChannelName(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'WEATHER_ALERT':
        return 'Weather Alerts';
      case 'DIAGNOSIS_COMPLETE':
        return 'Crop Diagnosis';
      case 'ORDER_UPDATE':
        return 'Order Updates';
      case 'EXPERT_RESPONSE':
        return 'Expert Messages';
      default:
        return 'General';
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to subscribe to topic: $topic', e);
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to unsubscribe from topic: $topic', e);
    }
  }

  Future<void> unregisterDevice() async {
    try {
      if (_fcmToken != null) {
        await ApiService().delete('/notifications/unregister-device', {
          'token': _fcmToken,
        });
      }
      await _messaging.deleteToken();
      _fcmToken = null;
      AppLogger.info('FCM device unregistered');
    } catch (e) {
      AppLogger.error('Failed to unregister FCM device', e);
    }
  }
}

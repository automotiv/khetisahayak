import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kheti_sahayak_app/utils/logger.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          AppLogger.info('Notification clicked: ${response.payload}');
          // Handle notification tap logic here if needed
        },
      );

      _isInitialized = true;
      AppLogger.info('LocalNotificationService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize LocalNotificationService', e);
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'weather_alerts_channel',
    String channelName = 'Weather Alerts',
    String channelDescription = 'Notifications for severe weather alerts',
  }) async {
    if (!_isInitialized) await initialize();

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> showApplicationStatusNotification({
    required String schemeName,
    required String status,
    required String applicationId,
  }) async {
    await showNotification(
      id: applicationId.hashCode,
      title: 'Application Update: $schemeName',
      body: 'Your application status has been updated to: $status',
      payload: '/application/$applicationId',
      channelId: 'application_updates_channel',
      channelName: 'Application Updates',
      channelDescription: 'Notifications for application status changes',
    );
  }
}

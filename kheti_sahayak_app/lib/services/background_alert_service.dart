import 'dart:async';
import 'package:kheti_sahayak_app/services/weather_alert_service.dart';
import 'package:kheti_sahayak_app/utils/logger.dart';

/// Background Alert Service
///
/// Handles periodic checking of weather alerts in the background.
/// This service can be initialized during app startup and will
/// check for new alerts at regular intervals.
///
/// For true background execution when app is closed, integrate with
/// workmanager package (see setup instructions below).
///
/// ## Setup for Background Execution (workmanager)
///
/// 1. Add to pubspec.yaml:
/// ```yaml
/// dependencies:
///   workmanager: ^0.5.2
/// ```
///
/// 2. Android: Add to AndroidManifest.xml:
/// ```xml
/// <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
/// <uses-permission android:name="android.permission.WAKE_LOCK"/>
/// ```
///
/// 3. iOS: Enable background fetch in Xcode capabilities
///
/// 4. Initialize in main.dart:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await BackgroundAlertService.initializeWorkManager();
///   runApp(MyApp());
/// }
/// ```
class BackgroundAlertService {
  static Timer? _periodicTimer;
  static const Duration _checkInterval = Duration(minutes: 30);
  static bool _isRunning = false;

  /// Start periodic alert checking when app is in foreground
  static void startPeriodicCheck() {
    if (_isRunning) return;
    
    _isRunning = true;
    
    // Check immediately on start
    _checkAlerts();
    
    // Then check every 30 minutes
    _periodicTimer = Timer.periodic(_checkInterval, (_) {
      _checkAlerts();
    });
    
    AppLogger.info('Background alert checking started (foreground mode)');
  }

  /// Stop periodic alert checking
  static void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _isRunning = false;
    AppLogger.info('Background alert checking stopped');
  }

  /// Check for alerts once
  static Future<void> _checkAlerts() async {
    try {
      AppLogger.debug('Checking for new weather alerts...');
      await WeatherAlertService.checkAndNotifyAlerts();
    } catch (e) {
      AppLogger.error('Error checking alerts in background', e);
    }
  }

  /// Check if service is running
  static bool get isRunning => _isRunning;

  // ============================================================
  // WorkManager Integration (uncomment when workmanager is added)
  // ============================================================

  /*
  static const String _taskName = 'weatherAlertCheck';
  static const String _taskTag = 'weatherAlerts';

  /// Initialize WorkManager for true background execution
  /// Call this in main() before runApp()
  static Future<void> initializeWorkManager() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Register periodic task
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(minutes: 30),
      tag: _taskTag,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    AppLogger.info('WorkManager initialized for background alerts');
  }

  /// Cancel all background tasks
  static Future<void> cancelBackgroundTasks() async {
    await Workmanager().cancelByTag(_taskTag);
    AppLogger.info('Background alert tasks cancelled');
  }
  */
}

// ============================================================
// WorkManager Callback (uncomment when workmanager is added)
// ============================================================

/*
/// Top-level function for WorkManager callback
/// This must be a top-level function (not a class method)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize services needed for background execution
      WidgetsFlutterBinding.ensureInitialized();
      await LocalNotificationService().initialize();
      
      // Check and notify alerts
      await WeatherAlertService.checkAndNotifyAlerts();
      
      return true;
    } catch (e) {
      print('Background task error: $e');
      return false;
    }
  });
}
*/

/// Alert Check Result
class AlertCheckResult {
  final bool success;
  final int alertsFound;
  final int notificationsSent;
  final String? error;
  final DateTime checkedAt;

  AlertCheckResult({
    required this.success,
    this.alertsFound = 0,
    this.notificationsSent = 0,
    this.error,
    DateTime? checkedAt,
  }) : checkedAt = checkedAt ?? DateTime.now();

  @override
  String toString() {
    return 'AlertCheckResult(success: $success, alertsFound: $alertsFound, '
        'notificationsSent: $notificationsSent, error: $error)';
  }
}

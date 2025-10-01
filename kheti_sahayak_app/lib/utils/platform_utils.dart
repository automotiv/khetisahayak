// Platform detection and utility functions for Kheti Sahayak
// Supports Web, Android, iOS, macOS, Windows, and Linux

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform detection and utility class
/// Provides easy methods to detect the current platform
class PlatformUtils {
  // Platform detection
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  
  // Platform groups
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => isMacOS || isWindows || isLinux;
  
  // Platform name
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isMacOS) return 'macOS';
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }
  
  // Platform icon
  static String get platformIcon {
    if (isWeb) return '🌐';
    if (isAndroid) return '🤖';
    if (isIOS) return '🍎';
    if (isMacOS) return '💻';
    if (isWindows) return '🪟';
    if (isLinux) return '🐧';
    return '❓';
  }
  
  // Feature support detection
  static bool get supportsCamera => isMobile;
  static bool get supportsGPS => isMobile;
  static bool get supportsPushNotifications => isMobile;
  static bool get supportsFileSystem => isDesktop || isAndroid || isIOS;
  static bool get supportsKeyboardShortcuts => isDesktop || isWeb;
  
  // Get appropriate padding for platform
  static double get defaultPadding {
    if (isMobile) return 16.0;
    if (isDesktop) return 24.0;
    return 16.0;
  }
  
  // Get appropriate icon size
  static double get defaultIconSize {
    if (isMobile) return 24.0;
    if (isDesktop) return 32.0;
    return 24.0;
  }
  
  // Check if running in debug mode
  static bool get isDebugMode => kDebugMode;
  
  // Check if running in release mode
  static bool get isReleaseMode => kReleaseMode;
  
  // Check if running in profile mode
  static bool get isProfileMode => kProfileMode;
  
  // Log platform information
  static void logPlatformInfo() {
    if (kDebugMode) {
      print('🌾 Kheti Sahayak - Platform Info');
      print('Platform: $platformIcon $platformName');
      print('Mobile: $isMobile');
      print('Desktop: $isDesktop');
      print('Web: $isWeb');
      print('Debug Mode: $isDebugMode');
      print('Camera Support: $supportsCamera');
      print('GPS Support: $supportsGPS');
      print('Push Notifications: $supportsPushNotifications');
    }
  }
}


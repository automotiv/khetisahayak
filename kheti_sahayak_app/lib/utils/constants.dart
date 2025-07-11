class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'https://api.kheti-sahayak.com'; // Update with your actual API URL
  static const String socketUrl = 'wss://api.kheti-sahayak.com'; // Update with your actual WebSocket URL

  // App Information
  static const String appName = 'Kheti Sahayak';
  static const String appVersion = '1.0.0';

  // Supported Languages
  static const List<String> supportedLanguages = [
    'en', // English
    'hi', // Hindi
    'pa', // Punjabi
    'gu', // Gujarati
    'ta', // Tamil
    'te', // Telugu
    'kn', // Kannada
    'ml', // Malayalam
    'bn', // Bengali
    'or', // Odia
    'as', // Assamese
    'mr', // Marathi
  ];

  // File Upload Limits
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Cache Duration
  static const Duration weatherCacheDuration = Duration(minutes: 30);
  static const Duration productCacheDuration = Duration(hours: 1);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Product Categories
  static const List<String> productCategories = [
    'Seeds',
    'Fertilizers',
    'Pesticides',
    'Tools & Equipment',
    'Machinery',
    'Crops',
    'Livestock',
    'Organic Products',
  ];

  // Weather Alert Types
  static const List<String> weatherAlertTypes = [
    'rain',
    'storm',
    'heat_wave',
    'cold_wave',
    'frost',
    'hail',
    'drought',
    'flood',
  ];

  // Diagnostic Confidence Levels
  static const double minDiagnosticConfidence = 0.6;
  static const double highDiagnosticConfidence = 0.8;

  // Notification Types
  static const String notificationTypeWeather = 'weather';
  static const String notificationTypeMarket = 'market';
  static const String notificationTypeCommunity = 'community';
  static const String notificationTypeSystem = 'system';

  // Storage Keys
  static const String storageKeyOnboardingCompleted = 'onboarding_completed';
  static const String storageKeyLanguagePreference = 'language_preference';
  static const String storageKeyLocationPermission = 'location_permission';
  static const String storageKeyNotificationSettings = 'notification_settings';
}
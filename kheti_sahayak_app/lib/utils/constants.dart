class AppConstants {
  // For web development, use localhost
  // static const String baseUrl = 'http://localhost:3000';

  // For Android emulator, use 10.0.2.2 to access host machine's localhost
  // static const String baseUrl = 'http://10.0.2.2:5002';

  // Production URL (Render deployment) - WITHOUT /api suffix
  // Service files add /api prefix to their paths
  static const String baseUrl = 'https://khetisahayak.onrender.com';

  // Add other constants here
}

// Alias for backwards compatibility with services using Constants.baseUrl
typedef Constants = AppConstants;

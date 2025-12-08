import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SchemeService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get schemes (online first, then cache)
  static Future<List<Scheme>> getSchemes({bool forceRefresh = false}) async {
    // 1. Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    try {
      if (isOnline) {
        // 2. Fetch from API
        final response = await http.get(Uri.parse('${AppConstants.baseUrl}/schemes'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final List<dynamic> items = data['data'];
            final schemes = items.map((item) => Scheme.fromJson(item)).toList();

            // 3. Cache schemes
            await _cacheSchemes(items.cast<Map<String, dynamic>>());

            return schemes;
          }
        }
      }
    } catch (e) {
      print('Error fetching schemes from API: $e');
    }

    // 4. Fallback to cache
    print('Fetching schemes from cache...');
    final cachedData = await _dbHelper.getCachedSchemes();
    return cachedData.map((item) => Scheme.fromJson(item)).toList();
  }

  /// Search schemes (local DB)
  static Future<List<Scheme>> searchSchemes(String query) async {
    final cachedData = await _dbHelper.getCachedSchemes(query: query);
    return cachedData.map((item) => Scheme.fromJson(item)).toList();
  }

  /// Update last accessed time
  static Future<void> markSchemeAccessed(int id) async {
    await _dbHelper.updateSchemeLastAccessed(id);
  }

  /// Get recently accessed schemes
  static Future<List<Scheme>> getRecentSchemes() async {
    final cachedData = await _dbHelper.getRecentSchemes();
    return cachedData.map((item) => Scheme.fromJson(item)).toList();
  }

  /// Helper to cache schemes
  static Future<void> _cacheSchemes(List<Map<String, dynamic>> schemes) async {
    try {
      await _dbHelper.cacheSchemes(schemes);
      // Clean up old cache if needed (optional, but good for "Scheme database <100MB")
      // Since text is small, we might not need aggressive cleanup yet.
    } catch (e) {
      print('Error caching schemes: $e');
    }
  }
}

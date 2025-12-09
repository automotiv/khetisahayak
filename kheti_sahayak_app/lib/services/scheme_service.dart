import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SchemeService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get schemes (online first, then cache)
  static Future<List<Scheme>> getSchemes({
    bool forceRefresh = false,
    double? farmSize,
    String? crop,
    String? state,
    String? district,
    double? income,
    String? landOwnership,
  }) async {
    // 1. Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    try {
      if (isOnline) {
        // 2. Fetch from API with filters
        final queryParams = <String, String>{};
        if (farmSize != null) queryParams['farm_size'] = farmSize.toString();
        if (crop != null) queryParams['crop'] = crop;
        if (state != null) queryParams['state'] = state;
        if (district != null) queryParams['district'] = district;
        if (income != null) queryParams['income'] = income.toString();
        if (landOwnership != null) queryParams['land_ownership'] = landOwnership;

        final uri = Uri.parse('${AppConstants.baseUrl}/api/schemes').replace(queryParameters: queryParams);
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final List<dynamic> items = data['data'];
            final schemes = items.map((item) => Scheme.fromJson(item)).toList();

            // 3. Cache schemes (only if no filters applied, or handle partial cache?)
            // For simplicity, we only cache "all schemes" fetch (no filters).
            // Or we just cache everything we get.
            // If filters are applied, we might not want to overwrite the "full list" cache with a partial list.
            // So let's only cache if no filters are applied.
            if (queryParams.isEmpty) {
              await _cacheSchemes(items.cast<Map<String, dynamic>>());
            }
            
            return schemes;
          }
        }
      }
    } catch (e) {
      print('Error fetching schemes from API: $e');
    }

    // 4. Fallback to cache (and apply local filtering if needed)
    print('Fetching schemes from cache...');
    final cachedData = await _dbHelper.getCachedSchemes();
    var schemes = cachedData.map((item) => Scheme.fromJson(item)).toList();

    // Apply local filtering if offline or API failed
    if (farmSize != null) {
      schemes = schemes.where((s) => 
        (s.minFarmSize == null || s.minFarmSize! <= farmSize) && 
        (s.maxFarmSize == null || s.maxFarmSize! >= farmSize)
      ).toList();
    }
    if (crop != null) {
      schemes = schemes.where((s) => s.crops.isEmpty || s.crops.contains('All') || s.crops.contains(crop)).toList();
    }
    if (state != null) {
      schemes = schemes.where((s) => s.states.isEmpty || s.states.contains('All') || s.states.contains(state)).toList();
    }
    if (district != null) {
      schemes = schemes.where((s) => s.districts.isEmpty || s.districts.contains('All') || s.districts.contains(district)).toList();
    }
    if (income != null) {
      schemes = schemes.where((s) => 
        (s.minIncome == null || s.minIncome! <= income) && 
        (s.maxIncome == null || s.maxIncome! >= income)
      ).toList();
    }
    if (landOwnership != null) {
      schemes = schemes.where((s) => s.landOwnershipType == null || s.landOwnershipType == 'Any' || s.landOwnershipType == landOwnership).toList();
    }

    return schemes;
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

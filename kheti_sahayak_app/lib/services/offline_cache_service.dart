import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/models/user.dart';
import 'package:kheti_sahayak_app/models/product.dart';
import 'package:kheti_sahayak_app/models/educational_content.dart';
import 'package:kheti_sahayak_app/models/expert.dart';

/// Cache TTL (Time To Live) configuration
class CacheTTL {
  /// User profile: 7 days (P0 - Critical)
  static const Duration userProfile = Duration(days: 7);
  
  /// Weather data: 24 hours (P0 - Critical)
  static const Duration weather = Duration(hours: 24);
  
  /// Products: 12 hours (P1 - Important)
  static const Duration products = Duration(hours: 12);
  
  /// Educational content: 7 days (P1 - Important)
  static const Duration educationalContent = Duration(days: 7);
  
  /// Experts: 24 hours (P2 - Normal)
  static const Duration experts = Duration(hours: 24);
  
  /// Schemes: 7 days (P1 - Important)
  static const Duration schemes = Duration(days: 7);
}

/// Cache priority levels
enum CachePriority {
  /// P0: Critical data (user profile, weather)
  critical(0),
  
  /// P1: Important data (products, educational content)
  important(1),
  
  /// P2: Normal data (experts, community)
  normal(2),
  
  /// P3: Low priority (analytics, logs)
  low(3);
  
  final int value;
  const CachePriority(this.value);
}

/// Comprehensive offline cache service for Kheti Sahayak
class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  static OfflineCacheService get instance => _instance;
  
  factory OfflineCacheService() => _instance;
  
  OfflineCacheService._internal();
  
  /// Maximum cache size in bytes (50 MB default)
  static const int maxCacheSizeBytes = 50 * 1024 * 1024;
  
  // ================== WEATHER CACHING ==================
  
  /// Cache weather data for a location (24-hour TTL)
  static Future<void> cacheWeather(double lat, double lon, Map<String, dynamic> data, {String? locationName}) async {
    await DatabaseHelper.instance.cacheWeatherByCoords(
      latitude: lat,
      longitude: lon,
      locationName: locationName,
      data: data,
      ttl: CacheTTL.weather,
    );
  }
  
  /// Get cached weather data for a location
  static Future<Map<String, dynamic>?> getCachedWeather(double lat, double lon) async {
    final result = await DatabaseHelper.instance.getCachedWeatherByCoords(lat, lon);
    if (result != null) {
      return result['data'] as Map<String, dynamic>;
    }
    return null;
  }
  
  /// Check if weather cache is valid for a location
  static Future<bool> isWeatherCacheValid(double lat, double lon) async {
    return await DatabaseHelper.instance.isWeatherCacheValid(lat, lon);
  }
  
  /// Clear expired weather cache
  static Future<int> clearExpiredWeatherCache() async {
    return await DatabaseHelper.instance.clearExpiredWeatherCacheV2();
  }
  
  // ================== PRODUCTS CACHING ==================
  
  /// Cache products (12-hour TTL)
  static Future<void> cacheProducts(List<Product> products) async {
    final productMaps = products.map((p) => p.toJson()).toList();
    await DatabaseHelper.instance.cacheProducts(productMaps);
  }
  
  /// Get cached products
  static Future<List<Product>> getCachedProducts({String? category, String? searchQuery, int? limit}) async {
    final results = await DatabaseHelper.instance.getCachedProducts(
      category: category,
      searchQuery: searchQuery,
      limit: limit,
    );
    
    return results.map((map) => Product.fromJson(map)).toList();
  }
  
  /// Get single cached product
  static Future<Product?> getCachedProduct(int id) async {
    final result = await DatabaseHelper.instance.getCachedProduct(id);
    if (result != null) {
      return Product.fromJson(result);
    }
    return null;
  }
  
  /// Clear products cache
  static Future<int> clearProductsCache() async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('cached_products');
  }
  
  // ================== EDUCATIONAL CONTENT CACHING ==================
  
  /// Cache educational content (7-day TTL)
  static Future<void> cacheContent(List<EducationalContent> content, {CachePriority priority = CachePriority.important}) async {
    final contentMaps = content.map((c) => c.toJson()).toList();
    await DatabaseHelper.instance.cacheEducationalContent(contentMaps, priority: priority.value);
  }
  
  /// Get cached educational content
  static Future<List<EducationalContent>> getCachedContent({String? category, String? searchQuery, int? limit}) async {
    final results = await DatabaseHelper.instance.getCachedEducationalContent(
      category: category,
      searchQuery: searchQuery,
      limit: limit,
    );
    
    return results.map((map) => EducationalContent.fromJson(map)).toList();
  }
  
  /// Clear educational content cache
  static Future<int> clearContentCache() async {
    return await DatabaseHelper.instance.clearEducationalContentCache();
  }
  
  // ================== EXPERTS CACHING ==================
  
  /// Cache experts (24-hour TTL)
  static Future<void> cacheExperts(List<Expert> experts) async {
    final expertMaps = experts.map((e) => {
      'id': e.id,
      'name': e.name,
      'specialization': e.specialization,
      'qualification': e.qualification,
      'experience_years': e.experienceYears,
      'rating': e.rating,
      'image_url': e.imageUrl,
      'is_online': e.isOnline,
    }).toList();
    
    await DatabaseHelper.instance.cacheExperts(expertMaps);
  }
  
  /// Get cached experts
  static Future<List<Expert>> getCachedExperts({String? specialization}) async {
    final results = await DatabaseHelper.instance.getCachedExperts(specialization: specialization);
    
    return results.map((map) => Expert.fromJson(map)).toList();
  }
  
  /// Clear experts cache
  static Future<int> clearExpertsCache() async {
    return await DatabaseHelper.instance.clearExpertsCache();
  }
  
  // ================== USER PROFILE CACHING ==================
  
  /// Cache user profile (7-day TTL)
  static Future<void> cacheUserProfile(User user) async {
    await DatabaseHelper.instance.cacheUserProfile(user.toJson(), ttl: CacheTTL.userProfile);
  }
  
  /// Get cached user profile
  static Future<User?> getCachedUserProfile({String? userId}) async {
    Map<String, dynamic>? result;
    
    if (userId != null) {
      result = await DatabaseHelper.instance.getCachedUserProfile(userId);
    } else {
      result = await DatabaseHelper.instance.getAnyCachedUserProfile();
    }
    
    if (result != null) {
      return User.fromJson(result);
    }
    return null;
  }
  
  /// Clear user profile cache
  static Future<int> clearUserProfileCache() async {
    return await DatabaseHelper.instance.clearUserProfileCache();
  }
  
  // ================== CACHE MANAGEMENT ==================
  
  /// Clear all expired caches
  static Future<Map<String, int>> clearExpiredCache() async {
    return await DatabaseHelper.instance.clearAllExpiredCaches();
  }
  
  /// Get total cache size in bytes
  static Future<int> getCacheSizeBytes() async {
    return await DatabaseHelper.instance.getTotalCacheSizeBytes();
  }
  
  /// Check if cache is within size limits
  static Future<bool> isCacheWithinLimits() async {
    final size = await getCacheSizeBytes();
    return size <= maxCacheSizeBytes;
  }
  
  /// Clear all cache data
  static Future<void> clearAllCache() async {
    await DatabaseHelper.instance.clearAllCaches();
  }
  
  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    return await DatabaseHelper.instance.getComprehensiveStats();
  }
  
  /// Prune cache if it exceeds size limits
  /// Removes lowest priority items first
  static Future<void> pruneCache() async {
    final currentSize = await getCacheSizeBytes();
    
    if (currentSize <= maxCacheSizeBytes) {
      return; // Cache is within limits
    }
    
    // Calculate how much we need to remove
    final targetSize = (maxCacheSizeBytes * 0.8).toInt(); // Target 80% of max
    
    // Clear in order of priority (lowest first)
    // P3: Clear completed sync operations
    await DatabaseHelper.instance.clearCompletedSyncOperations();
    
    if (await getCacheSizeBytes() <= targetSize) return;
    
    // P2: Clear old experts cache
    await clearExpertsCache();
    
    if (await getCacheSizeBytes() <= targetSize) return;
    
    // P1: Clear old products cache
    await DatabaseHelper.instance.clearOldCachedProducts(daysToKeep: 3);
    
    if (await getCacheSizeBytes() <= targetSize) return;
    
    // P1: Clear old educational content (keep most recent)
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'cached_educational_content',
      where: 'priority > 0',
    );
    
    if (await getCacheSizeBytes() <= targetSize) return;
    
    // P0: Clear old diagnostics cache
    await DatabaseHelper.instance.clearOldCache(daysToKeep: 7);
  }
  
  // ================== IMAGE CACHING ==================
  
  /// Get cache directory for images
  static Future<Directory> getImageCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/image_cache');
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }
  
  /// Cache an image from URL
  static Future<String?> cacheImage(String imageUrl) async {
    try {
      final cacheDir = await getImageCacheDirectory();
      final fileName = imageUrl.hashCode.toString();
      final filePath = '${cacheDir.path}/$fileName';
      
      final file = File(filePath);
      if (await file.exists()) {
        return filePath; // Already cached
      }
      
      // Download and save
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(imageUrl));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>(
          [],
          (previous, element) => previous..addAll(element),
        );
        await file.writeAsBytes(bytes);
        return filePath;
      }
    } catch (e) {
      print('Error caching image: $e');
    }
    return null;
  }
  
  /// Get cached image path
  static Future<String?> getCachedImagePath(String imageUrl) async {
    try {
      final cacheDir = await getImageCacheDirectory();
      final fileName = imageUrl.hashCode.toString();
      final filePath = '${cacheDir.path}/$fileName';
      
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }
    } catch (e) {
      print('Error getting cached image: $e');
    }
    return null;
  }
  
  /// Clear image cache
  static Future<void> clearImageCache() async {
    try {
      final cacheDir = await getImageCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing image cache: $e');
    }
  }
  
  /// Get image cache size
  static Future<int> getImageCacheSizeBytes() async {
    try {
      final cacheDir = await getImageCacheDirectory();
      if (!await cacheDir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
  
  // ================== DATA COMPRESSION ==================
  
  /// Compress data for storage
  static String compressData(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final compressed = gzip.encode(bytes);
    return base64Encode(compressed);
  }
  
  /// Decompress data from storage
  static Map<String, dynamic> decompressData(String compressedData) {
    final compressed = base64Decode(compressedData);
    final bytes = gzip.decode(compressed);
    final jsonString = utf8.decode(bytes);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
  
  // ================== BULK OPERATIONS ==================
  
  /// Preload essential data for offline use
  static Future<void> preloadEssentialData({
    required User user,
    List<Product>? products,
    List<EducationalContent>? content,
    List<Expert>? experts,
    Map<String, dynamic>? weatherData,
    double? latitude,
    double? longitude,
  }) async {
    // Cache user profile (P0)
    await cacheUserProfile(user);
    
    // Cache weather if provided (P0)
    if (weatherData != null && latitude != null && longitude != null) {
      await cacheWeather(latitude, longitude, weatherData);
    }
    
    // Cache products (P1)
    if (products != null && products.isNotEmpty) {
      await cacheProducts(products);
    }
    
    // Cache educational content (P1)
    if (content != null && content.isNotEmpty) {
      await cacheContent(content);
    }
    
    // Cache experts (P2)
    if (experts != null && experts.isNotEmpty) {
      await cacheExperts(experts);
    }
    
    // Prune if necessary
    await pruneCache();
  }
  
  /// Check if essential data is cached
  static Future<Map<String, bool>> checkEssentialDataCached({
    String? userId,
    double? latitude,
    double? longitude,
  }) async {
    final results = <String, bool>{};
    
    // Check user profile
    final userProfile = await getCachedUserProfile(userId: userId);
    results['userProfile'] = userProfile != null;
    
    // Check weather
    if (latitude != null && longitude != null) {
      results['weather'] = await isWeatherCacheValid(latitude, longitude);
    } else {
      results['weather'] = false;
    }
    
    // Check products
    final products = await getCachedProducts(limit: 1);
    results['products'] = products.isNotEmpty;
    
    // Check educational content
    final content = await getCachedContent(limit: 1);
    results['educationalContent'] = content.isNotEmpty;
    
    // Check experts
    final experts = await getCachedExperts();
    results['experts'] = experts.isNotEmpty;
    
    return results;
  }
}

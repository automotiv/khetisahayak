import 'package:kheti_sahayak_app/models/wishlist.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';

class WishlistService {
  static Set<String> _cachedWishlistIds = {};
  static bool _isCacheInitialized = false;

  static Future<Wishlist> getWishlist() async {
    try {
      final response = await ApiService.get('api/marketplace/wishlist');

      if (response['success'] == true && response['data'] != null) {
        final wishlist = Wishlist.fromJson(response['data']);
        _cachedWishlistIds = wishlist.items.map((item) => item.productId).toSet();
        _isCacheInitialized = true;
        return wishlist;
      } else {
        throw Exception(response['error'] ?? 'Failed to get wishlist');
      }
    } catch (e) {
      throw Exception('Failed to get wishlist: ${e.toString()}');
    }
  }

  static Future<Set<String>> getWishlistProductIds() async {
    if (_isCacheInitialized) {
      return _cachedWishlistIds;
    }

    try {
      final response = await ApiService.get('api/marketplace/wishlist/ids');

      if (response['success'] == true && response['data'] != null) {
        final ids = List<String>.from(response['data']['productIds'] ?? []);
        _cachedWishlistIds = ids.toSet();
        _isCacheInitialized = true;
        return _cachedWishlistIds;
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  static Future<void> addToWishlist(String productId) async {
    try {
      final response = await ApiService.post(
        'api/marketplace/wishlist/$productId',
        {},
      );

      if (response['success'] == true) {
        _cachedWishlistIds.add(productId);
      } else {
        throw Exception(response['error'] ?? 'Failed to add to wishlist');
      }
    } catch (e) {
      throw Exception('Failed to add to wishlist: ${e.toString()}');
    }
  }

  static Future<void> removeFromWishlist(String productId) async {
    try {
      final response = await ApiService.delete(
        'api/marketplace/wishlist/$productId',
      );

      if (response['success'] == true) {
        _cachedWishlistIds.remove(productId);
      } else {
        throw Exception(response['error'] ?? 'Failed to remove from wishlist');
      }
    } catch (e) {
      throw Exception('Failed to remove from wishlist: ${e.toString()}');
    }
  }

  static Future<void> toggleWishlist(String productId) async {
    if (isInWishlistSync(productId)) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(productId);
    }
  }

  static Future<bool> isInWishlist(String productId) async {
    try {
      final response = await ApiService.get(
        'api/marketplace/wishlist/$productId',
      );

      if (response['success'] == true && response['data'] != null) {
        return response['data']['inWishlist'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static bool isInWishlistSync(String productId) {
    return _cachedWishlistIds.contains(productId);
  }

  static void clearCache() {
    _cachedWishlistIds.clear();
    _isCacheInitialized = false;
  }

  static Future<void> initializeCache() async {
    await getWishlistProductIds();
  }
}

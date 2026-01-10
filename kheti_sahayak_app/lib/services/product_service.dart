import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/services/auth_service.dart';
import 'package:kheti_sahayak_app/models/product.dart';

class ProductService {
  static Future<List<Product>> getProducts({
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await ApiService.get(
        'marketplace',
        queryParams: queryParams,
      );

      // Handle response formats - ApiService.get always returns Map<String, dynamic>
      if (response['products'] != null) {
        return (response['products'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
      } else if (response['data'] != null) {
        return (response['data'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error in getProducts: $e');
      throw Exception('Failed to fetch products: $e');
    }
  }

  static Future<Product> getProduct(String productId) async {
    try {
      final response = await ApiService.get('marketplace/$productId');
      return Product.fromJson(response['product'] ?? response);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  static Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await ApiService.post('marketplace', productData);
      return Product.fromJson(response['product'] ?? response);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  static Future<Product> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      final response = await ApiService.put('marketplace/$productId', productData);
      return Product.fromJson(response['product'] ?? response);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  static Future<void> deleteProduct(String productId) async {
    try {
      await ApiService.delete('marketplace/$productId');
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      final response = await ApiService.get('marketplace/categories');

      if (response['categories'] != null) {
        return List<String>.from(response['categories']);
      } else if (response['data'] != null) {
        return List<String>.from(response['data']);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }
}
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
      Map<String, dynamic> params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category.isNotEmpty) {
        params['category'] = category;
      }

      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final token = await AuthService.getToken();
      final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

      final response = await ApiService.get(
        '/marketplace/products?${_buildQueryString(params)}',
        headers: headers,
      );

      if (response['products'] != null) {
        return (response['products'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  static Future<Product> getProduct(String productId) async {
    try {
      final token = await AuthService.getToken();
      final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

      final response = await ApiService.get(
        '/marketplace/products/$productId',
        headers: headers,
      );

      return Product.fromJson(response['product']);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  static Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication required');

      final response = await ApiService.post(
        '/marketplace/products',
        body: productData,
        headers: {'Authorization': 'Bearer $token'},
      );

      return Product.fromJson(response['product']);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  static Future<Product> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication required');

      final response = await ApiService.put(
        '/marketplace/products/$productId',
        body: productData,
        headers: {'Authorization': 'Bearer $token'},
      );

      return Product.fromJson(response['product']);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  static Future<void> deleteProduct(String productId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication required');

      await ApiService.delete(
        '/marketplace/products/$productId',
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      final response = await ApiService.get('/marketplace/categories');

      if (response['categories'] != null) {
        return List<String>.from(response['categories']);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  static String _buildQueryString(Map<String, dynamic> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
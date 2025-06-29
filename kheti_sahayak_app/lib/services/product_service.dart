import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/models/product.dart';

class ProductService {
  static Future<List<Product>> getProducts() async {
    final response = await ApiService.get('marketplace/products');
    return (response['products'] as List)
        .map((productJson) => Product.fromJson(productJson))
        .toList();
  }

  static Future<Product> getProductById(String id) async {
    final response = await ApiService.get('marketplace/products/$id');
    return Product.fromJson(response['product']);
  }

  static Future<Product> createProduct(Product product) async {
    final response = await ApiService.post('marketplace/products', product.toJson());
    return Product.fromJson(response);
  }

  static Future<Product> updateProduct(String id, Product product) async {
    final response = await ApiService.put('marketplace/products/$id', product.toJson());
    return Product.fromJson(response);
  }

  static Future<void> deleteProduct(String id) async {
    await ApiService.delete('marketplace/products/$id');
  }
}
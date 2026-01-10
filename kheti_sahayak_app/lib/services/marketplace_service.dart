import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/product.dart';
import 'package:kheti_sahayak_app/models/cart.dart';
import 'package:kheti_sahayak_app/models/order.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class MarketplaceService {
  static DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static http.Client _client = http.Client();
  static const _uuid = Uuid();

  // For testing
  static void setHelpers({DatabaseHelper? dbHelper, http.Client? client}) {
    if (dbHelper != null) _dbHelper = dbHelper;
    if (client != null) _client = client;
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get products (Offline First)
  static Future<List<Product>> getProducts({String? category}) async {
    try {
      // 1. Try to fetch from API
      final token = await _getToken();
      if (token != null) {
        final uri = category != null
            ? Uri.parse('${Constants.baseUrl}/api/products?category=$category')
            : Uri.parse('${Constants.baseUrl}/api/products');
            
        final response = await _client.get(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final List<dynamic> items = data['data'];
            // Cache products
            await _dbHelper.cacheProducts(items.cast<Map<String, dynamic>>());
            return items.map((item) => Product.fromJson(item)).toList();
          }
        }
      }
    } catch (e) {
      print('Error fetching products from API: $e');
    }

    // 2. Fallback to cache
    final cached = await _dbHelper.getCachedProducts(category: category);
    return cached.map((map) => Product.fromJson(map)).toList();
  }

  /// Get cart items (Local)
  static Future<List<CartItem>> getCart() async {
    final cached = await _dbHelper.getCartItems();
    return cached.map((map) => CartItem.fromJson(map)).toList();
  }

  /// Add to cart (Local)
  static Future<void> addToCart(Product product, int quantity) async {
    final cartItems = await getCart();
    final existingItem = cartItems.firstWhere(
      (item) => item.productId == product.id,
      orElse: () => CartItem(
        id: '',
        productId: '',
        quantity: 0,
        unitPrice: 0,
        totalPrice: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        productName: '',
        isAvailable: false,
      ),
    );

    if (existingItem.productId.isNotEmpty) {
      // Update existing
      final newQuantity = existingItem.quantity + quantity;
      final newTotal = newQuantity * existingItem.unitPrice;
      await _dbHelper.updateMarketplaceCartItemQuantity(existingItem.id, newQuantity, newTotal);
    } else {
      // Add new
      final newItem = CartItem(
        id: _uuid.v4(),
        productId: product.id,
        quantity: quantity,
        unitPrice: product.price,
        totalPrice: product.price * quantity,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        productName: product.name,
        productDescription: product.description,
        productImages: product.imageUrl != null ? [product.imageUrl!] : [],
        isAvailable: true,
        category: product.category,
      );
      await _dbHelper.addToCart(newItem.toJson());
    }
  }

  /// Update cart quantity
  static Future<void> updateCartQuantity(String itemId, int quantity, double unitPrice) async {
    await _dbHelper.updateMarketplaceCartItemQuantity(itemId, quantity, quantity * unitPrice);
  }

  /// Place order
  static Future<bool> placeOrder(Order order) async {
    try {
      // 1. Save locally
      await _dbHelper.saveOrder(order.toJson());

      // 2. Send to API
      final token = await _getToken();
      if (token != null) {
        final response = await _client.post(
          Uri.parse('${Constants.baseUrl}/api/orders'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(order.toJson()),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Clear cart on success
          await _dbHelper.clearCart();
          return true;
        }
      }
    } catch (e) {
      print('Error placing order: $e');
    }
    
    // Even if API fails, we saved locally. 
    // Ideally we should have a sync mechanism for pending orders.
    // For now, let's clear cart if local save worked (simulating offline success)
    await _dbHelper.clearCart();
    return true;
  }
}

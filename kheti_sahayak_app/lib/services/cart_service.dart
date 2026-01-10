import 'package:kheti_sahayak_app/models/cart.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';

class CartService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get all cart items with product details
  static Future<Cart> getCart() async {
    try {
      final response = await ApiService.get('api/cart');

      if (response['success'] == true && response['data'] != null) {
        // Cache the cart (store as list of items)
        final cartData = response['data'];
        if (cartData is Map<String, dynamic> && cartData['items'] != null) {
          await _dbHelper.clearCachedCart();
          for (var item in cartData['items']) {
            await _dbHelper.upsertCartItem(
              productId: int.tryParse(item['product_id']?.toString() ?? '0') ?? 0,
              productName: item['product_name'] ?? '',
              productImage: item['product_image'],
              quantity: item['quantity'] ?? 1,
              price: (item['unit_price'] as num?)?.toDouble() ?? 0.0,
            );
          }
        }
        return Cart.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Failed to get cart');
      }
    } catch (e) {
      // Try to load from cache - getCachedCart returns List<Map<String, dynamic>>
      final cachedCartItems = await _dbHelper.getCachedCart();
      if (cachedCartItems.isNotEmpty) {
        // Convert cached cart items back to Cart format
        final items = cachedCartItems.map((item) {
          final quantity = item['quantity'] ?? 1;
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
          return CartItem(
            id: item['id']?.toString() ?? '',
            productId: item['product_id']?.toString() ?? '',
            quantity: quantity,
            unitPrice: price,
            totalPrice: price * quantity,
            createdAt: DateTime.now(),
            updatedAt: DateTime.tryParse(item['updated_at'] ?? '') ?? DateTime.now(),
            productName: item['product_name'] ?? '',
            productImages: item['product_image'] != null ? [item['product_image']] : null,
            isAvailable: true,
          );
        }).toList();
        
        // Calculate summary
        final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
        final totalItems = items.fold(0, (sum, item) => sum + item.quantity);
        
        return Cart(
          items: items,
          summary: CartSummary(
            subtotal: subtotal,
            totalItems: totalItems,
            itemCount: items.length,
          ),
        );
      }
      // If no cache, rethrow error
      throw Exception('Failed to get cart: ${e.toString()}');
    }
  }

  // Get cart summary (count and total only, lighter than full cart)
  static Future<CartSummary> getCartSummary() async {
    try {
      final response = await ApiService.get('api/cart/summary');

      if (response['success'] == true && response['data'] != null) {
        return CartSummary.fromJson(response['data']);
      } else {
        // Return empty summary if error or no data
        return CartSummary(subtotal: 0.0, totalItems: 0, itemCount: 0);
      }
    } catch (e) {
      // Return empty summary on error instead of throwing
      return CartSummary(subtotal: 0.0, totalItems: 0, itemCount: 0);
    }
  }

  // Add item to cart or increase quantity if already exists
  static Future<Map<String, dynamic>> addToCart({
    required String productId,
    int quantity = 1,
  }) async {
    try {
      final response = await ApiService.post(
        'api/cart',
        {
          'product_id': productId,
          'quantity': quantity,
        },
      );

      if (response['success'] == true) {
        return response;
      } else {
        throw Exception(response['error'] ?? 'Failed to add item to cart');
      }
    } catch (e) {
      throw Exception('Failed to add to cart: ${e.toString()}');
    }
  }

  // Update cart item quantity
  static Future<Map<String, dynamic>> updateCartItem({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      if (quantity < 1) {
        throw Exception('Quantity must be at least 1');
      }

      final response = await ApiService.put(
        'api/cart/$cartItemId',
        {'quantity': quantity},
      );

      if (response['success'] == true) {
        return response;
      } else {
        throw Exception(response['error'] ?? 'Failed to update cart item');
      }
    } catch (e) {
      throw Exception('Failed to update cart item: ${e.toString()}');
    }
  }

  // Remove item from cart
  static Future<void> removeCartItem(String cartItemId) async {
    try {
      final response = await ApiService.delete('api/cart/$cartItemId');

      if (response['success'] != true) {
        throw Exception(response['error'] ?? 'Failed to remove item from cart');
      }
    } catch (e) {
      throw Exception('Failed to remove cart item: ${e.toString()}');
    }
  }

  // Clear entire cart
  static Future<void> clearCart() async {
    try {
      final response = await ApiService.delete('api/cart');

      if (response['success'] != true) {
        throw Exception(response['error'] ?? 'Failed to clear cart');
      }
    } catch (e) {
      throw Exception('Failed to clear cart: ${e.toString()}');
    }
  }

  // Increment item quantity in cart
  static Future<Map<String, dynamic>> incrementQuantity(CartItem item) async {
    return await updateCartItem(
      cartItemId: item.id,
      quantity: item.quantity + 1,
    );
  }

  // Decrement item quantity in cart (removes if quantity becomes 0)
  static Future<void> decrementQuantity(CartItem item) async {
    if (item.quantity > 1) {
      await updateCartItem(
        cartItemId: item.id,
        quantity: item.quantity - 1,
      );
    } else {
      await removeCartItem(item.id);
    }
  }

  // Check if a product is in the cart
  static Future<bool> isProductInCart(String productId) async {
    try {
      final cart = await getCart();
      return cart.items.any((item) => item.productId == productId);
    } catch (e) {
      return false;
    }
  }

  // Get quantity of a specific product in cart
  static Future<int> getProductQuantityInCart(String productId) async {
    try {
      final cart = await getCart();
      final item = cart.items.firstWhere(
        (item) => item.productId == productId,
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
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }
}

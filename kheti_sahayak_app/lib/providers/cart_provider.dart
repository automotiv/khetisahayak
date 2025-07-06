import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final String seller;
  int quantity;
  bool inStock;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.seller,
    this.quantity = 1,
    this.inStock = true,
  });

  // Convert CartItem to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'seller': seller,
      'quantity': quantity,
      'inStock': inStock,
    };
  }

  // Create CartItem from Map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num).toDouble(),
      originalPrice: map['originalPrice'] != null ? (map['originalPrice'] as num).toDouble() : null,
      imageUrl: map['imageUrl'] ?? '',
      seller: map['seller'] ?? '',
      quantity: map['quantity'] ?? 1,
      inStock: map['inStock'] ?? true,
    );
  }

  // Create a copy of CartItem with updated values
  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    double? price,
    double? originalPrice,
    String? imageUrl,
    String? seller,
    int? quantity,
    bool? inStock,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      seller: seller ?? this.seller,
      quantity: quantity ?? this.quantity,
      inStock: inStock ?? this.inStock,
    );
  }
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final List<CartItem> _savedForLater = [];
  String? _couponCode;
  double _couponDiscount = 0.0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CartItem> get items => [..._items];
  List<CartItem> get savedForLater => [..._savedForLater];
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get totalSavings => _items.fold(0, (sum, item) {
        final originalPrice = item.originalPrice ?? item.price;
        return sum + ((originalPrice - item.price) * item.quantity);
      });
  double get deliveryCharge => subtotal > 500 ? 0 : 50;
  double get couponDiscount => _couponDiscount;
  double get total => (subtotal + deliveryCharge - _couponDiscount).clamp(0, double.infinity);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get couponCode => _couponCode;

  // Add item to cart
  void addItem(CartItem newItem) {
    final existingItemIndex = _items.indexWhere((item) => item.productId == newItem.productId);
    
    if (existingItemIndex >= 0) {
      // Item already in cart, update quantity
      _items[existingItemIndex] = _items[existingItemIndex].copyWith(
        quantity: _items[existingItemIndex].quantity + newItem.quantity,
      );
    } else {
      // Add new item to cart
      _items.add(newItem);
    }
    
    _saveCartToLocal();
    notifyListeners();
  }

  // Remove item from cart
  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    _saveCartToLocal();
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }
    
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: newQuantity);
      _saveCartToLocal();
      notifyListeners();
    }
  }

  // Clear the entire cart
  void clearCart() {
    _items.clear();
    _saveCartToLocal();
    notifyListeners();
  }

  // Save item for later
  void saveForLater(String productId) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final item = _items.removeAt(index);
      _savedForLater.add(item);
      _saveCartToLocal();
      notifyListeners();
    }
  }

  // Move item back to cart
  void moveToCart(String productId) {
    final index = _savedForLater.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final item = _savedForLater.removeAt(index);
      _items.add(item);
      _saveCartToLocal();
      notifyListeners();
    }
  }

  // Remove from saved items
  void removeSavedItem(String productId) {
    _savedForLater.removeWhere((item) => item.productId == productId);
    _saveCartToLocal();
    notifyListeners();
  }

  // Apply coupon code
  Future<void> applyCoupon(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock validation - in a real app, this would be an API call
      if (code.toLowerCase() == 'welcome10') {
        _couponCode = code;
        _couponDiscount = subtotal * 0.1; // 10% discount
        _error = null;
      } else if (code.toLowerCase() == 'freeship') {
        _couponCode = code;
        _couponDiscount = deliveryCharge; // Free shipping
        _error = null;
      } else {
        _couponCode = null;
        _couponDiscount = 0.0;
        _error = 'Invalid or expired coupon code';
      }
    } catch (e) {
      _error = 'Failed to apply coupon. Please try again.';
      _couponCode = null;
      _couponDiscount = 0.0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove coupon
  void removeCoupon() {
    _couponCode = null;
    _couponDiscount = 0.0;
    _error = null;
    _saveCartToLocal();
    notifyListeners();
  }

  // Check if a product is in the cart
  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  // Get cart item by product ID
  CartItem? getCartItem(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Load cart from local storage
  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, load from SharedPreferences or local database
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock data for development
      // _items = [];
      // _savedForLater = [];
      // _couponCode = null;
      // _couponDiscount = 0.0;
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load cart';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save cart to local storage
  Future<void> _saveCartToLocal() async {
    try {
      // In a real app, save to SharedPreferences or local database
      final cartData = {
        'items': _items.map((item) => item.toMap()).toList(),
        'savedForLater': _savedForLater.map((item) => item.toMap()).toList(),
        'couponCode': _couponCode,
        'couponDiscount': _couponDiscount,
      };
      
      // Save to local storage
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setString('cart', jsonEncode(cartData));
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  // Clear cart after successful order
  void clearAfterOrder() {
    _items.clear();
    _couponCode = null;
    _couponDiscount = 0.0;
    _saveCartToLocal();
    notifyListeners();
  }
}

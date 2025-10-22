class CartItem {
  final String id;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Product details
  final String productName;
  final String? productDescription;
  final List<String>? productImages;
  final int? stockQuantity;
  final bool isAvailable;
  final String? category;
  final String? brand;

  CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
    required this.productName,
    this.productDescription,
    this.productImages,
    this.stockQuantity,
    required this.isAvailable,
    this.category,
    this.brand,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      unitPrice: double.parse(json['unit_price'].toString()),
      totalPrice: double.parse(json['total_price'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      productName: json['product_name'],
      productDescription: json['product_description'],
      productImages: json['product_images'] != null
          ? (json['product_images'] is List
              ? List<String>.from(json['product_images'])
              : [json['product_images'].toString()])
          : null,
      stockQuantity: json['stock_quantity'],
      isAvailable: json['is_available'] ?? true,
      category: json['category'],
      brand: json['brand'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'product_name': productName,
      'product_description': productDescription,
      'product_images': productImages,
      'stock_quantity': stockQuantity,
      'is_available': isAvailable,
      'category': category,
      'brand': brand,
    };
  }

  CartItem copyWith({
    String? id,
    String? productId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? productName,
    String? productDescription,
    List<String>? productImages,
    int? stockQuantity,
    bool? isAvailable,
    String? category,
    String? brand,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      productImages: productImages ?? this.productImages,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category,
      brand: brand ?? this.brand,
    );
  }
}

class CartSummary {
  final double subtotal;
  final int totalItems;
  final int itemCount;

  CartSummary({
    required this.subtotal,
    required this.totalItems,
    required this.itemCount,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      subtotal: json['subtotal'] is String
          ? double.parse(json['subtotal'])
          : (json['subtotal'] as num).toDouble(),
      totalItems: json['totalItems'] ?? json['total_items'] ?? 0,
      itemCount: json['itemCount'] ?? json['item_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'totalItems': totalItems,
      'itemCount': itemCount,
    };
  }

  CartSummary copyWith({
    double? subtotal,
    int? totalItems,
    int? itemCount,
  }) {
    return CartSummary(
      subtotal: subtotal ?? this.subtotal,
      totalItems: totalItems ?? this.totalItems,
      itemCount: itemCount ?? this.itemCount,
    );
  }
}

class Cart {
  final List<CartItem> items;
  final CartSummary summary;

  Cart({
    required this.items,
    required this.summary,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    final items = itemsList.map((item) => CartItem.fromJson(item)).toList();

    final summaryData = json['summary'] ?? {};
    final summary = CartSummary.fromJson(summaryData);

    return Cart(
      items: items,
      summary: summary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'summary': summary.toJson(),
    };
  }

  Cart copyWith({
    List<CartItem>? items,
    CartSummary? summary,
  }) {
    return Cart(
      items: items ?? this.items,
      summary: summary ?? this.summary,
    );
  }

  factory Cart.empty() {
    return Cart(
      items: [],
      summary: CartSummary(subtotal: 0.0, totalItems: 0, itemCount: 0),
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

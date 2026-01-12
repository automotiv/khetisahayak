class WishlistItem {
  final String id;
  final String productId;
  final DateTime createdAt;
  final String productName;
  final String? productDescription;
  final double price;
  final List<String>? productImages;
  final int? stockQuantity;
  final bool isAvailable;
  final String? category;
  final String? brand;
  final bool? isOrganic;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.createdAt,
    required this.productName,
    this.productDescription,
    required this.price,
    this.productImages,
    this.stockQuantity,
    required this.isAvailable,
    this.category,
    this.brand,
    this.isOrganic,
  });

  String? get productImage =>
      (productImages != null && productImages!.isNotEmpty)
          ? productImages!.first
          : null;

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'],
      productId: json['product_id'],
      createdAt: DateTime.parse(json['created_at']),
      productName: json['product_name'],
      productDescription: json['product_description'],
      price: double.parse(json['price'].toString()),
      productImages: json['product_images'] != null
          ? (json['product_images'] is List
              ? List<String>.from(json['product_images'])
              : [json['product_images'].toString()])
          : null,
      stockQuantity: json['stock_quantity'],
      isAvailable: json['is_available'] ?? true,
      category: json['category'],
      brand: json['brand'],
      isOrganic: json['is_organic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'created_at': createdAt.toIso8601String(),
      'product_name': productName,
      'product_description': productDescription,
      'price': price,
      'product_images': productImages,
      'stock_quantity': stockQuantity,
      'is_available': isAvailable,
      'category': category,
      'brand': brand,
      'is_organic': isOrganic,
    };
  }

  WishlistItem copyWith({
    String? id,
    String? productId,
    DateTime? createdAt,
    String? productName,
    String? productDescription,
    double? price,
    List<String>? productImages,
    int? stockQuantity,
    bool? isAvailable,
    String? category,
    String? brand,
    bool? isOrganic,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      price: price ?? this.price,
      productImages: productImages ?? this.productImages,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      isOrganic: isOrganic ?? this.isOrganic,
    );
  }
}

class Wishlist {
  final List<WishlistItem> items;
  final int count;

  Wishlist({
    required this.items,
    required this.count,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    final items = itemsList.map((item) => WishlistItem.fromJson(item)).toList();

    return Wishlist(
      items: items,
      count: json['count'] ?? items.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'count': count,
    };
  }

  factory Wishlist.empty() {
    return Wishlist(items: [], count: 0);
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  bool containsProduct(String productId) {
    return items.any((item) => item.productId == productId);
  }
}

class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? imageUrl;
  final DateTime createdAt;
  final String? sellerId;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.imageUrl,
    required this.createdAt,
    this.sellerId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle price as either string or num
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: parsePrice(json['price']),
      category: json['category'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      sellerId: json['seller_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'seller_id': sellerId,
    };
  }
}
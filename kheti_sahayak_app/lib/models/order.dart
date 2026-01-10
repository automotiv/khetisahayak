import 'package:kheti_sahayak_app/models/cart.dart';

class Order {
  final String id;
  final int? userId;
  final List<CartItem> items;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'shipped', 'delivered', 'cancelled'
  final String paymentMethod;
  final String? paymentStatus;
  final String shippingAddress;
  final DateTime createdAt;

  Order({
    required this.id,
    this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.paymentStatus,
    required this.shippingAddress,
    required this.createdAt,
  });

  // Computed getters
  DateTime get orderDate => createdAt;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get canBeCancelled => status == 'pending' || status == 'pending_sync' || status == 'confirmed';

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      items: (json['items'] as List).map((i) => CartItem.fromJson(i)).toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      shippingAddress: json['shipping_address'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'items': items.map((i) => i.toJson()).toList(),
      'total_amount': totalAmount,
      'status': status,
      'payment_method': paymentMethod,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      'shipping_address': shippingAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Type alias for OrderItem to match usage in some screens
typedef OrderItem = CartItem;

import 'package:kheti_sahayak_app/models/cart.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'shipped', 'delivered', 'cancelled'
  final String paymentMethod;
  final String shippingAddress;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      items: (json['items'] as List).map((i) => CartItem.fromJson(i)).toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      paymentMethod: json['payment_method'],
      shippingAddress: json['shipping_address'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((i) => i.toJson()).toList(),
      'total_amount': totalAmount,
      'status': status,
      'payment_method': paymentMethod,
      'shipping_address': shippingAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

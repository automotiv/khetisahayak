import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/providers/cart_provider.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  returned,
  refunded,
}

class OrderItem {
  final String id;
  final String orderNumber;
  final DateTime orderDate;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryCharge;
  final double discount;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String shippingAddress;
  final String? trackingNumber;
  final String? courierName;
  OrderStatus status;
  final List<OrderStatusHistory> statusHistory;

  OrderItem({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.items,
    required this.subtotal,
    required this.deliveryCharge,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.shippingAddress,
    this.trackingNumber,
    this.courierName,
    required this.status,
    List<OrderStatusHistory>? statusHistory,
  }) : statusHistory = statusHistory ?? [
          OrderStatusHistory(
            status: OrderStatus.pending,
            date: orderDate,
            message: 'Order placed',
          ),
        ];

  // Convert OrderItem to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'orderDate': orderDate.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'shippingAddress': shippingAddress,
      'trackingNumber': trackingNumber,
      'courierName': courierName,
      'status': status.toString(),
      'statusHistory': statusHistory.map((h) => h.toMap()).toList(),
    };
  }

  // Create OrderItem from Map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      orderDate: DateTime.parse(map['orderDate']),
      items: (map['items'] as List<dynamic>)
          .map((item) => CartItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      deliveryCharge: (map['deliveryCharge'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      paymentStatus: map['paymentStatus'] ?? '',
      shippingAddress: map['shippingAddress'] ?? '',
      trackingNumber: map['trackingNumber'],
      courierName: map['courierName'],
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      statusHistory: (map['statusHistory'] as List<dynamic>?)
              ?.map((h) => OrderStatusHistory.fromMap(Map<String, dynamic>.from(h)))
              .toList() ??
          [],
    );
  }

  // Get order status text
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returned:
        return 'Returned';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  // Get order status color
  Color get statusColor {
    switch (status) {
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
      case OrderStatus.returned:
      case OrderStatus.refunded:
        return Colors.red;
      case OrderStatus.outForDelivery:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

class OrderStatusHistory {
  final OrderStatus status;
  final DateTime date;
  final String message;
  final String? location;

  OrderStatusHistory({
    required this.status,
    required this.date,
    required this.message,
    this.location,
  });

  // Convert OrderStatusHistory to Map
  Map<String, dynamic> toMap() {
    return {
      'status': status.toString(),
      'date': date.toIso8601String(),
      'message': message,
      'location': location,
    };
  }

  // Create OrderStatusHistory from Map
  factory OrderStatusHistory.fromMap(Map<String, dynamic> map) {
    return OrderStatusHistory(
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      date: DateTime.parse(map['date']),
      message: map['message'] ?? '',
      location: map['location'],
    );
  }

  // Get status text
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returned:
        return 'Returned';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }
}

class OrderProvider with ChangeNotifier {
  final List<OrderItem> _orders = [];
  bool _isLoading = false;
  String? _error;
  OrderItem? _currentOrder;

  // Getters
  List<OrderItem> get orders => [..._orders];
  bool get isLoading => _isLoading;
  String? get error => _error;
  OrderItem? get currentOrder => _currentOrder;

  // Get order by ID
  OrderItem? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  // Get orders by status
  List<OrderItem> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  // Load user orders
  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real app, fetch orders from the API
      // final response = await api.get('/orders');
      // _orders = (response.data as List).map((item) => OrderItem.fromMap(item)).toList();
      
      // For demo, use empty list or mock data
      _orders.clear();
      _error = null;
    } catch (e) {
      _error = 'Failed to load orders. Please try again.';
      debugPrint('Error loading orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Place a new order
  Future<OrderItem?> placeOrder({
    required List<CartItem> items,
    required String shippingAddress,
    required String paymentMethod,
    required String paymentStatus,
    double? discount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real app, send order to the API
      // final response = await api.post('/orders', data: {
      //   'items': items.map((item) => item.toMap()).toList(),
      //   'shippingAddress': shippingAddress,
      //   'paymentMethod': paymentMethod,
      //   'paymentStatus': paymentStatus,
      //   'discount': discount,
      // });
      
      // Calculate order total
      final subtotal = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
      final deliveryCharge = subtotal > 500 ? 0 : 50;
      final total = (subtotal + deliveryCharge - (discount ?? 0)).clamp(0, double.infinity);
      
      // Create new order
      final newOrder = OrderItem(
        id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        orderDate: DateTime.now(),
        items: items,
        subtotal: subtotal,
        deliveryCharge: deliveryCharge.toDouble(),
        discount: discount ?? 0,
        total: total.toDouble(),
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        shippingAddress: shippingAddress,
        status: OrderStatus.pending,
      );
      
      // Add to orders list
      _orders.insert(0, newOrder);
      _currentOrder = newOrder;
      
      // Clear cart after successful order
      // final cartProvider = Provider.of<CartProvider>(context, listen: false);
      // cartProvider.clearAfterOrder();
      
      _error = null;
      return newOrder;
    } catch (e) {
      _error = 'Failed to place order. Please try again.';
      debugPrint('Error placing order: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel an order
  Future<bool> cancelOrder(String orderId, {String reason = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real app, send cancellation request to the API
      // final response = await api.put('/orders/$orderId/cancel', data: {'reason': reason});
      
      // Update order status
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final order = _orders[index];
        _orders[index] = OrderItem(
          id: order.id,
          orderNumber: order.orderNumber,
          orderDate: order.orderDate,
          items: order.items,
          subtotal: order.subtotal,
          deliveryCharge: order.deliveryCharge,
          discount: order.discount,
          total: order.total,
          paymentMethod: order.paymentMethod,
          paymentStatus: order.paymentStatus,
          shippingAddress: order.shippingAddress,
          trackingNumber: order.trackingNumber,
          courierName: order.courierName,
          status: OrderStatus.cancelled,
          statusHistory: [
            ...order.statusHistory,
            OrderStatusHistory(
              status: OrderStatus.cancelled,
              date: DateTime.now(),
              message: 'Order cancelled${reason.isNotEmpty ? ': $reason' : ''}',
            ),
          ],
        );
        
        _error = null;
        return true;
      }
      
      _error = 'Order not found';
      return false;
    } catch (e) {
      _error = 'Failed to cancel order. Please try again.';
      debugPrint('Error cancelling order: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Track order
  Future<OrderItem?> trackOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real app, fetch order details from the API
      // final response = await api.get('/orders/$orderId/track');
      // return OrderItem.fromMap(response.data);
      
      // For demo, return the order if found
      final order = getOrderById(orderId);
      if (order != null) {
        _currentOrder = order;
        return order;
      }
      
      _error = 'Order not found';
      return null;
    } catch (e) {
      _error = 'Failed to track order. Please try again.';
      debugPrint('Error tracking order: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }
}

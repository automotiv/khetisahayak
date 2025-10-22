import 'package:kheti_sahayak_app/models/order.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';

class OrderService {
  // Create order from cart
  static Future<Order> createOrderFromCart({
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      final response = await ApiService.post(
        'api/orders/from-cart',
        {
          'shipping_address': shippingAddress,
          'payment_method': paymentMethod,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        return Order.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Failed to create order');
      }
    } catch (e) {
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }

  // Create order with custom items
  static Future<Order> createOrder({
    required List<Map<String, dynamic>> items,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      final response = await ApiService.post(
        'api/orders',
        {
          'items': items,
          'shipping_address': shippingAddress,
          'payment_method': paymentMethod,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        return Order.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Failed to create order');
      }
    } catch (e) {
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }

  // Get all user orders
  static Future<List<Order>> getUserOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await ApiService.get(
        'api/orders',
        queryParams: queryParams,
      );

      if (response['orders'] != null) {
        final ordersList = response['orders'] as List;
        return ordersList.map((order) => Order.fromJson(order)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Failed to get orders: ${e.toString()}');
    }
  }

  // Get specific order by ID
  static Future<Order> getOrderById(String orderId) async {
    try {
      final response = await ApiService.get('api/orders/$orderId');

      if (response['success'] == true && response['data'] != null) {
        return Order.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Order not found');
      }
    } catch (e) {
      throw Exception('Failed to get order: ${e.toString()}');
    }
  }

  // Update order status (admin/seller only)
  static Future<Order> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final response = await ApiService.put(
        'api/orders/$orderId/status',
        {'status': status},
      );

      if (response['success'] == true && response['data'] != null) {
        return Order.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Failed to update order status');
      }
    } catch (e) {
      throw Exception('Failed to update order status: ${e.toString()}');
    }
  }

  // Cancel order
  static Future<Order> cancelOrder(String orderId) async {
    try {
      final response = await ApiService.put(
        'api/orders/$orderId/cancel',
        {},
      );

      if (response['success'] == true && response['data'] != null) {
        return Order.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      throw Exception('Failed to cancel order: ${e.toString()}');
    }
  }

  // Get seller orders (for sellers)
  static Future<List<Order>> getSellerOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await ApiService.get(
        'api/orders/seller',
        queryParams: queryParams,
      );

      if (response['orders'] != null) {
        final ordersList = response['orders'] as List;
        return ordersList.map((order) => Order.fromJson(order)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Failed to get seller orders: ${e.toString()}');
    }
  }

  // Helper method to get orders by status
  static Future<List<Order>> getOrdersByStatus(String status) async {
    return getUserOrders(status: status);
  }

  // Helper method to get pending orders
  static Future<List<Order>> getPendingOrders() async {
    return getOrdersByStatus('pending');
  }

  // Helper method to get delivered orders
  static Future<List<Order>> getDeliveredOrders() async {
    return getOrdersByStatus('delivered');
  }

  // Helper method to get cancelled orders
  static Future<List<Order>> getCancelledOrders() async {
    return getOrdersByStatus('cancelled');
  }
}

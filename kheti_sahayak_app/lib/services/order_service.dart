import 'package:kheti_sahayak_app/models/order.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/services/offline_service.dart';
import 'package:kheti_sahayak_app/services/sync_manager_service.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/services/cart_service.dart';
import 'package:uuid/uuid.dart';

class OrderService {
  static final OfflineService _offlineService = OfflineService();
  static final SyncManagerService _syncManager = SyncManagerService();
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const _uuid = Uuid();

  // Create order from cart
  static Future<Order> createOrderFromCart({
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    // 1. Check Connectivity
    if (!_offlineService.isOnline) {
      return _createOfflineOrder(shippingAddress, paymentMethod);
    }

    // 2. Try Online
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
      // Fallback to offline if network fails
      print('OrderService: Network error ($e). Switching to offline mode.');
      return _createOfflineOrder(shippingAddress, paymentMethod);
    }
  }

  // Internal: Handle Offline Order Creation
  static Future<Order> _createOfflineOrder(String shippingAddress, String paymentMethod) async {
    final cart = await CartService.getCart();
    if (cart.isEmpty) throw Exception('Cart is empty');

    final orderId = _uuid.v4();
    final now = DateTime.now();

    final orderMap = {
      'id': orderId,
      'user_id': 1, // Mock user ID for local
      'status': 'pending_sync',
      'total_amount': cart.summary.subtotal, // Simplified
      'payment_status': 'pending',
      'payment_method': paymentMethod,
      'shipping_address': shippingAddress,
      'created_at': now.toIso8601String(),
    };

    final itemsMap = cart.items.map((item) => {
      'order_id': orderId,
      'product_id': item.id, // Assuming cart item ID maps to product ID
      'product_name': item.productName,
      'quantity': item.quantity,
      'unit_price': item.unitPrice,
    }).toList();

    // 1. Save to Local DB
    await _dbHelper.cacheOrder(orderMap, itemsMap);

    // 2. Queue for Sync
    await _syncManager.addToQueue(
      'order',
      'create',
      {
        'order_id': orderId,
        'shipping_address': shippingAddress,
        'payment_method': paymentMethod,
        'items': itemsMap,
      },
    );

    // 3. Clear Cart (since order is "placed")
    await CartService.clearCart();

    // 4. Return Order object
    return Order(
      id: orderId,
      userId: 1,
      status: 'Pending (Offline)',
      totalAmount: cart.summary.subtotal,
      createdAt: now,
      items: [], // Populate if needed for UI
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
    );
  }

  // Create order with custom items
  static Future<Order> createOrder({
    required List<Map<String, dynamic>> items,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    // Online only for custom items for now
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
  }

  // Get all user orders
  static Future<List<Order>> getUserOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    // Merge Online + Offline
    List<Order> onlineOrders = [];
    List<Order> offlineOrders = [];

    // Fetch Offline
    final cached = await _dbHelper.getCachedOrders();
    offlineOrders = cached.map((e) => Order(
      id: e['id'].toString(), // cached ID is string (UUID)
      userId: e['user_id'] as int,
      status: e['status'],
      totalAmount: e['total_amount'] as double,
      createdAt: DateTime.parse(e['created_at']),
      items: [], // Fetch items if needed
      shippingAddress: e['shipping_address'] ?? '',
      paymentMethod: e['payment_method'] ?? '',
    )).toList();

    // Fetch Online if connected
    if (_offlineService.isOnline) {
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
          onlineOrders = ordersList.map((order) => Order.fromJson(order)).toList();
        }
      } catch (e) {
        print('Failed to fetch online orders: $e');
      }
    }

    return [...offlineOrders, ...onlineOrders];
  }

  // Get specific order by ID
  static Future<Order> getOrderById(String orderId) async {
    // Check Local First
    final localOrder = await _dbHelper.getCachedOrder(orderId);
    if (localOrder != null) {
       return Order(
        id: localOrder['id'].toString(),
        userId: localOrder['user_id'] as int,
        status: localOrder['status'],
        totalAmount: localOrder['total_amount'] as double,
        createdAt: DateTime.parse(localOrder['created_at']),
        items: [], // Populate items from localOrder['items'] if mapped
        shippingAddress: localOrder['shipping_address'] ?? '',
        paymentMethod: localOrder['payment_method'] ?? '',
      );
    }

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
      final response = await ApiService.put(
        'api/orders/$orderId/status',
        {'status': status},
      );

      if (response['success'] == true && response['data'] != null) {
        return Order.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Failed to update order status');
      }
  }

  // Cancel order
  static Future<Order> cancelOrder(String orderId) async {
      final response = await ApiService.put(
        'api/orders/$orderId/cancel',
        {},
      );

      if (response['success'] == true && response['data'] != null) {
        return Order.fromJson(response['data']);
      } else {
        throw Exception(response['error'] ?? 'Failed to cancel order');
      }
  }

  // Get seller orders (for sellers)
  static Future<List<Order>> getSellerOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
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


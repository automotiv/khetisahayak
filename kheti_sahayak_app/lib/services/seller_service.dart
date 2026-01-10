import 'package:kheti_sahayak_app/models/seller_dashboard.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';

/// Seller Service
/// 
/// Handles all seller-related API calls for dashboard, orders, analytics, and inventory

class SellerService {
  /// Get seller dashboard stats
  static Future<SellerDashboardStats> getDashboardStats() async {
    try {
      final response = await ApiService.get('api/seller/dashboard');
      
      if (response['success'] == true && response['data'] != null) {
        return SellerDashboardStats.fromJson(response['data']);
      }
      
      return SellerDashboardStats.empty();
    } catch (e) {
      print('SellerService.getDashboardStats error: $e');
      return SellerDashboardStats.empty();
    }
  }

  /// Get seller orders with pagination and filtering
  static Future<List<SellerOrder>> getSellerOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null && status.isNotEmpty && status != 'all') {
        queryParams['status'] = status;
      }

      final response = await ApiService.get(
        'api/seller/orders',
        queryParams: queryParams,
      );

      if (response['orders'] != null) {
        final ordersList = response['orders'] as List;
        return ordersList.map((order) => SellerOrder.fromJson(order)).toList();
      }
      
      return [];
    } catch (e) {
      print('SellerService.getSellerOrders error: $e');
      return [];
    }
  }

  /// Update order status
  static Future<SellerOrder?> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final response = await ApiService.put(
        'api/seller/orders/$orderId/status',
        {'status': status},
      );

      if (response['success'] == true && response['data'] != null) {
        return SellerOrder.fromJson(response['data']);
      }
      
      return null;
    } catch (e) {
      print('SellerService.updateOrderStatus error: $e');
      rethrow;
    }
  }

  /// Get seller analytics
  static Future<SellerAnalytics> getAnalytics({
    String period = '7d',
  }) async {
    try {
      final response = await ApiService.get(
        'api/seller/analytics',
        queryParams: {'period': period},
      );

      if (response['success'] == true && response['data'] != null) {
        return SellerAnalytics.fromJson(response['data']);
      }
      
      return SellerAnalytics.empty();
    } catch (e) {
      print('SellerService.getAnalytics error: $e');
      return SellerAnalytics.empty();
    }
  }

  /// Get seller products (inventory)
  static Future<List<SellerProduct>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? stockFilter, // 'all', 'low_stock', 'out_of_stock'
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (stockFilter != null && stockFilter != 'all') {
        queryParams['stock_filter'] = stockFilter;
      }

      final response = await ApiService.get(
        'api/seller/products',
        queryParams: queryParams,
      );

      if (response['products'] != null) {
        final productsList = response['products'] as List;
        return productsList.map((product) => SellerProduct.fromJson(product)).toList();
      }
      
      return [];
    } catch (e) {
      print('SellerService.getProducts error: $e');
      return [];
    }
  }

  /// Update product stock
  static Future<SellerProduct?> updateStock({
    required String productId,
    required int newStock,
  }) async {
    try {
      final response = await ApiService.put(
        'api/seller/products/$productId/stock',
        {'stock': newStock},
      );

      if (response['success'] == true && response['data'] != null) {
        return SellerProduct.fromJson(response['data']);
      }
      
      return null;
    } catch (e) {
      print('SellerService.updateStock error: $e');
      rethrow;
    }
  }

  /// Bulk update product stock
  static Future<bool> bulkUpdateStock({
    required List<Map<String, dynamic>> updates,
  }) async {
    try {
      final response = await ApiService.put(
        'api/seller/products/bulk-stock',
        {'updates': updates},
      );

      return response['success'] == true;
    } catch (e) {
      print('SellerService.bulkUpdateStock error: $e');
      return false;
    }
  }

  /// Get order details
  static Future<SellerOrder?> getOrderDetails(String orderId) async {
    try {
      final response = await ApiService.get('api/seller/orders/$orderId');

      if (response['success'] == true && response['data'] != null) {
        return SellerOrder.fromJson(response['data']);
      }
      
      return null;
    } catch (e) {
      print('SellerService.getOrderDetails error: $e');
      return null;
    }
  }

  /// Confirm order
  static Future<SellerOrder?> confirmOrder(String orderId) async {
    return updateOrderStatus(orderId: orderId, status: 'confirmed');
  }

  /// Ship order
  static Future<SellerOrder?> shipOrder(String orderId) async {
    return updateOrderStatus(orderId: orderId, status: 'shipped');
  }

  /// Mark order as delivered
  static Future<SellerOrder?> deliverOrder(String orderId) async {
    return updateOrderStatus(orderId: orderId, status: 'delivered');
  }

  /// Cancel order
  static Future<SellerOrder?> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId: orderId, status: 'cancelled');
  }

  /// Get revenue chart data
  static Future<List<RevenueDataPoint>> getRevenueChart({
    String period = '7d',
  }) async {
    try {
      final response = await ApiService.get(
        'api/seller/revenue-chart',
        queryParams: {'period': period},
      );

      if (response['data'] != null) {
        final dataList = response['data'] as List;
        return dataList.map((d) => RevenueDataPoint.fromJson(d)).toList();
      }
      
      return [];
    } catch (e) {
      print('SellerService.getRevenueChart error: $e');
      return [];
    }
  }

  /// Get top selling products
  static Future<List<TopSellingProduct>> getTopProducts({
    String period = '7d',
    int limit = 5,
  }) async {
    try {
      final response = await ApiService.get(
        'api/seller/top-products',
        queryParams: {
          'period': period,
          'limit': limit.toString(),
        },
      );

      if (response['data'] != null) {
        final dataList = response['data'] as List;
        return dataList.map((d) => TopSellingProduct.fromJson(d)).toList();
      }
      
      return [];
    } catch (e) {
      print('SellerService.getTopProducts error: $e');
      return [];
    }
  }
}

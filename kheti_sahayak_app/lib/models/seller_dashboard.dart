/// Seller Dashboard Models
/// 
/// Data models for seller dashboard, analytics, and inventory management

class SellerDashboardStats {
  final int totalOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final double totalRevenue;
  final double revenueToday;
  final double revenueThisWeek;
  final double revenueThisMonth;
  final double revenueTrend; // percentage change from last period
  final int totalProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final List<RevenueDataPoint> revenueChart;
  final List<SellerOrder> recentOrders;

  SellerDashboardStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
    required this.totalRevenue,
    required this.revenueToday,
    required this.revenueThisWeek,
    required this.revenueThisMonth,
    required this.revenueTrend,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.revenueChart,
    required this.recentOrders,
  });

  factory SellerDashboardStats.fromJson(Map<String, dynamic> json) {
    return SellerDashboardStats(
      totalOrders: json['total_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      confirmedOrders: json['confirmed_orders'] ?? 0,
      shippedOrders: json['shipped_orders'] ?? 0,
      deliveredOrders: json['delivered_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      revenueToday: (json['revenue_today'] as num?)?.toDouble() ?? 0.0,
      revenueThisWeek: (json['revenue_this_week'] as num?)?.toDouble() ?? 0.0,
      revenueThisMonth: (json['revenue_this_month'] as num?)?.toDouble() ?? 0.0,
      revenueTrend: (json['revenue_trend'] as num?)?.toDouble() ?? 0.0,
      totalProducts: json['total_products'] ?? 0,
      lowStockProducts: json['low_stock_products'] ?? 0,
      outOfStockProducts: json['out_of_stock_products'] ?? 0,
      revenueChart: (json['revenue_chart'] as List?)
              ?.map((e) => RevenueDataPoint.fromJson(e))
              .toList() ??
          [],
      recentOrders: (json['recent_orders'] as List?)
              ?.map((e) => SellerOrder.fromJson(e))
              .toList() ??
          [],
    );
  }

  factory SellerDashboardStats.empty() {
    return SellerDashboardStats(
      totalOrders: 0,
      pendingOrders: 0,
      confirmedOrders: 0,
      shippedOrders: 0,
      deliveredOrders: 0,
      totalRevenue: 0.0,
      revenueToday: 0.0,
      revenueThisWeek: 0.0,
      revenueThisMonth: 0.0,
      revenueTrend: 0.0,
      totalProducts: 0,
      lowStockProducts: 0,
      outOfStockProducts: 0,
      revenueChart: [],
      recentOrders: [],
    );
  }
}

class RevenueDataPoint {
  final DateTime date;
  final double amount;
  final int orderCount;

  RevenueDataPoint({
    required this.date,
    required this.amount,
    required this.orderCount,
  });

  factory RevenueDataPoint.fromJson(Map<String, dynamic> json) {
    return RevenueDataPoint(
      date: DateTime.parse(json['date']),
      amount: (json['amount'] as num).toDouble(),
      orderCount: json['order_count'] ?? 0,
    );
  }
}

class SellerOrder {
  final String id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final String buyerName;
  final String? buyerPhone;
  final String? buyerAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<SellerOrderItem> items;

  SellerOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.buyerName,
    this.buyerPhone,
    this.buyerAddress,
    required this.createdAt,
    this.updatedAt,
    required this.items,
  });

  factory SellerOrder.fromJson(Map<String, dynamic> json) {
    return SellerOrder(
      id: json['id'],
      orderNumber: json['order_number'] ?? json['id'].toString().substring(0, 8).toUpperCase(),
      status: json['status'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      buyerName: json['buyer_name'] ?? 'Customer',
      buyerPhone: json['buyer_phone'],
      buyerAddress: json['buyer_address'] ?? json['shipping_address'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      items: (json['items'] as List?)
              ?.map((e) => SellerOrderItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get canConfirm => status == 'pending';
  bool get canShip => status == 'confirmed';
  bool get canDeliver => status == 'shipped';
  bool get canCancel => status == 'pending' || status == 'confirmed';
}

class SellerOrderItem {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  SellerOrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory SellerOrderItem.fromJson(Map<String, dynamic> json) {
    final unitPrice = (json['unit_price'] as num?)?.toDouble() ?? 0.0;
    final quantity = json['quantity'] ?? 1;
    return SellerOrderItem(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? 'Product',
      productImage: json['product_image'] ?? json['image_url'],
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? (unitPrice * quantity),
    );
  }
}

class SellerProduct {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String category;
  final String? imageUrl;
  final int stock;
  final int lowStockThreshold;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SellerProduct({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.stock,
    this.lowStockThreshold = 10,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory SellerProduct.fromJson(Map<String, dynamic> json) {
    return SellerProduct(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      category: json['category'] ?? 'General',
      imageUrl: json['image_url'],
      stock: json['stock'] ?? json['quantity'] ?? 0,
      lowStockThreshold: json['low_stock_threshold'] ?? 10,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  bool get isLowStock => stock > 0 && stock <= lowStockThreshold;
  bool get isOutOfStock => stock <= 0;
  
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }
}

class SellerAnalytics {
  final String period;
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final int repeatCustomers;
  final int newCustomers;
  final List<RevenueDataPoint> revenueTrend;
  final List<TopSellingProduct> topProducts;
  final Map<String, int> orderStatusDistribution;

  SellerAnalytics({
    required this.period,
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.repeatCustomers,
    required this.newCustomers,
    required this.revenueTrend,
    required this.topProducts,
    required this.orderStatusDistribution,
  });

  factory SellerAnalytics.fromJson(Map<String, dynamic> json) {
    return SellerAnalytics(
      period: json['period'] ?? '7d',
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] ?? 0,
      averageOrderValue: (json['average_order_value'] as num?)?.toDouble() ?? 0.0,
      repeatCustomers: json['repeat_customers'] ?? 0,
      newCustomers: json['new_customers'] ?? 0,
      revenueTrend: (json['revenue_trend'] as List?)
              ?.map((e) => RevenueDataPoint.fromJson(e))
              .toList() ??
          [],
      topProducts: (json['top_products'] as List?)
              ?.map((e) => TopSellingProduct.fromJson(e))
              .toList() ??
          [],
      orderStatusDistribution: Map<String, int>.from(
        json['order_status_distribution'] ?? {},
      ),
    );
  }

  factory SellerAnalytics.empty() {
    return SellerAnalytics(
      period: '7d',
      totalRevenue: 0.0,
      totalOrders: 0,
      averageOrderValue: 0.0,
      repeatCustomers: 0,
      newCustomers: 0,
      revenueTrend: [],
      topProducts: [],
      orderStatusDistribution: {},
    );
  }
}

class TopSellingProduct {
  final String id;
  final String name;
  final String? imageUrl;
  final int totalSold;
  final double totalRevenue;

  TopSellingProduct({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.totalSold,
    required this.totalRevenue,
  });

  factory TopSellingProduct.fromJson(Map<String, dynamic> json) {
    return TopSellingProduct(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
      totalSold: json['total_sold'] ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

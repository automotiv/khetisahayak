// Seller Dashboard Types
import { OrderStatus } from './enums';

export interface SellerStats {
  totalOrders: number;
  pendingOrders: number;
  totalRevenue: number;
  revenueChange: number;
  totalProducts: number;
  lowStockProducts: number;
  averageRating: number;
  totalReviews: number;
}

export interface RevenueData {
  date: string;
  revenue: number;
  orders: number;
}

export interface SellerOrder {
  id: string;
  orderNumber: string;
  customerId: string;
  customerName: string;
  customerPhone: string;
  customerAddress: string;
  products: OrderProduct[];
  totalAmount: number;
  status: OrderStatus;
  paymentStatus: 'pending' | 'paid' | 'failed' | 'refunded';
  paymentMethod: string;
  createdAt: string;
  updatedAt: string;
  shippedAt?: string;
  deliveredAt?: string;
  notes?: string;
}

export interface OrderProduct {
  id: string;
  productId: string;
  name: string;
  quantity: number;
  price: number;
  image?: string;
}

export interface SellerProduct {
  id: string;
  name: string;
  description: string;
  category: string;
  price: number;
  originalPrice?: number;
  stockQuantity: number;
  lowStockThreshold: number;
  unit: string;
  images: string[];
  rating: number;
  reviewCount: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface AnalyticsData {
  revenueByDay: RevenueData[];
  topProducts: TopProduct[];
  ordersByStatus: OrderStatusCount[];
  customerStats: CustomerStats;
  periodComparison: PeriodComparison;
}

export interface TopProduct {
  id: string;
  name: string;
  image: string;
  totalSold: number;
  revenue: number;
  rating: number;
}

export interface OrderStatusCount {
  status: OrderStatus;
  count: number;
  percentage: number;
}

export interface CustomerStats {
  totalCustomers: number;
  newCustomers: number;
  repeatCustomers: number;
  repeatRate: number;
}

export interface PeriodComparison {
  currentRevenue: number;
  previousRevenue: number;
  changePercent: number;
  currentOrders: number;
  previousOrders: number;
  ordersChangePercent: number;
}

export interface InventoryFilter {
  search?: string;
  category?: string;
  stockStatus?: 'all' | 'low_stock' | 'out_of_stock' | 'in_stock';
  sortBy?: 'name' | 'price' | 'stock' | 'rating' | 'created';
  sortOrder?: 'asc' | 'desc';
  page?: number;
  limit?: number;
}

export interface OrdersFilter {
  status?: OrderStatus | 'all';
  search?: string;
  dateFrom?: string;
  dateTo?: string;
  page?: number;
  limit?: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export type AnalyticsPeriod = '7d' | '30d' | '90d' | '1y';

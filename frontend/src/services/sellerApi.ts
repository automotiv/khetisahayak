import axios from 'axios';
import {
  SellerStats,
  SellerOrder,
  SellerProduct,
  AnalyticsData,
  OrdersFilter,
  InventoryFilter,
  PaginatedResponse,
  AnalyticsPeriod,
  RevenueData,
} from '../types/seller';
import { OrderStatus } from '../types/enums';

const API_URL = (import.meta as any).env.VITE_API_URL || 'http://localhost:5002/api';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

const generateMockRevenueData = (days: number): RevenueData[] => {
  const data: RevenueData[] = [];
  const today = new Date();
  
  for (let i = days - 1; i >= 0; i--) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    const baseRevenue = 15000 + Math.random() * 25000;
    const orders = Math.floor(5 + Math.random() * 15);
    
    data.push({
      date: date.toISOString().split('T')[0],
      revenue: Math.round(baseRevenue),
      orders,
    });
  }
  return data;
};

const mockOrders: SellerOrder[] = [
  {
    id: '1',
    orderNumber: 'ORD-2024-001',
    customerId: 'cust-1',
    customerName: 'Rajesh Kumar',
    customerPhone: '+91 98765 43210',
    customerAddress: 'Village Khandala, Nashik, Maharashtra',
    products: [
      { id: 'p1', productId: 'prod-1', name: 'Organic Wheat Seeds (5kg)', quantity: 2, price: 850, image: '/products/wheat.jpg' },
      { id: 'p2', productId: 'prod-2', name: 'NPK Fertilizer (10kg)', quantity: 1, price: 1200, image: '/products/fertilizer.jpg' },
    ],
    totalAmount: 2900,
    status: OrderStatus.PENDING,
    paymentStatus: 'paid',
    paymentMethod: 'UPI',
    createdAt: '2024-01-09T10:30:00Z',
    updatedAt: '2024-01-09T10:30:00Z',
  },
  {
    id: '2',
    orderNumber: 'ORD-2024-002',
    customerId: 'cust-2',
    customerName: 'Sunita Devi',
    customerPhone: '+91 87654 32109',
    customerAddress: 'Village Sinnar, Nashik, Maharashtra',
    products: [
      { id: 'p3', productId: 'prod-3', name: 'Tomato Seeds (500g)', quantity: 3, price: 450, image: '/products/tomato.jpg' },
    ],
    totalAmount: 1350,
    status: OrderStatus.CONFIRMED,
    paymentStatus: 'paid',
    paymentMethod: 'COD',
    createdAt: '2024-01-08T14:20:00Z',
    updatedAt: '2024-01-09T08:00:00Z',
  },
  {
    id: '3',
    orderNumber: 'ORD-2024-003',
    customerId: 'cust-3',
    customerName: 'Amit Patil',
    customerPhone: '+91 76543 21098',
    customerAddress: 'Village Igatpuri, Nashik, Maharashtra',
    products: [
      { id: 'p4', productId: 'prod-4', name: 'Pesticide Spray (1L)', quantity: 2, price: 680, image: '/products/pesticide.jpg' },
      { id: 'p5', productId: 'prod-5', name: 'Hand Sprayer', quantity: 1, price: 1500, image: '/products/sprayer.jpg' },
    ],
    totalAmount: 2860,
    status: OrderStatus.SHIPPED,
    paymentStatus: 'paid',
    paymentMethod: 'Card',
    createdAt: '2024-01-07T09:15:00Z',
    updatedAt: '2024-01-08T16:00:00Z',
    shippedAt: '2024-01-08T16:00:00Z',
  },
  {
    id: '4',
    orderNumber: 'ORD-2024-004',
    customerId: 'cust-4',
    customerName: 'Priya Sharma',
    customerPhone: '+91 65432 10987',
    customerAddress: 'Village Trimbak, Nashik, Maharashtra',
    products: [
      { id: 'p6', productId: 'prod-6', name: 'Drip Irrigation Kit', quantity: 1, price: 4500, image: '/products/drip.jpg' },
    ],
    totalAmount: 4500,
    status: OrderStatus.DELIVERED,
    paymentStatus: 'paid',
    paymentMethod: 'UPI',
    createdAt: '2024-01-05T11:45:00Z',
    updatedAt: '2024-01-07T14:30:00Z',
    shippedAt: '2024-01-06T10:00:00Z',
    deliveredAt: '2024-01-07T14:30:00Z',
  },
  {
    id: '5',
    orderNumber: 'ORD-2024-005',
    customerId: 'cust-5',
    customerName: 'Vikram Singh',
    customerPhone: '+91 54321 09876',
    customerAddress: 'Village Dindori, Nashik, Maharashtra',
    products: [
      { id: 'p7', productId: 'prod-1', name: 'Organic Wheat Seeds (5kg)', quantity: 5, price: 850, image: '/products/wheat.jpg' },
    ],
    totalAmount: 4250,
    status: OrderStatus.PENDING,
    paymentStatus: 'pending',
    paymentMethod: 'COD',
    createdAt: '2024-01-09T16:00:00Z',
    updatedAt: '2024-01-09T16:00:00Z',
  },
];

const mockProducts: SellerProduct[] = [
  {
    id: 'prod-1',
    name: 'Organic Wheat Seeds (5kg)',
    description: 'High-quality organic wheat seeds for rabi season',
    category: 'seeds',
    price: 850,
    originalPrice: 950,
    stockQuantity: 45,
    lowStockThreshold: 20,
    unit: 'pack',
    images: ['/products/wheat.jpg'],
    rating: 4.5,
    reviewCount: 128,
    isActive: true,
    createdAt: '2023-10-15T00:00:00Z',
    updatedAt: '2024-01-09T00:00:00Z',
  },
  {
    id: 'prod-2',
    name: 'NPK Fertilizer (10kg)',
    description: 'Balanced NPK 19:19:19 for all crops',
    category: 'fertilizers',
    price: 1200,
    stockQuantity: 8,
    lowStockThreshold: 15,
    unit: 'bag',
    images: ['/products/fertilizer.jpg'],
    rating: 4.3,
    reviewCount: 89,
    isActive: true,
    createdAt: '2023-09-20T00:00:00Z',
    updatedAt: '2024-01-08T00:00:00Z',
  },
  {
    id: 'prod-3',
    name: 'Tomato Seeds (500g)',
    description: 'Hybrid tomato seeds with high yield',
    category: 'seeds',
    price: 450,
    stockQuantity: 0,
    lowStockThreshold: 10,
    unit: 'pack',
    images: ['/products/tomato.jpg'],
    rating: 4.7,
    reviewCount: 156,
    isActive: true,
    createdAt: '2023-11-01T00:00:00Z',
    updatedAt: '2024-01-09T00:00:00Z',
  },
  {
    id: 'prod-4',
    name: 'Pesticide Spray (1L)',
    description: 'Broad-spectrum pesticide for common pests',
    category: 'pesticides',
    price: 680,
    stockQuantity: 32,
    lowStockThreshold: 15,
    unit: 'bottle',
    images: ['/products/pesticide.jpg'],
    rating: 4.2,
    reviewCount: 67,
    isActive: true,
    createdAt: '2023-08-10T00:00:00Z',
    updatedAt: '2024-01-07T00:00:00Z',
  },
  {
    id: 'prod-5',
    name: 'Hand Sprayer (16L)',
    description: 'Manual backpack sprayer for pesticide application',
    category: 'tools',
    price: 1500,
    stockQuantity: 12,
    lowStockThreshold: 5,
    unit: 'unit',
    images: ['/products/sprayer.jpg'],
    rating: 4.6,
    reviewCount: 42,
    isActive: true,
    createdAt: '2023-07-25T00:00:00Z',
    updatedAt: '2024-01-05T00:00:00Z',
  },
  {
    id: 'prod-6',
    name: 'Drip Irrigation Kit',
    description: 'Complete drip irrigation system for 1 acre',
    category: 'tools',
    price: 4500,
    originalPrice: 5200,
    stockQuantity: 5,
    lowStockThreshold: 3,
    unit: 'kit',
    images: ['/products/drip.jpg'],
    rating: 4.8,
    reviewCount: 34,
    isActive: true,
    createdAt: '2023-06-15T00:00:00Z',
    updatedAt: '2024-01-04T00:00:00Z',
  },
];

export const sellerApi = {
  getDashboard: async (): Promise<SellerStats> => {
    try {
      const response = await api.get('/seller/dashboard');
      return response.data;
    } catch {
      return {
        totalOrders: 156,
        pendingOrders: 12,
        totalRevenue: 487500,
        revenueChange: 12.5,
        totalProducts: 24,
        lowStockProducts: 3,
        averageRating: 4.5,
        totalReviews: 342,
      };
    }
  },

  getOrders: async (filters?: OrdersFilter): Promise<PaginatedResponse<SellerOrder>> => {
    try {
      const response = await api.get('/seller/orders', { params: filters });
      return response.data;
    } catch {
      let filteredOrders = [...mockOrders];
      
      if (filters?.status && filters.status !== 'all') {
        filteredOrders = filteredOrders.filter(o => o.status === filters.status);
      }
      
      if (filters?.search) {
        const search = filters.search.toLowerCase();
        filteredOrders = filteredOrders.filter(o => 
          o.customerName.toLowerCase().includes(search) ||
          o.orderNumber.toLowerCase().includes(search)
        );
      }
      
      return {
        data: filteredOrders,
        total: filteredOrders.length,
        page: filters?.page || 1,
        limit: filters?.limit || 10,
        totalPages: Math.ceil(filteredOrders.length / (filters?.limit || 10)),
      };
    }
  },

  getRevenue: async (period: AnalyticsPeriod): Promise<RevenueData[]> => {
    try {
      const response = await api.get('/seller/revenue', { params: { period } });
      return response.data;
    } catch {
      const daysMap: Record<AnalyticsPeriod, number> = {
        '7d': 7,
        '30d': 30,
        '90d': 90,
        '1y': 365,
      };
      return generateMockRevenueData(daysMap[period]);
    }
  },

  getAnalytics: async (period: AnalyticsPeriod = '30d'): Promise<AnalyticsData> => {
    try {
      const response = await api.get('/seller/analytics', { params: { period } });
      return response.data;
    } catch {
      const daysMap: Record<AnalyticsPeriod, number> = {
        '7d': 7,
        '30d': 30,
        '90d': 90,
        '1y': 365,
      };
      
      return {
        revenueByDay: generateMockRevenueData(daysMap[period]),
        topProducts: [
          { id: 'prod-1', name: 'Organic Wheat Seeds', image: '/products/wheat.jpg', totalSold: 156, revenue: 132600, rating: 4.5 },
          { id: 'prod-6', name: 'Drip Irrigation Kit', image: '/products/drip.jpg', totalSold: 34, revenue: 153000, rating: 4.8 },
          { id: 'prod-3', name: 'Tomato Seeds', image: '/products/tomato.jpg', totalSold: 89, revenue: 40050, rating: 4.7 },
          { id: 'prod-2', name: 'NPK Fertilizer', image: '/products/fertilizer.jpg', totalSold: 67, revenue: 80400, rating: 4.3 },
          { id: 'prod-5', name: 'Hand Sprayer', image: '/products/sprayer.jpg', totalSold: 42, revenue: 63000, rating: 4.6 },
        ],
        ordersByStatus: [
          { status: OrderStatus.PENDING, count: 12, percentage: 8 },
          { status: OrderStatus.CONFIRMED, count: 18, percentage: 12 },
          { status: OrderStatus.SHIPPED, count: 24, percentage: 15 },
          { status: OrderStatus.DELIVERED, count: 98, percentage: 63 },
          { status: OrderStatus.CANCELLED, count: 4, percentage: 2 },
        ],
        customerStats: {
          totalCustomers: 234,
          newCustomers: 45,
          repeatCustomers: 89,
          repeatRate: 38,
        },
        periodComparison: {
          currentRevenue: 487500,
          previousRevenue: 433333,
          changePercent: 12.5,
          currentOrders: 156,
          previousOrders: 142,
          ordersChangePercent: 9.9,
        },
      };
    }
  },

  getInventory: async (filters?: InventoryFilter): Promise<PaginatedResponse<SellerProduct>> => {
    try {
      const response = await api.get('/seller/inventory', { params: filters });
      return response.data;
    } catch {
      let filteredProducts = [...mockProducts];
      
      if (filters?.search) {
        const search = filters.search.toLowerCase();
        filteredProducts = filteredProducts.filter(p => 
          p.name.toLowerCase().includes(search) ||
          p.category.toLowerCase().includes(search)
        );
      }
      
      if (filters?.stockStatus && filters.stockStatus !== 'all') {
        filteredProducts = filteredProducts.filter(p => {
          if (filters.stockStatus === 'out_of_stock') return p.stockQuantity === 0;
          if (filters.stockStatus === 'low_stock') return p.stockQuantity > 0 && p.stockQuantity <= p.lowStockThreshold;
          if (filters.stockStatus === 'in_stock') return p.stockQuantity > p.lowStockThreshold;
          return true;
        });
      }
      
      if (filters?.category) {
        filteredProducts = filteredProducts.filter(p => p.category === filters.category);
      }
      
      return {
        data: filteredProducts,
        total: filteredProducts.length,
        page: filters?.page || 1,
        limit: filters?.limit || 10,
        totalPages: Math.ceil(filteredProducts.length / (filters?.limit || 10)),
      };
    }
  },

  updateStock: async (productId: string, quantity: number): Promise<SellerProduct> => {
    try {
      const response = await api.patch(`/seller/products/${productId}/stock`, { quantity });
      return response.data;
    } catch {
      const product = mockProducts.find(p => p.id === productId);
      if (!product) throw new Error('Product not found');
      return { ...product, stockQuantity: quantity };
    }
  },

  updateOrderStatus: async (orderId: string, status: OrderStatus): Promise<SellerOrder> => {
    try {
      const response = await api.patch(`/seller/orders/${orderId}/status`, { status });
      return response.data;
    } catch {
      const order = mockOrders.find(o => o.id === orderId);
      if (!order) throw new Error('Order not found');
      return { ...order, status, updatedAt: new Date().toISOString() };
    }
  },
};

export default sellerApi;

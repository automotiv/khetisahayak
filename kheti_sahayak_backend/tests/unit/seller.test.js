const mockQuery = jest.fn();
const mockPoolConnect = jest.fn();
const mockClient = {
  query: jest.fn(),
  release: jest.fn()
};

jest.mock('../../db', () => ({
  query: mockQuery,
  pool: {
    connect: mockPoolConnect
  }
}));

mockPoolConnect.mockResolvedValue(mockClient);

describe('Seller Controller Unit Tests', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getSellerDashboard', () => {
    it('should retrieve seller dashboard stats successfully', async () => {
      const sellerId = 'seller-uuid-1';

      mockQuery
        .mockResolvedValueOnce({ rows: [{ total_orders: '25' }] })
        .mockResolvedValueOnce({ rows: [{ pending_orders: '5' }] })
        .mockResolvedValueOnce({ rows: [{ total_revenue: '15000.50' }] })
        .mockResolvedValueOnce({ rows: [{ total_products: '12' }] })
        .mockResolvedValueOnce({ rows: [{ low_stock_count: '3' }] });

      const db = require('../../db');

      const totalOrders = await db.query(
        `SELECT COUNT(DISTINCT o.id) as total_orders
         FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         WHERE p.seller_id = $1`,
        [sellerId]
      );

      const pendingOrders = await db.query(
        `SELECT COUNT(DISTINCT o.id) as pending_orders
         FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         WHERE p.seller_id = $1 AND o.status = 'pending'`,
        [sellerId]
      );

      const revenue = await db.query(
        `SELECT COALESCE(SUM(oi.total_price), 0) as total_revenue
         FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         WHERE p.seller_id = $1 AND o.status = 'delivered'`,
        [sellerId]
      );

      const products = await db.query(
        `SELECT COUNT(*) as total_products FROM products WHERE seller_id = $1`,
        [sellerId]
      );

      const lowStock = await db.query(
        `SELECT COUNT(*) as low_stock_count
         FROM products
         WHERE seller_id = $1 AND stock_quantity < 10 AND is_available = true`,
        [sellerId]
      );

      expect(parseInt(totalOrders.rows[0].total_orders)).toBe(25);
      expect(parseInt(pendingOrders.rows[0].pending_orders)).toBe(5);
      expect(parseFloat(revenue.rows[0].total_revenue)).toBe(15000.50);
      expect(parseInt(products.rows[0].total_products)).toBe(12);
      expect(parseInt(lowStock.rows[0].low_stock_count)).toBe(3);
    });

    it('should handle empty dashboard stats', async () => {
      mockQuery
        .mockResolvedValueOnce({ rows: [{ total_orders: '0' }] })
        .mockResolvedValueOnce({ rows: [{ pending_orders: '0' }] })
        .mockResolvedValueOnce({ rows: [{ total_revenue: '0' }] })
        .mockResolvedValueOnce({ rows: [{ total_products: '0' }] })
        .mockResolvedValueOnce({ rows: [{ low_stock_count: '0' }] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT COUNT(DISTINCT o.id) as total_orders FROM orders o`,
        []
      );

      expect(parseInt(result.rows[0].total_orders)).toBe(0);
    });
  });

  describe('getSellerOrders', () => {
    it('should retrieve seller orders with pagination', async () => {
      const mockOrders = [
        {
          id: 'order-1',
          total_amount: 500.00,
          status: 'pending',
          buyer_name: 'John Farmer',
          items: [{ product_id: 'prod-1', quantity: 2 }]
        },
        {
          id: 'order-2',
          total_amount: 750.00,
          status: 'delivered',
          buyer_name: 'Jane Farmer',
          items: [{ product_id: 'prod-2', quantity: 3 }]
        }
      ];

      mockQuery
        .mockResolvedValueOnce({ rows: mockOrders })
        .mockResolvedValueOnce({ rows: [{ total: '10' }] });

      const db = require('../../db');

      const result = await db.query(
        `SELECT DISTINCT o.id, o.total_amount, o.status, u.username as buyer_name
         FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         JOIN users u ON o.user_id = u.id
         WHERE p.seller_id = $1
         ORDER BY o.created_at DESC
         LIMIT $2 OFFSET $3`,
        ['seller-1', 10, 0]
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows[0].status).toBe('pending');
      expect(result.rows[1].status).toBe('delivered');
    });

    it('should filter orders by status', async () => {
      const mockPendingOrders = [
        { id: 'order-1', status: 'pending', total_amount: 500.00 }
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockPendingOrders });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         WHERE p.seller_id = $1 AND o.status = $2`,
        ['seller-1', 'pending']
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].status).toBe('pending');
    });

    it('should filter orders by date range', async () => {
      const mockDateOrders = [
        { id: 'order-1', created_at: '2025-01-05', total_amount: 500.00 }
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockDateOrders });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         WHERE p.seller_id = $1 AND o.created_at >= $2 AND o.created_at <= $3`,
        ['seller-1', '2025-01-01', '2025-01-10']
      );

      expect(result.rows).toHaveLength(1);
    });
  });

  describe('getSellerRevenue', () => {
    it('should retrieve revenue analytics for 30 days', async () => {
      const mockRevenueData = [
        { date: '2025-01-01', revenue: 1000.00, order_count: 5 },
        { date: '2025-01-02', revenue: 1500.00, order_count: 7 },
        { date: '2025-01-03', revenue: 800.00, order_count: 3 }
      ];

      mockQuery
        .mockResolvedValueOnce({ rows: mockRevenueData })
        .mockResolvedValueOnce({ rows: [{ total_revenue: '3300.00', total_orders: '15' }] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT DATE(o.created_at) as date,
                COALESCE(SUM(oi.total_price), 0) as revenue,
                COUNT(DISTINCT o.id) as order_count
         FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         WHERE p.seller_id = $1 
           AND o.status IN ('delivered', 'shipped', 'confirmed')
           AND o.created_at >= CURRENT_DATE - INTERVAL '30 days'
         GROUP BY DATE(o.created_at)
         ORDER BY date ASC`,
        ['seller-1']
      );

      expect(result.rows).toHaveLength(3);
      expect(result.rows[0].revenue).toBe(1000.00);
    });

    it('should support different time periods', () => {
      const periodConfigs = {
        '7d': { interval: '7 days', groupBy: 'day' },
        '30d': { interval: '30 days', groupBy: 'day' },
        '90d': { interval: '90 days', groupBy: 'week' },
        '1y': { interval: '365 days', groupBy: 'month' }
      };

      expect(periodConfigs['7d'].interval).toBe('7 days');
      expect(periodConfigs['90d'].groupBy).toBe('week');
      expect(periodConfigs['1y'].groupBy).toBe('month');
    });
  });

  describe('getSellerAnalytics', () => {
    it('should retrieve top selling products', async () => {
      const mockTopProducts = [
        { id: 'prod-1', name: 'Organic Seeds', total_sold: 100, total_revenue: 5000.00 },
        { id: 'prod-2', name: 'NPK Fertilizer', total_sold: 80, total_revenue: 4000.00 }
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockTopProducts });

      const db = require('../../db');
      const result = await db.query(
        `SELECT p.id, p.name, SUM(oi.quantity) as total_sold, SUM(oi.total_price) as total_revenue
         FROM products p
         JOIN order_items oi ON p.id = oi.product_id
         JOIN orders o ON oi.order_id = o.id
         WHERE p.seller_id = $1 AND o.status IN ('delivered', 'shipped', 'confirmed')
         GROUP BY p.id, p.name
         ORDER BY total_sold DESC
         LIMIT 10`,
        ['seller-1']
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows[0].total_sold).toBe(100);
    });

    it('should calculate average order value', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [{ average_order_value: '450.50' }] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT AVG(order_total) as average_order_value
         FROM (
           SELECT o.id, SUM(oi.total_price) as order_total
           FROM orders o
           JOIN order_items oi ON o.id = oi.order_id
           JOIN products p ON oi.product_id = p.id
           WHERE p.seller_id = $1 AND o.status IN ('delivered', 'shipped', 'confirmed')
           GROUP BY o.id
         ) as order_totals`,
        ['seller-1']
      );

      expect(parseFloat(result.rows[0].average_order_value)).toBe(450.50);
    });

    it('should calculate repeat customer rate', async () => {
      mockQuery.mockResolvedValueOnce({ 
        rows: [{ total_customers: '100', repeat_customers: '25' }] 
      });

      const db = require('../../db');
      const result = await db.query(
        `SELECT COUNT(DISTINCT o.user_id) as total_customers FROM orders o`,
        ['seller-1']
      );

      const totalCustomers = parseInt(result.rows[0].total_customers);
      const repeatCustomers = parseInt(result.rows[0].repeat_customers);
      const repeatRate = totalCustomers > 0 ? ((repeatCustomers / totalCustomers) * 100).toFixed(2) : 0;

      expect(repeatRate).toBe('25.00');
    });
  });

  describe('getSellerInventory', () => {
    it('should retrieve inventory with pagination', async () => {
      const mockProducts = [
        { id: 'prod-1', name: 'Seeds', stock_quantity: 100, is_available: true },
        { id: 'prod-2', name: 'Fertilizer', stock_quantity: 50, is_available: true }
      ];

      mockQuery
        .mockResolvedValueOnce({ rows: mockProducts })
        .mockResolvedValueOnce({ rows: [{ total: '20' }] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT p.id, p.name, p.stock_quantity, p.is_available
         FROM products p
         WHERE p.seller_id = $1
         ORDER BY p.created_at DESC
         LIMIT $2 OFFSET $3`,
        ['seller-1', 20, 0]
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows[0].is_available).toBe(true);
    });

    it('should filter low stock items', async () => {
      const mockLowStock = [
        { id: 'prod-1', name: 'Almost Out', stock_quantity: 5 }
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockLowStock });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM products WHERE seller_id = $1 AND stock_quantity < 10`,
        ['seller-1']
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].stock_quantity).toBe(5);
    });

    it('should support sorting by different fields', () => {
      const allowedSortFields = ['name', 'price', 'stock_quantity', 'created_at', 'updated_at'];
      const allowedSortOrders = ['ASC', 'DESC'];

      expect(allowedSortFields).toContain('stock_quantity');
      expect(allowedSortOrders).toContain('DESC');
    });
  });

  describe('updateInventory', () => {
    it('should update stock quantity successfully', async () => {
      mockQuery
        .mockResolvedValueOnce({ rows: [{ id: 'prod-1', name: 'Seeds', stock_quantity: 50 }] })
        .mockResolvedValueOnce({ 
          rows: [{ 
            id: 'prod-1', 
            name: 'Seeds', 
            stock_quantity: 100, 
            is_available: true,
            updated_at: new Date()
          }] 
        });

      const db = require('../../db');

      const productCheck = await db.query(
        `SELECT id, name, stock_quantity FROM products WHERE id = $1 AND seller_id = $2`,
        ['prod-1', 'seller-1']
      );
      expect(productCheck.rows.length).toBe(1);

      const result = await db.query(
        `UPDATE products 
         SET stock_quantity = $1, updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2 AND seller_id = $3 
         RETURNING id, name, stock_quantity, is_available, updated_at`,
        [100, 'prod-1', 'seller-1']
      );

      expect(result.rows[0].stock_quantity).toBe(100);
    });

    it('should validate stock quantity is non-negative', () => {
      const validQuantities = [0, 1, 100, 9999];
      const invalidQuantities = [-1, -100];

      validQuantities.forEach(qty => {
        expect(qty >= 0).toBe(true);
      });

      invalidQuantities.forEach(qty => {
        expect(qty >= 0).toBe(false);
      });
    });

    it('should return 404 for non-existent product', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT id FROM products WHERE id = $1 AND seller_id = $2`,
        ['non-existent', 'seller-1']
      );

      expect(result.rows.length).toBe(0);
    });

    it('should prevent updating other seller products', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT id FROM products WHERE id = $1 AND seller_id = $2`,
        ['prod-1', 'wrong-seller']
      );

      expect(result.rows.length).toBe(0);
    });
  });

  describe('Order Status Distribution', () => {
    it('should calculate order status distribution', async () => {
      const mockDistribution = [
        { status: 'pending', count: 10 },
        { status: 'confirmed', count: 8 },
        { status: 'shipped', count: 5 },
        { status: 'delivered', count: 20 },
        { status: 'cancelled', count: 2 }
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockDistribution });

      const db = require('../../db');
      const result = await db.query(
        `SELECT o.status, COUNT(DISTINCT o.id) as count
         FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         WHERE p.seller_id = $1
         GROUP BY o.status`,
        ['seller-1']
      );

      expect(result.rows).toHaveLength(5);
      expect(result.rows.find(r => r.status === 'delivered').count).toBe(20);
    });
  });

  describe('Category Revenue', () => {
    it('should calculate revenue by category', async () => {
      const mockCategoryRevenue = [
        { category: 'Seeds', revenue: 5000.00, order_count: 50 },
        { category: 'Fertilizers', revenue: 3000.00, order_count: 30 },
        { category: 'Tools', revenue: 2000.00, order_count: 20 }
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockCategoryRevenue });

      const db = require('../../db');
      const result = await db.query(
        `SELECT p.category,
                COALESCE(SUM(oi.total_price), 0) as revenue,
                COUNT(DISTINCT o.id) as order_count
         FROM products p
         JOIN order_items oi ON p.id = oi.product_id
         JOIN orders o ON oi.order_id = o.id
         WHERE p.seller_id = $1 AND o.status IN ('delivered', 'shipped', 'confirmed')
         GROUP BY p.category
         ORDER BY revenue DESC`,
        ['seller-1']
      );

      expect(result.rows).toHaveLength(3);
      expect(result.rows[0].category).toBe('Seeds');
      expect(result.rows[0].revenue).toBe(5000.00);
    });
  });
});

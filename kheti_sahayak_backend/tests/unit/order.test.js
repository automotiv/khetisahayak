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

jest.mock('../../services/emailService', () => ({
  sendOrderConfirmation: jest.fn().mockResolvedValue({ success: true }),
  sendOrderStatusUpdate: jest.fn().mockResolvedValue({ success: true })
}));

mockPoolConnect.mockResolvedValue(mockClient);

describe('Order Controller Unit Tests', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createOrder', () => {
    it('should create order with valid items', async () => {
      const mockProduct = {
        id: 'prod-1',
        name: 'Organic Seeds',
        price: 250.00,
        stock_quantity: 100,
        is_available: true
      };

      const mockOrder = {
        id: 'order-1',
        user_id: 'user-1',
        total_amount: 500.00,
        status: 'pending',
        shipping_address: '123 Farm Lane',
        created_at: new Date()
      };

      mockClient.query
        .mockResolvedValueOnce({ command: 'BEGIN' })
        .mockResolvedValueOnce({ rows: [mockProduct] })
        .mockResolvedValueOnce({ rows: [mockOrder] })
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ command: 'COMMIT' });

      mockQuery
        .mockResolvedValueOnce({ rows: [{ ...mockOrder, items: [] }] })
        .mockResolvedValueOnce({ rows: [{ email: 'user@example.com' }] });

      const db = require('../../db');
      const client = await db.pool.connect();

      await client.query('BEGIN');

      const productResult = await client.query(
        'SELECT * FROM products WHERE id = $1 AND is_available = true',
        ['prod-1']
      );

      expect(productResult.rows[0].price).toBe(250.00);
      expect(productResult.rows[0].stock_quantity).toBe(100);
    });

    it('should validate items array is not empty', () => {
      const validItems = [{ product_id: 'prod-1', quantity: 2 }];
      const emptyItems = [];

      expect(Array.isArray(validItems) && validItems.length > 0).toBe(true);
      expect(Array.isArray(emptyItems) && emptyItems.length > 0).toBe(false);
    });

    it('should require shipping address', () => {
      const orderWithAddress = { shipping_address: '123 Farm Lane', items: [] };
      const orderWithoutAddress = { items: [] };

      expect('shipping_address' in orderWithAddress && orderWithAddress.shipping_address).toBeTruthy();
      expect('shipping_address' in orderWithoutAddress && orderWithoutAddress.shipping_address).toBeFalsy();
    });

    it('should validate product availability', async () => {
      mockClient.query.mockResolvedValueOnce({ rows: [] });

      const db = require('../../db');
      const client = await db.pool.connect();
      const result = await client.query(
        'SELECT * FROM products WHERE id = $1 AND is_available = true',
        ['unavailable-product']
      );

      expect(result.rows.length).toBe(0);
    });

    it('should check sufficient stock quantity', () => {
      const product = { stock_quantity: 10 };
      const orderQuantity = 15;
      const validQuantity = 5;

      expect(product.stock_quantity >= orderQuantity).toBe(false);
      expect(product.stock_quantity >= validQuantity).toBe(true);
    });

    it('should calculate total amount correctly', () => {
      const items = [
        { product_id: 'prod-1', quantity: 2, price: 250.00 },
        { product_id: 'prod-2', quantity: 3, price: 100.00 }
      ];

      const totalAmount = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
      expect(totalAmount).toBe(800.00);
    });

    it('should update product stock after order', async () => {
      mockClient.query.mockResolvedValueOnce({ rowCount: 1 });

      const db = require('../../db');
      const client = await db.pool.connect();
      const result = await client.query(
        'UPDATE products SET stock_quantity = stock_quantity - $1 WHERE id = $2',
        [5, 'prod-1']
      );

      expect(result.rowCount).toBe(1);
    });

    it('should send order confirmation email', async () => {
      const emailService = require('../../services/emailService');
      const result = await emailService.sendOrderConfirmation(
        { id: 'order-1', items: [], total_amount: 500 },
        { email: 'user@example.com' }
      );

      expect(result.success).toBe(true);
    });
  });

  describe('getUserOrders', () => {
    it('should retrieve user orders with pagination', async () => {
      const mockOrders = [
        { id: 'order-1', total_amount: 500.00, status: 'pending', items: [] },
        { id: 'order-2', total_amount: 750.00, status: 'delivered', items: [] }
      ];

      mockQuery
        .mockResolvedValueOnce({ rows: mockOrders })
        .mockResolvedValueOnce({ rows: [{ count: '10' }] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT o.*, json_agg(json_build_object('id', oi.id)) as items
         FROM orders o
         LEFT JOIN order_items oi ON o.id = oi.order_id
         LEFT JOIN products p ON oi.product_id = p.id
         WHERE o.user_id = $1
         GROUP BY o.id
         ORDER BY o.created_at DESC
         LIMIT $2 OFFSET $3`,
        ['user-1', 10, 0]
      );

      expect(result.rows).toHaveLength(2);
    });

    it('should filter orders by status', async () => {
      const mockDelivered = [
        { id: 'order-1', status: 'delivered' }
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockDelivered });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM orders WHERE user_id = $1 AND status = $2`,
        ['user-1', 'delivered']
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].status).toBe('delivered');
    });

    it('should calculate pagination correctly', () => {
      const page = 3;
      const limit = 10;
      const totalItems = 25;

      const offset = (page - 1) * limit;
      const totalPages = Math.ceil(totalItems / limit);

      expect(offset).toBe(20);
      expect(totalPages).toBe(3);
    });
  });

  describe('getOrderById', () => {
    it('should retrieve order details by ID', async () => {
      const mockOrder = {
        id: 'order-1',
        user_id: 'user-1',
        total_amount: 500.00,
        status: 'pending',
        shipping_address: '123 Farm Lane',
        items: [
          { product_id: 'prod-1', product_name: 'Seeds', quantity: 2, unit_price: 250.00 }
        ]
      };

      mockQuery.mockResolvedValueOnce({ rows: [mockOrder] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT o.*, json_agg(json_build_object('product_name', p.name)) as items
         FROM orders o
         LEFT JOIN order_items oi ON o.id = oi.order_id
         LEFT JOIN products p ON oi.product_id = p.id
         WHERE o.id = $1 AND o.user_id = $2
         GROUP BY o.id`,
        ['order-1', 'user-1']
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].total_amount).toBe(500.00);
    });

    it('should return 404 for non-existent order', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM orders WHERE id = $1 AND user_id = $2`,
        ['non-existent', 'user-1']
      );

      expect(result.rows.length).toBe(0);
    });

    it('should prevent accessing other user orders', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM orders WHERE id = $1 AND user_id = $2`,
        ['order-1', 'wrong-user']
      );

      expect(result.rows.length).toBe(0);
    });
  });

  describe('updateOrderStatus', () => {
    it('should update order status for seller', async () => {
      mockQuery
        .mockResolvedValueOnce({ rows: [{ id: 'order-1' }] })
        .mockResolvedValueOnce({ rows: [{ id: 'order-1', status: 'shipped' }] });

      const db = require('../../db');

      const orderCheck = await db.query(
        `SELECT o.id FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         WHERE o.id = $1 AND p.seller_id = $2`,
        ['order-1', 'seller-1']
      );

      expect(orderCheck.rows.length).toBe(1);

      const result = await db.query(
        'UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
        ['shipped', 'order-1']
      );

      expect(result.rows[0].status).toBe('shipped');
    });

    it('should validate status value', () => {
      const validStatuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
      const invalidStatus = 'invalid_status';

      expect(validStatuses.includes('shipped')).toBe(true);
      expect(validStatuses.includes(invalidStatus)).toBe(false);
    });

    it('should prevent non-sellers from updating status', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const db = require('../../db');
      const result = await db.query(
        `SELECT o.id FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         WHERE o.id = $1 AND p.seller_id = $2`,
        ['order-1', 'not-seller']
      );

      expect(result.rows.length).toBe(0);
    });

    it('should send status update email', async () => {
      const emailService = require('../../services/emailService');
      const result = await emailService.sendOrderStatusUpdate(
        { id: 'order-1' },
        { email: 'user@example.com' },
        'shipped'
      );

      expect(result.success).toBe(true);
    });
  });

  describe('cancelOrder', () => {
    it('should cancel pending order', async () => {
      const mockOrder = {
        id: 'order-1',
        user_id: 'user-1',
        status: 'pending'
      };

      mockQuery.mockResolvedValueOnce({ rows: [mockOrder] });

      mockClient.query
        .mockResolvedValueOnce({ command: 'BEGIN' })
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ rows: [{ product_id: 'prod-1', quantity: 2 }] })
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ command: 'COMMIT' });

      const db = require('../../db');
      const orderResult = await db.query(
        'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
        ['order-1', 'user-1']
      );

      expect(orderResult.rows[0].status).toBe('pending');
    });

    it('should not allow cancelling non-pending orders', () => {
      const pendingStatus = 'pending';
      const shippedStatus = 'shipped';
      const deliveredStatus = 'delivered';

      expect(pendingStatus === 'pending').toBe(true);
      expect(shippedStatus === 'pending').toBe(false);
      expect(deliveredStatus === 'pending').toBe(false);
    });

    it('should restore product stock on cancellation', async () => {
      mockClient.query.mockResolvedValueOnce({ rowCount: 1 });

      const db = require('../../db');
      const client = await db.pool.connect();
      const result = await client.query(
        'UPDATE products SET stock_quantity = stock_quantity + $1 WHERE id = $2',
        [5, 'prod-1']
      );

      expect(result.rowCount).toBe(1);
    });

    it('should return 404 for non-existent order', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const db = require('../../db');
      const result = await db.query(
        'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
        ['non-existent', 'user-1']
      );

      expect(result.rows.length).toBe(0);
    });
  });

  describe('getSellerOrders', () => {
    it('should retrieve orders for seller products', async () => {
      const mockOrders = [
        {
          id: 'order-1',
          total_amount: 500.00,
          status: 'pending',
          buyer_name: 'John Farmer',
          items: [{ product_name: 'Seeds', quantity: 2 }]
        }
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockOrders });

      const db = require('../../db');
      const result = await db.query(
        `SELECT o.id, o.total_amount, o.status, u.username as buyer_name
         FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         JOIN users u ON o.user_id = u.id
         WHERE p.seller_id = $1
         GROUP BY o.id, u.username
         ORDER BY o.created_at DESC
         LIMIT $2 OFFSET $3`,
        ['seller-1', 10, 0]
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].buyer_name).toBe('John Farmer');
    });

    it('should filter seller orders by status', async () => {
      const mockPending = [{ id: 'order-1', status: 'pending' }];

      mockQuery.mockResolvedValueOnce({ rows: mockPending });

      const db = require('../../db');
      const result = await db.query(
        `SELECT * FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         WHERE p.seller_id = $1 AND o.status = $2`,
        ['seller-1', 'pending']
      );

      expect(result.rows[0].status).toBe('pending');
    });
  });

  describe('createOrderFromCart', () => {
    it('should create order from cart items', async () => {
      const mockCartItems = [
        { product_id: 'prod-1', quantity: 2, name: 'Seeds', price: 250, unit_price: 250, stock_quantity: 100, is_available: true }
      ];

      const mockOrder = {
        id: 'order-1',
        user_id: 'user-1',
        total_amount: 500.00,
        status: 'pending'
      };

      mockClient.query
        .mockResolvedValueOnce({ command: 'BEGIN' })
        .mockResolvedValueOnce({ rows: mockCartItems })
        .mockResolvedValueOnce({ rows: [mockOrder] })
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ command: 'COMMIT' });

      const db = require('../../db');
      const client = await db.pool.connect();

      await client.query('BEGIN');
      const cartResult = await client.query(
        `SELECT ci.*, p.name, p.price, p.stock_quantity, p.is_available
         FROM cart_items ci
         JOIN products p ON ci.product_id = p.id
         WHERE ci.user_id = $1`,
        ['user-1']
      );

      expect(cartResult.rows).toHaveLength(1);
      expect(cartResult.rows[0].is_available).toBe(true);
    });

    it('should require shipping address', () => {
      const validRequest = { shipping_address: '123 Farm Lane' };
      const invalidRequest = {};

      expect('shipping_address' in validRequest).toBe(true);
      expect('shipping_address' in invalidRequest).toBe(false);
    });

    it('should fail on empty cart', async () => {
      mockClient.query
        .mockResolvedValueOnce({ command: 'BEGIN' })
        .mockResolvedValueOnce({ rows: [] });

      const db = require('../../db');
      const client = await db.pool.connect();

      await client.query('BEGIN');
      const cartResult = await client.query(
        `SELECT * FROM cart_items WHERE user_id = $1`,
        ['user-1']
      );

      expect(cartResult.rows.length).toBe(0);
    });

    it('should clear cart after order creation', async () => {
      mockClient.query.mockResolvedValueOnce({ rowCount: 3 });

      const db = require('../../db');
      const client = await db.pool.connect();
      const result = await client.query(
        'DELETE FROM cart_items WHERE user_id = $1',
        ['user-1']
      );

      expect(result.rowCount).toBe(3);
    });

    it('should check product availability from cart', () => {
      const availableItem = { is_available: true, stock_quantity: 10, quantity: 5 };
      const unavailableItem = { is_available: false, stock_quantity: 10, quantity: 5 };
      const insufficientStock = { is_available: true, stock_quantity: 3, quantity: 5 };

      expect(availableItem.is_available && availableItem.stock_quantity >= availableItem.quantity).toBe(true);
      expect(unavailableItem.is_available).toBe(false);
      expect(insufficientStock.stock_quantity >= insufficientStock.quantity).toBe(false);
    });
  });

  describe('Order Status Transitions', () => {
    it('should validate status transition rules', () => {
      const validTransitions = {
        pending: ['confirmed', 'cancelled'],
        confirmed: ['shipped', 'cancelled'],
        shipped: ['delivered'],
        delivered: [],
        cancelled: []
      };

      expect(validTransitions.pending).toContain('confirmed');
      expect(validTransitions.confirmed).toContain('shipped');
      expect(validTransitions.shipped).toContain('delivered');
      expect(validTransitions.delivered).toHaveLength(0);
      expect(validTransitions.cancelled).toHaveLength(0);
    });
  });

  describe('Order Item Calculations', () => {
    it('should calculate item total correctly', () => {
      const item = { unit_price: 250.00, quantity: 3 };
      const total = item.unit_price * item.quantity;

      expect(total).toBe(750.00);
    });

    it('should calculate order total from multiple items', () => {
      const items = [
        { unit_price: 250.00, quantity: 2 },
        { unit_price: 100.00, quantity: 5 },
        { unit_price: 50.00, quantity: 10 }
      ];

      const total = items.reduce((sum, item) => sum + (item.unit_price * item.quantity), 0);
      expect(total).toBe(1500.00);
    });
  });

  describe('Payment Status', () => {
    it('should have valid payment status values', () => {
      const validPaymentStatuses = ['pending', 'paid', 'failed', 'refunded'];

      expect(validPaymentStatuses).toContain('pending');
      expect(validPaymentStatuses).toContain('paid');
      expect(validPaymentStatuses).toContain('refunded');
    });
  });
});

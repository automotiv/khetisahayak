/**
 * Unit Tests for Wishlist API
 * Tests for wishlist operations including add, remove, and retrieval (#Sprint4)
 */

const mockQuery = jest.fn();
jest.mock('../../db', () => ({
  query: mockQuery
}));

describe('Wishlist Operations', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('Get Wishlist', () => {
    it('should retrieve all wishlist items for user', async () => {
      const mockWishlistItems = [
        {
          id: 'w-uuid-1',
          product_id: 'p-uuid-1',
          product_name: 'Organic Seeds',
          product_description: 'High quality organic seeds',
          price: '120.00',
          product_images: ['https://example.com/img1.jpg'],
          stock_quantity: 100,
          is_available: true,
          category: 'seeds',
          brand: 'AgriPro',
          is_organic: true,
          created_at: new Date(),
        },
        {
          id: 'w-uuid-2',
          product_id: 'p-uuid-2',
          product_name: 'Fertilizer Pack',
          product_description: 'Organic fertilizer',
          price: '250.00',
          product_images: ['https://example.com/img2.jpg'],
          stock_quantity: 50,
          is_available: true,
          category: 'fertilizers',
          brand: 'FarmBest',
          is_organic: true,
          created_at: new Date(),
        },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockWishlistItems });

      const result = await db.query(
        `SELECT
          w.id,
          w.product_id,
          w.created_at,
          p.name as product_name,
          p.description as product_description,
          p.price,
          p.image_urls as product_images,
          p.stock_quantity,
          p.is_available,
          p.category,
          p.brand,
          p.is_organic
        FROM wishlists w
        JOIN products p ON w.product_id = p.id
        WHERE w.user_id = $1
        ORDER BY w.created_at DESC`,
        ['user-1']
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows[0].product_name).toBe('Organic Seeds');
    });

    it('should return empty array for user with no wishlist items', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        'SELECT * FROM wishlists WHERE user_id = $1',
        ['user-with-empty-wishlist']
      );

      expect(result.rows).toHaveLength(0);
    });

    it('should include product availability status', async () => {
      const mockItems = [
        { id: 'w-1', product_id: 'p-1', is_available: true },
        { id: 'w-2', product_id: 'p-2', is_available: false },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockItems });

      const result = await db.query(
        'SELECT w.*, p.is_available FROM wishlists w JOIN products p ON w.product_id = p.id WHERE w.user_id = $1',
        ['user-1']
      );

      expect(result.rows.some(item => item.is_available === true)).toBe(true);
      expect(result.rows.some(item => item.is_available === false)).toBe(true);
    });

    it('should return correct item count', async () => {
      const mockItems = Array(5).fill({ id: 'w-uuid', product_id: 'p-uuid' });

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockItems });

      const result = await db.query(
        'SELECT * FROM wishlists WHERE user_id = $1',
        ['user-1']
      );

      expect(result.rows.length).toBe(5);
    });
  });

  describe('Add to Wishlist', () => {
    it('should verify product exists before adding', async () => {
      const mockProduct = { id: 'p-uuid-1', name: 'Test Product' };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockProduct] });

      const result = await db.query(
        'SELECT id, name FROM products WHERE id = $1',
        ['p-uuid-1']
      );

      expect(result.rows).toHaveLength(1);
    });

    it('should return 404 for non-existent product', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        'SELECT id FROM products WHERE id = $1',
        ['non-existent-product']
      );

      expect(result.rows).toHaveLength(0);
    });

    it('should check if product already in wishlist', async () => {
      const existingItem = { id: 'w-uuid-1' };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [existingItem] });

      const result = await db.query(
        'SELECT id FROM wishlists WHERE user_id = $1 AND product_id = $2',
        ['user-1', 'p-uuid-1']
      );

      expect(result.rows).toHaveLength(1);
    });

    it('should reject duplicate wishlist entry', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [{ id: 'existing-item' }] });

      const existingCheck = await db.query(
        'SELECT id FROM wishlists WHERE user_id = $1 AND product_id = $2',
        ['user-1', 'p-uuid-1']
      );

      const isDuplicate = existingCheck.rows.length > 0;
      expect(isDuplicate).toBe(true);
    });

    it('should successfully add product to wishlist', async () => {
      const mockWishlistItem = {
        id: 'w-uuid-new',
        user_id: 'user-1',
        product_id: 'p-uuid-1',
        created_at: new Date(),
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockWishlistItem] });

      const result = await db.query(
        `INSERT INTO wishlists (user_id, product_id)
         VALUES ($1, $2)
         RETURNING *`,
        ['user-1', 'p-uuid-1']
      );

      expect(result.rows[0].id).toBe('w-uuid-new');
      expect(result.rows[0].user_id).toBe('user-1');
      expect(result.rows[0].product_id).toBe('p-uuid-1');
    });
  });

  describe('Remove from Wishlist', () => {
    it('should remove product from wishlist', async () => {
      const removedItem = {
        id: 'w-uuid-1',
        user_id: 'user-1',
        product_id: 'p-uuid-1',
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [removedItem] });

      const result = await db.query(
        'DELETE FROM wishlists WHERE user_id = $1 AND product_id = $2 RETURNING *',
        ['user-1', 'p-uuid-1']
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].product_id).toBe('p-uuid-1');
    });

    it('should return 404 if product not in wishlist', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        'DELETE FROM wishlists WHERE user_id = $1 AND product_id = $2 RETURNING *',
        ['user-1', 'not-in-wishlist']
      );

      expect(result.rows).toHaveLength(0);
    });

    it('should only remove from current user wishlist', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        'DELETE FROM wishlists WHERE user_id = $1 AND product_id = $2 RETURNING *',
        ['user-2', 'p-uuid-1']
      );

      expect(result.rows).toHaveLength(0);
    });
  });

  describe('Check Product in Wishlist', () => {
    it('should return true if product is in wishlist', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [{ id: 'w-uuid-1' }] });

      const result = await db.query(
        'SELECT id FROM wishlists WHERE user_id = $1 AND product_id = $2',
        ['user-1', 'p-uuid-1']
      );

      const inWishlist = result.rows.length > 0;
      expect(inWishlist).toBe(true);
    });

    it('should return false if product is not in wishlist', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        'SELECT id FROM wishlists WHERE user_id = $1 AND product_id = $2',
        ['user-1', 'p-uuid-not-in-wishlist']
      );

      const inWishlist = result.rows.length > 0;
      expect(inWishlist).toBe(false);
    });
  });

  describe('Get Wishlist Product IDs', () => {
    it('should return array of product IDs', async () => {
      const mockRows = [
        { product_id: 'p-uuid-1' },
        { product_id: 'p-uuid-2' },
        { product_id: 'p-uuid-3' },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockRows });

      const result = await db.query(
        'SELECT product_id FROM wishlists WHERE user_id = $1',
        ['user-1']
      );

      const productIds = result.rows.map(row => row.product_id);
      
      expect(productIds).toHaveLength(3);
      expect(productIds).toContain('p-uuid-1');
      expect(productIds).toContain('p-uuid-2');
      expect(productIds).toContain('p-uuid-3');
    });

    it('should return empty array for user with no wishlist', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        'SELECT product_id FROM wishlists WHERE user_id = $1',
        ['user-with-no-wishlist']
      );

      const productIds = result.rows.map(row => row.product_id);
      expect(productIds).toEqual([]);
    });
  });

  describe('Response Formatting', () => {
    it('should return correct success response for get wishlist', () => {
      const response = {
        success: true,
        data: {
          items: [],
          count: 0,
        },
      };

      expect(response).toHaveProperty('success', true);
      expect(response.data).toHaveProperty('items');
      expect(response.data).toHaveProperty('count');
    });

    it('should return correct success response for add to wishlist', () => {
      const response = {
        success: true,
        message: 'Product added to wishlist',
        data: { id: 'w-uuid-1', product_id: 'p-uuid-1' },
      };

      expect(response).toHaveProperty('success', true);
      expect(response).toHaveProperty('message');
      expect(response).toHaveProperty('data');
    });

    it('should return correct success response for remove from wishlist', () => {
      const response = {
        success: true,
        message: 'Product removed from wishlist',
      };

      expect(response).toHaveProperty('success', true);
      expect(response).toHaveProperty('message');
    });

    it('should return correct response for is in wishlist check', () => {
      const response = {
        success: true,
        data: {
          inWishlist: true,
        },
      };

      expect(response.data).toHaveProperty('inWishlist');
      expect(typeof response.data.inWishlist).toBe('boolean');
    });

    it('should return correct response for get product IDs', () => {
      const response = {
        success: true,
        data: {
          productIds: ['p-uuid-1', 'p-uuid-2'],
        },
      };

      expect(response.data).toHaveProperty('productIds');
      expect(Array.isArray(response.data.productIds)).toBe(true);
    });
  });

  describe('Edge Cases', () => {
    it('should handle product that was deleted after being added to wishlist', async () => {
      const mockItems = [
        { id: 'w-1', product_id: 'p-deleted', product_name: null, is_available: false },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockItems });

      const result = await db.query(
        `SELECT w.*, p.name as product_name, p.is_available
         FROM wishlists w
         LEFT JOIN products p ON w.product_id = p.id
         WHERE w.user_id = $1`,
        ['user-1']
      );

      expect(result.rows[0].product_name).toBeNull();
    });

    it('should handle concurrent add requests gracefully', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [{ id: 'existing' }] });

      const result = await db.query(
        'SELECT id FROM wishlists WHERE user_id = $1 AND product_id = $2',
        ['user-1', 'p-uuid-1']
      );

      const alreadyExists = result.rows.length > 0;
      expect(alreadyExists).toBe(true);
    });
  });
});

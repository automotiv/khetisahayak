/**
 * Integration Tests for Wishlist API
 * Tests end-to-end wishlist operations (#Sprint4)
 */

const request = require('supertest');

const mockQuery = jest.fn();
jest.mock('../../db', () => ({
  query: mockQuery
}));

const express = require('express');
const wishlistRoutes = require('../../routes/wishlist');

const app = express();
app.use(express.json());

const mockProtect = (req, res, next) => {
  req.user = { id: 'test-user-id', role: 'user' };
  next();
};

app.use('/api/wishlist', mockProtect, wishlistRoutes);

describe('Wishlist Integration Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Get Wishlist', () => {
    it('should return user wishlist with product details', async () => {
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

      mockQuery.mockResolvedValueOnce({ rows: mockWishlistItems });

      const response = await request(app)
        .get('/api/wishlist')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.items).toHaveLength(2);
      expect(response.body.data.count).toBe(2);
    });

    it('should return empty wishlist for new user', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .get('/api/wishlist')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(200);
      expect(response.body.data.items).toHaveLength(0);
      expect(response.body.data.count).toBe(0);
    });
  });

  describe('Add to Wishlist', () => {
    it('should add product to wishlist', async () => {
      const mockProduct = { id: 'p-uuid-1', name: 'Organic Seeds' };
      const mockWishlistItem = {
        id: 'w-uuid-new',
        user_id: 'test-user-id',
        product_id: 'p-uuid-1',
        created_at: new Date(),
      };

      mockQuery.mockResolvedValueOnce({ rows: [mockProduct] });
      mockQuery.mockResolvedValueOnce({ rows: [] });
      mockQuery.mockResolvedValueOnce({ rows: [mockWishlistItem] });

      const response = await request(app)
        .post('/api/wishlist/p-uuid-1')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Product added to wishlist');
    });

    it('should return 404 for non-existent product', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/wishlist/non-existent')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(404);
    });

    it('should return 400 for duplicate wishlist entry', async () => {
      const mockProduct = { id: 'p-uuid-1', name: 'Organic Seeds' };
      const existingItem = { id: 'w-uuid-existing' };

      mockQuery.mockResolvedValueOnce({ rows: [mockProduct] });
      mockQuery.mockResolvedValueOnce({ rows: [existingItem] });

      const response = await request(app)
        .post('/api/wishlist/p-uuid-1')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(400);
    });
  });

  describe('Remove from Wishlist', () => {
    it('should remove product from wishlist', async () => {
      const removedItem = {
        id: 'w-uuid-1',
        user_id: 'test-user-id',
        product_id: 'p-uuid-1',
      };

      mockQuery.mockResolvedValueOnce({ rows: [removedItem] });

      const response = await request(app)
        .delete('/api/wishlist/p-uuid-1')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Product removed from wishlist');
    });

    it('should return 404 if product not in wishlist', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .delete('/api/wishlist/not-in-wishlist')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(404);
    });
  });

  describe('Check Product in Wishlist', () => {
    it('should return true if product is in wishlist', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [{ id: 'w-uuid-1' }] });

      const response = await request(app)
        .get('/api/wishlist/check/p-uuid-1')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(200);
      expect(response.body.data.inWishlist).toBe(true);
    });

    it('should return false if product is not in wishlist', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .get('/api/wishlist/check/not-in-wishlist')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(200);
      expect(response.body.data.inWishlist).toBe(false);
    });
  });

  describe('Get Wishlist Product IDs', () => {
    it('should return array of product IDs', async () => {
      const mockRows = [
        { product_id: 'p-uuid-1' },
        { product_id: 'p-uuid-2' },
        { product_id: 'p-uuid-3' },
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockRows });

      const response = await request(app)
        .get('/api/wishlist/product-ids')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(200);
      expect(response.body.data.productIds).toHaveLength(3);
      expect(response.body.data.productIds).toContain('p-uuid-1');
    });

    it('should return empty array for user with no wishlist', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .get('/api/wishlist/product-ids')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(200);
      expect(response.body.data.productIds).toEqual([]);
    });
  });

  describe('Complete Wishlist Flow', () => {
    it('should handle add, check, and remove flow', async () => {
      const mockProduct = { id: 'p-uuid-1', name: 'Test Product' };
      const mockWishlistItem = { id: 'w-uuid-1', product_id: 'p-uuid-1' };

      mockQuery.mockResolvedValueOnce({ rows: [mockProduct] });
      mockQuery.mockResolvedValueOnce({ rows: [] });
      mockQuery.mockResolvedValueOnce({ rows: [mockWishlistItem] });

      const addResponse = await request(app)
        .post('/api/wishlist/p-uuid-1')
        .set('Authorization', 'Bearer test-token');

      expect(addResponse.status).toBe(201);

      mockQuery.mockResolvedValueOnce({ rows: [{ id: 'w-uuid-1' }] });

      const checkResponse = await request(app)
        .get('/api/wishlist/check/p-uuid-1')
        .set('Authorization', 'Bearer test-token');

      expect(checkResponse.body.data.inWishlist).toBe(true);

      mockQuery.mockResolvedValueOnce({ rows: [mockWishlistItem] });

      const removeResponse = await request(app)
        .delete('/api/wishlist/p-uuid-1')
        .set('Authorization', 'Bearer test-token');

      expect(removeResponse.status).toBe(200);
    });
  });
});

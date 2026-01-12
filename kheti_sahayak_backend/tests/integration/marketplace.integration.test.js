/**
 * Integration Tests for Marketplace API
 * Tests end-to-end product comparison and marketplace flows (#Sprint4)
 */

const request = require('supertest');

const mockQuery = jest.fn();
jest.mock('../../db', () => ({
  query: mockQuery
}));

const express = require('express');
const marketplaceRoutes = require('../../routes/marketplace');

const app = express();
app.use(express.json());

const mockProtect = (req, res, next) => {
  req.user = { id: 'test-user-id', role: 'user' };
  next();
};

app.use('/api/marketplace', (req, res, next) => {
  if (req.path === '/compare' || req.path.startsWith('/categories') || req.method === 'GET') {
    return next();
  }
  return mockProtect(req, res, next);
}, marketplaceRoutes);

describe('Marketplace Integration Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Product Comparison Flow', () => {
    it('should compare products successfully with valid IDs', async () => {
      const mockProducts = [
        {
          id: 'uuid-1',
          name: 'Organic Tomato Seeds',
          price: '120.00',
          category: 'seeds',
          brand: 'AgriPro',
          is_organic: true,
          stock_quantity: 100,
          unit: 'packet',
          seller_name: 'farmer1',
          avg_rating: '4.5',
          review_count: '10',
          specifications: { weight: '100g', germination_rate: '95%' },
        },
        {
          id: 'uuid-2',
          name: 'Hybrid Tomato Seeds',
          price: '150.00',
          category: 'seeds',
          brand: 'FarmBest',
          is_organic: false,
          stock_quantity: 75,
          unit: 'packet',
          seller_name: 'farmer2',
          avg_rating: '4.2',
          review_count: '5',
          specifications: { weight: '150g', germination_rate: '92%' },
        },
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const response = await request(app)
        .post('/api/marketplace/compare')
        .send({ product_ids: ['uuid-1', 'uuid-2'] });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.products).toHaveLength(2);
      expect(response.body.comparison_summary).toBeDefined();
      expect(response.body.comparison_summary.lowest_price).toBe(120);
      expect(response.body.attributes).toBeDefined();
    });

    it('should reject comparison with less than 2 products', async () => {
      const response = await request(app)
        .post('/api/marketplace/compare')
        .send({ product_ids: ['uuid-1'] });

      expect(response.status).toBe(400);
    });

    it('should reject comparison with more than 5 products', async () => {
      const response = await request(app)
        .post('/api/marketplace/compare')
        .send({ 
          product_ids: ['uuid-1', 'uuid-2', 'uuid-3', 'uuid-4', 'uuid-5', 'uuid-6'] 
        });

      expect(response.status).toBe(400);
    });

    it('should return 404 when no products found', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/marketplace/compare')
        .send({ product_ids: ['non-existent-1', 'non-existent-2'] });

      expect(response.status).toBe(404);
    });

    it('should include specification attributes in comparison', async () => {
      const mockProducts = [
        {
          id: 'uuid-1',
          name: 'Product 1',
          price: '100.00',
          avg_rating: '4.0',
          review_count: '5',
          specifications: { weight: '100g', color: 'red' },
        },
        {
          id: 'uuid-2',
          name: 'Product 2',
          price: '120.00',
          avg_rating: '4.5',
          review_count: '10',
          specifications: { weight: '150g', size: 'large' },
        },
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const response = await request(app)
        .post('/api/marketplace/compare')
        .send({ product_ids: ['uuid-1', 'uuid-2'] });

      expect(response.status).toBe(200);
      const specAttributes = response.body.attributes.filter(a => a.isSpec);
      expect(specAttributes.length).toBeGreaterThan(0);
    });
  });

  describe('Product Listing', () => {
    it('should list products with pagination', async () => {
      const mockProducts = Array(10).fill(null).map((_, i) => ({
        id: `uuid-${i}`,
        name: `Product ${i}`,
        price: (100 + i * 10).toFixed(2),
        is_available: true,
      }));

      mockQuery.mockResolvedValueOnce({ rows: mockProducts });
      mockQuery.mockResolvedValueOnce({ rows: [{ count: '25' }] });

      const response = await request(app)
        .get('/api/marketplace')
        .query({ page: 1, limit: 10 });

      expect(response.status).toBe(200);
      expect(response.body.products).toHaveLength(10);
      expect(response.body.pagination).toBeDefined();
    });

    it('should filter products by category', async () => {
      const mockProducts = [
        { id: 'uuid-1', name: 'Seeds 1', category: 'seeds' },
        { id: 'uuid-2', name: 'Seeds 2', category: 'seeds' },
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockProducts });
      mockQuery.mockResolvedValueOnce({ rows: [{ count: '2' }] });

      const response = await request(app)
        .get('/api/marketplace')
        .query({ category: 'seeds' });

      expect(response.status).toBe(200);
      expect(response.body.products.every(p => p.category === 'seeds')).toBe(true);
    });

    it('should filter products by price range', async () => {
      const mockProducts = [
        { id: 'uuid-1', name: 'Product 1', price: '120.00' },
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockProducts });
      mockQuery.mockResolvedValueOnce({ rows: [{ count: '1' }] });

      const response = await request(app)
        .get('/api/marketplace')
        .query({ min_price: 100, max_price: 200 });

      expect(response.status).toBe(200);
    });

    it('should search products by name', async () => {
      const mockProducts = [
        { id: 'uuid-1', name: 'Tomato Seeds', description: 'Organic tomatoes' },
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockProducts });
      mockQuery.mockResolvedValueOnce({ rows: [{ count: '1' }] });

      const response = await request(app)
        .get('/api/marketplace')
        .query({ search: 'tomato' });

      expect(response.status).toBe(200);
    });
  });

  describe('Product Details', () => {
    it('should get product by ID', async () => {
      const mockProduct = {
        id: 'uuid-1',
        name: 'Organic Seeds',
        price: '120.00',
        seller_name: 'farmer1',
      };

      mockQuery.mockResolvedValueOnce({ rows: [mockProduct] });

      const response = await request(app)
        .get('/api/marketplace/uuid-1');

      expect(response.status).toBe(200);
      expect(response.body.name).toBe('Organic Seeds');
    });

    it('should return 404 for non-existent product', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .get('/api/marketplace/non-existent');

      expect(response.status).toBe(404);
    });
  });

  describe('Product Categories', () => {
    it('should get all categories with subcategories', async () => {
      const mockCategories = [
        { category: 'seeds', subcategory: 'vegetables' },
        { category: 'seeds', subcategory: 'fruits' },
        { category: 'fertilizers', subcategory: 'organic' },
      ];

      mockQuery.mockResolvedValueOnce({ rows: mockCategories });

      const response = await request(app)
        .get('/api/marketplace/categories');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('seeds');
      expect(response.body.seeds).toContain('vegetables');
    });
  });
});

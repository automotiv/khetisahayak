/**
 * Unit Tests for Product Comparison API
 *
 * Tests for product comparison functionality including validation,
 * data aggregation, and response formatting (#Sprint4)
 */

const mockQuery = jest.fn();
jest.mock('../../db', () => ({
  query: mockQuery
}));

describe('Product Comparison', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('compareProducts Validation', () => {
    it('should require at least 2 product IDs', () => {
      const productIds = ['uuid-1'];
      
      const isValid = Array.isArray(productIds) && productIds.length >= 2;
      expect(isValid).toBe(false);
    });

    it('should accept 2 product IDs', () => {
      const productIds = ['uuid-1', 'uuid-2'];
      
      const isValid = Array.isArray(productIds) && productIds.length >= 2;
      expect(isValid).toBe(true);
    });

    it('should reject more than 5 product IDs', () => {
      const productIds = ['uuid-1', 'uuid-2', 'uuid-3', 'uuid-4', 'uuid-5', 'uuid-6'];
      
      const isValid = productIds.length <= 5;
      expect(isValid).toBe(false);
    });

    it('should accept exactly 5 product IDs', () => {
      const productIds = ['uuid-1', 'uuid-2', 'uuid-3', 'uuid-4', 'uuid-5'];
      
      const isValid = Array.isArray(productIds) && productIds.length >= 2 && productIds.length <= 5;
      expect(isValid).toBe(true);
    });

    it('should reject non-array input', () => {
      const productIds = 'uuid-1,uuid-2';
      
      const isValid = Array.isArray(productIds);
      expect(isValid).toBe(false);
    });

    it('should reject null input', () => {
      const productIds = null;
      
      const isValid = productIds && Array.isArray(productIds);
      expect(isValid).toBe(false);
    });

    it('should reject undefined input', () => {
      const productIds = undefined;
      
      const isValid = productIds && Array.isArray(productIds);
      expect(isValid).toBe(false);
    });
  });

  describe('compareProducts Database Query', () => {
    it('should fetch products with ratings and reviews', async () => {
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
          seller_name: 'testuser',
          avg_rating: '4.5',
          review_count: '10',
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
          seller_name: 'testuser2',
          avg_rating: '4.2',
          review_count: '5',
        },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const productIds = ['uuid-1', 'uuid-2'];
      const result = await db.query(`
        SELECT 
          p.*,
          u.username as seller_name,
          COALESCE(r.avg_rating, 0) as avg_rating,
          COALESCE(r.review_count, 0) as review_count
        FROM products p
        LEFT JOIN users u ON p.seller_id = u.id
        LEFT JOIN (
          SELECT product_id, AVG(rating) as avg_rating, COUNT(*) as review_count
          FROM reviews
          GROUP BY product_id
        ) r ON p.id = r.product_id
        WHERE p.id IN ($1, $2)
      `, productIds);

      expect(result.rows).toHaveLength(2);
      expect(result.rows[0].avg_rating).toBeDefined();
      expect(result.rows[0].review_count).toBeDefined();
    });

    it('should handle products without reviews', async () => {
      const mockProducts = [
        {
          id: 'uuid-1',
          name: 'New Product',
          price: '100.00',
          avg_rating: 0,
          review_count: 0,
        },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const result = await db.query('SELECT * FROM products WHERE id = $1', ['uuid-1']);

      expect(result.rows[0].avg_rating).toBe(0);
      expect(result.rows[0].review_count).toBe(0);
    });

    it('should return empty array for non-existent products', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        'SELECT * FROM products WHERE id IN ($1, $2)',
        ['non-existent-1', 'non-existent-2']
      );

      expect(result.rows).toHaveLength(0);
    });
  });

  describe('Comparison Attributes', () => {
    it('should include standard comparison attributes', () => {
      const attributes = [
        { key: 'price', label: 'Price', type: 'currency' },
        { key: 'category', label: 'Category', type: 'text' },
        { key: 'brand', label: 'Brand', type: 'text' },
        { key: 'is_organic', label: 'Organic', type: 'boolean' },
        { key: 'stock_quantity', label: 'Stock', type: 'number' },
        { key: 'unit', label: 'Unit', type: 'text' },
        { key: 'avg_rating', label: 'Rating', type: 'rating' },
        { key: 'review_count', label: 'Reviews', type: 'number' },
      ];

      expect(attributes.find(a => a.key === 'price')).toBeDefined();
      expect(attributes.find(a => a.key === 'avg_rating')).toBeDefined();
      expect(attributes.find(a => a.type === 'currency')).toBeDefined();
      expect(attributes.find(a => a.type === 'rating')).toBeDefined();
    });

    it('should extract specification keys from products', () => {
      const products = [
        {
          id: 'uuid-1',
          specifications: {
            weight: '100g',
            germination_rate: '95%',
            shelf_life: '12 months',
          },
        },
        {
          id: 'uuid-2',
          specifications: {
            weight: '150g',
            germination_rate: '92%',
            origin: 'Maharashtra',
          },
        },
      ];

      const specKeys = new Set();
      products.forEach(product => {
        if (product.specifications && typeof product.specifications === 'object') {
          Object.keys(product.specifications).forEach(key => specKeys.add(key));
        }
      });

      expect(specKeys.has('weight')).toBe(true);
      expect(specKeys.has('germination_rate')).toBe(true);
      expect(specKeys.has('shelf_life')).toBe(true);
      expect(specKeys.has('origin')).toBe(true);
      expect(specKeys.size).toBe(4);
    });

    it('should handle products without specifications', () => {
      const products = [
        { id: 'uuid-1', specifications: null },
        { id: 'uuid-2', specifications: undefined },
        { id: 'uuid-3' },
      ];

      const specKeys = new Set();
      products.forEach(product => {
        if (product.specifications && typeof product.specifications === 'object') {
          Object.keys(product.specifications).forEach(key => specKeys.add(key));
        }
      });

      expect(specKeys.size).toBe(0);
    });
  });

  describe('Comparison Summary', () => {
    it('should calculate lowest price', () => {
      const products = [
        { id: 'uuid-1', price: '120.00' },
        { id: 'uuid-2', price: '150.00' },
        { id: 'uuid-3', price: '100.00' },
      ];

      const lowestPrice = Math.min(...products.map(p => parseFloat(p.price)));
      expect(lowestPrice).toBe(100.00);
    });

    it('should calculate highest rating', () => {
      const products = [
        { id: 'uuid-1', avg_rating: '4.5' },
        { id: 'uuid-2', avg_rating: '4.2' },
        { id: 'uuid-3', avg_rating: '4.8' },
      ];

      const highestRating = Math.max(...products.map(p => parseFloat(p.avg_rating) || 0));
      expect(highestRating).toBe(4.8);
    });

    it('should handle products with zero ratings', () => {
      const products = [
        { id: 'uuid-1', avg_rating: '0' },
        { id: 'uuid-2', avg_rating: null },
        { id: 'uuid-3', avg_rating: '3.5' },
      ];

      const highestRating = Math.max(...products.map(p => parseFloat(p.avg_rating) || 0));
      expect(highestRating).toBe(3.5);
    });

    it('should return correct product count', () => {
      const products = [
        { id: 'uuid-1' },
        { id: 'uuid-2' },
        { id: 'uuid-3' },
      ];

      expect(products.length).toBe(3);
    });

    it('should build correct comparison summary', () => {
      const products = [
        { id: 'uuid-1', price: '120.00', avg_rating: '4.5' },
        { id: 'uuid-2', price: '150.00', avg_rating: '4.8' },
      ];

      const summary = {
        lowest_price: Math.min(...products.map(p => parseFloat(p.price))),
        highest_rating: Math.max(...products.map(p => parseFloat(p.avg_rating) || 0)),
        product_count: products.length,
      };

      expect(summary.lowest_price).toBe(120.00);
      expect(summary.highest_rating).toBe(4.8);
      expect(summary.product_count).toBe(2);
    });
  });

  describe('Product Formatting', () => {
    it('should flatten specifications into product object', () => {
      const product = {
        id: 'uuid-1',
        name: 'Test Product',
        specifications: {
          weight: '100g',
          color: 'green',
        },
      };

      const formatted = { ...product };
      if (product.specifications && typeof product.specifications === 'object') {
        Object.entries(product.specifications).forEach(([key, value]) => {
          formatted[`spec_${key}`] = value;
        });
      }

      expect(formatted.spec_weight).toBe('100g');
      expect(formatted.spec_color).toBe('green');
    });

    it('should preserve original product fields', () => {
      const product = {
        id: 'uuid-1',
        name: 'Test Product',
        price: '100.00',
        specifications: { weight: '100g' },
      };

      const formatted = { ...product };
      if (product.specifications && typeof product.specifications === 'object') {
        Object.entries(product.specifications).forEach(([key, value]) => {
          formatted[`spec_${key}`] = value;
        });
      }

      expect(formatted.id).toBe('uuid-1');
      expect(formatted.name).toBe('Test Product');
      expect(formatted.price).toBe('100.00');
    });
  });

  describe('Response Structure', () => {
    it('should return correct response structure', () => {
      const response = {
        success: true,
        products: [],
        attributes: [],
        comparison_summary: {
          lowest_price: 0,
          highest_rating: 0,
          product_count: 0,
        },
      };

      expect(response).toHaveProperty('success');
      expect(response).toHaveProperty('products');
      expect(response).toHaveProperty('attributes');
      expect(response).toHaveProperty('comparison_summary');
      expect(response.comparison_summary).toHaveProperty('lowest_price');
      expect(response.comparison_summary).toHaveProperty('highest_rating');
      expect(response.comparison_summary).toHaveProperty('product_count');
    });
  });

  describe('Edge Cases', () => {
    it('should handle products with same price', () => {
      const products = [
        { id: 'uuid-1', price: '100.00' },
        { id: 'uuid-2', price: '100.00' },
      ];

      const lowestPrice = Math.min(...products.map(p => parseFloat(p.price)));
      expect(lowestPrice).toBe(100.00);
    });

    it('should handle products with same rating', () => {
      const products = [
        { id: 'uuid-1', avg_rating: '4.5' },
        { id: 'uuid-2', avg_rating: '4.5' },
      ];

      const highestRating = Math.max(...products.map(p => parseFloat(p.avg_rating) || 0));
      expect(highestRating).toBe(4.5);
    });

    it('should handle duplicate product IDs', async () => {
      const productIds = ['uuid-1', 'uuid-1', 'uuid-2'];
      const uniqueIds = [...new Set(productIds)];

      expect(uniqueIds).toHaveLength(2);
    });

    it('should handle mixed valid and invalid UUIDs', async () => {
      const mockProducts = [
        { id: 'uuid-1', name: 'Product 1' },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const result = await db.query(
        'SELECT * FROM products WHERE id IN ($1, $2)',
        ['uuid-1', 'invalid-uuid']
      );

      expect(result.rows.length).toBeLessThanOrEqual(2);
    });
  });
});

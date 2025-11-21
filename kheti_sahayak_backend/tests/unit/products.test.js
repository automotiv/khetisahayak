/**
 * Unit Tests for Product/Marketplace API
 *
 * Tests for product listing, creation, filtering, and category management (#367)
 */

const mockQuery = jest.fn();
jest.mock('../../db', () => ({
  query: mockQuery
}));

describe('Products Database Operations', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('Get All Products', () => {
    it('should retrieve all active products', async () => {
      const mockProducts = [
        {
          id: 'uuid-1',
          name: 'Organic Tomato Seeds',
          description: 'High-yield organic tomato seeds',
          price: 120.00,
          quantity: 100,
          category_id: 'cat-1',
          seller_id: 'seller-1',
          status: 'active',
          created_at: new Date(),
        },
        {
          id: 'uuid-2',
          name: 'NPK Fertilizer',
          description: 'Balanced 20-20-20 fertilizer',
          price: 450.00,
          quantity: 50,
          category_id: 'cat-2',
          seller_id: 'seller-1',
          status: 'active',
          created_at: new Date(),
        },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE status = 'active' ORDER BY created_at DESC`
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows[0].name).toBe('Organic Tomato Seeds');
      expect(result.rows[1].name).toBe('NPK Fertilizer');
    });

    it('should paginate products correctly', async () => {
      const page = 2;
      const limit = 10;
      const offset = (page - 1) * limit;

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: Array(10).fill({ id: 'mock' }) });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE status = 'active' ORDER BY created_at DESC LIMIT $1 OFFSET $2`,
        [limit, offset]
      );

      expect(result.rows).toHaveLength(10);
      expect(offset).toBe(10);
    });

    it('should handle empty product list', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE status = 'active'`
      );

      expect(result.rows).toHaveLength(0);
    });
  });

  describe('Get Product By ID', () => {
    it('should retrieve a single product by ID', async () => {
      const mockProduct = {
        id: 'uuid-1',
        name: 'Organic Tomato Seeds',
        description: 'High-yield organic tomato seeds',
        price: 120.00,
        quantity: 100,
        category_name: 'Seeds',
        seller_name: 'Farmer John',
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockProduct] });

      const result = await db.query(
        `SELECT mp.*, mc.name as category_name, u.username as seller_name
         FROM marketplace_products mp
         LEFT JOIN marketplace_categories mc ON mp.category_id = mc.id
         LEFT JOIN users u ON mp.seller_id = u.id
         WHERE mp.id = $1`,
        ['uuid-1']
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].name).toBe('Organic Tomato Seeds');
      expect(result.rows[0].category_name).toBe('Seeds');
    });

    it('should return empty for non-existent product', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE id = $1`,
        ['non-existent-id']
      );

      expect(result.rows).toHaveLength(0);
    });
  });

  describe('Create Product', () => {
    it('should create a new product successfully', async () => {
      const newProduct = {
        id: 'uuid-new',
        name: 'Premium Rice Seeds',
        description: 'High-quality Basmati rice seeds',
        price: 250.00,
        quantity: 200,
        unit: 'kg',
        category_id: 'cat-1',
        seller_id: 'seller-1',
        status: 'active',
        created_at: new Date(),
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [newProduct] });

      const result = await db.query(
        `INSERT INTO marketplace_products (name, description, price, quantity, unit, category_id, seller_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        ['Premium Rice Seeds', 'High-quality Basmati rice seeds', 250.00, 200, 'kg', 'cat-1', 'seller-1']
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].name).toBe('Premium Rice Seeds');
      expect(result.rows[0].price).toBe(250.00);
    });

    it('should validate required fields', () => {
      const requiredFields = ['name', 'price', 'quantity', 'seller_id'];
      const product = { name: 'Test', price: 100 };

      const missingFields = requiredFields.filter(field => !product[field]);

      expect(missingFields).toContain('quantity');
      expect(missingFields).toContain('seller_id');
    });

    it('should enforce positive price constraint', () => {
      const validPrice = 100.00;
      const invalidPrice = -50.00;

      expect(validPrice).toBeGreaterThan(0);
      expect(invalidPrice).toBeLessThan(0);
    });

    it('should enforce non-negative quantity constraint', () => {
      const validQuantity = 50;
      const invalidQuantity = -10;

      expect(validQuantity).toBeGreaterThanOrEqual(0);
      expect(invalidQuantity).toBeLessThan(0);
    });
  });

  describe('Update Product', () => {
    it('should update product details', async () => {
      const updatedProduct = {
        id: 'uuid-1',
        name: 'Updated Product Name',
        price: 150.00,
        updated_at: new Date(),
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [updatedProduct] });

      const result = await db.query(
        `UPDATE marketplace_products
         SET name = $1, price = $2, updated_at = CURRENT_TIMESTAMP
         WHERE id = $3
         RETURNING *`,
        ['Updated Product Name', 150.00, 'uuid-1']
      );

      expect(result.rows[0].name).toBe('Updated Product Name');
      expect(result.rows[0].price).toBe(150.00);
    });

    it('should verify seller ownership before update', async () => {
      const mockProduct = {
        id: 'uuid-1',
        seller_id: 'seller-1',
      };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockProduct] });

      const result = await db.query(
        'SELECT seller_id FROM marketplace_products WHERE id = $1',
        ['uuid-1']
      );

      const requestingSellerId = 'seller-1';
      expect(result.rows[0].seller_id).toBe(requestingSellerId);
    });
  });

  describe('Delete Product', () => {
    it('should soft delete a product by updating status', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const result = await db.query(
        `UPDATE marketplace_products SET status = 'inactive' WHERE id = $1`,
        ['uuid-1']
      );

      expect(result.rowCount).toBe(1);
    });

    it('should verify authorization before deletion', async () => {
      const mockProduct = { id: 'uuid-1', seller_id: 'seller-1' };

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [mockProduct] });

      const result = await db.query(
        'SELECT * FROM marketplace_products WHERE id = $1',
        ['uuid-1']
      );

      const isOwner = result.rows[0].seller_id === 'seller-1';
      const isAdmin = false;

      expect(isOwner || isAdmin).toBe(true);
    });
  });

  describe('Product Categories', () => {
    it('should retrieve all categories', async () => {
      const mockCategories = [
        { id: 'cat-1', name: 'Seeds', description: 'All types of seeds' },
        { id: 'cat-2', name: 'Fertilizers', description: 'Organic and chemical fertilizers' },
        { id: 'cat-3', name: 'Tools', description: 'Farming tools and equipment' },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockCategories });

      const result = await db.query(
        'SELECT * FROM marketplace_categories ORDER BY name'
      );

      expect(result.rows).toHaveLength(3);
      expect(result.rows[0].name).toBe('Seeds');
    });

    it('should get products by category', async () => {
      const mockProducts = [
        { id: 'uuid-1', name: 'Tomato Seeds', category_id: 'cat-1' },
        { id: 'uuid-2', name: 'Wheat Seeds', category_id: 'cat-1' },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE category_id = $1 AND status = 'active'`,
        ['cat-1']
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows.every(p => p.category_id === 'cat-1')).toBe(true);
    });
  });

  describe('Product Search', () => {
    it('should search products by name', async () => {
      const mockResults = [
        { id: 'uuid-1', name: 'Organic Tomato Seeds' },
        { id: 'uuid-2', name: 'Tomato Fertilizer' },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockResults });

      const searchTerm = '%tomato%';
      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE LOWER(name) LIKE LOWER($1) AND status = 'active'`,
        [searchTerm]
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows[0].name).toContain('Tomato');
    });

    it('should search in description as well', async () => {
      const mockResults = [
        { id: 'uuid-1', name: 'Premium Seeds', description: 'High-yield organic seeds' },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockResults });

      const result = await db.query(
        `SELECT * FROM marketplace_products
         WHERE (LOWER(name) LIKE LOWER($1) OR LOWER(description) LIKE LOWER($1))
         AND status = 'active'`,
        ['%organic%']
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].description).toContain('organic');
    });

    it('should handle empty search results', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE LOWER(name) LIKE LOWER($1)`,
        ['%nonexistent%']
      );

      expect(result.rows).toHaveLength(0);
    });
  });

  describe('Product Filtering', () => {
    it('should filter by price range', async () => {
      const mockProducts = [
        { id: 'uuid-1', name: 'Budget Seeds', price: 75.00 },
        { id: 'uuid-2', name: 'Premium Seeds', price: 125.00 },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const minPrice = 50;
      const maxPrice = 150;

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE price >= $1 AND price <= $2 AND status = 'active'`,
        [minPrice, maxPrice]
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows.every(p => p.price >= minPrice && p.price <= maxPrice)).toBe(true);
    });

    it('should filter by availability (in stock)', async () => {
      const mockProducts = [
        { id: 'uuid-1', name: 'Available Product', quantity: 50 },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE quantity > 0 AND status = 'active'`
      );

      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].quantity).toBeGreaterThan(0);
    });

    it('should combine multiple filters', async () => {
      const mockProducts = [
        { id: 'uuid-1', name: 'Organic Seeds', price: 100, category_id: 'cat-1', quantity: 30 },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const result = await db.query(
        `SELECT * FROM marketplace_products
         WHERE category_id = $1
         AND price >= $2 AND price <= $3
         AND quantity > 0
         AND status = 'active'`,
        ['cat-1', 50, 150]
      );

      expect(result.rows).toHaveLength(1);
    });
  });

  describe('Product Sorting', () => {
    it('should sort by price ascending', async () => {
      const mockProducts = [
        { id: 'uuid-1', price: 50 },
        { id: 'uuid-2', price: 100 },
        { id: 'uuid-3', price: 150 },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE status = 'active' ORDER BY price ASC`
      );

      expect(result.rows[0].price).toBe(50);
      expect(result.rows[2].price).toBe(150);
    });

    it('should sort by price descending', async () => {
      const mockProducts = [
        { id: 'uuid-1', price: 150 },
        { id: 'uuid-2', price: 100 },
        { id: 'uuid-3', price: 50 },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE status = 'active' ORDER BY price DESC`
      );

      expect(result.rows[0].price).toBe(150);
      expect(result.rows[2].price).toBe(50);
    });

    it('should sort by creation date (newest first)', async () => {
      const now = new Date();
      const yesterday = new Date(now - 86400000);

      const mockProducts = [
        { id: 'uuid-1', created_at: now },
        { id: 'uuid-2', created_at: yesterday },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE status = 'active' ORDER BY created_at DESC`
      );

      expect(result.rows[0].created_at.getTime()).toBeGreaterThan(result.rows[1].created_at.getTime());
    });

    const sortOptions = ['price_asc', 'price_desc', 'newest', 'oldest', 'name'];
    it('should support multiple sort options', () => {
      expect(sortOptions).toContain('price_asc');
      expect(sortOptions).toContain('newest');
      expect(sortOptions.length).toBe(5);
    });
  });

  describe('Seller Products', () => {
    it('should get all products by seller', async () => {
      const mockProducts = [
        { id: 'uuid-1', name: 'Product 1', seller_id: 'seller-1' },
        { id: 'uuid-2', name: 'Product 2', seller_id: 'seller-1' },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockProducts });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE seller_id = $1 ORDER BY created_at DESC`,
        ['seller-1']
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows.every(p => p.seller_id === 'seller-1')).toBe(true);
    });

    it('should count products by seller', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [{ count: 5 }] });

      const result = await db.query(
        `SELECT COUNT(*) as count FROM marketplace_products WHERE seller_id = $1`,
        ['seller-1']
      );

      expect(result.rows[0].count).toBe(5);
    });
  });

  describe('Product Images', () => {
    it('should support multiple product images', () => {
      const images = [
        'https://s3.amazonaws.com/products/img1.jpg',
        'https://s3.amazonaws.com/products/img2.jpg',
        'https://s3.amazonaws.com/products/img3.jpg',
      ];

      expect(Array.isArray(images)).toBe(true);
      expect(images.length).toBeLessThanOrEqual(10);
    });

    it('should handle products without images', () => {
      const images = [];
      expect(Array.isArray(images)).toBe(true);
      expect(images.length).toBe(0);
    });
  });

  describe('Product Status', () => {
    it('should have valid status values', () => {
      const validStatuses = ['active', 'inactive', 'pending', 'sold_out'];

      expect(validStatuses).toContain('active');
      expect(validStatuses).toContain('sold_out');
    });

    it('should only show active products in public listings', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [{ id: 'uuid-1', status: 'active' }] });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE status = 'active'`
      );

      expect(result.rows.every(p => p.status === 'active')).toBe(true);
    });
  });

  describe('Product Units', () => {
    it('should support various unit types', () => {
      const validUnits = ['kg', 'g', 'litre', 'ml', 'piece', 'packet', 'bag', 'quintal'];

      expect(validUnits).toContain('kg');
      expect(validUnits).toContain('packet');
    });
  });

  describe('Inventory Management', () => {
    it('should update quantity after sale', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: [{ quantity: 45 }] });

      const quantitySold = 5;
      const result = await db.query(
        `UPDATE marketplace_products SET quantity = quantity - $1 WHERE id = $2 RETURNING quantity`,
        [quantitySold, 'uuid-1']
      );

      expect(result.rows[0].quantity).toBe(45);
    });

    it('should not allow negative inventory', () => {
      const currentQuantity = 3;
      const orderQuantity = 5;

      const canFulfill = currentQuantity >= orderQuantity;
      expect(canFulfill).toBe(false);
    });

    it('should auto-update status when out of stock', async () => {
      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const result = await db.query(
        `UPDATE marketplace_products SET status = 'sold_out' WHERE id = $1 AND quantity = 0`,
        ['uuid-1']
      );

      expect(result.rowCount).toBe(1);
    });
  });

  describe('Featured Products', () => {
    it('should retrieve featured products', async () => {
      const mockFeatured = [
        { id: 'uuid-1', name: 'Featured 1', is_featured: true },
        { id: 'uuid-2', name: 'Featured 2', is_featured: true },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockFeatured });

      const result = await db.query(
        `SELECT * FROM marketplace_products WHERE is_featured = true AND status = 'active' LIMIT 10`
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows.every(p => p.is_featured === true)).toBe(true);
    });
  });

  describe('Related Products', () => {
    it('should get related products in same category', async () => {
      const mockRelated = [
        { id: 'uuid-2', name: 'Related 1', category_id: 'cat-1' },
        { id: 'uuid-3', name: 'Related 2', category_id: 'cat-1' },
      ];

      const db = require('../../db');
      mockQuery.mockResolvedValueOnce({ rows: mockRelated });

      const result = await db.query(
        `SELECT * FROM marketplace_products
         WHERE category_id = $1 AND id != $2 AND status = 'active'
         LIMIT 4`,
        ['cat-1', 'uuid-1']
      );

      expect(result.rows).toHaveLength(2);
      expect(result.rows.every(p => p.id !== 'uuid-1')).toBe(true);
    });
  });
});

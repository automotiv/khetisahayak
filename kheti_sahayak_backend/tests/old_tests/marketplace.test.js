const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const marketplaceRoutes = require('../routes/marketplace');
const { errorHandler } = require('../middleware/errorMiddleware');
const db = require('../db');

// Tell Jest to use the mock for the '../db' module
jest.mock('../db');

// Set up a minimal express app for testing
const app = express();
app.use(express.json());
app.use('/api/marketplace', marketplaceRoutes);
app.use(errorHandler);

let testUser;
let testToken;

describe('Marketplace Routes', () => {
  beforeEach(async () => {
    db.__reset();
    // Create a user to act as the seller for protected routes
    const hashedPassword = 'somehashedpassword'; // We don't need to check it, just have it.
    const userResult = await db.query(
      'INSERT INTO users (username, email, password_hash, role) VALUES ($1, $2, $3, $4) RETURNING *',
      ['seller', 'seller@example.com', hashedPassword, 'user']
    );
    testUser = userResult.rows[0];
    // Create a valid JWT for this user
    testToken = jwt.sign({ id: testUser.id, role: testUser.role }, process.env.JWT_SECRET, { expiresIn: '1h' });
  });

  describe('GET /api/marketplace', () => {
    it('should return an empty array when no products exist', async () => {
      const res = await request(app).get('/api/marketplace');
      expect(res.statusCode).toEqual(200);
      expect(res.body).toEqual([]);
    });

    it('should return all products', async () => {
      // Add a product first
      await db.query(
        'INSERT INTO products (name, description, price, seller_id) VALUES ($1, $2, $3, $4)',
        ['Test Tomato', 'Fresh and red', 2.50, testUser.id]
      );

      const res = await request(app).get('/api/marketplace');
      expect(res.statusCode).toEqual(200);
      expect(res.body.length).toBe(1);
      expect(res.body[0].name).toBe('Test Tomato');
    });
  });

  describe('POST /api/marketplace', () => {
    const newProductData = {
      name: 'Organic Carrots',
      description: 'Sweet and crunchy',
      price: 3.00,
      category: 'Vegetables',
    };

    it('should return 401 if no token is provided', async () => {
      const res = await request(app)
        .post('/api/marketplace')
        .send(newProductData);
      
      expect(res.statusCode).toEqual(401);
      expect(res.body.error).toBe('Not authorized, no token');
    });

    it('should create a new product if a valid token is provided', async () => {
      const res = await request(app)
        .post('/api/marketplace')
        .set('Authorization', `Bearer ${testToken}`)
        .send(newProductData);

      expect(res.statusCode).toEqual(201);
      expect(res.body.message).toBe('Product added successfully');
      expect(res.body.product).toHaveProperty('id');
      expect(res.body.product.name).toBe(newProductData.name);
      expect(res.body.product.seller_id).toBe(testUser.id);
    });

    it('should return 400 if required fields are missing', async () => {
        const res = await request(app)
          .post('/api/marketplace')
          .set('Authorization', `Bearer ${testToken}`)
          .send({ description: 'Just a description' }); // Missing name and price
  
        expect(res.statusCode).toEqual(400);
        expect(res.body.error).toBe('Product name and price are required');
      });
  });

  describe('GET /api/marketplace/:id', () => {
    let product;

    beforeEach(async () => {
      // Add a product first to be fetched
      const productResult = await db.query(
        'INSERT INTO products (name, description, price, seller_id) VALUES ($1, $2, $3, $4) RETURNING *',
        ['Test Tomato', 'Fresh and red', 2.50, testUser.id]
      );
      product = productResult.rows[0];
    });

    it('should return a single product if found', async () => {
      const res = await request(app).get(`/api/marketplace/${product.id}`);

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('id', product.id);
      expect(res.body.name).toBe('Test Tomato');
    });

    it('should return 404 if product is not found', async () => {
      const nonExistentId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479'; // A valid but non-existent UUID
      const res = await request(app).get(`/api/marketplace/${nonExistentId}`);

      expect(res.statusCode).toEqual(404);
      expect(res.body.error).toBe('Product not found');
    });
  });
});
const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const educationalContentRoutes = require('../routes/educationalContent');
const { errorHandler } = require('../middleware/errorMiddleware');
const db = require('../db');

// Mock dependencies
jest.mock('../db');

// Set up a minimal express app for testing
const app = express();
app.use(express.json());
app.use('/api/educational-content', educationalContentRoutes);
app.use(errorHandler);

let adminUser, contentCreatorUser, regularUser;
let adminToken, contentCreatorToken, regularUserToken;

const createTestUser = async (username, email, role) => {
  const hashedPassword = 'somehashedpassword';
  const { rows } = await db.query(
    'INSERT INTO users (username, email, password_hash, role) VALUES ($1, $2, $3, $4) RETURNING *',
    [username, email, hashedPassword, role]
  );
  const user = rows[0];
  const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET);
  return { user, token };
};

describe('Educational Content Routes', () => {
  beforeEach(async () => {
    db.__reset();
    // Create users with different roles
    ({ user: adminUser, token: adminToken } = await createTestUser('admin', 'admin@example.com', 'admin'));
    ({ user: contentCreatorUser, token: contentCreatorToken } = await createTestUser('creator', 'creator@example.com', 'content-creator'));
    ({ user: regularUser, token: regularUserToken } = await createTestUser('user', 'user@example.com', 'user'));
  });

  describe('GET /api/educational-content', () => {
    it('should return all educational content', async () => {
      // Seed some content
      await db.query(
        'INSERT INTO educational_content (title, content, author_id) VALUES ($1, $2, $3)',
        ['Farming 101', 'Content about farming.', adminUser.id]
      );

      const res = await request(app).get('/api/educational-content');

      expect(res.statusCode).toEqual(200);
      expect(res.body.length).toBe(1);
      expect(res.body[0].title).toBe('Farming 101');
    });
  });

  describe('GET /api/educational-content/:id', () => {
    it('should return a single content item if found', async () => {
      const { rows } = await db.query(
        'INSERT INTO educational_content (title, content, author_id) VALUES ($1, $2, $3) RETURNING *',
        ['Farming 101', 'Content about farming.', adminUser.id]
      );
      const contentId = rows[0].id;

      const res = await request(app).get(`/api/educational-content/${contentId}`);

      expect(res.statusCode).toEqual(200);
      expect(res.body.id).toBe(contentId);
    });

    it('should return 404 if content not found', async () => {
      const nonExistentId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
      const res = await request(app).get(`/api/educational-content/${nonExistentId}`);
      expect(res.statusCode).toEqual(404);
    });
  });

  describe('POST /api/educational-content', () => {
    const newContentData = {
      title: 'Advanced Pest Control',
      content: 'Here is how to control pests...',
      category: 'Pests',
    };

    it('should return 401 if no token is provided', async () => {
      const res = await request(app)
        .post('/api/educational-content')
        .send(newContentData);
      expect(res.statusCode).toEqual(401);
    });

    it('should return 403 if user has an invalid role (user)', async () => {
      const res = await request(app)
        .post('/api/educational-content')
        .set('Authorization', `Bearer ${regularUserToken}`)
        .send(newContentData);
      expect(res.statusCode).toEqual(403);
      expect(res.body.error).toContain('Forbidden');
    });

    it('should create content if user has a valid role (content-creator)', async () => {
      const res = await request(app)
        .post('/api/educational-content')
        .set('Authorization', `Bearer ${contentCreatorToken}`)
        .send(newContentData);

      expect(res.statusCode).toEqual(201);
      expect(res.body.message).toBe('Educational content added successfully');
      expect(res.body.content.author_id).toBe(contentCreatorUser.id);
    });

    it('should create content if user has a valid role (admin)', async () => {
      const res = await request(app)
        .post('/api/educational-content')
        .set('Authorization', `Bearer ${adminToken}`)
        .send(newContentData);

      expect(res.statusCode).toEqual(201);
      expect(res.body.content.author_id).toBe(adminUser.id);
    });

    it('should return 400 if required fields are missing', async () => {
      const res = await request(app)
        .post('/api/educational-content')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ category: 'Incomplete' }); // Missing title and content

      expect(res.statusCode).toEqual(400);
      expect(res.body.error).toBe('Title and content are required');
    });
  });
});
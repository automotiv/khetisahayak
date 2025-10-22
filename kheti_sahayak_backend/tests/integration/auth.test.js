const request = require('supertest');
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Mock db with query function
const mockQuery = jest.fn();
jest.mock('../../db', () => ({
  query: mockQuery
}));

jest.mock('../../s3', () => ({
  uploadFileToS3: jest.fn(() => Promise.resolve('https://s3.amazonaws.com/test-bucket/profile-image.jpg'))
}));

const db = require('../../db');

// Create Express app for testing
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Import routes
const authRoutes = require('../../routes/auth');
app.use('/api/auth', authRoutes);

// Error handler
app.use((err, req, res, next) => {
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error'
  });
});

describe('Authentication API Integration Tests', () => {
  let authToken;
  let adminToken;
  const testUserId = 1;
  const adminUserId = 2;

  beforeAll(() => {
    const secret = process.env.JWT_SECRET || 'test-secret';
    authToken = jwt.sign({ id: testUserId, email: 'test@example.com', role: 'farmer' }, secret, { expiresIn: '1h' });
    adminToken = jwt.sign({ id: adminUserId, email: 'admin@example.com', role: 'admin' }, secret, { expiresIn: '1h' });
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user successfully', async () => {
      const hashedPassword = await bcrypt.hash('Test@123', 10);
      const mockUser = {
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        first_name: 'Test',
        last_name: 'User',
        role: 'farmer',
        created_at: new Date()
      };

      // Mock email check (no existing user)
      db.query
        .mockResolvedValueOnce({ rows: [] })
        // Mock user insertion
        .mockResolvedValueOnce({ rows: [{ ...mockUser, password: hashedPassword }] });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'testuser',
          email: 'test@example.com',
          password: 'Test@123',
          first_name: 'Test',
          last_name: 'User',
          phone: '+1234567890',
          location_lat: 40.7128,
          location_lng: -74.0060
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.user).toBeDefined();
      expect(response.body.token).toBeDefined();
      expect(response.body.user.email).toBe('test@example.com');
    });

    it('should return 400 when email is invalid', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'testuser',
          email: 'invalid-email',
          password: 'Test@123',
          first_name: 'Test',
          last_name: 'User'
        });

      expect(response.status).toBe(400);
    });

    it('should return 400 when password is too short', async () => {
      db.query.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'testuser',
          email: 'test@example.com',
          password: '123',
          first_name: 'Test',
          last_name: 'User'
        });

      expect(response.status).toBe(400);
    });

    it('should return 400 when email already exists', async () => {
      // Mock existing user
      db.query.mockResolvedValueOnce({
        rows: [{ id: 1, email: 'test@example.com' }]
      });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'testuser',
          email: 'test@example.com',
          password: 'Test@123',
          first_name: 'Test',
          last_name: 'User'
        });

      expect(response.status).toBe(400);
    });

    it('should return 400 when required fields are missing', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'test@example.com',
          password: 'Test@123'
        });

      expect(response.status).toBe(400);
    });

    it('should validate phone number format', async () => {
      db.query.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'testuser',
          email: 'test@example.com',
          password: 'Test@123',
          first_name: 'Test',
          last_name: 'User',
          phone: 'invalid-phone'
        });

      expect(response.status).toBe(400);
    });

    it('should validate location coordinates', async () => {
      db.query.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'testuser',
          email: 'test@example.com',
          password: 'Test@123',
          first_name: 'Test',
          last_name: 'User',
          location_lat: 200, // Invalid latitude
          location_lng: -74.0060
        });

      expect(response.status).toBe(400);
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login user successfully', async () => {
      const hashedPassword = await bcrypt.hash('Test@123', 10);
      const mockUser = {
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        password: hashedPassword,
        first_name: 'Test',
        last_name: 'User',
        role: 'farmer'
      };

      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'Test@123'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.token).toBeDefined();
      expect(response.body.user).toBeDefined();
      expect(response.body.user.email).toBe('test@example.com');
    });

    it('should return 401 with invalid email', async () => {
      db.query.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'Test@123'
        });

      expect(response.status).toBe(401);
    });

    it('should return 401 with incorrect password', async () => {
      const hashedPassword = await bcrypt.hash('Test@123', 10);
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        password: hashedPassword
      };

      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'WrongPassword'
        });

      expect(response.status).toBe(401);
    });

    it('should return 400 when email is missing', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          password: 'Test@123'
        });

      expect(response.status).toBe(400);
    });

    it('should return 400 when password is missing', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com'
        });

      expect(response.status).toBe(400);
    });

    it('should return 400 with invalid email format', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'invalid-email',
          password: 'Test@123'
        });

      expect(response.status).toBe(400);
    });
  });

  describe('GET /api/auth/profile', () => {
    it('should get user profile successfully', async () => {
      const mockUser = {
        id: testUserId,
        username: 'testuser',
        email: 'test@example.com',
        first_name: 'Test',
        last_name: 'User',
        role: 'farmer',
        phone: '+1234567890',
        location_lat: 40.7128,
        location_lng: -74.0060
      };

      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.user).toBeDefined();
      expect(response.body.user.email).toBe('test@example.com');
    });

    it('should return 401 without authentication token', async () => {
      const response = await request(app)
        .get('/api/auth/profile');

      expect(response.status).toBe(401);
    });

    it('should return 401 with invalid token', async () => {
      const response = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', 'Bearer invalid-token');

      expect(response.status).toBe(401);
    });
  });

  describe('PUT /api/auth/profile', () => {
    it('should update user profile successfully', async () => {
      const mockUser = {
        id: testUserId,
        username: 'testuser',
        email: 'test@example.com',
        first_name: 'Updated',
        last_name: 'Name',
        role: 'farmer'
      };

      db.query
        .mockResolvedValueOnce({ rows: [mockUser] })
        .mockResolvedValueOnce({ rows: [{ ...mockUser, first_name: 'Updated', last_name: 'Name' }] });

      const response = await request(app)
        .put('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          first_name: 'Updated',
          last_name: 'Name',
          phone: '+9876543210'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.user.first_name).toBe('Updated');
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app)
        .put('/api/auth/profile')
        .send({
          first_name: 'Updated'
        });

      expect(response.status).toBe(401);
    });

    it('should return 400 with invalid phone number', async () => {
      const mockUser = { id: testUserId, email: 'test@example.com' };
      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .put('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          phone: 'invalid-phone'
        });

      expect(response.status).toBe(400);
    });

    it('should return 400 with invalid coordinates', async () => {
      const mockUser = { id: testUserId, email: 'test@example.com' };
      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .put('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          location_lat: 200 // Invalid
        });

      expect(response.status).toBe(400);
    });
  });

  describe('POST /api/auth/profile-image', () => {
    it('should upload profile image successfully', async () => {
      const mockUser = { id: testUserId, email: 'test@example.com' };
      const mockUpdatedUser = {
        ...mockUser,
        profile_image: 'https://s3.amazonaws.com/test-bucket/profile-image.jpg'
      };

      db.query
        .mockResolvedValueOnce({ rows: [mockUser] })
        .mockResolvedValueOnce({ rows: [mockUpdatedUser] });

      const response = await request(app)
        .post('/api/auth/profile-image')
        .set('Authorization', `Bearer ${authToken}`)
        .attach('image', Buffer.from('fake-image-data'), 'profile.jpg');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.user.profile_image).toBeDefined();
    });

    it('should return 400 when no image is provided', async () => {
      const mockUser = { id: testUserId, email: 'test@example.com' };
      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .post('/api/auth/profile-image')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(400);
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app)
        .post('/api/auth/profile-image')
        .attach('image', Buffer.from('fake-image-data'), 'profile.jpg');

      expect(response.status).toBe(401);
    });
  });

  describe('PUT /api/auth/change-password', () => {
    it('should change password successfully', async () => {
      const currentPasswordHash = await bcrypt.hash('OldPass@123', 10);
      const mockUser = {
        id: testUserId,
        email: 'test@example.com',
        password: currentPasswordHash
      };

      db.query
        .mockResolvedValueOnce({ rows: [mockUser] })
        .mockResolvedValueOnce({ rows: [mockUser] })
        .mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .put('/api/auth/change-password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          current_password: 'OldPass@123',
          new_password: 'NewPass@123'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    it('should return 401 with incorrect current password', async () => {
      const currentPasswordHash = await bcrypt.hash('OldPass@123', 10);
      const mockUser = {
        id: testUserId,
        email: 'test@example.com',
        password: currentPasswordHash
      };

      db.query
        .mockResolvedValueOnce({ rows: [mockUser] })
        .mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .put('/api/auth/change-password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          current_password: 'WrongPassword',
          new_password: 'NewPass@123'
        });

      expect(response.status).toBe(401);
    });

    it('should return 400 when new password is too short', async () => {
      const mockUser = { id: testUserId, email: 'test@example.com' };
      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .put('/api/auth/change-password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          current_password: 'OldPass@123',
          new_password: '123'
        });

      expect(response.status).toBe(400);
    });

    it('should return 400 when current_password is missing', async () => {
      const mockUser = { id: testUserId, email: 'test@example.com' };
      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .put('/api/auth/change-password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          new_password: 'NewPass@123'
        });

      expect(response.status).toBe(400);
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app)
        .put('/api/auth/change-password')
        .send({
          current_password: 'OldPass@123',
          new_password: 'NewPass@123'
        });

      expect(response.status).toBe(401);
    });
  });

  describe('POST /api/auth/logout', () => {
    it('should logout user successfully', async () => {
      const mockUser = { id: testUserId, email: 'test@example.com' };
      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app)
        .post('/api/auth/logout');

      expect(response.status).toBe(401);
    });
  });

  describe('GET /api/auth/users (Admin)', () => {
    it('should get all users as admin', async () => {
      const mockUsers = [
        { id: 1, email: 'user1@example.com', role: 'farmer' },
        { id: 2, email: 'user2@example.com', role: 'farmer' }
      ];

      const mockAdminUser = { id: adminUserId, email: 'admin@example.com', role: 'admin' };

      db.query
        .mockResolvedValueOnce({ rows: [mockAdminUser] })
        .mockResolvedValueOnce({ rows: mockUsers });

      const response = await request(app)
        .get('/api/auth/users')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.users).toHaveLength(2);
    });

    it('should return 403 for non-admin user', async () => {
      const mockUser = { id: testUserId, email: 'test@example.com', role: 'farmer' };
      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .get('/api/auth/users')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(403);
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app)
        .get('/api/auth/users');

      expect(response.status).toBe(401);
    });
  });

  describe('DELETE /api/auth/users/:id (Admin)', () => {
    it('should delete user as admin', async () => {
      const mockAdminUser = { id: adminUserId, email: 'admin@example.com', role: 'admin' };
      const mockDeletedUser = { id: 3, email: 'deleted@example.com' };

      db.query
        .mockResolvedValueOnce({ rows: [mockAdminUser] })
        .mockResolvedValueOnce({ rows: [mockDeletedUser] });

      const response = await request(app)
        .delete('/api/auth/users/3')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    it('should return 403 for non-admin user', async () => {
      const mockUser = { id: testUserId, email: 'test@example.com', role: 'farmer' };
      db.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .delete('/api/auth/users/3')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(403);
    });

    it('should return 404 when user not found', async () => {
      const mockAdminUser = { id: adminUserId, email: 'admin@example.com', role: 'admin' };

      db.query
        .mockResolvedValueOnce({ rows: [mockAdminUser] })
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .delete('/api/auth/users/999')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(404);
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app)
        .delete('/api/auth/users/3');

      expect(response.status).toBe(401);
    });
  });
});

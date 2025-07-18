const request = require('supertest');
const { generateTestToken } = require('../utils/auth');
const db = require('../utils/db');

// The base URL of your running application for E2E tests.
// This should point to a local instance for local testing, assuming your server runs on port 3000.
const API_URL = process.env.TEST_API_URL || 'http://localhost:3000/v1';

// These will be populated before tests run.
let USER_TOKEN;
let ADMIN_TOKEN;
let testUser;
let testAdmin;

describe('Notification Service E2E', () => {
  beforeAll(async () => {
    // Create test users in the database before running any tests in this suite.
    // Using Date.now() ensures email uniqueness for each test run.
    testUser = await db.createTestUser({
      email: `farmer-${Date.now()}@example.com`,
      password: 'password123',
      role: 'farmer',
    });
    testAdmin = await db.createTestUser({
      email: `admin-${Date.now()}@example.com`,
      password: 'password123',
      role: 'admin',
    });

    // Generate tokens with the real user IDs from the database.
    USER_TOKEN = generateTestToken({ sub: testUser.id, role: testUser.role });
    ADMIN_TOKEN = generateTestToken({ sub: testAdmin.id, role: testAdmin.role });
  });

  afterAll(async () => {
    // Clean up by deleting the created users and closing the DB connection.
    await db.deleteUserById(testUser.id);
    await db.deleteUserById(testAdmin.id);
    await db.disconnect();
  });

  describe('GET /notifications/settings', () => {
    it('should return 401 Unauthorized if no auth token is provided', async () => {
      const response = await request(API_URL)
        .get('/notifications/settings')
        .expect(401);

      // Check the error response body based on your OpenAPI spec
      expect(response.body.message).toBe('Unauthorized - The request requires user authentication.');
    });

    it('should return 200 OK and settings for an authenticated user', async () => {
      const response = await request(API_URL)
        .get('/notifications/settings')
        .set('Authorization', USER_TOKEN)
        .expect(200)
        .expect('Content-Type', /json/);

      // Verify the response body matches the NotificationSettings schema
      expect(response.body).toHaveProperty('weatherAlerts');
      expect(response.body).toHaveProperty('marketplace');
    });
  });

  describe('POST /notifications/broadcast', () => {
    const broadcastPayload = {
      segment: 'all_farmers',
      type: 'push',
      subject: 'App Update Available',
      message: 'A new version of Kheti Sahayak is available with exciting new features!',
    };

    it('should return 403 Forbidden if the user is not an admin', async () => {
      const response = await request(API_URL)
        .post('/notifications/broadcast')
        .set('Authorization', USER_TOKEN) // Using a non-admin token
        .send(broadcastPayload)
        .expect(403);

      // Check the error response body based on your OpenAPI spec
      expect(response.body.message).toBe('Forbidden - The authenticated user does not have permission to perform this action.');
    });

    it('should return 202 Accepted for a valid request from an admin', async () => {
      const response = await request(API_URL)
        .post('/notifications/broadcast')
        .set('Authorization', ADMIN_TOKEN) // Using an admin token
        .send(broadcastPayload)
        .expect(202)
        .expect('Content-Type', /json/);

      expect(response.body.status).toBe('broadcast_queued');
    });
  });
});
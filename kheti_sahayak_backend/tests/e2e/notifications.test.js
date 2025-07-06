const request = require('supertest');

// The base URL of your running application for E2E tests.
// This should point to a staging or local instance.
const API_URL = process.env.TEST_API_URL || 'https://api.staging.khetisahayak.com/v1';

// In a real test suite, you would generate a valid test token.
// For this example, we'll use placeholders for different user roles.
const MOCK_USER_TOKEN = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0X3VzZXIifQ.fake_signature';

// A token representing a user with admin privileges.
// In a real scenario, the 'role' claim would be validated by your backend.
const MOCK_ADMIN_TOKEN = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0X2FkbWluIiwicm9sZSI6ImFkbWluIn0.fake_admin_signature';

describe('Notification Service E2E', () => {
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
        .set('Authorization', MOCK_USER_TOKEN)
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
        .set('Authorization', MOCK_USER_TOKEN) // Using a non-admin token
        .send(broadcastPayload)
        .expect(403);

      // Check the error response body based on your OpenAPI spec
      expect(response.body.message).toBe('Forbidden - The authenticated user does not have permission to perform this action.');
    });

    it('should return 202 Accepted for a valid request from an admin', async () => {
      const response = await request(API_URL)
        .post('/notifications/broadcast')
        .set('Authorization', MOCK_ADMIN_TOKEN) // Using an admin token
        .send(broadcastPayload)
        .expect(202)
        .expect('Content-Type', /json/);

      expect(response.body.status).toBe('broadcast_queued');
    });
  });
});
const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const diagnosticsRoutes = require('../routes/diagnostics');
const { errorHandler } = require('../middleware/errorMiddleware');
const db = require('../db');
const { uploadFileToS3 } = require('../s3');

// Mock dependencies
jest.mock('../db');
jest.mock('../s3'); // This will use __mocks__/s3.js

// Set up a minimal express app for testing
const app = express();
app.use(express.json());
app.use('/api/diagnostics', diagnosticsRoutes);
app.use(errorHandler);

let testUser;
let testToken;

describe('Diagnostics Routes', () => {
  beforeEach(async () => {
    db.__reset();
    jest.clearAllMocks(); // Clear mocks before each test

    // Create a user to make authenticated requests
    const hashedPassword = 'somehashedpassword';
    const userResult = await db.query(
      'INSERT INTO users (username, email, password_hash, role) VALUES ($1, $2, $3, $4) RETURNING *',
      ['diag_user', 'diag@example.com', hashedPassword, 'user']
    );
    testUser = userResult.rows[0];
    testToken = jwt.sign({ id: testUser.id, role: testUser.role }, process.env.JWT_SECRET);
  });

  describe('POST /api/diagnostics/upload', () => {
    it('should return 401 if no token is provided', async () => {
      const res = await request(app)
        .post('/api/diagnostics/upload')
        .field('crop_type', 'Tomato')
        .field('issue_description', 'Leaves are yellow')
        .attach('image', Buffer.from('fake image data'), 'test.jpg');

      expect(res.statusCode).toEqual(401);
      expect(res.body.error).toBe('Not authorized, no token');
    });

    it('should return 400 if no image is provided', async () => {
      const res = await request(app)
        .post('/api/diagnostics/upload')
        .set('Authorization', `Bearer ${testToken}`)
        .field('crop_type', 'Tomato')
        .field('issue_description', 'Leaves are yellow');

      expect(res.statusCode).toEqual(400);
      expect(res.body.error).toBe('No image file provided');
    });

    it('should return 400 if crop_type is missing', async () => {
      const res = await request(app)
        .post('/api/diagnostics/upload')
        .set('Authorization', `Bearer ${testToken}`)
        .field('issue_description', 'Leaves are yellow')
        .attach('image', Buffer.from('fake image data'), 'test.jpg');

      expect(res.statusCode).toEqual(400);
      expect(res.body.error).toBe('Crop type and issue description are required.');
    });

    it('should upload an image and create a diagnostic record successfully', async () => {
      const res = await request(app)
        .post('/api/diagnostics/upload')
        .set('Authorization', `Bearer ${testToken}`)
        .field('crop_type', 'Tomato')
        .field('issue_description', 'Leaves are yellow')
        .attach('image', Buffer.from('fake image data'), 'tomato.jpg');

      expect(res.statusCode).toEqual(200);
      expect(res.body.message).toBe('Image uploaded and analyzed successfully');
      expect(res.body.diagnosticRecord).toHaveProperty('id');
      expect(res.body.diagnosticRecord.user_id).toBe(testUser.id);
      expect(res.body.diagnosticRecord.image_url).toBe('https://fake-s3-url.com/diagnostics/mock-image.jpg');

      // Verify that the S3 upload function was called
      expect(uploadFileToS3).toHaveBeenCalledTimes(1);

      // Verify that a record was inserted into the database
      const dbResult = await db.query('SELECT * FROM diagnostics WHERE user_id = $1', [testUser.id]);
      expect(dbResult.rows.length).toBe(1);
      expect(dbResult.rows[0].recommendations).toContain('Apply fungicide');
    });
  });
});
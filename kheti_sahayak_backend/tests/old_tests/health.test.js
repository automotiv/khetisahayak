const request = require('supertest');
const express = require('express');
const healthRoutes = require('../routes/health');
const { errorHandler } = require('../middleware/errorMiddleware');
const db = require('../db');
const redisClient = require('../utils/redisClient');

// Mock dependencies
jest.mock('../db');
jest.mock('../utils/redisClient');

// Set up a minimal express app for testing
const app = express();
app.use(express.json());
app.use('/api/health', healthRoutes);
app.use(errorHandler);

describe('Health Check Route', () => {
  beforeEach(() => {
    // Reset mocks before each test
    jest.clearAllMocks();
  });

  it('should return 200 OK when all services are healthy', async () => {
    // Arrange: Mock successful responses from dependencies
    db.query.mockResolvedValue(); // A simple SELECT 1 doesn't need a specific return value
    redisClient.ping.mockResolvedValue('PONG');

    // Act
    const res = await request(app).get('/api/health');

    // Assert
    expect(res.statusCode).toEqual(200);
    expect(res.body.message).toBe('OK');
    expect(res.body.checks).toEqual([
      { name: 'database', status: 'OK' },
      { name: 'redis', status: 'OK' },
    ]);
  });

  it('should return 503 Service Unavailable when the database is down', async () => {
    // Arrange: Mock a database failure
    const dbError = new Error('Database connection failed');
    db.query.mockRejectedValue(dbError);
    redisClient.ping.mockResolvedValue('PONG');

    // Act
    const res = await request(app).get('/api/health');

    // Assert
    expect(res.statusCode).toEqual(503);
    expect(res.body.message).toBe('Service Unavailable');
    expect(res.body.checks[0]).toEqual({ name: 'database', status: 'FAIL', error: 'Database connection failed' });
    expect(res.body.checks[1]).toEqual({ name: 'redis', status: 'OK' });
  });

  it('should return 503 Service Unavailable when Redis is down', async () => {
    // Arrange: Mock a Redis failure
    const redisError = new Error('Redis connection failed');
    db.query.mockResolvedValue();
    redisClient.ping.mockRejectedValue(redisError);

    // Act
    const res = await request(app).get('/api/health');

    // Assert
    expect(res.statusCode).toEqual(503);
    expect(res.body.message).toBe('Service Unavailable');
    expect(res.body.checks[0]).toEqual({ name: 'database', status: 'OK' });
    expect(res.body.checks[1]).toEqual({ name: 'redis', status: 'FAIL', error: 'Redis connection failed' });
  });
});
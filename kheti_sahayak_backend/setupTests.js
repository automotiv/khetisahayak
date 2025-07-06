// This file runs before each test file
const db = require('./__mocks__/db');
const Redis = require('./__mocks__/ioredis');

// Reset database state before each test
beforeEach(() => {
  db.__reset();
  Redis.reset();
});

// Mock environment variables
process.env.JWT_SECRET = 'test-secret';
process.env.JWT_EXPIRES_IN = '1h';
process.env.NODE_ENV = 'test';

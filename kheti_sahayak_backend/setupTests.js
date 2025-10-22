// Setup file for Jest tests
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret-key-for-testing-only';
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/kheti_sahayak_test';
process.env.ML_API_URL = 'http://localhost:8000';

// Mock console methods to reduce test noise
global.console = {
  ...console,
  error: jest.fn(),
  warn: jest.fn(),
};

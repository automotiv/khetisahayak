module.exports = {
  testEnvironment: 'node',
  setupFilesAfterEnv: ['./setupTests.js'],
  testMatch: ['**/tests/**/*.test.js'],
  testPathIgnorePatterns: [
    '/node_modules/',
    '/tests/old_tests/'
  ],
  clearMocks: true,
  resetMocks: true,
  restoreMocks: true,
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
  },
  testTimeout: 10000, // 10 seconds
};

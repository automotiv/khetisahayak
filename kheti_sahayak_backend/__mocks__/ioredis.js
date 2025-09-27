// Mock Redis client for testing
class RedisMock {
  constructor() {
    this.store = new Map();
    this.connected = true;
  }

  async get(key) {
    return this.store.get(key) || null;
  }

  async set(key, value) {
    this.store.set(key, value);
    return 'OK';
  }

  async del(key) {
    const existed = this.store.has(key);
    this.store.delete(key);
    return existed ? 1 : 0;
  }

  async expire(key, seconds) {
    if (!this.store.has(key)) return 0;
    // In a real implementation, we would set a timeout here
    return 1;
  }

  async disconnect() {
    this.connected = false;
    return 'OK';
  }

  // Add any other Redis methods your application uses
}

// Create a single instance for all tests
const redisMock = new RedisMock();

// Mock the Redis constructor to return our mock instance
const Redis = jest.fn().mockImplementation(() => redisMock);

// Add reset method for tests
Redis.reset = () => {
  redisMock.store.clear();
  redisMock.connected = true;
};

module.exports = Redis;

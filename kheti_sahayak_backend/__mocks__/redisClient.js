// Mock Redis client for testing
class RedisClient {
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
const redisClient = new RedisClient();

// Add reset method for tests
redisClient.reset = () => {
  redisClient.store.clear();
  redisClient.connected = true;
};

module.exports = redisClient;

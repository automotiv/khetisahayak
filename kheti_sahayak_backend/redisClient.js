const Redis = require('ioredis');

// Create a mock Redis client for development when Redis is not available
class MockRedisClient {
  constructor() {
    this.store = new Map();
    console.log('Using mock Redis client');
  }

  async get(key) {
    return this.store.get(key);
  }

  async set(key, value, ...args) {
    this.store.set(key, value);
    return 'OK';
  }

  async setex(key, seconds, value) {
    this.store.set(key, value);
    // In a real implementation, you'd set a timeout to delete after 'seconds'
    // For mock purposes, we'll just store it
    setTimeout(() => {
      this.store.delete(key);
    }, seconds * 1000);
    return 'OK';
  }

  async del(key) {
    this.store.delete(key);
    return 1;
  }

  async expire(key, seconds) {
    return 1;
  }

  on(event, callback) {
    // Mock event handling
    if (event === 'connect') {
      callback();
    }
    return this;
  }
}

let redisClient;

try {
  // Try to connect to Redis if host and port are provided
  // Try to connect to Redis if URL or host/port are provided
  if (process.env.REDIS_URL) {
    redisClient = new Redis(process.env.REDIS_URL, {
      lazyConnect: true,
      connectTimeout: 2000,
      maxRetriesPerRequest: 1,
    });
  } else if (process.env.REDIS_HOST && process.env.REDIS_PORT) {
    redisClient = new Redis({
      host: process.env.REDIS_HOST,
      port: process.env.REDIS_PORT,
      lazyConnect: true,
      connectTimeout: 2000, // 2 seconds timeout
      maxRetriesPerRequest: 1,
    });

    redisClient.on('connect', () => console.log('Connected to Redis!'));
    redisClient.on('error', (err) => {
      console.error('Redis Client Error', err);
      // Fall back to mock client on connection error
      if (!redisClient.mockFallback) {
        console.log('Falling back to mock Redis client');
        redisClient = new MockRedisClient();
        redisClient.mockFallback = true;
      }
    });
  } else {
    // Use mock client if Redis connection details are not provided
    redisClient = new MockRedisClient();
  }
} catch (error) {
  console.error('Failed to initialize Redis client:', error);
  // Fall back to mock client
  redisClient = new MockRedisClient();
}

module.exports = redisClient;
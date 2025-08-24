/**
 * Configuration settings for the application
 */
module.exports = {
  // ML service configuration
  ml: {
    apiUrl: process.env.ML_API_URL || 'http://ml-inference:8000',
    timeout: 30000, // 30 seconds
  },
  
  // Database configuration
  db: {
    host: process.env.DB_HOST || 'postgres',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'postgres',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
  },
  
  // Server configuration
  server: {
    port: process.env.PORT || 5001,
    env: process.env.NODE_ENV || 'development',
  },
};
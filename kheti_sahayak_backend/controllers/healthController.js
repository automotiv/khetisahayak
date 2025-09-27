const asyncHandler = require('express-async-handler');
const db = require('../db');
const redisClient = require('../utils/redisClient');

// @desc    Check application and services health
// @route   GET /api/health
// @access  Public
const checkHealth = asyncHandler(async (req, res) => {
  const checks = [];
  let isHealthy = true;

  // Check Database connection
  try {
    await db.query('SELECT 1');
    checks.push({ name: 'database', status: 'OK' });
  } catch (error) {
    isHealthy = false;
    checks.push({ name: 'database', status: 'FAIL', error: error.message });
  }

  // Check Redis connection
  try {
    await redisClient.ping();
    checks.push({ name: 'redis', status: 'OK' });
  } catch (error) {
    isHealthy = false;
    checks.push({ name: 'redis', status: 'FAIL', error: error.message });
  }

  const healthcheck = {
    uptime: process.uptime(),
    message: isHealthy ? 'OK' : 'Service Unavailable',
    timestamp: Date.now(),
    checks,
  };

  res.status(isHealthy ? 200 : 503).json(healthcheck);
});

module.exports = {
  checkHealth,
};
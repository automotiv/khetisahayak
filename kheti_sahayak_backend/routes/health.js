const express = require('express');
const router = express.Router();

/**
 * @route   GET /api/health
 * @desc    Health check endpoint
 * @access  Public
 */
const db = require('../db');

router.get('/', async (req, res) => {
  try {
    await db.query('SELECT NOW()');
    res.status(200).json({
      status: 'ok',
      message: 'Server is running and DB is connected',
      timestamp: new Date().toISOString(),
      db_status: 'connected'
    });
  } catch (error) {
    console.error('Health check DB error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Server is running but DB connection failed',
      timestamp: new Date().toISOString(),
      db_status: 'disconnected',
      error: error.message
    });
  }
});

module.exports = router;

const { validationResult } = require('express-validator');
const logger = require('../utils/logger');

/**
 * Middleware to handle validation errors from express-validator
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    // Log validation errors for monitoring
    logger.warn('Validation errors:', {
      url: req.originalUrl,
      method: req.method,
      errors: errors.array(),
      body: req.body,
      userId: req.user?.id || 'anonymous'
    });

    // Format errors for client response
    const formattedErrors = errors.array().map(error => ({
      field: error.path || error.param,
      message: error.msg,
      value: error.value,
      location: error.location
    }));

    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      code: 'VALIDATION_ERROR',
      details: formattedErrors,
      timestamp: new Date().toISOString()
    });
  }
  
  next();
};

/**
 * Sanitize request body to prevent XSS and other attacks
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
const sanitizeInput = (req, res, next) => {
  // Remove any potential script tags or dangerous HTML
  const sanitizeValue = (value) => {
    if (typeof value === 'string') {
      return value
        .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
        .replace(/javascript:/gi, '')
        .replace(/on\w+\s*=/gi, '')
        .trim();
    }
    return value;
  };

  const sanitizeObject = (obj) => {
    if (typeof obj !== 'object' || obj === null) {
      return sanitizeValue(obj);
    }

    if (Array.isArray(obj)) {
      return obj.map(sanitizeObject);
    }

    const sanitized = {};
    for (const [key, value] of Object.entries(obj)) {
      sanitized[key] = sanitizeObject(value);
    }
    return sanitized;
  };

  if (req.body) {
    req.body = sanitizeObject(req.body);
  }

  if (req.query) {
    req.query = sanitizeObject(req.query);
  }

  if (req.params) {
    req.params = sanitizeObject(req.params);
  }

  next();
};

/**
 * Rate limiting middleware to prevent abuse
 * Simple in-memory implementation - should use Redis in production
 */
const rateLimitStore = new Map();

const rateLimit = (options = {}) => {
  const {
    windowMs = 15 * 60 * 1000, // 15 minutes
    maxRequests = 100,
    message = 'Too many requests, please try again later',
    keyGenerator = (req) => req.ip
  } = options;

  return (req, res, next) => {
    const key = keyGenerator(req);
    const now = Date.now();
    const windowStart = now - windowMs;

    // Clean up old entries
    if (rateLimitStore.has(key)) {
      const requests = rateLimitStore.get(key).filter(time => time > windowStart);
      rateLimitStore.set(key, requests);
    } else {
      rateLimitStore.set(key, []);
    }

    const requests = rateLimitStore.get(key);
    
    if (requests.length >= maxRequests) {
      logger.warn('Rate limit exceeded:', {
        ip: req.ip,
        url: req.originalUrl,
        userAgent: req.get('User-Agent'),
        requestCount: requests.length
      });

      return res.status(429).json({
        success: false,
        error: message,
        code: 'RATE_LIMIT_EXCEEDED',
        retryAfter: Math.ceil(windowMs / 1000),
        timestamp: new Date().toISOString()
      });
    }

    requests.push(now);
    rateLimitStore.set(key, requests);
    next();
  };
};

module.exports = {
  handleValidationErrors,
  sanitizeInput,
  rateLimit
};

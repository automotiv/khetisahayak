const logger = require('../utils/logger');

// Handles requests to routes that don't exist (404)
const notFound = (req, res, next) => {
  const error = new Error(`Not Found - ${req.originalUrl}`);
  error.status = 404;
  res.status(404);
  next(error);
};

// A catch-all for errors passed via next(error)
const errorHandler = (err, req, res, next) => {
  // Log the error for debugging purposes
  const statusCode = err.status || res.statusCode === 200 ? 500 : res.statusCode;
  
  // Create structured error log
  const errorLog = {
    statusCode,
    message: err.message,
    url: req.originalUrl,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    userId: req.user?.id || 'anonymous',
    timestamp: new Date().toISOString(),
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
  };
  
  logger.error('Request error:', errorLog);

  // Determine error type and provide appropriate response
  let errorResponse = {
    success: false,
    error: err.message,
    code: err.code || 'INTERNAL_ERROR',
    timestamp: new Date().toISOString()
  };

  // Add stack trace in development
  if (process.env.NODE_ENV !== 'production') {
    errorResponse.stack = err.stack;
  }

  // Handle specific error types
  if (err.name === 'ValidationError') {
    errorResponse.code = 'VALIDATION_ERROR';
    errorResponse.details = err.details || [];
  } else if (err.name === 'CastError') {
    errorResponse.code = 'INVALID_ID';
    errorResponse.error = 'Invalid resource ID';
  } else if (err.code === 11000) {
    errorResponse.code = 'DUPLICATE_ENTRY';
    errorResponse.error = 'Duplicate entry detected';
  }

  res.status(statusCode).json(errorResponse);
};

module.exports = { notFound, errorHandler };
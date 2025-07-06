const logger = require('../utils/logger');

// Handles requests to routes that don't exist (404)
const notFound = (req, res, next) => {
  const error = new Error(`Not Found - ${req.originalUrl}`);
  res.status(404);
  next(error);
};

// A catch-all for errors passed via next(error)
const errorHandler = (err, req, res, next) => {
  // Log the error for debugging purposes
  logger.error(`${err.status || 500} - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);

  // If the status code is still 200, it's likely an unhandled error, so set it to 500
  const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  res.status(statusCode);
  res.json({
    error: err.message,
    // Only show the stack trace in development for security reasons
    stack: process.env.NODE_ENV === 'production' ? null : err.stack,
  });
};

module.exports = { notFound, errorHandler };
const logger = require('../utils/logger');
const { validationResult } = require('express-validator');

/**
 * Middleware to validate request using express-validator
 * Should be used after validation rules
 */
const validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    logger.warn(`Validation error for ${req.method} ${req.originalUrl}: ${JSON.stringify(errors.array())}`);
    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      errors: errors.array().map(err => ({
        field: err.param || err.path,
        message: err.msg,
        value: err.value
      }))
    });
  }
  next();
};

/**
 * Handles requests to routes that don't exist (404)
 */
const notFound = (req, res, next) => {
  const error = new Error(`Route not found - ${req.method} ${req.originalUrl}`);
  res.status(404);
  next(error);
};

/**
 * Handles database-specific errors
 */
const handleDatabaseError = (err) => {
  // PostgreSQL error codes
  const pgErrors = {
    '23505': { status: 409, message: 'Duplicate entry. This record already exists.' },
    '23503': { status: 400, message: 'Referenced record not found.' },
    '23502': { status: 400, message: 'Required field is missing.' },
    '22P02': { status: 400, message: 'Invalid data type provided.' },
    '42P01': { status: 500, message: 'Database table does not exist.' },
    '42703': { status: 500, message: 'Database column does not exist.' },
    '28P01': { status: 500, message: 'Database authentication failed.' },
    '08006': { status: 500, message: 'Database connection failed.' }
  };

  if (err.code && pgErrors[err.code]) {
    return pgErrors[err.code];
  }

  // Handle other database errors
  if (err.name === 'SequelizeValidationError' || err.name === 'ValidationError') {
    return {
      status: 400,
      message: 'Validation error',
      details: err.errors ? err.errors.map(e => e.message) : []
    };
  }

  return null;
};

/**
 * Handles JWT-specific errors
 */
const handleJWTError = (err) => {
  if (err.name === 'JsonWebTokenError') {
    return { status: 401, message: 'Invalid token. Please log in again.' };
  }
  if (err.name === 'TokenExpiredError') {
    return { status: 401, message: 'Token expired. Please log in again.' };
  }
  return null;
};

/**
 * Handles Multer file upload errors
 */
const handleMulterError = (err) => {
  if (err.name === 'MulterError') {
    const multerErrors = {
      'LIMIT_FILE_SIZE': 'File size too large. Maximum size is 10MB.',
      'LIMIT_FILE_COUNT': 'Too many files uploaded.',
      'LIMIT_UNEXPECTED_FILE': 'Unexpected file field.',
      'LIMIT_FIELD_KEY': 'Field name too long.',
      'LIMIT_FIELD_VALUE': 'Field value too long.',
      'LIMIT_FIELD_COUNT': 'Too many fields.',
      'LIMIT_PART_COUNT': 'Too many parts in multipart upload.'
    };
    return {
      status: 400,
      message: multerErrors[err.code] || 'File upload error.'
    };
  }
  return null;
};

/**
 * Comprehensive error handler middleware
 * Handles all types of errors and returns appropriate responses
 */
const errorHandler = (err, req, res, next) => {
  let statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  let message = err.message || 'Internal server error';
  let errorType = 'ServerError';
  let details = null;

  // Handle database errors
  const dbError = handleDatabaseError(err);
  if (dbError) {
    statusCode = dbError.status;
    message = dbError.message;
    details = dbError.details;
    errorType = 'DatabaseError';
  }

  // Handle JWT errors
  const jwtError = handleJWTError(err);
  if (jwtError) {
    statusCode = jwtError.status;
    message = jwtError.message;
    errorType = 'AuthenticationError';
  }

  // Handle Multer errors
  const multerError = handleMulterError(err);
  if (multerError) {
    statusCode = multerError.status;
    message = multerError.message;
    errorType = 'FileUploadError';
  }

  // Handle Axios errors (external API calls)
  if (err.isAxiosError) {
    statusCode = err.response?.status || 500;
    message = err.response?.data?.message || 'External service error';
    errorType = 'ExternalServiceError';
  }

  // Handle validation errors from express-validator (if not caught by validateRequest)
  if (err.array && typeof err.array === 'function') {
    statusCode = 400;
    message = 'Validation failed';
    details = err.array();
    errorType = 'ValidationError';
  }

  // Handle syntax errors in JSON
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    statusCode = 400;
    message = 'Invalid JSON in request body';
    errorType = 'SyntaxError';
  }

  // Log the error
  const logMessage = `${statusCode} - ${errorType} - ${message} - ${req.method} ${req.originalUrl} - IP: ${req.ip}`;

  if (statusCode >= 500) {
    logger.error(logMessage, {
      error: err.message,
      stack: err.stack,
      user: req.user?.id,
      body: req.body,
      params: req.params,
      query: req.query
    });
  } else if (statusCode >= 400) {
    logger.warn(logMessage, {
      error: err.message,
      user: req.user?.id
    });
  }

  // Send error response
  const errorResponse = {
    success: false,
    error: message,
    type: errorType
  };

  // Add details if available
  if (details) {
    errorResponse.details = details;
  }

  // Add error code if available
  if (err.code) {
    errorResponse.code = err.code;
  }

  // Only show stack trace in development
  if (process.env.NODE_ENV !== 'production') {
    errorResponse.stack = err.stack;
    errorResponse.path = req.originalUrl;
    errorResponse.method = req.method;
  }

  res.status(statusCode).json(errorResponse);
};

/**
 * Async error handler wrapper
 * Wraps async route handlers to catch errors automatically
 * Usage: router.get('/route', asyncHandler(async (req, res) => { ... }))
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

/**
 * Request timeout middleware
 * Terminates requests that take too long
 */
const requestTimeout = (timeout = 30000) => {
  return (req, res, next) => {
    req.setTimeout(timeout, () => {
      const err = new Error('Request timeout');
      err.status = 408;
      next(err);
    });
    next();
  };
};

/**
 * Custom error classes for specific error types
 */
class AppError extends Error {
  constructor(message, statusCode = 500) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationError extends AppError {
  constructor(message) {
    super(message, 400);
    this.name = 'ValidationError';
  }
}

class AuthenticationError extends AppError {
  constructor(message = 'Authentication failed') {
    super(message, 401);
    this.name = 'AuthenticationError';
  }
}

class AuthorizationError extends AppError {
  constructor(message = 'Access denied') {
    super(message, 403);
    this.name = 'AuthorizationError';
  }
}

class NotFoundError extends AppError {
  constructor(message = 'Resource not found') {
    super(message, 404);
    this.name = 'NotFoundError';
  }
}

class ConflictError extends AppError {
  constructor(message = 'Resource conflict') {
    super(message, 409);
    this.name = 'ConflictError';
  }
}

module.exports = {
  notFound,
  errorHandler,
  validateRequest,
  asyncHandler,
  requestTimeout,
  // Error classes
  AppError,
  ValidationError,
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
  ConflictError
};
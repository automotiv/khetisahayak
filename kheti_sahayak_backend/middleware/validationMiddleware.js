/**
 * Comprehensive Input Validation Middleware
 * 
 * Provides reusable validation chains and validators using express-validator
 * for consistent input validation across all API routes.
 * 
 * @module middleware/validationMiddleware
 */

const { body, param, query, validationResult } = require('express-validator');
const logger = require('../utils/logger');

// ============================================================
// VALIDATION RESULT HANDLER
// ============================================================

/**
 * Middleware to check validation results and return formatted errors
 * Must be used after validation rules in route chains
 */
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map(err => ({
      field: err.path || err.param,
      message: err.msg,
      value: err.value,
      location: err.location
    }));

    logger.warn(`Validation failed for ${req.method} ${req.originalUrl}`, {
      errors: formattedErrors,
      ip: req.ip,
      userId: req.user?.id
    });

    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      errors: formattedErrors
    });
  }
  next();
};

// ============================================================
// COMMON VALIDATORS
// ============================================================

/**
 * Validates UUID format (v4)
 * @param {string} fieldName - Name of the field to validate
 * @param {string} [location='param'] - Location: 'param', 'body', or 'query'
 */
const validateUUID = (fieldName, location = 'param') => {
  const validator = location === 'body' ? body : location === 'query' ? query : param;
  return validator(fieldName)
    .isUUID(4)
    .withMessage(`${fieldName} must be a valid UUID`);
};

/**
 * Validates email format with normalization
 */
const validateEmail = (fieldName = 'email') => {
  return body(fieldName)
    .isEmail()
    .withMessage('Please provide a valid email address')
    .normalizeEmail({
      gmail_remove_dots: false,
      gmail_remove_subaddress: false
    })
    .isLength({ max: 255 })
    .withMessage('Email must be less than 255 characters');
};

/**
 * Validates Indian phone number format
 * Supports formats: +919876543210, 919876543210, 9876543210
 */
const validatePhone = (fieldName = 'phone') => {
  return body(fieldName)
    .optional()
    .matches(/^(\+91|91)?[6-9]\d{9}$/)
    .withMessage('Please provide a valid Indian phone number (e.g., +919876543210)')
    .customSanitizer(value => {
      if (!value) return value;
      // Normalize to +91 format
      const digits = value.replace(/\D/g, '');
      if (digits.length === 10) return '+91' + digits;
      if (digits.length === 12 && digits.startsWith('91')) return '+' + digits;
      return value;
    });
};

/**
 * Validates password with security requirements
 * Requirements: min 8 chars, 1 uppercase, 1 lowercase, 1 number
 */
const validatePassword = (fieldName = 'password', options = {}) => {
  const { minLength = 8, requireUppercase = true, requireNumber = true } = options;
  
  let validator = body(fieldName)
    .isLength({ min: minLength })
    .withMessage(`Password must be at least ${minLength} characters long`);

  if (requireUppercase) {
    validator = validator
      .matches(/[A-Z]/)
      .withMessage('Password must contain at least one uppercase letter');
  }

  if (requireNumber) {
    validator = validator
      .matches(/\d/)
      .withMessage('Password must contain at least one number');
  }

  return validator
    .matches(/[a-z]/)
    .withMessage('Password must contain at least one lowercase letter');
};

/**
 * Validates pagination parameters
 */
const validatePagination = [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer')
    .toInt(),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100')
    .toInt()
];

/**
 * Validates coordinates (latitude and longitude)
 */
const validateCoordinates = (latField = 'location_lat', lngField = 'location_lng') => {
  return [
    body(latField)
      .optional()
      .isFloat({ min: -90, max: 90 })
      .withMessage('Latitude must be between -90 and 90')
      .toFloat(),
    body(lngField)
      .optional()
      .isFloat({ min: -180, max: 180 })
      .withMessage('Longitude must be between -180 and 180')
      .toFloat()
  ];
};

/**
 * Validates price (positive float)
 */
const validatePrice = (fieldName = 'price', options = {}) => {
  const { required = true, min = 0 } = options;
  let validator = body(fieldName);
  
  if (!required) {
    validator = validator.optional();
  }
  
  return validator
    .isFloat({ min })
    .withMessage(`${fieldName} must be a positive number`)
    .toFloat();
};

/**
 * Validates quantity (positive integer)
 */
const validateQuantity = (fieldName = 'quantity', options = {}) => {
  const { required = true, min = 0, max = 99999 } = options;
  let validator = body(fieldName);
  
  if (!required) {
    validator = validator.optional();
  }
  
  return validator
    .isInt({ min, max })
    .withMessage(`${fieldName} must be a non-negative integer (max: ${max})`)
    .toInt();
};

/**
 * Validates date in ISO 8601 format
 */
const validateDate = (fieldName, options = {}) => {
  const { required = true, location = 'body' } = options;
  const validator = location === 'query' ? query : body;
  
  let chain = validator(fieldName);
  
  if (!required) {
    chain = chain.optional();
  }
  
  return chain
    .isISO8601()
    .withMessage(`${fieldName} must be a valid ISO 8601 date`)
    .toDate();
};

/**
 * Validates URL format
 */
const validateURL = (fieldName, options = {}) => {
  const { required = false, protocols = ['http', 'https'] } = options;
  let validator = body(fieldName);
  
  if (!required) {
    validator = validator.optional();
  }
  
  return validator
    .isURL({ protocols, require_protocol: true })
    .withMessage(`${fieldName} must be a valid URL`)
    .isLength({ max: 2048 })
    .withMessage('URL must be less than 2048 characters');
};

/**
 * Validates rating (1-5)
 */
const validateRating = (fieldName = 'rating') => {
  return body(fieldName)
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5')
    .toInt();
};

// ============================================================
// SANITIZERS
// ============================================================

/**
 * Sanitizes string input - trims and escapes HTML
 */
const sanitizeString = (fieldName, options = {}) => {
  const { required = true, maxLength = 1000, location = 'body' } = options;
  const validator = location === 'query' ? query : body;
  
  let chain = validator(fieldName);
  
  if (!required) {
    chain = chain.optional();
  } else {
    chain = chain.notEmpty().withMessage(`${fieldName} is required`);
  }
  
  return chain
    .trim()
    .isLength({ max: maxLength })
    .withMessage(`${fieldName} must be less than ${maxLength} characters`)
    .escape();
};

/**
 * Sanitizes text content - trims and removes low ASCII characters
 * Suitable for longer text fields like descriptions
 */
const sanitizeText = (fieldName, options = {}) => {
  const { required = true, maxLength = 10000 } = options;
  let validator = body(fieldName);
  
  if (!required) {
    validator = validator.optional();
  } else {
    validator = validator.notEmpty().withMessage(`${fieldName} is required`);
  }
  
  return validator
    .trim()
    .isLength({ max: maxLength })
    .withMessage(`${fieldName} must be less than ${maxLength} characters`)
    .stripLow({ keep_new_lines: true });
};

/**
 * Validates and sanitizes array fields
 */
const validateArray = (fieldName, options = {}) => {
  const { required = true, minLength = 0, maxLength = 100, itemValidator = null } = options;
  
  let chain = body(fieldName);
  
  if (!required) {
    chain = chain.optional();
  }
  
  chain = chain
    .isArray({ min: minLength, max: maxLength })
    .withMessage(`${fieldName} must be an array with ${minLength}-${maxLength} items`);
  
  return chain;
};

/**
 * Validates boolean fields
 */
const validateBoolean = (fieldName, options = {}) => {
  const { required = false } = options;
  let validator = body(fieldName);
  
  if (!required) {
    validator = validator.optional();
  }
  
  return validator
    .isBoolean()
    .withMessage(`${fieldName} must be a boolean`)
    .toBoolean();
};

/**
 * Validates enum values
 */
const validateEnum = (fieldName, allowedValues, options = {}) => {
  const { required = true, location = 'body' } = options;
  const validator = location === 'query' ? query : body;
  
  let chain = validator(fieldName);
  
  if (!required) {
    chain = chain.optional();
  }
  
  return chain
    .isIn(allowedValues)
    .withMessage(`${fieldName} must be one of: ${allowedValues.join(', ')}`);
};

// ============================================================
// ROUTE-SPECIFIC VALIDATION CHAINS
// ============================================================

/**
 * Validation for community post creation
 */
const communityPostValidation = [
  sanitizeString('user_name', { maxLength: 100 }),
  sanitizeText('content', { maxLength: 5000 }),
  validateURL('image_url', { required: false }),
  handleValidationErrors
];

/**
 * Validation for logbook entry creation
 */
const logbookEntryValidation = [
  sanitizeString('activity_type', { maxLength: 100 }),
  validateDate('date'),
  sanitizeText('description', { required: false, maxLength: 2000 }),
  validatePrice('cost', { required: false }),
  validatePrice('income', { required: false }),
  handleValidationErrors
];

/**
 * Validation for equipment listing creation
 */
const equipmentListingValidation = [
  validateUUID('category_id', 'body'),
  sanitizeString('name', { maxLength: 200 }),
  sanitizeText('description', { required: false, maxLength: 2000 }),
  sanitizeString('brand', { required: false, maxLength: 100 }),
  sanitizeString('model', { required: false, maxLength: 100 }),
  body('year_of_manufacture')
    .optional()
    .isInt({ min: 1900, max: new Date().getFullYear() })
    .withMessage('Year must be valid')
    .toInt(),
  validateEnum('condition', ['excellent', 'good', 'fair', 'needs_repair'], { required: false }),
  validatePrice('hourly_rate', { required: false }),
  validatePrice('daily_rate'),
  validatePrice('weekly_rate', { required: false }),
  validatePrice('deposit_amount', { required: false }),
  sanitizeString('location_address', { required: false, maxLength: 500 }),
  ...validateCoordinates('location_lat', 'location_lng'),
  body('service_radius_km')
    .optional()
    .isInt({ min: 1, max: 500 })
    .withMessage('Service radius must be between 1 and 500 km')
    .toInt(),
  validateArray('images', { required: false, maxLength: 10 }),
  validateBoolean('is_operator_included'),
  validatePrice('operator_rate_per_day', { required: false }),
  body('minimum_rental_days')
    .optional()
    .isInt({ min: 1, max: 365 })
    .withMessage('Minimum rental days must be between 1 and 365')
    .toInt(),
  body('maximum_rental_days')
    .optional()
    .isInt({ min: 1, max: 365 })
    .withMessage('Maximum rental days must be between 1 and 365')
    .toInt(),
  handleValidationErrors
];

/**
 * Validation for equipment booking
 */
const equipmentBookingValidation = [
  validateUUID('equipment_id', 'body'),
  validateDate('start_date'),
  validateDate('end_date'),
  validateBoolean('operator_included'),
  sanitizeString('delivery_address', { required: false, maxLength: 500 }),
  body('delivery_lat')
    .optional()
    .isFloat({ min: -90, max: 90 })
    .toFloat(),
  body('delivery_lng')
    .optional()
    .isFloat({ min: -180, max: 180 })
    .toFloat(),
  sanitizeText('notes', { required: false, maxLength: 1000 }),
  handleValidationErrors
];

/**
 * Validation for cart operations
 */
const cartAddValidation = [
  validateUUID('product_id', 'body'),
  validateQuantity('quantity', { required: false, min: 1, max: 9999 }),
  handleValidationErrors
];

const cartUpdateValidation = [
  validateUUID('itemId', 'param'),
  validateQuantity('quantity', { min: 1, max: 9999 }),
  handleValidationErrors
];

/**
 * Validation for review creation
 */
const reviewValidation = [
  validateRating('rating'),
  sanitizeString('title', { required: false, maxLength: 200 }),
  sanitizeText('review_text', { required: false, maxLength: 5000 }),
  handleValidationErrors
];

/**
 * Validation for technology experience sharing
 */
const technologyExperienceValidation = [
  validateUUID('technology_id', 'body'),
  sanitizeString('title', { maxLength: 200 }),
  sanitizeText('experience_text', { maxLength: 5000 }),
  validatePrice('implementation_cost', { required: false }),
  body('roi_achieved_percent')
    .optional()
    .isFloat({ min: -100, max: 10000 })
    .withMessage('ROI percent must be a valid number')
    .toFloat(),
  body('time_to_implement_days')
    .optional()
    .isInt({ min: 1, max: 3650 })
    .withMessage('Implementation time must be between 1 and 3650 days')
    .toInt(),
  body('farm_size_acres')
    .optional()
    .isFloat({ min: 0.1, max: 100000 })
    .withMessage('Farm size must be between 0.1 and 100000 acres')
    .toFloat(),
  sanitizeString('crop_type', { required: false, maxLength: 100 }),
  validateRating('rating'),
  validateBoolean('would_recommend'),
  validateArray('images', { required: false, maxLength: 10 }),
  handleValidationErrors
];

/**
 * Validation for scheme query parameters
 */
const schemeQueryValidation = [
  query('farm_size')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Farm size must be a positive number')
    .toFloat(),
  query('income')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Income must be a positive number')
    .toFloat(),
  sanitizeString('crop', { required: false, maxLength: 100, location: 'query' }),
  sanitizeString('state', { required: false, maxLength: 100, location: 'query' }),
  sanitizeString('district', { required: false, maxLength: 100, location: 'query' }),
  sanitizeString('land_ownership', { required: false, maxLength: 50, location: 'query' }),
  sanitizeString('category', { required: false, maxLength: 50, location: 'query' }),
  sanitizeString('scheme_type', { required: false, maxLength: 50, location: 'query' }),
  sanitizeString('search', { required: false, maxLength: 200, location: 'query' }),
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer')
    .toInt(),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100')
    .toInt(),
  handleValidationErrors
];

const eligibilityProfileValidation = [
  body('farm_size_hectares')
    .optional()
    .isFloat({ min: 0, max: 10000 })
    .withMessage('Farm size must be between 0 and 10000 hectares')
    .toFloat(),
  body('annual_income')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Annual income must be a positive number')
    .toFloat(),
  body('land_ownership_type')
    .optional()
    .isIn(['owner', 'tenant', 'sharecropper', 'lease'])
    .withMessage('Land ownership type must be owner, tenant, sharecropper, or lease'),
  body('primary_crops')
    .optional()
    .isArray()
    .withMessage('Primary crops must be an array'),
  sanitizeString('state', { required: false, maxLength: 100 }),
  sanitizeString('district', { required: false, maxLength: 100 }),
  sanitizeString('block', { required: false, maxLength: 100 }),
  sanitizeString('village', { required: false, maxLength: 100 }),
  sanitizeString('social_category', { required: false, maxLength: 50 }),
  sanitizeString('gender', { required: false, maxLength: 20 }),
  body('age')
    .optional()
    .isInt({ min: 18, max: 120 })
    .withMessage('Age must be between 18 and 120')
    .toInt(),
  body('has_bank_account')
    .optional()
    .isBoolean()
    .withMessage('has_bank_account must be a boolean')
    .toBoolean(),
  body('has_aadhar')
    .optional()
    .isBoolean()
    .withMessage('has_aadhar must be a boolean')
    .toBoolean(),
  body('has_kcc')
    .optional()
    .isBoolean()
    .withMessage('has_kcc must be a boolean')
    .toBoolean(),
  sanitizeString('irrigation_type', { required: false, maxLength: 50 }),
  sanitizeString('soil_type', { required: false, maxLength: 50 }),
  handleValidationErrors
];

/**
 * Generic ID parameter validation
 */
const validateIdParam = [
  validateUUID('id', 'param'),
  handleValidationErrors
];

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  // Core utilities
  handleValidationErrors,
  
  // Common validators
  validateUUID,
  validateEmail,
  validatePhone,
  validatePassword,
  validatePagination,
  validateCoordinates,
  validatePrice,
  validateQuantity,
  validateDate,
  validateURL,
  validateRating,
  validateArray,
  validateBoolean,
  validateEnum,
  
  // Sanitizers
  sanitizeString,
  sanitizeText,
  
  // Route-specific validation chains
  communityPostValidation,
  logbookEntryValidation,
  equipmentListingValidation,
  equipmentBookingValidation,
  cartAddValidation,
  cartUpdateValidation,
  reviewValidation,
  technologyExperienceValidation,
  schemeQueryValidation,
  eligibilityProfileValidation,
  validateIdParam
};

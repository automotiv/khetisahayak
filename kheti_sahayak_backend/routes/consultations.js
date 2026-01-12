const express = require('express');
const { body, query, param } = require('express-validator');
const router = express.Router();

const {
  getExperts,
  getExpertById,
  getExpertAvailability,
  registerAsExpert,
  updateExpertProfile,
  setAvailability,
  bookConsultation,
  getMyConsultations,
  getConsultationById,
  rescheduleConsultation,
  cancelConsultation,
  startConsultation,
  completeConsultation,
  addReview,
  getExpertReviews,
  confirmConsultation,
  rejectConsultation,
  getVideoTokens,
  joinConsultation,
  getPendingConsultations,
  markNoShow
} = require('../controllers/consultationController');

const { protect, authorize } = require('../middleware/authMiddleware');
const {
  handleValidationErrors,
  validateUUID,
  validatePagination,
  validateRating,
  sanitizeText,
  validateDate,
  validateEnum,
  validatePrice,
  validateArray,
  validateBoolean
} = require('../middleware/validationMiddleware');

const expertQueryValidation = [
  ...validatePagination,
  query('specialization').optional().trim().isLength({ max: 100 }),
  query('min_rating').optional().isFloat({ min: 0, max: 5 }).toFloat(),
  query('language').optional().trim().isLength({ max: 50 }),
  query('is_verified').optional().isBoolean().toBoolean(),
  query('sort').optional().isIn(['rating', 'consultations', 'fee_low', 'fee_high', 'experience']),
  handleValidationErrors
];

const availabilityQueryValidation = [
  validateUUID('id', 'param'),
  query('date').notEmpty().isISO8601().withMessage('Date must be in YYYY-MM-DD format'),
  handleValidationErrors
];

const registerExpertValidation = [
  body('specialization').notEmpty().trim().isLength({ max: 255 }).withMessage('Specialization is required'),
  body('expertise_areas').optional().isArray({ max: 20 }),
  body('expertise_areas.*').optional().trim().isLength({ max: 100 }),
  body('qualification').optional().trim().isLength({ max: 255 }),
  body('experience_years').optional().isInt({ min: 0, max: 60 }).toInt(),
  body('bio').optional().trim().isLength({ max: 2000 }),
  body('languages').optional().isArray({ max: 10 }),
  body('languages.*').optional().trim().isLength({ max: 50 }),
  body('consultation_fee').optional().isFloat({ min: 0, max: 50000 }).toFloat(),
  body('profile_image_url').optional().isURL(),
  handleValidationErrors
];

const updateExpertValidation = [
  body('specialization').optional().trim().isLength({ max: 255 }),
  body('expertise_areas').optional().isArray({ max: 20 }),
  body('qualification').optional().trim().isLength({ max: 255 }),
  body('experience_years').optional().isInt({ min: 0, max: 60 }).toInt(),
  body('bio').optional().trim().isLength({ max: 2000 }),
  body('languages').optional().isArray({ max: 10 }),
  body('consultation_fee').optional().isFloat({ min: 0, max: 50000 }).toFloat(),
  body('profile_image_url').optional().isURL(),
  body('is_active').optional().isBoolean().toBoolean(),
  handleValidationErrors
];

const setAvailabilityValidation = [
  body('availability').isArray({ min: 1, max: 21 }).withMessage('Availability must be an array'),
  body('availability.*.day_of_week').isInt({ min: 0, max: 6 }).withMessage('day_of_week must be 0-6'),
  body('availability.*.start_time').matches(/^([01]\d|2[0-3]):([0-5]\d)$/).withMessage('start_time must be HH:MM format'),
  body('availability.*.end_time').matches(/^([01]\d|2[0-3]):([0-5]\d)$/).withMessage('end_time must be HH:MM format'),
  body('availability.*.slot_duration_minutes').optional().isInt({ min: 15, max: 120 }).toInt(),
  body('availability.*.is_available').optional().isBoolean().toBoolean(),
  handleValidationErrors
];

const bookConsultationValidation = [
  validateUUID('expert_id', 'body'),
  body('scheduled_at').isISO8601().withMessage('scheduled_at must be a valid ISO 8601 datetime'),
  body('duration_minutes').optional().isInt({ min: 15, max: 120 }).toInt(),
  body('consultation_type').optional().isIn(['video', 'audio', 'chat']),
  body('issue_description').optional().trim().isLength({ max: 2000 }),
  body('issue_images').optional().isArray({ max: 5 }),
  body('issue_images.*').optional().isURL(),
  validateUUID('diagnosis_id', 'body').optional(),
  handleValidationErrors
];

const rescheduleValidation = [
  validateUUID('id', 'param'),
  body('new_scheduled_at').isISO8601().withMessage('new_scheduled_at must be a valid ISO 8601 datetime'),
  handleValidationErrors
];

const cancelValidation = [
  validateUUID('id', 'param'),
  body('reason').optional().trim().isLength({ max: 500 }),
  handleValidationErrors
];

const completeValidation = [
  validateUUID('id', 'param'),
  body('expert_notes').optional().trim().isLength({ max: 5000 }),
  body('recommendations').optional().trim().isLength({ max: 5000 }),
  body('follow_up_required').optional().isBoolean().toBoolean(),
  body('follow_up_date').optional().isISO8601(),
  handleValidationErrors
];

const reviewValidation = [
  validateUUID('id', 'param'),
  body('rating').isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5').toInt(),
  body('review_text').optional().trim().isLength({ max: 2000 }),
  body('was_helpful').optional().isBoolean().toBoolean(),
  body('would_recommend').optional().isBoolean().toBoolean(),
  handleValidationErrors
];

const expertReviewsValidation = [
  validateUUID('id', 'param'),
  ...validatePagination,
  query('sort').optional().isIn(['recent', 'oldest', 'highest', 'lowest']),
  handleValidationErrors
];

const consultationsQueryValidation = [
  ...validatePagination,
  query('status').optional().isIn(['pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show']),
  query('role').optional().isIn(['farmer', 'expert']),
  handleValidationErrors
];

router.get('/experts', expertQueryValidation, getExperts);

router.get('/experts/:id', [validateUUID('id', 'param'), handleValidationErrors], getExpertById);

router.get('/experts/:id/availability', availabilityQueryValidation, getExpertAvailability);

router.get('/experts/:id/reviews', expertReviewsValidation, getExpertReviews);

router.post('/experts/register', protect, registerExpertValidation, registerAsExpert);

router.put('/experts/profile', protect, updateExpertValidation, updateExpertProfile);

router.post('/experts/availability', protect, setAvailabilityValidation, setAvailability);

router.post('/book', protect, bookConsultationValidation, bookConsultation);

router.get('/', protect, consultationsQueryValidation, getMyConsultations);

router.get('/expert/pending', protect, [
  ...validatePagination,
  handleValidationErrors
], getPendingConsultations);

router.get('/:id', protect, [validateUUID('id', 'param'), handleValidationErrors], getConsultationById);

router.put('/:id/reschedule', protect, rescheduleValidation, rescheduleConsultation);

router.put('/:id/cancel', protect, cancelValidation, cancelConsultation);

router.post('/:id/start', protect, [validateUUID('id', 'param'), handleValidationErrors], startConsultation);

router.post('/:id/complete', protect, completeValidation, completeConsultation);

router.post('/:id/review', protect, reviewValidation, addReview);

router.post('/:id/confirm', protect, [validateUUID('id', 'param'), handleValidationErrors], confirmConsultation);

router.post('/:id/reject', protect, [
  validateUUID('id', 'param'),
  body('reason').optional().trim().isLength({ max: 500 }),
  handleValidationErrors
], rejectConsultation);

router.get('/:id/video-tokens', protect, [validateUUID('id', 'param'), handleValidationErrors], getVideoTokens);

router.post('/:id/join', protect, [validateUUID('id', 'param'), handleValidationErrors], joinConsultation);

router.post('/:id/no-show', protect, [validateUUID('id', 'param'), handleValidationErrors], markNoShow);

module.exports = router;

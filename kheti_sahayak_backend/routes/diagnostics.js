const express = require('express');
const { body, query, param } = require('express-validator');
const multer = require('multer');
const { validatePagination, validateIdParam, handleValidationErrors, sanitizeString } = require('../middleware/validationMiddleware');
const { uploadRateLimiter } = require('../middleware/securityMiddleware');
const {
  uploadForDiagnosis,
  getDiagnosticHistory,
  getDiagnosticById,
  getTreatmentRecommendations,
  requestExpertReview,
  submitExpertReview,
  getExpertAssignedDiagnostics,
  getCropRecommendations,
  getDiagnosticStats,
} = require('../controllers/diagnosticsController');
const { protect, authorize } = require('../middleware/authMiddleware');

/**
 * @swagger
 * tags:
 *   name: Diagnostics
 *   description: Crop diagnostics and expert review operations
 */

const router = express.Router();

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  },
});

// Validation rules for diagnostic upload
const diagnosticUploadValidationRules = [
  body('crop_type', 'Crop type is required').not().isEmpty().trim().escape(),
  body('issue_description', 'Issue description is required').not().isEmpty().trim(),
];

// Validation rules for expert review
const expertReviewValidationRules = [
  body('expert_diagnosis', 'Expert diagnosis is required').not().isEmpty().trim(),
  body('expert_recommendations', 'Expert recommendations are required').not().isEmpty().trim(),
  body('severity_level', 'Severity level must be low, moderate, or high').optional().isIn(['low', 'moderate', 'high']),
];

/**
 * @swagger
 * /api/diagnostics/recommendations:
 *   get:
 *     summary: Get crop recommendations
 *     tags: [Diagnostics]
 *     parameters:
 *       - in: query
 *         name: season
 *         schema:
 *           type: string
 *         description: Growing season
 *       - in: query
 *         name: soil_type
 *         schema:
 *           type: string
 *         description: Soil type
 *       - in: query
 *         name: climate_zone
 *         schema:
 *           type: string
 *         description: Climate zone
 *       - in: query
 *         name: water_availability
 *         schema:
 *           type: string
 *         description: Water availability
 *     responses:
 *       200:
 *         description: Crop recommendations
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 recommendations:
 *                   type: array
 *                   items:
 *                     type: object
 */
const recommendationsQueryValidation = [
  query('season').optional().trim().escape().isLength({ max: 50 }),
  query('soil_type').optional().trim().escape().isLength({ max: 50 }),
  query('climate_zone').optional().trim().escape().isLength({ max: 50 }),
  query('water_availability').optional().trim().escape().isLength({ max: 50 }),
  handleValidationErrors
];

router.get('/recommendations', recommendationsQueryValidation, getCropRecommendations);

/**
 * @swagger
 * /api/diagnostics/stats:
 *   get:
 *     summary: Get diagnostic statistics for user
 *     tags: [Diagnostics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Diagnostic statistics
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 stats:
 *                   type: object
 *                   properties:
 *                     total_diagnostics:
 *                       type: integer
 *                     by_status:
 *                       type: array
 *                     by_crop_type:
 *                       type: array
 *                     recent_diagnostics:
 *                       type: array
 *       401:
 *         description: Not authorized
 */
router.get('/stats', protect, getDiagnosticStats);

/**
 * @swagger
 * /api/diagnostics/upload:
 *   post:
 *     summary: Upload image for crop diagnosis
 *     tags: [Diagnostics]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - image
 *               - crop_type
 *               - issue_description
 *             properties:
 *               image:
 *                 type: string
 *                 format: binary
 *               crop_type:
 *                 type: string
 *               issue_description:
 *                 type: string
 *     responses:
 *       201:
 *         description: Diagnostic uploaded successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 diagnostic:
 *                   $ref: '#/components/schemas/CropDiagnostic'
 *       401:
 *         description: Not authorized
 */
router.post('/upload', protect, uploadRateLimiter, upload.single('image'), diagnosticUploadValidationRules, uploadForDiagnosis);

/**
 * @swagger
 * /api/diagnostics:
 *   get:
 *     summary: Get user's diagnostic history
 *     tags: [Diagnostics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Diagnostic history
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 diagnostics:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/CropDiagnostic'
 *       401:
 *         description: Not authorized
 */
router.get('/', protect, [...validatePagination, handleValidationErrors], getDiagnosticHistory);

/**
 * @swagger
 * /api/diagnostics/{id}:
 *   get:
 *     summary: Get diagnostic by ID
 *     tags: [Diagnostics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Diagnostic ID
 *     responses:
 *       200:
 *         description: Diagnostic details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 diagnostic:
 *                   $ref: '#/components/schemas/CropDiagnostic'
 *       401:
 *         description: Not authorized
 *       404:
 *         description: Diagnostic not found
 */
router.get('/:id', protect, validateIdParam, getDiagnosticById);

/**
 * @swagger
 * /api/diagnostics/{id}/treatments:
 *   get:
 *     summary: Get treatment recommendations for a diagnostic
 *     tags: [Diagnostics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Diagnostic ID
 *     responses:
 *       200:
 *         description: Treatment recommendations retrieved successfully
 *       404:
 *         description: Diagnostic not found
 */
router.get('/:id/treatments', protect, validateIdParam, getTreatmentRecommendations);

/**
 * @swagger
 * /api/diagnostics/{id}/expert-review:
 *   post:
 *     summary: Request expert review for diagnostic
 *     tags: [Diagnostics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Diagnostic ID
 *     responses:
 *       200:
 *         description: Expert review requested successfully
 *       401:
 *         description: Not authorized
 */
router.post('/:id/expert-review', protect, validateIdParam, requestExpertReview);

/**
 * @swagger
 * /api/diagnostics/{id}/expert-review:
 *   put:
 *     summary: Submit expert review for diagnostic
 *     tags: [Diagnostics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Diagnostic ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - expert_diagnosis
 *               - expert_recommendations
 *             properties:
 *               expert_diagnosis:
 *                 type: string
 *               expert_recommendations:
 *                 type: string
 *               severity_level:
 *                 type: string
 *                 enum: [low, moderate, high]
 *     responses:
 *       200:
 *         description: Expert review submitted successfully
 *       401:
 *         description: Not authorized
 *       403:
 *         description: Access denied - Expert role required
 */
router.put('/:id/expert-review', protect, authorize('expert'), [param('id').isUUID().withMessage('Invalid diagnostic ID'), ...expertReviewValidationRules], submitExpertReview);

/**
 * @swagger
 * /api/diagnostics/expert/assigned:
 *   get:
 *     summary: Get diagnostics assigned to expert
 *     tags: [Diagnostics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Assigned diagnostics
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 diagnostics:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/CropDiagnostic'
 *       401:
 *         description: Not authorized
 *       403:
 *         description: Access denied - Expert role required
 */
router.get('/expert/assigned', protect, authorize('expert'), getExpertAssignedDiagnostics);

module.exports = router;
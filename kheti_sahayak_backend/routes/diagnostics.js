const express = require('express');
const { body } = require('express-validator');
const multer = require('multer');
const {
  uploadForDiagnosis,
  getDiagnosticHistory,
  getDiagnosticById,
  requestExpertReview,
  submitExpertReview,
  getExpertAssignedDiagnostics,
  getCropRecommendations,
} = require('../controllers/diagnosticsController');
const { protect, authorize } = require('../middleware/authMiddleware');

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

// Public routes
router.get('/recommendations', getCropRecommendations);

// Protected routes
router.post('/upload', protect, upload.single('image'), diagnosticUploadValidationRules, uploadForDiagnosis);
router.get('/', protect, getDiagnosticHistory);
router.get('/:id', protect, getDiagnosticById);
router.post('/:id/expert-review', protect, requestExpertReview);

// Expert routes
router.put('/:id/expert-review', protect, authorize('expert'), expertReviewValidationRules, submitExpertReview);
router.get('/expert/assigned', protect, authorize('expert'), getExpertAssignedDiagnostics);

module.exports = router;
const express = require('express');
const multer = require('multer');
const { protect } = require('../middleware/authMiddleware');
const { uploadForDiagnosis } = require('../controllers/diagnosticsController');

const router = express.Router();

// Configure multer for memory storage
const upload = multer({ storage: multer.memoryStorage() });

// The 'protect' middleware runs first to authenticate the user.
// Then 'upload.single' handles the file upload.
// Finally, 'uploadForDiagnosis' processes the request.
router.post('/upload', protect, upload.single('image'), uploadForDiagnosis);

module.exports = router;
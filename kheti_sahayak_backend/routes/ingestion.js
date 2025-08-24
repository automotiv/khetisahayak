const express = require('express');
const { createPresignedUpload, finalizeIngest } = require('../controllers/ingestionController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Create presigned upload URL
router.post('/presign', protect, createPresignedUpload);

// Finalize ingest after client upload
router.post('/finalize', protect, finalizeIngest);

module.exports = router;

const express = require('express');
const {
  getAllContent,
  getContentById,
  addContent,
} = require('../controllers/educationalContentController');
const { protect, authorize } = require('../middleware/authMiddleware');

const router = express.Router();

// Get all educational content
router.get('/', getAllContent);

// Get a single educational content by ID
router.get('/:id', getContentById);

// Add new educational content (Admin/Content Creator functionality)
router.post('/', protect, authorize('admin', 'content-creator'), addContent);

module.exports = router;
const express = require('express');
const {
  getAllProducts,
  addProduct,
  getProductById,
} = require('../controllers/marketplaceController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// List all products
router.get('/', getAllProducts);

// Add a new product
router.post('/', protect, addProduct);

// Get a single product by ID
router.get('/:id', getProductById);

module.exports = router;
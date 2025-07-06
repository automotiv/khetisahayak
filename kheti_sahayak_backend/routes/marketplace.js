const express = require('express');
const { body } = require('express-validator');
const multer = require('multer');
const {
  getAllProducts,
  getProductById,
  addProduct,
  updateProduct,
  deleteProduct,
  uploadProductImages,
  getSellerProducts,
  getProductCategories,
} = require('../controllers/marketplaceController');
const { protect, authorize } = require('../middleware/authMiddleware');

const router = express.Router();

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit per file
    files: 5 // Maximum 5 files
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  },
});

// Validation rules for product creation/update
const productValidationRules = [
  body('name', 'Product name is required').not().isEmpty().trim().escape(),
  body('price', 'Price must be a positive number').isFloat({ min: 0 }),
  body('category', 'Category is required').not().isEmpty().trim().escape(),
  body('description', 'Description cannot be empty').optional().not().isEmpty().trim(),
  body('stock_quantity', 'Stock quantity must be a non-negative integer').optional().isInt({ min: 0 }),
  body('is_organic', 'is_organic must be a boolean').optional().isBoolean(),
  body('is_available', 'is_available must be a boolean').optional().isBoolean(),
];

// Public routes
router.get('/', getAllProducts);
router.get('/categories', getProductCategories);
router.get('/:id', getProductById);

// Protected routes
router.post('/', protect, productValidationRules, addProduct);
router.put('/:id', protect, productValidationRules, updateProduct);
router.delete('/:id', protect, deleteProduct);
router.post('/:id/images', protect, upload.array('images', 5), uploadProductImages);
router.get('/seller/products', protect, getSellerProducts);

module.exports = router;
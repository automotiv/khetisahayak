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

/**
 * @swagger
 * tags:
 *   name: Marketplace
 *   description: Product marketplace operations
 */

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

/**
 * @swagger
 * /api/marketplace:
 *   get:
 *     summary: Get all products
 *     tags: [Marketplace]
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Filter by category
 *       - in: query
 *         name: minPrice
 *         schema:
 *           type: number
 *         description: Minimum price filter
 *       - in: query
 *         name: maxPrice
 *         schema:
 *           type: number
 *         description: Maximum price filter
 *       - in: query
 *         name: organic
 *         schema:
 *           type: boolean
 *         description: Filter organic products
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *         description: Page number for pagination
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         description: Number of items per page
 *     responses:
 *       200:
 *         description: List of products
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 products:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Product'
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     page:
 *                       type: integer
 *                     limit:
 *                       type: integer
 *                     total:
 *                       type: integer
 *                     pages:
 *                       type: integer
 */
router.get('/', getAllProducts);

/**
 * @swagger
 * /api/marketplace/categories:
 *   get:
 *     summary: Get product categories
 *     tags: [Marketplace]
 *     responses:
 *       200:
 *         description: List of categories
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 categories:
 *                   type: array
 *                   items:
 *                     type: string
 */
router.get('/categories', getProductCategories);

/**
 * @swagger
 * /api/marketplace/{id}:
 *   get:
 *     summary: Get product by ID
 *     tags: [Marketplace]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Product ID
 *     responses:
 *       200:
 *         description: Product details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 product:
 *                   $ref: '#/components/schemas/Product'
 *       404:
 *         description: Product not found
 */
router.get('/:id', getProductById);

/**
 * @swagger
 * /api/marketplace:
 *   post:
 *     summary: Add a new product
 *     tags: [Marketplace]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - price
 *               - category
 *             properties:
 *               name:
 *                 type: string
 *               price:
 *                 type: number
 *               category:
 *                 type: string
 *               description:
 *                 type: string
 *               stock_quantity:
 *                 type: integer
 *               is_organic:
 *                 type: boolean
 *               is_available:
 *                 type: boolean
 *     responses:
 *       201:
 *         description: Product created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 product:
 *                   $ref: '#/components/schemas/Product'
 *       401:
 *         description: Not authorized
 *       400:
 *         description: Validation error
 */
router.post('/', protect, productValidationRules, addProduct);

/**
 * @swagger
 * /api/marketplace/{id}:
 *   put:
 *     summary: Update a product
 *     tags: [Marketplace]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Product ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               price:
 *                 type: number
 *               category:
 *                 type: string
 *               description:
 *                 type: string
 *               stock_quantity:
 *                 type: integer
 *               is_organic:
 *                 type: boolean
 *               is_available:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Product updated successfully
 *       401:
 *         description: Not authorized
 *       404:
 *         description: Product not found
 */
router.put('/:id', protect, productValidationRules, updateProduct);

/**
 * @swagger
 * /api/marketplace/{id}:
 *   delete:
 *     summary: Delete a product
 *     tags: [Marketplace]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Product ID
 *     responses:
 *       200:
 *         description: Product deleted successfully
 *       401:
 *         description: Not authorized
 *       404:
 *         description: Product not found
 */
router.delete('/:id', protect, deleteProduct);

/**
 * @swagger
 * /api/marketplace/{id}/images:
 *   post:
 *     summary: Upload product images
 *     tags: [Marketplace]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Product ID
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               images:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: binary
 *     responses:
 *       200:
 *         description: Images uploaded successfully
 *       401:
 *         description: Not authorized
 */
router.post('/:id/images', protect, upload.array('images', 5), uploadProductImages);

/**
 * @swagger
 * /api/marketplace/seller/products:
 *   get:
 *     summary: Get seller's products
 *     tags: [Marketplace]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Seller's products
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 products:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Product'
 *       401:
 *         description: Not authorized
 */
router.get('/seller/products', protect, getSellerProducts);

module.exports = router;
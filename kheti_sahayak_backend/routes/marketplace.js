const express = require('express');
const { body, query, param } = require('express-validator');
const multer = require('multer');
const { validatePagination, validateIdParam, handleValidationErrors } = require('../middleware/validationMiddleware');
const {
  getAllProducts,
  getProductById,
  addProduct,
  updateProduct,
  deleteProduct,
  uploadProductImages,
  getSellerProducts,
  getProductCategories,
  compareProducts,
} = require('../controllers/marketplaceController');
const {
  getWishlist,
  addToWishlist,
  removeFromWishlist,
  isInWishlist,
  getWishlistProductIds,
} = require('../controllers/wishlistController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { validateUUID } = require('../middleware/validationMiddleware');

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
const productsQueryValidation = [
  query('category').optional().trim().escape().isLength({ max: 100 }),
  query('minPrice').optional().isFloat({ min: 0 }).withMessage('Minimum price must be positive').toFloat(),
  query('maxPrice').optional().isFloat({ min: 0 }).withMessage('Maximum price must be positive').toFloat(),
  query('organic').optional().isBoolean().toBoolean(),
  query('search').optional().trim().escape().isLength({ max: 200 }),
  ...validatePagination,
  handleValidationErrors
];

router.get('/', productsQueryValidation, getAllProducts);

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

router.post('/compare', [
  body('product_ids')
    .isArray({ min: 2, max: 5 })
    .withMessage('Must provide 2-5 product IDs for comparison'),
  body('product_ids.*')
    .isUUID()
    .withMessage('Each product ID must be a valid UUID'),
], compareProducts);

/**
 * @swagger
 * /api/marketplace/wishlist:
 *   get:
 *     summary: Get user's wishlist
 *     tags: [Wishlist]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Wishlist items retrieved successfully
 *       401:
 *         description: Unauthorized
 */
router.get('/wishlist', protect, getWishlist);

/**
 * @swagger
 * /api/marketplace/wishlist/ids:
 *   get:
 *     summary: Get product IDs in user's wishlist
 *     tags: [Wishlist]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Wishlist product IDs retrieved successfully
 *       401:
 *         description: Unauthorized
 */
router.get('/wishlist/ids', protect, getWishlistProductIds);

/**
 * @swagger
 * /api/marketplace/wishlist/{productId}:
 *   get:
 *     summary: Check if product is in wishlist
 *     tags: [Wishlist]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Returns whether product is in wishlist
 *       401:
 *         description: Unauthorized
 */
router.get('/wishlist/:productId', protect, [validateUUID('productId', 'param')], isInWishlist);

/**
 * @swagger
 * /api/marketplace/wishlist/{productId}:
 *   post:
 *     summary: Add product to wishlist
 *     tags: [Wishlist]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       201:
 *         description: Product added to wishlist
 *       400:
 *         description: Product already in wishlist
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Product not found
 */
router.post('/wishlist/:productId', protect, [validateUUID('productId', 'param')], addToWishlist);

/**
 * @swagger
 * /api/marketplace/wishlist/{productId}:
 *   delete:
 *     summary: Remove product from wishlist
 *     tags: [Wishlist]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Product removed from wishlist
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Product not found in wishlist
 */
router.delete('/wishlist/:productId', protect, [validateUUID('productId', 'param')], removeFromWishlist);

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
router.get('/:id', validateIdParam, getProductById);

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
router.put('/:id', protect, [param('id').isUUID().withMessage('Invalid product ID'), ...productValidationRules], updateProduct);

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
router.delete('/:id', protect, validateIdParam, deleteProduct);

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
router.post('/:id/images', protect, validateIdParam, upload.array('images', 5), uploadProductImages);

module.exports = router;
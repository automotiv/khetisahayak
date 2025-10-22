const express = require('express');
const router = express.Router();
const multer = require('multer');
const {
  createReview,
  getProductReviews,
  getReviewById,
  updateReview,
  deleteReview,
  markReviewHelpful,
  getMyReviews,
  flagReview,
} = require('../controllers/reviewsController');
const { protect } = require('../middleware/authMiddleware');

// Configure multer for file uploads (review images)
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit per image
    files: 5, // Maximum 5 images per review
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  },
});

/**
 * @swagger
 * components:
 *   schemas:
 *     Review:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           example: 1
 *         product_id:
 *           type: integer
 *           example: 123
 *         user_id:
 *           type: integer
 *           example: 456
 *         rating:
 *           type: integer
 *           minimum: 1
 *           maximum: 5
 *           example: 5
 *         title:
 *           type: string
 *           example: "Excellent product!"
 *         review_text:
 *           type: string
 *           example: "This product exceeded my expectations. Highly recommended!"
 *         images:
 *           type: array
 *           items:
 *             type: string
 *           example: ["https://s3.amazonaws.com/reviews/image1.jpg"]
 *         verified_purchase:
 *           type: boolean
 *           example: true
 *         helpful_count:
 *           type: integer
 *           example: 15
 *         status:
 *           type: string
 *           enum: [active, hidden, flagged, deleted]
 *           example: "active"
 *         created_at:
 *           type: string
 *           format: date-time
 *         updated_at:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/reviews/my-reviews:
 *   get:
 *     summary: Get current user's reviews
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *     responses:
 *       200:
 *         description: List of user's reviews
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/my-reviews', protect, getMyReviews);

/**
 * @swagger
 * /api/reviews/{productId}:
 *   get:
 *     summary: Get all reviews for a product
 *     tags: [Reviews]
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema:
 *           type: integer
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *       - in: query
 *         name: rating
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 5
 *       - in: query
 *         name: sort
 *         schema:
 *           type: string
 *           enum: [recent, oldest, highest, lowest, helpful]
 *           default: recent
 *     responses:
 *       200:
 *         description: List of product reviews with statistics
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.get('/:productId', getProductReviews);

/**
 * @swagger
 * /api/reviews/{productId}:
 *   post:
 *     summary: Create a product review
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - rating
 *             properties:
 *               rating:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *               title:
 *                 type: string
 *               review_text:
 *                 type: string
 *               images:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: binary
 *     responses:
 *       201:
 *         description: Review created successfully
 *       400:
 *         description: Validation error or duplicate review
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.post('/:productId', protect, upload.array('images', 5), createReview);

/**
 * @swagger
 * /api/reviews/review/{reviewId}:
 *   get:
 *     summary: Get a review by ID
 *     tags: [Reviews]
 *     parameters:
 *       - in: path
 *         name: reviewId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Review details
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.get('/review/:reviewId', getReviewById);

/**
 * @swagger
 * /api/reviews/review/{reviewId}:
 *   put:
 *     summary: Update a review
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: reviewId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               rating:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *               title:
 *                 type: string
 *               review_text:
 *                 type: string
 *               images:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: binary
 *     responses:
 *       200:
 *         description: Review updated successfully
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.put('/review/:reviewId', protect, upload.array('images', 5), updateReview);

/**
 * @swagger
 * /api/reviews/review/{reviewId}:
 *   delete:
 *     summary: Delete a review
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: reviewId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Review deleted successfully
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.delete('/review/:reviewId', protect, deleteReview);

/**
 * @swagger
 * /api/reviews/review/{reviewId}/helpful:
 *   post:
 *     summary: Mark/unmark a review as helpful
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: reviewId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Review helpful status toggled
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.post('/review/:reviewId/helpful', protect, markReviewHelpful);

/**
 * @swagger
 * /api/reviews/review/{reviewId}/flag:
 *   post:
 *     summary: Flag a review as inappropriate
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: reviewId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - reason
 *             properties:
 *               reason:
 *                 type: string
 *                 example: "Spam or inappropriate content"
 *     responses:
 *       200:
 *         description: Review flagged for moderation
 *       400:
 *         description: Reason not provided
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.post('/review/:reviewId/flag', protect, flagReview);

module.exports = router;

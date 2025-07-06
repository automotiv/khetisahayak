const express = require('express');
const { body } = require('express-validator');
const {
  getAllContent,
  getContentById,
  addContent,
  updateContent,
  deleteContent,
  getCategories,
  getContentByCategory,
  getPopularContent,
  getContentAnalytics,
} = require('../controllers/educationalContentController');
const { protect, authorize } = require('../middleware/authMiddleware');

/**
 * @swagger
 * tags:
 *   name: Educational Content
 *   description: Educational content management and learning resources
 */

const router = express.Router();

// Validation rules for content creation/update
const contentValidationRules = [
  body('title', 'Title is required').not().isEmpty().trim().escape(),
  body('content', 'Content is required').not().isEmpty().trim(),
  body('category', 'Category is required').not().isEmpty().trim().escape(),
  body('summary', 'Summary cannot be empty').optional().not().isEmpty().trim(),
  body('subcategory', 'Subcategory cannot be empty').optional().not().isEmpty().trim().escape(),
  body('difficulty_level', 'Difficulty level must be beginner, intermediate, or advanced').optional().isIn(['beginner', 'intermediate', 'advanced']),
  body('image_url', 'Image URL must be valid').optional().isURL(),
  body('video_url', 'Video URL must be valid').optional().isURL(),
  body('tags', 'Tags must be an array').optional().isArray(),
  body('is_published', 'is_published must be a boolean').optional().isBoolean(),
];

/**
 * @swagger
 * /api/educational-content:
 *   get:
 *     summary: Get all educational content with filtering and pagination
 *     tags: [Educational Content]
 *     parameters:
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
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Filter by category
 *       - in: query
 *         name: subcategory
 *         schema:
 *           type: string
 *         description: Filter by subcategory
 *       - in: query
 *         name: difficulty_level
 *         schema:
 *           type: string
 *           enum: [beginner, intermediate, advanced]
 *         description: Filter by difficulty level
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search in title, content, and summary
 *       - in: query
 *         name: sort_by
 *         schema:
 *           type: string
 *           enum: [created_at, updated_at, title, view_count, difficulty_level]
 *         description: Sort field
 *       - in: query
 *         name: sort_order
 *         schema:
 *           type: string
 *           enum: [ASC, DESC]
 *         description: Sort order
 *     responses:
 *       200:
 *         description: List of educational content
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 content:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                       title:
 *                         type: string
 *                       content:
 *                         type: string
 *                       summary:
 *                         type: string
 *                       category:
 *                         type: string
 *                       subcategory:
 *                         type: string
 *                       difficulty_level:
 *                         type: string
 *                       view_count:
 *                         type: integer
 *                       author_first_name:
 *                         type: string
 *                       author_last_name:
 *                         type: string
 *                       created_at:
 *                         type: string
 *                         format: date-time
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     current_page:
 *                       type: integer
 *                     total_pages:
 *                       type: integer
 *                     total_items:
 *                       type: integer
 *                     items_per_page:
 *                       type: integer
 */
router.get('/', getAllContent);

/**
 * @swagger
 * /api/educational-content/categories:
 *   get:
 *     summary: Get all content categories
 *     tags: [Educational Content]
 *     responses:
 *       200:
 *         description: List of categories with content counts
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
 *                     type: object
 *                     properties:
 *                       category:
 *                         type: string
 *                       content_count:
 *                         type: integer
 *                       subcategories:
 *                         type: array
 *                         items:
 *                           type: string
 */
router.get('/categories', getCategories);

/**
 * @swagger
 * /api/educational-content/popular:
 *   get:
 *     summary: Get popular educational content
 *     tags: [Educational Content]
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         description: Number of popular items to return
 *     responses:
 *       200:
 *         description: Popular educational content
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 content:
 *                   type: array
 *                   items:
 *                     type: object
 */
router.get('/popular', getPopularContent);

/**
 * @swagger
 * /api/educational-content/analytics:
 *   get:
 *     summary: Get content analytics (Admin/Creator only)
 *     tags: [Educational Content]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Content analytics data
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 analytics:
 *                   type: object
 *                   properties:
 *                     total_content:
 *                       type: integer
 *                     published_content:
 *                       type: integer
 *                     total_views:
 *                       type: integer
 *                     content_by_category:
 *                       type: array
 *                     most_viewed:
 *                       type: array
 *                     recent_content:
 *                       type: array
 *       403:
 *         description: Not authorized
 */
router.get('/analytics', protect, authorize('admin', 'content-creator'), getContentAnalytics);

/**
 * @swagger
 * /api/educational-content/category/{category}:
 *   get:
 *     summary: Get content by category
 *     tags: [Educational Content]
 *     parameters:
 *       - in: path
 *         name: category
 *         required: true
 *         schema:
 *           type: string
 *         description: Category name
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
 *         description: Content filtered by category
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 category:
 *                   type: string
 *                 content:
 *                   type: array
 *                   items:
 *                     type: object
 *                 pagination:
 *                   type: object
 */
router.get('/category/:category', getContentByCategory);

/**
 * @swagger
 * /api/educational-content/{id}:
 *   get:
 *     summary: Get educational content by ID
 *     tags: [Educational Content]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Content ID
 *     responses:
 *       200:
 *         description: Educational content details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 content:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *                     title:
 *                       type: string
 *                     content:
 *                       type: string
 *                     summary:
 *                       type: string
 *                     category:
 *                       type: string
 *                     subcategory:
 *                       type: string
 *                     difficulty_level:
 *                       type: string
 *                     view_count:
 *                       type: integer
 *                     author_first_name:
 *                       type: string
 *                     author_last_name:
 *                       type: string
 *                     created_at:
 *                       type: string
 *                       format: date-time
 *       404:
 *         description: Content not found
 */
router.get('/:id', getContentById);

/**
 * @swagger
 * /api/educational-content:
 *   post:
 *     summary: Add new educational content
 *     tags: [Educational Content]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - content
 *               - category
 *             properties:
 *               title:
 *                 type: string
 *               content:
 *                 type: string
 *               summary:
 *                 type: string
 *               category:
 *                 type: string
 *               subcategory:
 *                 type: string
 *               difficulty_level:
 *                 type: string
 *                 enum: [beginner, intermediate, advanced]
 *               image_url:
 *                 type: string
 *                 format: uri
 *               video_url:
 *                 type: string
 *                 format: uri
 *               tags:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       201:
 *         description: Content created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 content:
 *                   type: object
 *       400:
 *         description: Validation error
 *       401:
 *         description: Not authorized
 *       403:
 *         description: Access denied
 */
router.post('/', protect, authorize('admin', 'content-creator'), contentValidationRules, addContent);

/**
 * @swagger
 * /api/educational-content/{id}:
 *   put:
 *     summary: Update educational content
 *     tags: [Educational Content]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Content ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               content:
 *                 type: string
 *               summary:
 *                 type: string
 *               category:
 *                 type: string
 *               subcategory:
 *                 type: string
 *               difficulty_level:
 *                 type: string
 *                 enum: [beginner, intermediate, advanced]
 *               image_url:
 *                 type: string
 *                 format: uri
 *               video_url:
 *                 type: string
 *                 format: uri
 *               tags:
 *                 type: array
 *                 items:
 *                   type: string
 *               is_published:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Content updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 content:
 *                   type: object
 *       401:
 *         description: Not authorized
 *       403:
 *         description: Access denied
 *       404:
 *         description: Content not found
 */
router.put('/:id', protect, contentValidationRules, updateContent);

/**
 * @swagger
 * /api/educational-content/{id}:
 *   delete:
 *     summary: Delete educational content
 *     tags: [Educational Content]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Content ID
 *     responses:
 *       200:
 *         description: Content deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *       401:
 *         description: Not authorized
 *       403:
 *         description: Access denied
 *       404:
 *         description: Content not found
 */
router.delete('/:id', protect, deleteContent);

module.exports = router;
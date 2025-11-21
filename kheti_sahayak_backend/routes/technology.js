/**
 * Technology Routes
 *
 * New Technology Adoption Hub API (Epic #396)
 */

const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const {
  getCategories,
  createCategory,
  getTechnologies,
  getTechnologyById,
  createTechnology,
  calculateROI,
  getCourses,
  getCourseById,
  enrollInCourse,
  updateCourseProgress,
  getMyCourses,
  shareExperience,
  getTechnologyExperiences,
  requestDemo,
  getMyDemoRequests
} = require('../controllers/technologyController');

/**
 * @swagger
 * components:
 *   schemas:
 *     TechnologyCategory:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         name:
 *           type: string
 *         name_hi:
 *           type: string
 *         description:
 *           type: string
 *         icon:
 *           type: string
 *         technology_count:
 *           type: integer
 *     Technology:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         name:
 *           type: string
 *         name_hi:
 *           type: string
 *         slug:
 *           type: string
 *         description:
 *           type: string
 *         difficulty_level:
 *           type: string
 *           enum: [easy, medium, hard, expert]
 *         implementation_cost_min:
 *           type: number
 *         implementation_cost_max:
 *           type: number
 *         expected_roi_percent:
 *           type: number
 *         average_rating:
 *           type: number
 *         adoption_count:
 *           type: integer
 *     Course:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         title:
 *           type: string
 *         title_hi:
 *           type: string
 *         description:
 *           type: string
 *         duration_minutes:
 *           type: integer
 *         difficulty_level:
 *           type: string
 *           enum: [beginner, intermediate, advanced]
 *         is_free:
 *           type: boolean
 *         average_rating:
 *           type: number
 *         enrollment_count:
 *           type: integer
 */

/**
 * @swagger
 * tags:
 *   name: Technology
 *   description: New technology adoption hub
 */

/**
 * @swagger
 * /api/technology/categories:
 *   get:
 *     summary: Get all technology categories
 *     tags: [Technology]
 *     responses:
 *       200:
 *         description: List of technology categories
 */
router.get('/categories', getCategories);

/**
 * @swagger
 * /api/technology/categories:
 *   post:
 *     summary: Create technology category (Admin only)
 *     tags: [Technology]
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
 *             properties:
 *               name:
 *                 type: string
 *               name_hi:
 *                 type: string
 *               description:
 *                 type: string
 *               icon:
 *                 type: string
 *               display_order:
 *                 type: integer
 *     responses:
 *       201:
 *         description: Category created
 */
router.post('/categories', protect, authorize('admin'), createCategory);

/**
 * @swagger
 * /api/technology/list:
 *   get:
 *     summary: Get technologies with filters
 *     tags: [Technology]
 *     parameters:
 *       - in: query
 *         name: category_id
 *         schema:
 *           type: string
 *       - in: query
 *         name: difficulty_level
 *         schema:
 *           type: string
 *           enum: [easy, medium, hard, expert]
 *       - in: query
 *         name: min_cost
 *         schema:
 *           type: number
 *       - in: query
 *         name: max_cost
 *         schema:
 *           type: number
 *       - in: query
 *         name: is_featured
 *         schema:
 *           type: boolean
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: List of technologies
 */
router.get('/list', getTechnologies);

/**
 * @swagger
 * /api/technology/{id}:
 *   get:
 *     summary: Get technology by ID or slug
 *     tags: [Technology]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Technology ID (UUID) or slug
 *     responses:
 *       200:
 *         description: Technology details with courses and experiences
 *       404:
 *         description: Technology not found
 */
router.get('/:id', getTechnologyById);

/**
 * @swagger
 * /api/technology:
 *   post:
 *     summary: Create new technology (Admin only)
 *     tags: [Technology]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - category_id
 *               - name
 *             properties:
 *               category_id:
 *                 type: string
 *                 format: uuid
 *               name:
 *                 type: string
 *               name_hi:
 *                 type: string
 *               slug:
 *                 type: string
 *               description:
 *                 type: string
 *               difficulty_level:
 *                 type: string
 *               implementation_cost_min:
 *                 type: number
 *               implementation_cost_max:
 *                 type: number
 *               expected_roi_percent:
 *                 type: number
 *               benefits:
 *                 type: array
 *                 items:
 *                   type: string
 *               suitable_crops:
 *                 type: array
 *                 items:
 *                   type: string
 *               implementation_steps:
 *                 type: array
 *                 items:
 *                   type: object
 *               government_subsidies:
 *                 type: array
 *                 items:
 *                   type: object
 *     responses:
 *       201:
 *         description: Technology created
 */
router.post('/', protect, authorize('admin'), createTechnology);

/**
 * @swagger
 * /api/technology/roi/calculate:
 *   post:
 *     summary: Calculate ROI for technology adoption
 *     tags: [Technology]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - technology_id
 *             properties:
 *               technology_id:
 *                 type: string
 *                 format: uuid
 *               farm_size_acres:
 *                 type: number
 *               current_yield:
 *                 type: number
 *               current_income:
 *                 type: number
 *               implementation_cost:
 *                 type: number
 *     responses:
 *       200:
 *         description: ROI calculation results
 */
router.post('/roi/calculate', calculateROI);

/**
 * @swagger
 * /api/technology/courses:
 *   get:
 *     summary: Get courses list
 *     tags: [Technology]
 *     parameters:
 *       - in: query
 *         name: technology_id
 *         schema:
 *           type: string
 *       - in: query
 *         name: difficulty_level
 *         schema:
 *           type: string
 *           enum: [beginner, intermediate, advanced]
 *       - in: query
 *         name: is_free
 *         schema:
 *           type: boolean
 *       - in: query
 *         name: language
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: List of courses
 */
router.get('/courses', getCourses);

/**
 * @swagger
 * /api/technology/courses/{id}:
 *   get:
 *     summary: Get course details with modules and lessons
 *     tags: [Technology]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Course details
 *       404:
 *         description: Course not found
 */
router.get('/courses/:id', getCourseById);

/**
 * @swagger
 * /api/technology/courses/enroll:
 *   post:
 *     summary: Enroll in a course
 *     tags: [Technology]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - course_id
 *             properties:
 *               course_id:
 *                 type: string
 *                 format: uuid
 *     responses:
 *       201:
 *         description: Enrollment successful
 *       400:
 *         description: Already enrolled
 */
router.post('/courses/enroll', protect, enrollInCourse);

/**
 * @swagger
 * /api/technology/courses/progress:
 *   put:
 *     summary: Update course progress
 *     tags: [Technology]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - course_id
 *               - lesson_id
 *             properties:
 *               course_id:
 *                 type: string
 *                 format: uuid
 *               lesson_id:
 *                 type: string
 *                 format: uuid
 *     responses:
 *       200:
 *         description: Progress updated
 */
router.put('/courses/progress', protect, updateCourseProgress);

/**
 * @swagger
 * /api/technology/courses/my:
 *   get:
 *     summary: Get user's enrolled courses
 *     tags: [Technology]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [enrolled, in_progress, completed, dropped]
 *     responses:
 *       200:
 *         description: User's enrolled courses
 */
router.get('/courses/my', protect, getMyCourses);

/**
 * @swagger
 * /api/technology/experiences:
 *   post:
 *     summary: Share technology adoption experience
 *     tags: [Technology]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - technology_id
 *               - title
 *               - experience_text
 *               - rating
 *             properties:
 *               technology_id:
 *                 type: string
 *                 format: uuid
 *               title:
 *                 type: string
 *               experience_text:
 *                 type: string
 *               implementation_cost:
 *                 type: number
 *               roi_achieved_percent:
 *                 type: number
 *               time_to_implement_days:
 *                 type: integer
 *               farm_size_acres:
 *                 type: number
 *               crop_type:
 *                 type: string
 *               rating:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *               would_recommend:
 *                 type: boolean
 *               images:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       201:
 *         description: Experience shared
 */
router.post('/experiences', protect, shareExperience);

/**
 * @swagger
 * /api/technology/experiences/{technology_id}:
 *   get:
 *     summary: Get experiences for a technology
 *     tags: [Technology]
 *     parameters:
 *       - in: path
 *         name: technology_id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Technology experiences
 */
router.get('/experiences/:technology_id', getTechnologyExperiences);

/**
 * @swagger
 * /api/technology/demo/request:
 *   post:
 *     summary: Request technology demo
 *     tags: [Technology]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - technology_id
 *             properties:
 *               technology_id:
 *                 type: string
 *                 format: uuid
 *               preferred_date:
 *                 type: string
 *                 format: date
 *               preferred_time:
 *                 type: string
 *               location:
 *                 type: string
 *               farm_size_acres:
 *                 type: number
 *               current_crops:
 *                 type: string
 *               contact_phone:
 *                 type: string
 *               notes:
 *                 type: string
 *     responses:
 *       201:
 *         description: Demo request submitted
 */
router.post('/demo/request', protect, requestDemo);

/**
 * @swagger
 * /api/technology/demo/my:
 *   get:
 *     summary: Get user's demo requests
 *     tags: [Technology]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User's demo requests
 */
router.get('/demo/my', protect, getMyDemoRequests);

module.exports = router;

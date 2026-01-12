const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const {
    schemeQueryValidation,
    eligibilityProfileValidation,
    validateIdParam,
    handleValidationErrors
} = require('../middleware/validationMiddleware');
const {
    getSchemes,
    getSchemeById,
    checkEligibility,
    getEligibleSchemes,
    subscribeToScheme,
    unsubscribeFromScheme,
    getUserSubscriptions,
    getUpcomingDeadlines,
    saveEligibilityProfile,
    getEligibilityProfile,
    getSchemesByRegion,
    getSchemeNotifications,
    markNotificationRead,
    getSchemeCategories,
    triggerDeadlineNotifications
} = require('../controllers/schemeController');

/**
 * @swagger
 * tags:
 *   name: Schemes
 *   description: Government agricultural schemes and eligibility management
 */

/**
 * @swagger
 * /api/schemes:
 *   get:
 *     summary: Get all government schemes with filtering
 *     tags: [Schemes]
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Filter by scheme category (subsidy, loan, insurance, training)
 *       - in: query
 *         name: scheme_type
 *         schema:
 *           type: string
 *         description: Filter by type (Central, State)
 *       - in: query
 *         name: state
 *         schema:
 *           type: string
 *         description: Filter by applicable state
 *       - in: query
 *         name: district
 *         schema:
 *           type: string
 *         description: Filter by applicable district
 *       - in: query
 *         name: crop
 *         schema:
 *           type: string
 *         description: Filter by supported crop
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search in scheme name and description
 *       - in: query
 *         name: is_featured
 *         schema:
 *           type: boolean
 *         description: Filter featured schemes
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *     responses:
 *       200:
 *         description: List of schemes with pagination
 */
router.get('/', schemeQueryValidation, getSchemes);

/**
 * @swagger
 * /api/schemes/categories:
 *   get:
 *     summary: Get available scheme categories and types
 *     tags: [Schemes]
 *     responses:
 *       200:
 *         description: List of categories and farmer types
 */
router.get('/categories', getSchemeCategories);

/**
 * @swagger
 * /api/schemes/deadlines:
 *   get:
 *     summary: Get schemes with upcoming deadlines
 *     tags: [Schemes]
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Number of days ahead to check
 *     responses:
 *       200:
 *         description: List of schemes with upcoming deadlines
 */
router.get('/deadlines', getUpcomingDeadlines);

/**
 * @swagger
 * /api/schemes/region:
 *   get:
 *     summary: Get schemes by state/region
 *     tags: [Schemes]
 *     parameters:
 *       - in: query
 *         name: state
 *         required: true
 *         schema:
 *           type: string
 *         description: State name (e.g., Maharashtra, Punjab)
 *       - in: query
 *         name: district
 *         schema:
 *           type: string
 *         description: Optional district name
 *     responses:
 *       200:
 *         description: List of schemes for the region
 */
router.get('/region', getSchemesByRegion);

/**
 * @swagger
 * /api/schemes/eligible:
 *   get:
 *     summary: Get schemes user is eligible for based on their profile
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of eligible schemes
 *       401:
 *         description: Not authorized
 */
router.get('/eligible', protect, getEligibleSchemes);

/**
 * @swagger
 * /api/schemes/subscriptions:
 *   get:
 *     summary: Get user's scheme subscriptions
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of subscribed schemes
 */
router.get('/subscriptions', protect, getUserSubscriptions);

/**
 * @swagger
 * /api/schemes/subscriptions:
 *   post:
 *     summary: Subscribe to scheme notifications
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - scheme_id
 *             properties:
 *               scheme_id:
 *                 type: integer
 *               notification_preferences:
 *                 type: object
 *                 properties:
 *                   email:
 *                     type: boolean
 *                   push:
 *                     type: boolean
 *                   sms:
 *                     type: boolean
 *     responses:
 *       200:
 *         description: Subscription created
 */
router.post('/subscriptions', protect, subscribeToScheme);

/**
 * @swagger
 * /api/schemes/subscriptions/{scheme_id}:
 *   delete:
 *     summary: Unsubscribe from scheme notifications
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: scheme_id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Unsubscribed successfully
 */
router.delete('/subscriptions/:scheme_id', protect, unsubscribeFromScheme);

/**
 * @swagger
 * /api/schemes/profile:
 *   get:
 *     summary: Get user's eligibility profile
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User eligibility profile
 */
router.get('/profile', protect, getEligibilityProfile);

/**
 * @swagger
 * /api/schemes/profile:
 *   post:
 *     summary: Save/update user's eligibility profile
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               farm_size_hectares:
 *                 type: number
 *               annual_income:
 *                 type: number
 *               land_ownership_type:
 *                 type: string
 *                 enum: [owner, tenant, sharecropper, lease]
 *               primary_crops:
 *                 type: array
 *                 items:
 *                   type: string
 *               state:
 *                 type: string
 *               district:
 *                 type: string
 *               has_bank_account:
 *                 type: boolean
 *               has_aadhar:
 *                 type: boolean
 *               has_kcc:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Profile saved successfully
 */
router.post('/profile', protect, eligibilityProfileValidation, saveEligibilityProfile);

/**
 * @swagger
 * /api/schemes/notifications:
 *   get:
 *     summary: Get user's scheme notifications
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: unread
 *         schema:
 *           type: boolean
 *         description: Filter unread notifications only
 *     responses:
 *       200:
 *         description: List of scheme notifications
 */
router.get('/notifications', protect, getSchemeNotifications);

/**
 * @swagger
 * /api/schemes/notifications/{id}/read:
 *   put:
 *     summary: Mark scheme notification as read
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Notification marked as read
 */
router.put('/notifications/:id/read', protect, markNotificationRead);

/**
 * @swagger
 * /api/schemes/notifications/trigger:
 *   post:
 *     summary: Trigger deadline notifications (Admin only)
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Notifications sent
 */
router.post('/notifications/trigger', protect, authorize('admin'), triggerDeadlineNotifications);

/**
 * @swagger
 * /api/schemes/{id}:
 *   get:
 *     summary: Get scheme details by ID
 *     tags: [Schemes]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Scheme details
 *       404:
 *         description: Scheme not found
 */
router.get('/:id', validateIdParam, getSchemeById);

/**
 * @swagger
 * /api/schemes/{id}/eligibility:
 *   get:
 *     summary: Check user eligibility for a specific scheme
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Eligibility check result with criteria breakdown
 */
router.get('/:id/eligibility', protect, validateIdParam, checkEligibility);

module.exports = router;

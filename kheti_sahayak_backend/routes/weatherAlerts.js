const express = require('express');
const { body } = require('express-validator');
const { protect, authorize } = require('../middleware/authMiddleware');
const {
  getAlertPreferences,
  updateAlertPreferences,
  getLocationSubscriptions,
  createLocationSubscription,
  updateLocationSubscription,
  deleteLocationSubscription,
  getAlertHistory,
  markAlertRead,
  dismissAlert,
  checkAlertsNow,
  getAvailableAlertTypes,
  triggerAlertCheck,
  sendTestAlert
} = require('../controllers/weatherAlertController');

const router = express.Router();

const preferencesValidation = [
  body('enabled_alerts').optional().isArray(),
  body('notification_channels').optional().isArray(),
  body('min_severity').optional().isIn(['low', 'moderate', 'high', 'severe', 'extreme']),
  body('sms_enabled').optional().isBoolean(),
  body('sms_critical_only').optional().isBoolean(),
  body('sms_phone').optional().isMobilePhone(),
  body('language').optional().isIn(['en', 'hi']),
  body('daily_limit').optional().isInt({ min: 0, max: 100 })
];

const subscriptionValidation = [
  body('lat').isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
  body('lon').isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude'),
  body('location_name').optional().trim().isLength({ max: 200 }),
  body('alert_types').optional().isArray(),
  body('is_primary').optional().isBoolean()
];

/**
 * @swagger
 * /api/weather-alerts/types:
 *   get:
 *     summary: Get available weather alert types
 *     tags: [Weather Alerts]
 *     responses:
 *       200:
 *         description: List of available alert types
 */
router.get('/types', getAvailableAlertTypes);

/**
 * @swagger
 * /api/weather-alerts/check:
 *   get:
 *     summary: Check current alerts for a location
 *     tags: [Weather Alerts]
 *     parameters:
 *       - in: query
 *         name: lat
 *         required: true
 *         schema:
 *           type: number
 *       - in: query
 *         name: lon
 *         required: true
 *         schema:
 *           type: number
 *     responses:
 *       200:
 *         description: Current weather alerts
 */
router.get('/check', checkAlertsNow);

router.use(protect);

/**
 * @swagger
 * /api/weather-alerts/preferences:
 *   get:
 *     summary: Get user's alert preferences
 *     tags: [Weather Alerts]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User's alert preferences
 */
router.get('/preferences', getAlertPreferences);

/**
 * @swagger
 * /api/weather-alerts/preferences:
 *   put:
 *     summary: Update user's alert preferences
 *     tags: [Weather Alerts]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               enabled_alerts:
 *                 type: array
 *                 items:
 *                   type: string
 *                   enum: [heat_wave, heavy_rain, frost, storm, drought, hail, fog, cold_wave, flood_warning]
 *               notification_channels:
 *                 type: array
 *                 items:
 *                   type: string
 *                   enum: [push, sms, email, in_app]
 *               min_severity:
 *                 type: string
 *                 enum: [low, moderate, high, severe, extreme]
 *               sms_enabled:
 *                 type: boolean
 *               sms_critical_only:
 *                 type: boolean
 *               sms_phone:
 *                 type: string
 *               language:
 *                 type: string
 *                 enum: [en, hi]
 *               daily_limit:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Updated preferences
 */
router.put('/preferences', preferencesValidation, updateAlertPreferences);

/**
 * @swagger
 * /api/weather-alerts/subscriptions:
 *   get:
 *     summary: Get user's location subscriptions
 *     tags: [Weather Alerts]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of location subscriptions
 */
router.get('/subscriptions', getLocationSubscriptions);

/**
 * @swagger
 * /api/weather-alerts/subscriptions:
 *   post:
 *     summary: Subscribe to alerts for a location
 *     tags: [Weather Alerts]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - lat
 *               - lon
 *             properties:
 *               lat:
 *                 type: number
 *               lon:
 *                 type: number
 *               location_name:
 *                 type: string
 *               alert_types:
 *                 type: array
 *                 items:
 *                   type: string
 *               is_primary:
 *                 type: boolean
 *     responses:
 *       201:
 *         description: Subscription created
 */
router.post('/subscriptions', subscriptionValidation, createLocationSubscription);

/**
 * @swagger
 * /api/weather-alerts/subscriptions/{id}:
 *   put:
 *     summary: Update a location subscription
 *     tags: [Weather Alerts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Subscription updated
 */
router.put('/subscriptions/:id', updateLocationSubscription);

/**
 * @swagger
 * /api/weather-alerts/subscriptions/{id}:
 *   delete:
 *     summary: Delete a location subscription
 *     tags: [Weather Alerts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Subscription deleted
 */
router.delete('/subscriptions/:id', deleteLocationSubscription);

/**
 * @swagger
 * /api/weather-alerts/history:
 *   get:
 *     summary: Get user's alert history
 *     tags: [Weather Alerts]
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
 *           default: 20
 *       - in: query
 *         name: alert_type
 *         schema:
 *           type: string
 *       - in: query
 *         name: is_read
 *         schema:
 *           type: boolean
 *       - in: query
 *         name: severity
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Alert history with pagination
 */
router.get('/history', getAlertHistory);

/**
 * @swagger
 * /api/weather-alerts/history/{id}/read:
 *   put:
 *     summary: Mark an alert as read
 *     tags: [Weather Alerts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Alert marked as read
 */
router.put('/history/:id/read', markAlertRead);

/**
 * @swagger
 * /api/weather-alerts/history/{id}/dismiss:
 *   put:
 *     summary: Dismiss an alert
 *     tags: [Weather Alerts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Alert dismissed
 */
router.put('/history/:id/dismiss', dismissAlert);

/**
 * @swagger
 * /api/weather-alerts/test:
 *   post:
 *     summary: Send a test alert to yourself
 *     tags: [Weather Alerts]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               alert_type:
 *                 type: string
 *                 default: heat_wave
 *               severity:
 *                 type: string
 *                 default: moderate
 *     responses:
 *       200:
 *         description: Test alert sent
 */
router.post('/test', sendTestAlert);

/**
 * @swagger
 * /api/weather-alerts/trigger-check:
 *   post:
 *     summary: Trigger alert check for all subscriptions (Admin only)
 *     tags: [Weather Alerts]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Alert check results
 */
router.post('/trigger-check', authorize('admin'), triggerAlertCheck);

module.exports = router;

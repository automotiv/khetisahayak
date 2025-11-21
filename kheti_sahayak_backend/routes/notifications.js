const express = require('express');
const { body } = require('express-validator');
const {
  getUserNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  deleteNotification,
  getNotificationStats,
  createNotification,
  createBulkNotifications,
  // FCM endpoints
  registerDevice,
  unregisterDevice,
  subscribeToTopic,
  unsubscribeFromTopic,
  getSubscriptions,
  sendTestNotification,
  sendPushNotification,
  sendToTopic
} = require('../controllers/notificationController');
const { protect, authorize } = require('../middleware/authMiddleware');

const router = express.Router();

// Validation rules for notification creation
const notificationValidationRules = [
  body('user_id', 'User ID is required').isUUID(),
  body('title', 'Title is required').not().isEmpty().trim().escape(),
  body('message', 'Message is required').not().isEmpty().trim(),
  body('type', 'Type must be info, warning, error, or success').optional().isIn(['info', 'warning', 'error', 'success']),
];

// Validation rules for bulk notification creation
const bulkNotificationValidationRules = [
  body('notifications', 'Notifications must be an array').isArray({ min: 1 }),
  body('notifications.*.user_id', 'User ID is required for each notification').isUUID(),
  body('notifications.*.title', 'Title is required for each notification').not().isEmpty().trim().escape(),
  body('notifications.*.message', 'Message is required for each notification').not().isEmpty().trim(),
  body('notifications.*.type', 'Type must be info, warning, error, or success').optional().isIn(['info', 'warning', 'error', 'success']),
];

// All routes are protected
router.use(protect);

// User notification routes
router.get('/', getUserNotifications);
router.get('/stats', getNotificationStats);
router.put('/:id/read', markNotificationAsRead);
router.put('/read-all', markAllNotificationsAsRead);
router.delete('/:id', deleteNotification);

// Admin routes
router.post('/', authorize('admin'), notificationValidationRules, createNotification);
router.post('/bulk', authorize('admin'), bulkNotificationValidationRules, createBulkNotifications);

// ===== FCM Push Notification Routes =====

// Device registration validation
const deviceValidationRules = [
  body('token', 'FCM token is required').notEmpty(),
  body('platform', 'Platform must be android, ios, or web').isIn(['android', 'ios', 'web'])
];

// Topic subscription validation
const topicValidationRules = [
  body('token', 'FCM token is required').notEmpty(),
  body('topic', 'Topic name is required').notEmpty().trim()
];

/**
 * @swagger
 * /api/notifications/register-device:
 *   post:
 *     summary: Register device for push notifications
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - token
 *               - platform
 *             properties:
 *               token:
 *                 type: string
 *                 description: FCM device token
 *               platform:
 *                 type: string
 *                 enum: [android, ios, web]
 *               device_name:
 *                 type: string
 *               app_version:
 *                 type: string
 *     responses:
 *       200:
 *         description: Device registered successfully
 */
router.post('/register-device', deviceValidationRules, registerDevice);

/**
 * @swagger
 * /api/notifications/unregister-device:
 *   delete:
 *     summary: Unregister device from push notifications
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - token
 *             properties:
 *               token:
 *                 type: string
 *     responses:
 *       200:
 *         description: Device unregistered successfully
 */
router.delete('/unregister-device', unregisterDevice);

/**
 * @swagger
 * /api/notifications/subscribe:
 *   post:
 *     summary: Subscribe to notification topic
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - token
 *               - topic
 *             properties:
 *               token:
 *                 type: string
 *               topic:
 *                 type: string
 *                 description: Topic name (e.g., weather-alerts, crop-tips)
 *     responses:
 *       200:
 *         description: Subscribed successfully
 */
router.post('/subscribe', topicValidationRules, subscribeToTopic);

/**
 * @swagger
 * /api/notifications/unsubscribe:
 *   delete:
 *     summary: Unsubscribe from notification topic
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.delete('/unsubscribe', topicValidationRules, unsubscribeFromTopic);

/**
 * @swagger
 * /api/notifications/subscriptions:
 *   get:
 *     summary: Get user's topic subscriptions
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of subscribed topics
 */
router.get('/subscriptions', getSubscriptions);

/**
 * @swagger
 * /api/notifications/send-test:
 *   post:
 *     summary: Send test push notification to device
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.post('/send-test', sendTestNotification);

// Admin-only push notification routes
/**
 * @swagger
 * /api/notifications/send-push:
 *   post:
 *     summary: Send push notification to user (Admin only)
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.post('/send-push', authorize('admin'), sendPushNotification);

/**
 * @swagger
 * /api/notifications/send-to-topic:
 *   post:
 *     summary: Send push notification to topic subscribers (Admin only)
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.post('/send-to-topic', authorize('admin'), sendToTopic);

module.exports = router; 
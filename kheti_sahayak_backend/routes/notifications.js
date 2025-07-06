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

module.exports = router; 
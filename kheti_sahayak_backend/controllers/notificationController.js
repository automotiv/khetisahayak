const db = require('../db');
const asyncHandler = require('express-async-handler');
const pushNotificationService = require('../services/pushNotificationService');

// @desc    Get user's notifications
// @route   GET /api/notifications
// @access  Private
const getUserNotifications = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, is_read } = req.query;

  let query = 'SELECT * FROM notifications WHERE user_id = $1';
  const queryParams = [req.user.id];
  let paramCount = 1;

  if (is_read !== undefined) {
    paramCount++;
    query += ` AND is_read = $${paramCount}`;
    queryParams.push(is_read === 'true');
  }

  query += ' ORDER BY created_at DESC';

  // Add pagination
  const offset = (page - 1) * limit;
  paramCount++;
  query += ` LIMIT $${paramCount}`;
  queryParams.push(parseInt(limit));
  
  paramCount++;
  query += ` OFFSET $${paramCount}`;
  queryParams.push(offset);

  const result = await db.query(query, queryParams);

  // Get total count
  let countQuery = 'SELECT COUNT(*) FROM notifications WHERE user_id = $1';
  const countParams = [req.user.id];

  if (is_read !== undefined) {
    countQuery += ' AND is_read = $2';
    countParams.push(is_read === 'true');
  }

  const countResult = await db.query(countQuery, countParams);
  const totalCount = parseInt(countResult.rows[0].count);

  // Get unread count
  const unreadResult = await db.query(
    'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false',
    [req.user.id]
  );
  const unreadCount = parseInt(unreadResult.rows[0].count);

  res.json({
    notifications: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(totalCount / limit),
      total_items: totalCount,
      items_per_page: parseInt(limit)
    },
    unread_count: unreadCount
  });
});

// @desc    Mark notification as read
// @route   PUT /api/notifications/:id/read
// @access  Private
const markNotificationAsRead = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2 RETURNING *',
    [id, req.user.id]
  );

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Notification not found');
  }

  res.json({
    message: 'Notification marked as read',
    notification: result.rows[0]
  });
});

// @desc    Mark all notifications as read
// @route   PUT /api/notifications/read-all
// @access  Private
const markAllNotificationsAsRead = asyncHandler(async (req, res) => {
  const result = await db.query(
    'UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false RETURNING COUNT(*)',
    [req.user.id]
  );

  const updatedCount = parseInt(result.rows[0].count);

  res.json({
    message: `Marked ${updatedCount} notifications as read`,
    updated_count: updatedCount
  });
});

// @desc    Delete notification
// @route   DELETE /api/notifications/:id
// @access  Private
const deleteNotification = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    'DELETE FROM notifications WHERE id = $1 AND user_id = $2 RETURNING id',
    [id, req.user.id]
  );

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Notification not found');
  }

  res.json({
    message: 'Notification deleted successfully'
  });
});

// @desc    Get notification statistics
// @route   GET /api/notifications/stats
// @access  Private
const getNotificationStats = asyncHandler(async (req, res) => {
  const statsResult = await db.query(
    `SELECT 
       COUNT(*) as total_notifications,
       COUNT(CASE WHEN is_read = false THEN 1 END) as unread_notifications,
       COUNT(CASE WHEN type = 'info' THEN 1 END) as info_count,
       COUNT(CASE WHEN type = 'warning' THEN 1 END) as warning_count,
       COUNT(CASE WHEN type = 'error' THEN 1 END) as error_count,
       COUNT(CASE WHEN type = 'success' THEN 1 END) as success_count
     FROM notifications 
     WHERE user_id = $1`,
    [req.user.id]
  );

  res.json(statsResult.rows[0]);
});

// @desc    Create notification (Admin/System use)
// @route   POST /api/notifications
// @access  Private/Admin
const createNotification = asyncHandler(async (req, res) => {
  const { user_id, title, message, type, related_entity_type, related_entity_id } = req.body;

  if (!user_id || !title || !message) {
    res.status(400);
    throw new Error('User ID, title, and message are required');
  }

  const result = await db.query(
    `INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
    [user_id, title, message, type || 'info', related_entity_type, related_entity_id]
  );

  res.status(201).json({
    message: 'Notification created successfully',
    notification: result.rows[0]
  });
});

// @desc    Create bulk notifications (Admin/System use)
// @route   POST /api/notifications/bulk
// @access  Private/Admin
const createBulkNotifications = asyncHandler(async (req, res) => {
  const { notifications } = req.body;

  if (!notifications || !Array.isArray(notifications)) {
    res.status(400);
    throw new Error('Notifications array is required');
  }

  const client = await db.pool.connect();
  
  try {
    await client.query('BEGIN');

    const createdNotifications = [];

    for (const notification of notifications) {
      const { user_id, title, message, type, related_entity_type, related_entity_id } = notification;

      if (!user_id || !title || !message) {
        throw new Error('User ID, title, and message are required for each notification');
      }

      const result = await client.query(
        `INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
        [user_id, title, message, type || 'info', related_entity_type, related_entity_id]
      );

      createdNotifications.push(result.rows[0]);
    }

    await client.query('COMMIT');

    res.status(201).json({
      message: `${createdNotifications.length} notifications created successfully`,
      notifications: createdNotifications
    });

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

// @desc    Register device for push notifications
// @route   POST /api/notifications/register-device
// @access  Private
const registerDevice = asyncHandler(async (req, res) => {
  const { token, platform, device_name, app_version } = req.body;

  if (!token || !platform) {
    res.status(400);
    throw new Error('Token and platform are required');
  }

  if (!['android', 'ios', 'web'].includes(platform)) {
    res.status(400);
    throw new Error('Platform must be android, ios, or web');
  }

  // Upsert device token
  const result = await db.query(
    `INSERT INTO device_tokens (user_id, token, platform, device_name, app_version, is_active, last_used_at)
     VALUES ($1, $2, $3, $4, $5, true, CURRENT_TIMESTAMP)
     ON CONFLICT (user_id, token)
     DO UPDATE SET
       platform = EXCLUDED.platform,
       device_name = EXCLUDED.device_name,
       app_version = EXCLUDED.app_version,
       is_active = true,
       last_used_at = CURRENT_TIMESTAMP,
       updated_at = CURRENT_TIMESTAMP
     RETURNING id`,
    [req.user.id, token, platform, device_name, app_version]
  );

  res.json({
    success: true,
    message: 'Device registered successfully',
    device_id: result.rows[0].id
  });
});

// @desc    Unregister device from push notifications
// @route   DELETE /api/notifications/unregister-device
// @access  Private
const unregisterDevice = asyncHandler(async (req, res) => {
  const { token } = req.body;

  if (!token) {
    res.status(400);
    throw new Error('Token is required');
  }

  await db.query(
    'UPDATE device_tokens SET is_active = false WHERE user_id = $1 AND token = $2',
    [req.user.id, token]
  );

  res.json({
    success: true,
    message: 'Device unregistered successfully'
  });
});

// @desc    Subscribe to notification topic
// @route   POST /api/notifications/subscribe
// @access  Private
const subscribeToTopic = asyncHandler(async (req, res) => {
  const { token, topic } = req.body;

  if (!token || !topic) {
    res.status(400);
    throw new Error('Token and topic are required');
  }

  // Subscribe via FCM
  const fcmResult = await pushNotificationService.subscribeToTopic(token, topic);

  if (!fcmResult.success && !fcmResult.mock) {
    res.status(500);
    throw new Error('Failed to subscribe to topic');
  }

  // Store subscription in database
  await db.query(
    `INSERT INTO notification_topics (user_id, topic)
     VALUES ($1, $2)
     ON CONFLICT (user_id, topic) DO NOTHING`,
    [req.user.id, topic]
  );

  res.json({
    success: true,
    message: `Subscribed to topic: ${topic}`
  });
});

// @desc    Unsubscribe from notification topic
// @route   DELETE /api/notifications/unsubscribe
// @access  Private
const unsubscribeFromTopic = asyncHandler(async (req, res) => {
  const { token, topic } = req.body;

  if (!token || !topic) {
    res.status(400);
    throw new Error('Token and topic are required');
  }

  // Unsubscribe via FCM
  await pushNotificationService.unsubscribeFromTopic(token, topic);

  // Remove subscription from database
  await db.query(
    'DELETE FROM notification_topics WHERE user_id = $1 AND topic = $2',
    [req.user.id, topic]
  );

  res.json({
    success: true,
    message: `Unsubscribed from topic: ${topic}`
  });
});

// @desc    Get user's topic subscriptions
// @route   GET /api/notifications/subscriptions
// @access  Private
const getSubscriptions = asyncHandler(async (req, res) => {
  const result = await db.query(
    'SELECT topic, subscribed_at FROM notification_topics WHERE user_id = $1 ORDER BY subscribed_at DESC',
    [req.user.id]
  );

  res.json({
    success: true,
    subscriptions: result.rows
  });
});

// @desc    Send test push notification
// @route   POST /api/notifications/send-test
// @access  Private
const sendTestNotification = asyncHandler(async (req, res) => {
  const { token } = req.body;

  if (!token) {
    res.status(400);
    throw new Error('Token is required');
  }

  const result = await pushNotificationService.sendToDevice(
    token,
    'Test Notification',
    'This is a test notification from Kheti Sahayak!',
    { type: 'test', timestamp: new Date().toISOString() }
  );

  res.json({
    success: result.success,
    message: result.success ? 'Test notification sent' : 'Failed to send notification',
    messageId: result.messageId,
    mock: result.mock || false
  });
});

// @desc    Send push notification to user (Admin only)
// @route   POST /api/notifications/send-push
// @access  Private/Admin
const sendPushNotification = asyncHandler(async (req, res) => {
  const { user_id, title, body, data } = req.body;

  if (!user_id || !title || !body) {
    res.status(400);
    throw new Error('User ID, title, and body are required');
  }

  const result = await pushNotificationService.sendToUser(user_id, title, body, data || {});

  // Also store in notification history
  await db.query(
    `INSERT INTO notification_history (user_id, title, body, notification_type, data)
     VALUES ($1, $2, $3, $4, $5)`,
    [user_id, title, body, data?.type || 'general', JSON.stringify(data || {})]
  );

  res.json({
    success: result.success,
    message: result.message || (result.success ? 'Notification sent' : 'Failed to send'),
    details: result
  });
});

// @desc    Send push notification to topic (Admin only)
// @route   POST /api/notifications/send-to-topic
// @access  Private/Admin
const sendToTopic = asyncHandler(async (req, res) => {
  const { topic, title, body, data } = req.body;

  if (!topic || !title || !body) {
    res.status(400);
    throw new Error('Topic, title, and body are required');
  }

  const result = await pushNotificationService.sendToTopic(topic, title, body, data || {});

  res.json({
    success: result.success,
    message: result.success ? `Notification sent to topic: ${topic}` : 'Failed to send',
    messageId: result.messageId
  });
});

module.exports = {
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
}; 
const db = require('../db');
const asyncHandler = require('express-async-handler');

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

module.exports = {
  getUserNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  deleteNotification,
  getNotificationStats,
  createNotification,
  createBulkNotifications,
}; 
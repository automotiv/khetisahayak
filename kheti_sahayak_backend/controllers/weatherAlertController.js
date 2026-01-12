const asyncHandler = require('express-async-handler');
const weatherAlertNotificationService = require('../services/weatherAlertNotificationService');
const db = require('../db');

const getAlertPreferences = asyncHandler(async (req, res) => {
  const preferences = await weatherAlertNotificationService.getUserAlertPreferences(req.user.id);
  
  res.json({
    success: true,
    data: preferences
  });
});

const updateAlertPreferences = asyncHandler(async (req, res) => {
  const {
    enabled_alerts,
    notification_channels,
    min_severity,
    quiet_hours_start,
    quiet_hours_end,
    sms_enabled,
    sms_critical_only,
    sms_phone,
    language,
    daily_limit
  } = req.body;
  
  const validAlertTypes = ['heat_wave', 'heavy_rain', 'frost', 'storm', 'drought', 'hail', 'fog', 'cold_wave', 'flood_warning'];
  const validChannels = ['push', 'sms', 'email', 'in_app'];
  const validSeverities = ['low', 'moderate', 'high', 'severe', 'extreme'];
  
  if (enabled_alerts && !enabled_alerts.every(a => validAlertTypes.includes(a))) {
    res.status(400);
    throw new Error('Invalid alert type. Valid types: ' + validAlertTypes.join(', '));
  }
  
  if (notification_channels && !notification_channels.every(c => validChannels.includes(c))) {
    res.status(400);
    throw new Error('Invalid notification channel. Valid channels: ' + validChannels.join(', '));
  }
  
  if (min_severity && !validSeverities.includes(min_severity)) {
    res.status(400);
    throw new Error('Invalid severity level. Valid levels: ' + validSeverities.join(', '));
  }
  
  const preferences = await weatherAlertNotificationService.updateAlertPreferences(req.user.id, {
    enabled_alerts,
    notification_channels,
    min_severity,
    quiet_hours_start,
    quiet_hours_end,
    sms_enabled,
    sms_critical_only,
    sms_phone,
    language,
    daily_limit
  });
  
  res.json({
    success: true,
    message: 'Alert preferences updated successfully',
    data: preferences
  });
});

const getLocationSubscriptions = asyncHandler(async (req, res) => {
  const subscriptions = await weatherAlertNotificationService.getUserSubscriptions(req.user.id);
  
  res.json({
    success: true,
    data: {
      subscriptions,
      count: subscriptions.length
    }
  });
});

const createLocationSubscription = asyncHandler(async (req, res) => {
  const { lat, lon, location_name, alert_types, is_primary } = req.body;
  
  if (!lat || !lon) {
    res.status(400);
    throw new Error('Latitude and longitude are required');
  }
  
  if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
    res.status(400);
    throw new Error('Invalid coordinates');
  }
  
  const validAlertTypes = ['heat_wave', 'heavy_rain', 'frost', 'storm', 'drought', 'hail', 'fog', 'cold_wave', 'flood_warning'];
  if (alert_types && !alert_types.every(a => validAlertTypes.includes(a))) {
    res.status(400);
    throw new Error('Invalid alert type');
  }
  
  const subscription = await weatherAlertNotificationService.createSubscription(
    req.user.id,
    parseFloat(lat),
    parseFloat(lon),
    location_name,
    alert_types,
    is_primary || false
  );
  
  res.status(201).json({
    success: true,
    message: 'Location subscription created successfully',
    data: subscription
  });
});

const updateLocationSubscription = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { location_name, alert_types, is_primary, is_active } = req.body;
  
  const checkResult = await db.query(
    'SELECT * FROM weather_alert_subscriptions WHERE id = $1 AND user_id = $2',
    [id, req.user.id]
  );
  
  if (checkResult.rows.length === 0) {
    res.status(404);
    throw new Error('Subscription not found');
  }
  
  if (is_primary === true) {
    await db.query(
      'UPDATE weather_alert_subscriptions SET is_primary = false WHERE user_id = $1',
      [req.user.id]
    );
  }
  
  const result = await db.query(`
    UPDATE weather_alert_subscriptions 
    SET 
      location_name = COALESCE($1, location_name),
      alert_types = COALESCE($2, alert_types),
      is_primary = COALESCE($3, is_primary),
      is_active = COALESCE($4, is_active),
      updated_at = CURRENT_TIMESTAMP
    WHERE id = $5 AND user_id = $6
    RETURNING *
  `, [
    location_name,
    alert_types ? JSON.stringify(alert_types) : null,
    is_primary,
    is_active,
    id,
    req.user.id
  ]);
  
  res.json({
    success: true,
    message: 'Subscription updated successfully',
    data: result.rows[0]
  });
});

const deleteLocationSubscription = asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  const deleted = await weatherAlertNotificationService.deleteSubscription(req.user.id, id);
  
  if (!deleted) {
    res.status(404);
    throw new Error('Subscription not found');
  }
  
  res.json({
    success: true,
    message: 'Subscription deleted successfully'
  });
});

const getAlertHistory = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, alert_type, is_read, severity } = req.query;
  
  const offset = (parseInt(page) - 1) * parseInt(limit);
  
  const alerts = await weatherAlertNotificationService.getAlertHistory(req.user.id, {
    limit: parseInt(limit),
    offset,
    alertType: alert_type,
    isRead: is_read !== undefined ? is_read === 'true' : undefined,
    severity
  });
  
  const countResult = await db.query(
    'SELECT COUNT(*) FROM weather_alert_history WHERE user_id = $1',
    [req.user.id]
  );
  const totalCount = parseInt(countResult.rows[0].count);
  
  const unreadResult = await db.query(
    'SELECT COUNT(*) FROM weather_alert_history WHERE user_id = $1 AND is_read = false',
    [req.user.id]
  );
  const unreadCount = parseInt(unreadResult.rows[0].count);
  
  res.json({
    success: true,
    data: {
      alerts,
      pagination: {
        current_page: parseInt(page),
        total_pages: Math.ceil(totalCount / parseInt(limit)),
        total_items: totalCount,
        items_per_page: parseInt(limit)
      },
      unread_count: unreadCount
    }
  });
});

const markAlertRead = asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  const alert = await weatherAlertNotificationService.markAlertAsRead(req.user.id, id);
  
  if (!alert) {
    res.status(404);
    throw new Error('Alert not found');
  }
  
  res.json({
    success: true,
    message: 'Alert marked as read',
    data: alert
  });
});

const dismissAlert = asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  const alert = await weatherAlertNotificationService.dismissAlert(req.user.id, id);
  
  if (!alert) {
    res.status(404);
    throw new Error('Alert not found');
  }
  
  res.json({
    success: true,
    message: 'Alert dismissed',
    data: alert
  });
});

const checkAlertsNow = asyncHandler(async (req, res) => {
  const { lat, lon } = req.query;
  
  if (!lat || !lon) {
    res.status(400);
    throw new Error('Latitude and longitude are required');
  }
  
  const alerts = await weatherAlertNotificationService.checkAndTriggerAlerts(
    parseFloat(lat),
    parseFloat(lon)
  );
  
  res.json({
    success: true,
    data: {
      alerts,
      count: alerts.length,
      has_severe: alerts.some(a => ['severe', 'extreme', 'high'].includes(a.severity)),
      checked_at: new Date().toISOString()
    }
  });
});

const getAvailableAlertTypes = asyncHandler(async (req, res) => {
  const rules = await weatherAlertNotificationService.getAlertRules();
  
  const alertTypes = rules.map(rule => ({
    type: rule.alert_type,
    name: rule.name,
    name_hi: rule.name_hi,
    description: rule.description,
    description_hi: rule.description_hi,
    sms_enabled: rule.sms_enabled
  }));
  
  res.json({
    success: true,
    data: alertTypes
  });
});

const triggerAlertCheck = asyncHandler(async (req, res) => {
  const results = await weatherAlertNotificationService.processAllSubscriptions();
  
  res.json({
    success: true,
    message: 'Alert check completed',
    data: results
  });
});

const sendTestAlert = asyncHandler(async (req, res) => {
  const { alert_type = 'heat_wave', severity = 'moderate' } = req.body;
  
  const rules = await weatherAlertNotificationService.getAlertRules();
  const rule = rules.find(r => r.alert_type === alert_type);
  
  if (!rule) {
    res.status(400);
    throw new Error('Invalid alert type');
  }
  
  const preferences = await weatherAlertNotificationService.getUserAlertPreferences(req.user.id);
  
  const testAlert = {
    alert_type: rule.alert_type,
    severity,
    title: `[TEST] ${rule.name}`,
    title_hi: rule.name_hi ? `[परीक्षण] ${rule.name_hi}` : null,
    description: rule.description,
    description_hi: rule.description_hi,
    recommendations: rule.recommendations,
    recommendations_hi: rule.recommendations_hi,
    sms_enabled: false,
    weather_data: { temp: 42, humidity: 30, wind_speed: 10, test: true }
  };
  
  const alertId = await weatherAlertNotificationService.sendAlertToUser(
    req.user.id,
    testAlert,
    null,
    preferences
  );
  
  res.json({
    success: true,
    message: 'Test alert sent successfully',
    data: { alert_id: alertId }
  });
});

module.exports = {
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
};

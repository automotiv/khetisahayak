const axios = require('axios');
const db = require('../db');
const pushNotificationService = require('./pushNotificationService');
const smsService = require('./smsService');

const SEVERITY_LEVELS = {
  low: 1,
  moderate: 2,
  high: 3,
  severe: 4,
  extreme: 5
};

const getSeverityLevel = (severity) => SEVERITY_LEVELS[severity] || 0;

async function getAlertRules() {
  const result = await db.query(
    'SELECT * FROM weather_alert_rules WHERE is_active = true ORDER BY priority ASC'
  );
  return result.rows;
}

async function getUserAlertPreferences(userId) {
  const result = await db.query(
    'SELECT * FROM weather_alert_preferences WHERE user_id = $1 AND is_active = true',
    [userId]
  );
  
  if (result.rows.length === 0) {
    return {
      enabled_alerts: ['heat_wave', 'heavy_rain', 'frost', 'storm', 'drought'],
      notification_channels: ['push', 'in_app'],
      min_severity: 'moderate',
      sms_enabled: false,
      sms_critical_only: true,
      language: 'en',
      daily_limit: 10
    };
  }
  
  return result.rows[0];
}

async function getUserSubscriptions(userId) {
  const result = await db.query(
    'SELECT * FROM weather_alert_subscriptions WHERE user_id = $1 AND is_active = true',
    [userId]
  );
  return result.rows;
}

async function getActiveSubscriptionsForLocation(lat, lon, radiusKm = 50) {
  const result = await db.query(`
    SELECT 
      s.*,
      p.enabled_alerts,
      p.notification_channels,
      p.min_severity,
      p.sms_enabled,
      p.sms_critical_only,
      p.sms_phone,
      p.language,
      p.daily_limit,
      p.quiet_hours_start,
      p.quiet_hours_end,
      u.phone as user_phone,
      u.email as user_email
    FROM weather_alert_subscriptions s
    JOIN users u ON s.user_id = u.id
    LEFT JOIN weather_alert_preferences p ON s.user_id = p.user_id AND p.is_active = true
    WHERE s.is_active = true
    AND (
      6371 * acos(
        cos(radians($1)) * cos(radians(s.latitude)) *
        cos(radians(s.longitude) - radians($2)) +
        sin(radians($1)) * sin(radians(s.latitude))
      )
    ) <= $3
  `, [lat, lon, radiusKm]);
  
  return result.rows;
}

async function getAlertsCountToday(userId) {
  const result = await db.query(`
    SELECT COUNT(*) FROM weather_alert_history 
    WHERE user_id = $1 
    AND created_at >= CURRENT_DATE
  `, [userId]);
  
  return parseInt(result.rows[0].count);
}

function isInQuietHours(quietStart, quietEnd) {
  if (!quietStart || !quietEnd) return false;
  
  const now = new Date();
  const currentTime = now.getHours() * 60 + now.getMinutes();
  
  const [startHour, startMin] = quietStart.split(':').map(Number);
  const [endHour, endMin] = quietEnd.split(':').map(Number);
  
  const startTime = startHour * 60 + startMin;
  const endTime = endHour * 60 + endMin;
  
  if (startTime <= endTime) {
    return currentTime >= startTime && currentTime <= endTime;
  }
  return currentTime >= startTime || currentTime <= endTime;
}

function evaluateConditions(weatherData, conditions) {
  for (const [key, threshold] of Object.entries(conditions)) {
    if (threshold === null) continue;
    
    if (key === 'temp_min' && weatherData.temp < threshold) return false;
    if (key === 'temp_max' && weatherData.temp > threshold) return false;
    if (key === 'precipitation_min' && (weatherData.precipitation || 0) < threshold) return false;
    if (key === 'wind_speed_min' && (weatherData.wind_speed || 0) < threshold) return false;
    if (key === 'humidity_min' && (weatherData.humidity || 0) < threshold) return false;
    if (key === 'humidity_max' && (weatherData.humidity || 0) > threshold) return false;
    if (key === 'visibility_max' && (weatherData.visibility || 10000) > threshold) return false;
    if (key === 'days_without_rain' && (weatherData.days_without_rain || 0) < threshold) return false;
  }
  return true;
}

function determineSeverity(weatherData, severityThresholds) {
  let highestSeverity = 'low';
  
  const severityOrder = ['moderate', 'high', 'severe', 'extreme'];
  
  for (const severity of severityOrder) {
    const thresholds = severityThresholds[severity];
    if (!thresholds) continue;
    
    let matches = true;
    for (const [key, value] of Object.entries(thresholds)) {
      if (key === 'temp_min' && weatherData.temp < value) matches = false;
      if (key === 'temp_max' && weatherData.temp > value) matches = false;
      if (key === 'precipitation_min' && (weatherData.precipitation || 0) < value) matches = false;
      if (key === 'wind_speed_min' && (weatherData.wind_speed || 0) < value) matches = false;
      if (key === 'days_without_rain' && (weatherData.days_without_rain || 0) < value) matches = false;
    }
    
    if (matches) {
      highestSeverity = severity;
    }
  }
  
  return highestSeverity;
}

async function fetchWeatherData(lat, lon) {
  const apiKey = process.env.WEATHER_API_KEY;
  
  if (!apiKey) {
    return {
      temp: 28,
      humidity: 65,
      wind_speed: 15,
      precipitation: 0,
      visibility: 10000,
      weather_condition: 'Clear'
    };
  }
  
  try {
    const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric`;
    const response = await axios.get(url);
    
    return {
      temp: response.data.main.temp,
      humidity: response.data.main.humidity,
      wind_speed: (response.data.wind?.speed || 0) * 3.6,
      precipitation: response.data.rain?.['1h'] || response.data.rain?.['3h'] || 0,
      visibility: response.data.visibility || 10000,
      weather_condition: response.data.weather?.[0]?.main || 'Clear',
      description: response.data.weather?.[0]?.description || ''
    };
  } catch (error) {
    console.error('Error fetching weather data:', error.message);
    throw error;
  }
}

async function checkAndTriggerAlerts(lat, lon, weatherData = null) {
  const triggeredAlerts = [];
  
  try {
    if (!weatherData) {
      weatherData = await fetchWeatherData(lat, lon);
    }
    
    const rules = await getAlertRules();
    
    for (const rule of rules) {
      const conditions = rule.conditions;
      const meetsConditions = evaluateConditions(weatherData, conditions);
      
      if (meetsConditions) {
        const severity = determineSeverity(weatherData, rule.severity_thresholds);
        
        triggeredAlerts.push({
          alert_type: rule.alert_type,
          severity,
          title: rule.name,
          title_hi: rule.name_hi,
          description: rule.description,
          description_hi: rule.description_hi,
          recommendations: rule.recommendations,
          recommendations_hi: rule.recommendations_hi,
          sms_enabled: rule.sms_enabled,
          priority: rule.priority,
          weather_data: weatherData
        });
      }
    }
    
    return triggeredAlerts.sort((a, b) => a.priority - b.priority);
  } catch (error) {
    console.error('Error checking alerts:', error.message);
    return triggeredAlerts;
  }
}

async function sendAlertToUser(userId, alert, subscription, preferences) {
  const language = preferences?.language || 'en';
  const title = language === 'hi' && alert.title_hi ? alert.title_hi : alert.title;
  const message = language === 'hi' && alert.description_hi ? alert.description_hi : alert.description;
  
  const alertHistoryResult = await db.query(`
    INSERT INTO weather_alert_history 
    (user_id, subscription_id, alert_type, severity, title, message, weather_data, latitude, longitude, location_name, valid_from, valid_until)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '24 hours')
    RETURNING id
  `, [
    userId,
    subscription?.id || null,
    alert.alert_type,
    alert.severity,
    title,
    message,
    JSON.stringify(alert.weather_data),
    subscription?.latitude || 0,
    subscription?.longitude || 0,
    subscription?.location_name || 'Unknown'
  ]);
  
  const alertId = alertHistoryResult.rows[0].id;
  const notificationChannels = preferences?.notification_channels || ['push', 'in_app'];
  
  if (notificationChannels.includes('push')) {
    try {
      await pushNotificationService.sendToUser(userId, title, message, {
        type: 'weather_alert',
        alert_id: alertId,
        alert_type: alert.alert_type,
        severity: alert.severity,
        recommendations: JSON.stringify(
          language === 'hi' && alert.recommendations_hi ? alert.recommendations_hi : alert.recommendations
        )
      });
      
      await db.query(
        'UPDATE weather_alert_history SET push_sent = true, push_sent_at = CURRENT_TIMESTAMP WHERE id = $1',
        [alertId]
      );
    } catch (error) {
      console.error('Failed to send push notification:', error.message);
    }
  }
  
  if (notificationChannels.includes('in_app')) {
    await db.query(`
      INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id)
      VALUES ($1, $2, $3, $4, $5, $6)
    `, [userId, title, message, 'warning', 'weather_alert', alertId]);
  }
  
  const shouldSendSms = preferences?.sms_enabled && 
    alert.sms_enabled &&
    (!preferences.sms_critical_only || getSeverityLevel(alert.severity) >= SEVERITY_LEVELS.high);
  
  if (shouldSendSms) {
    const phone = preferences.sms_phone || subscription?.user_phone;
    if (phone) {
      try {
        const smsMessage = `[Kheti Sahayak] ${title}: ${message.substring(0, 120)}...`;
        await smsService.sendSMS(phone, smsMessage);
        
        await db.query(
          'UPDATE weather_alert_history SET sms_sent = true, sms_sent_at = CURRENT_TIMESTAMP WHERE id = $1',
          [alertId]
        );
      } catch (error) {
        console.error('Failed to send SMS:', error.message);
      }
    }
  }
  
  return alertId;
}

async function processAlertsForSubscription(subscription, preferences) {
  const userId = subscription.user_id;
  const lat = parseFloat(subscription.latitude);
  const lon = parseFloat(subscription.longitude);
  
  const enabledAlerts = subscription.alert_types || preferences?.enabled_alerts || 
    ['heat_wave', 'heavy_rain', 'frost', 'storm', 'drought'];
  const minSeverity = preferences?.min_severity || 'moderate';
  const dailyLimit = preferences?.daily_limit || 10;
  
  const alertsToday = await getAlertsCountToday(userId);
  if (dailyLimit > 0 && alertsToday >= dailyLimit) {
    console.log(`User ${userId} has reached daily alert limit`);
    return [];
  }
  
  const inQuietHours = isInQuietHours(
    preferences?.quiet_hours_start, 
    preferences?.quiet_hours_end
  );
  
  const triggeredAlerts = await checkAndTriggerAlerts(lat, lon);
  const sentAlerts = [];
  
  for (const alert of triggeredAlerts) {
    if (!enabledAlerts.includes(alert.alert_type)) continue;
    if (getSeverityLevel(alert.severity) < getSeverityLevel(minSeverity)) continue;
    
    if (inQuietHours && getSeverityLevel(alert.severity) < SEVERITY_LEVELS.severe) {
      continue;
    }
    
    if (dailyLimit > 0 && alertsToday + sentAlerts.length >= dailyLimit) break;
    
    const alertId = await sendAlertToUser(userId, alert, subscription, preferences);
    sentAlerts.push({ alertId, ...alert });
  }
  
  await db.query(
    'UPDATE weather_alert_subscriptions SET last_checked_at = CURRENT_TIMESTAMP WHERE id = $1',
    [subscription.id]
  );
  
  return sentAlerts;
}

async function processAllSubscriptions() {
  const result = await db.query(`
    SELECT 
      s.*,
      p.enabled_alerts,
      p.notification_channels,
      p.min_severity,
      p.sms_enabled,
      p.sms_critical_only,
      p.sms_phone,
      p.language,
      p.daily_limit,
      p.quiet_hours_start,
      p.quiet_hours_end
    FROM weather_alert_subscriptions s
    LEFT JOIN weather_alert_preferences p ON s.user_id = p.user_id AND p.is_active = true
    WHERE s.is_active = true
    AND (s.last_checked_at IS NULL OR s.last_checked_at < CURRENT_TIMESTAMP - INTERVAL '30 minutes')
    ORDER BY s.last_checked_at NULLS FIRST
    LIMIT 100
  `);
  
  const results = {
    processed: 0,
    alertsSent: 0,
    errors: []
  };
  
  for (const subscription of result.rows) {
    try {
      const sentAlerts = await processAlertsForSubscription(subscription, subscription);
      results.processed++;
      results.alertsSent += sentAlerts.length;
    } catch (error) {
      console.error(`Error processing subscription ${subscription.id}:`, error.message);
      results.errors.push({ subscriptionId: subscription.id, error: error.message });
    }
  }
  
  return results;
}

async function createSubscription(userId, lat, lon, locationName = null, alertTypes = null, isPrimary = false) {
  if (isPrimary) {
    await db.query(
      'UPDATE weather_alert_subscriptions SET is_primary = false WHERE user_id = $1',
      [userId]
    );
  }
  
  const result = await db.query(`
    INSERT INTO weather_alert_subscriptions (user_id, latitude, longitude, location_name, alert_types, is_primary, is_active)
    VALUES ($1, $2, $3, $4, $5, $6, true)
    ON CONFLICT (user_id, latitude, longitude) 
    DO UPDATE SET 
      location_name = COALESCE(EXCLUDED.location_name, weather_alert_subscriptions.location_name),
      alert_types = COALESCE(EXCLUDED.alert_types, weather_alert_subscriptions.alert_types),
      is_primary = EXCLUDED.is_primary,
      is_active = true,
      updated_at = CURRENT_TIMESTAMP
    RETURNING *
  `, [userId, lat, lon, locationName, alertTypes ? JSON.stringify(alertTypes) : null, isPrimary]);
  
  return result.rows[0];
}

async function deleteSubscription(userId, subscriptionId) {
  const result = await db.query(
    'UPDATE weather_alert_subscriptions SET is_active = false WHERE id = $1 AND user_id = $2 RETURNING id',
    [subscriptionId, userId]
  );
  return result.rows.length > 0;
}

async function updateAlertPreferences(userId, preferences) {
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
  } = preferences;
  
  const result = await db.query(`
    INSERT INTO weather_alert_preferences 
    (user_id, enabled_alerts, notification_channels, min_severity, quiet_hours_start, quiet_hours_end, sms_enabled, sms_critical_only, sms_phone, language, daily_limit, is_active)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, true)
    ON CONFLICT (user_id) 
    DO UPDATE SET
      enabled_alerts = COALESCE($2, weather_alert_preferences.enabled_alerts),
      notification_channels = COALESCE($3, weather_alert_preferences.notification_channels),
      min_severity = COALESCE($4, weather_alert_preferences.min_severity),
      quiet_hours_start = $5,
      quiet_hours_end = $6,
      sms_enabled = COALESCE($7, weather_alert_preferences.sms_enabled),
      sms_critical_only = COALESCE($8, weather_alert_preferences.sms_critical_only),
      sms_phone = COALESCE($9, weather_alert_preferences.sms_phone),
      language = COALESCE($10, weather_alert_preferences.language),
      daily_limit = COALESCE($11, weather_alert_preferences.daily_limit),
      is_active = true,
      updated_at = CURRENT_TIMESTAMP
    RETURNING *
  `, [
    userId,
    enabled_alerts ? JSON.stringify(enabled_alerts) : null,
    notification_channels ? JSON.stringify(notification_channels) : null,
    min_severity || null,
    quiet_hours_start || null,
    quiet_hours_end || null,
    sms_enabled !== undefined ? sms_enabled : null,
    sms_critical_only !== undefined ? sms_critical_only : null,
    sms_phone || null,
    language || null,
    daily_limit !== undefined ? daily_limit : null
  ]);
  
  return result.rows[0];
}

async function getAlertHistory(userId, options = {}) {
  const { limit = 20, offset = 0, alertType, isRead, severity } = options;
  
  let query = 'SELECT * FROM weather_alert_history WHERE user_id = $1';
  const params = [userId];
  let paramCount = 1;
  
  if (alertType) {
    paramCount++;
    query += ` AND alert_type = $${paramCount}`;
    params.push(alertType);
  }
  
  if (isRead !== undefined) {
    paramCount++;
    query += ` AND is_read = $${paramCount}`;
    params.push(isRead);
  }
  
  if (severity) {
    paramCount++;
    query += ` AND severity = $${paramCount}`;
    params.push(severity);
  }
  
  query += ' ORDER BY created_at DESC';
  
  paramCount++;
  query += ` LIMIT $${paramCount}`;
  params.push(limit);
  
  paramCount++;
  query += ` OFFSET $${paramCount}`;
  params.push(offset);
  
  const result = await db.query(query, params);
  return result.rows;
}

async function markAlertAsRead(userId, alertId) {
  const result = await db.query(
    'UPDATE weather_alert_history SET is_read = true, read_at = CURRENT_TIMESTAMP WHERE id = $1 AND user_id = $2 RETURNING *',
    [alertId, userId]
  );
  return result.rows[0];
}

async function dismissAlert(userId, alertId) {
  const result = await db.query(
    'UPDATE weather_alert_history SET is_dismissed = true WHERE id = $1 AND user_id = $2 RETURNING *',
    [alertId, userId]
  );
  return result.rows[0];
}

module.exports = {
  getAlertRules,
  getUserAlertPreferences,
  getUserSubscriptions,
  getActiveSubscriptionsForLocation,
  checkAndTriggerAlerts,
  sendAlertToUser,
  processAlertsForSubscription,
  processAllSubscriptions,
  createSubscription,
  deleteSubscription,
  updateAlertPreferences,
  getAlertHistory,
  markAlertAsRead,
  dismissAlert,
  fetchWeatherData,
  SEVERITY_LEVELS
};

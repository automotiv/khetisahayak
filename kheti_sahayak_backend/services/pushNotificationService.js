/**
 * Push Notification Service using Firebase Cloud Messaging (FCM)
 *
 * Features:
 * - Send to single device
 * - Send to multiple devices
 * - Send to topic subscribers
 * - Notification with data payload
 * - Mock mode for development without Firebase
 */

const { getFirebaseAdmin, isFirebaseEnabled } = require('../config/firebase');
const db = require('../db');

/**
 * Send push notification to a single device
 * @param {string} token - FCM device token
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Optional data payload
 * @returns {Promise<object>} - Send result
 */
const sendToDevice = async (token, title, body, data = {}) => {
  if (!isFirebaseEnabled()) {
    console.log('[MOCK FCM] Sending to device:', { token: token.substring(0, 20) + '...', title, body });
    return { success: true, mock: true, messageId: `mock-${Date.now()}` };
  }

  const admin = getFirebaseAdmin();
  const message = {
    notification: {
      title,
      body
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'kheti_sahayak_channel',
        priority: 'high',
        defaultSound: true,
        defaultVibrateTimings: true
      }
    },
    apns: {
      payload: {
        aps: {
          badge: 1,
          sound: 'default',
          contentAvailable: true
        }
      }
    },
    token
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent notification:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending notification:', error);
    // Handle invalid token
    if (error.code === 'messaging/registration-token-not-registered' ||
        error.code === 'messaging/invalid-registration-token') {
      await removeInvalidToken(token);
    }
    return { success: false, error: error.message };
  }
};

/**
 * Send push notification to multiple devices
 * @param {string[]} tokens - Array of FCM device tokens
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Optional data payload
 * @returns {Promise<object>} - Send results
 */
const sendToMultipleDevices = async (tokens, title, body, data = {}) => {
  if (!tokens || tokens.length === 0) {
    return { success: true, successCount: 0, failureCount: 0 };
  }

  if (!isFirebaseEnabled()) {
    console.log('[MOCK FCM] Sending to', tokens.length, 'devices:', { title, body });
    return { success: true, mock: true, successCount: tokens.length, failureCount: 0 };
  }

  const admin = getFirebaseAdmin();
  const message = {
    notification: {
      title,
      body
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'kheti_sahayak_channel'
      }
    },
    apns: {
      payload: {
        aps: {
          badge: 1,
          sound: 'default'
        }
      }
    }
  };

  try {
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      ...message
    });

    console.log('Multicast result:', {
      successCount: response.successCount,
      failureCount: response.failureCount
    });

    // Remove invalid tokens
    const invalidTokens = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success && resp.error &&
          (resp.error.code === 'messaging/registration-token-not-registered' ||
           resp.error.code === 'messaging/invalid-registration-token')) {
        invalidTokens.push(tokens[idx]);
      }
    });

    if (invalidTokens.length > 0) {
      await removeInvalidTokens(invalidTokens);
    }

    return {
      success: response.successCount > 0,
      successCount: response.successCount,
      failureCount: response.failureCount
    };
  } catch (error) {
    console.error('Error sending multicast notification:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send push notification to a topic
 * @param {string} topic - Topic name (e.g., 'weather-alerts', 'crop-tips')
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Optional data payload
 * @returns {Promise<object>} - Send result
 */
const sendToTopic = async (topic, title, body, data = {}) => {
  if (!isFirebaseEnabled()) {
    console.log('[MOCK FCM] Sending to topic:', { topic, title, body });
    return { success: true, mock: true, messageId: `mock-topic-${Date.now()}` };
  }

  const admin = getFirebaseAdmin();
  const message = {
    notification: {
      title,
      body
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    },
    android: {
      priority: 'high'
    },
    apns: {
      payload: {
        aps: {
          sound: 'default'
        }
      }
    },
    topic
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent to topic:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending to topic:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Subscribe device to a topic
 * @param {string} token - FCM device token
 * @param {string} topic - Topic name
 * @returns {Promise<object>} - Subscribe result
 */
const subscribeToTopic = async (token, topic) => {
  if (!isFirebaseEnabled()) {
    console.log('[MOCK FCM] Subscribe to topic:', { token: token.substring(0, 20) + '...', topic });
    return { success: true, mock: true };
  }

  const admin = getFirebaseAdmin();
  try {
    const response = await admin.messaging().subscribeToTopic([token], topic);
    return { success: response.successCount > 0 };
  } catch (error) {
    console.error('Error subscribing to topic:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Unsubscribe device from a topic
 * @param {string} token - FCM device token
 * @param {string} topic - Topic name
 * @returns {Promise<object>} - Unsubscribe result
 */
const unsubscribeFromTopic = async (token, topic) => {
  if (!isFirebaseEnabled()) {
    console.log('[MOCK FCM] Unsubscribe from topic:', { token: token.substring(0, 20) + '...', topic });
    return { success: true, mock: true };
  }

  const admin = getFirebaseAdmin();
  try {
    const response = await admin.messaging().unsubscribeFromTopic([token], topic);
    return { success: response.successCount > 0 };
  } catch (error) {
    console.error('Error unsubscribing from topic:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send notification to a user (all their registered devices)
 * @param {string} userId - User ID
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Optional data payload
 * @returns {Promise<object>} - Send results
 */
const sendToUser = async (userId, title, body, data = {}) => {
  try {
    const result = await db.query(
      'SELECT token FROM device_tokens WHERE user_id = $1 AND is_active = true',
      [userId]
    );

    if (result.rows.length === 0) {
      console.log('No active device tokens for user:', userId);
      return { success: true, message: 'No devices registered' };
    }

    const tokens = result.rows.map(row => row.token);
    return await sendToMultipleDevices(tokens, title, body, data);
  } catch (error) {
    console.error('Error sending to user:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Remove invalid token from database
 * @param {string} token - Invalid FCM token
 */
const removeInvalidToken = async (token) => {
  try {
    await db.query(
      'UPDATE device_tokens SET is_active = false WHERE token = $1',
      [token]
    );
    console.log('Marked invalid token as inactive:', token.substring(0, 20) + '...');
  } catch (error) {
    console.error('Error removing invalid token:', error);
  }
};

/**
 * Remove multiple invalid tokens from database
 * @param {string[]} tokens - Array of invalid FCM tokens
 */
const removeInvalidTokens = async (tokens) => {
  try {
    await db.query(
      'UPDATE device_tokens SET is_active = false WHERE token = ANY($1)',
      [tokens]
    );
    console.log('Marked', tokens.length, 'invalid tokens as inactive');
  } catch (error) {
    console.error('Error removing invalid tokens:', error);
  }
};

// Notification types for the app
const NotificationTypes = {
  WEATHER_ALERT: 'weather_alert',
  CROP_TIP: 'crop_tip',
  DIAGNOSIS_COMPLETE: 'diagnosis_complete',
  ORDER_UPDATE: 'order_update',
  PRICE_ALERT: 'price_alert',
  EXPERT_RESPONSE: 'expert_response',
  COMMUNITY_REPLY: 'community_reply',
  SCHEME_UPDATE: 'scheme_update'
};

// Pre-built notification helpers
const sendWeatherAlert = async (userId, alertTitle, alertMessage, severity = 'warning') => {
  return await sendToUser(userId, alertTitle, alertMessage, {
    type: NotificationTypes.WEATHER_ALERT,
    severity,
    timestamp: new Date().toISOString()
  });
};

const sendDiagnosisComplete = async (userId, diagnosticId, cropType, result) => {
  return await sendToUser(
    userId,
    'Diagnosis Complete',
    `Your ${cropType} diagnosis is ready. Result: ${result}`,
    {
      type: NotificationTypes.DIAGNOSIS_COMPLETE,
      diagnosticId: String(diagnosticId),
      cropType,
      result
    }
  );
};

const sendOrderUpdate = async (userId, orderId, status, message) => {
  return await sendToUser(
    userId,
    'Order Update',
    message,
    {
      type: NotificationTypes.ORDER_UPDATE,
      orderId: String(orderId),
      status
    }
  );
};

module.exports = {
  sendToDevice,
  sendToMultipleDevices,
  sendToTopic,
  subscribeToTopic,
  unsubscribeFromTopic,
  sendToUser,
  NotificationTypes,
  sendWeatherAlert,
  sendDiagnosisComplete,
  sendOrderUpdate
};

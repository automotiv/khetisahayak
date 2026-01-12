/**
 * Agora Video Call Service
 * 
 * Provides video call token generation for expert consultations.
 * Uses Agora RTC SDK for real-time video communication.
 * 
 * Setup Instructions:
 * 1. Create Agora account at https://console.agora.io
 * 2. Create a project and get App ID and App Certificate
 * 3. Set environment variables:
 *    - AGORA_APP_ID=your_app_id
 *    - AGORA_APP_CERTIFICATE=your_app_certificate
 * 
 * @module services/agoraService
 */

const crypto = require('crypto');

// Agora token privileges
const Privileges = {
  JOIN_CHANNEL: 1,
  PUBLISH_AUDIO_STREAM: 2,
  PUBLISH_VIDEO_STREAM: 3,
  PUBLISH_DATA_STREAM: 4
};

// Token expiration time (24 hours in seconds)
const DEFAULT_TOKEN_EXPIRATION = 86400;

/**
 * Check if Agora is properly configured
 * @returns {boolean}
 */
const isEnabled = () => {
  return !!(process.env.AGORA_APP_ID && process.env.AGORA_APP_CERTIFICATE);
};

/**
 * Get Agora App ID (for frontend)
 * @returns {string}
 */
const getAppId = () => {
  return process.env.AGORA_APP_ID || 'mock_app_id';
};

/**
 * Generate a unique numeric UID from user UUID
 * Agora requires numeric UIDs
 * @param {string} userId - User UUID
 * @returns {number}
 */
const generateNumericUid = (userId) => {
  const hash = crypto.createHash('md5').update(userId).digest('hex');
  // Take first 8 hex chars and convert to number (max ~4 billion)
  return parseInt(hash.substring(0, 8), 16);
};

/**
 * Generate RTC token for video calls
 * Simplified implementation - for production, use official Agora SDK
 * @param {string} channelName - Channel/room name
 * @param {string} userId - User UUID
 * @param {string} role - 'publisher' (host) or 'subscriber' (audience)
 * @param {number} expirationSeconds - Token validity in seconds
 * @returns {object} Token details
 */
const generateRtcToken = (channelName, userId, role = 'publisher', expirationSeconds = DEFAULT_TOKEN_EXPIRATION) => {
  const appId = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;
  
  if (!appId || !appCertificate) {
    // Return mock token for development
    console.log('[MOCK AGORA] Generating RTC token for channel:', channelName);
    const mockToken = `mock_rtc_token_${channelName}_${Date.now()}`;
    return {
      token: mockToken,
      appId: 'mock_app_id',
      channelName,
      uid: generateNumericUid(userId),
      role,
      expiresAt: new Date(Date.now() + expirationSeconds * 1000).toISOString(),
      mock: true
    };
  }

  const uid = generateNumericUid(userId);
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationSeconds;

  // Build token message
  const tokenVersion = '006';
  const roleValue = role === 'publisher' ? 1 : 2;

  // Create signature
  const message = {
    salt: Math.floor(Math.random() * 100000000),
    ts: currentTimestamp,
    privileges: {
      [Privileges.JOIN_CHANNEL]: privilegeExpiredTs,
      [Privileges.PUBLISH_AUDIO_STREAM]: privilegeExpiredTs,
      [Privileges.PUBLISH_VIDEO_STREAM]: privilegeExpiredTs
    }
  };

  // Generate signature using HMAC-SHA256
  const signatureContent = `${appId}${channelName}${uid}${JSON.stringify(message)}`;
  const signature = crypto
    .createHmac('sha256', appCertificate)
    .update(signatureContent)
    .digest('base64');

  // Encode token
  const tokenContent = {
    appId,
    channelName,
    uid,
    role: roleValue,
    message,
    signature
  };

  const token = Buffer.from(JSON.stringify(tokenContent)).toString('base64');

  return {
    token: `${tokenVersion}${token}`,
    appId,
    channelName,
    uid,
    role,
    expiresAt: new Date(privilegeExpiredTs * 1000).toISOString(),
    mock: false
  };
};

/**
 * Generate RTM token for real-time messaging during calls
 * @param {string} userId - User UUID
 * @param {number} expirationSeconds - Token validity in seconds
 * @returns {object} Token details
 */
const generateRtmToken = (userId, expirationSeconds = DEFAULT_TOKEN_EXPIRATION) => {
  const appId = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;

  if (!appId || !appCertificate) {
    console.log('[MOCK AGORA] Generating RTM token for user:', userId);
    return {
      token: `mock_rtm_token_${userId}_${Date.now()}`,
      appId: 'mock_app_id',
      userId,
      expiresAt: new Date(Date.now() + expirationSeconds * 1000).toISOString(),
      mock: true
    };
  }

  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationSeconds;

  const message = {
    salt: Math.floor(Math.random() * 100000000),
    ts: currentTimestamp,
    privileges: { 1: privilegeExpiredTs } // RTM login privilege
  };

  const signatureContent = `${appId}${userId}${JSON.stringify(message)}`;
  const signature = crypto
    .createHmac('sha256', appCertificate)
    .update(signatureContent)
    .digest('base64');

  const tokenContent = {
    appId,
    userId,
    message,
    signature
  };

  const token = Buffer.from(JSON.stringify(tokenContent)).toString('base64');

  return {
    token: `006${token}`,
    appId,
    userId,
    expiresAt: new Date(privilegeExpiredTs * 1000).toISOString(),
    mock: false
  };
};

/**
 * Generate all tokens needed for a video consultation
 * @param {string} channelName - Channel/room name
 * @param {string} farmerId - Farmer's user UUID
 * @param {string} expertId - Expert's user UUID
 * @param {number} expirationSeconds - Token validity
 * @returns {object} Tokens for both participants
 */
const generateConsultationTokens = (channelName, farmerId, expertId, expirationSeconds = DEFAULT_TOKEN_EXPIRATION) => {
  const farmerRtcToken = generateRtcToken(channelName, farmerId, 'publisher', expirationSeconds);
  const expertRtcToken = generateRtcToken(channelName, expertId, 'publisher', expirationSeconds);
  const farmerRtmToken = generateRtmToken(farmerId, expirationSeconds);
  const expertRtmToken = generateRtmToken(expertId, expirationSeconds);

  return {
    channelName,
    appId: getAppId(),
    farmer: {
      rtcToken: farmerRtcToken.token,
      rtmToken: farmerRtmToken.token,
      uid: farmerRtcToken.uid,
      expiresAt: farmerRtcToken.expiresAt
    },
    expert: {
      rtcToken: expertRtcToken.token,
      rtmToken: expertRtmToken.token,
      uid: expertRtcToken.uid,
      expiresAt: expertRtcToken.expiresAt
    },
    mock: !isEnabled()
  };
};

/**
 * Validate channel name format
 * @param {string} channelName 
 * @returns {boolean}
 */
const isValidChannelName = (channelName) => {
  // Channel name must be alphanumeric with dashes/underscores, max 64 chars
  const pattern = /^[a-zA-Z0-9_-]{1,64}$/;
  return pattern.test(channelName);
};

/**
 * Generate a secure channel name for a consultation
 * @param {string} consultationId - Consultation UUID
 * @returns {string}
 */
const generateChannelName = (consultationId) => {
  const timestamp = Date.now().toString(36);
  const shortId = consultationId.replace(/-/g, '').substring(0, 8);
  return `ks-${shortId}-${timestamp}`;
};

module.exports = {
  isEnabled,
  getAppId,
  generateNumericUid,
  generateRtcToken,
  generateRtmToken,
  generateConsultationTokens,
  isValidChannelName,
  generateChannelName,
  Privileges,
  DEFAULT_TOKEN_EXPIRATION
};

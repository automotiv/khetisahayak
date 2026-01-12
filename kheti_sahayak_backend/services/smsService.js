/**
 * SMS Service for Kheti Sahayak
 * 
 * Handles sending SMS messages for:
 * - OTP verification
 * - Order notifications
 * - Alert notifications
 * 
 * Supports multiple providers:
 * - MSG91 (primary - India)
 * - Twilio (international fallback)
 * - Console logging (development)
 */

const fetch = require('node-fetch');

// SMS configuration
const SMS_CONFIG = {
  provider: process.env.SMS_PROVIDER || 'console', // 'msg91', 'twilio', 'console'
  
  // MSG91 settings (India - recommended)
  msg91: {
    authKey: process.env.MSG91_AUTH_KEY,
    senderId: process.env.MSG91_SENDER_ID || 'KHETIS',
    templateId: process.env.MSG91_OTP_TEMPLATE_ID,
    baseUrl: 'https://api.msg91.com/api/v5',
  },
  
  // Twilio settings (International)
  twilio: {
    accountSid: process.env.TWILIO_ACCOUNT_SID,
    authToken: process.env.TWILIO_AUTH_TOKEN,
    phoneNumber: process.env.TWILIO_PHONE_NUMBER,
  },
};

/**
 * Send OTP via MSG91
 * @param {string} phone - Phone number with country code
 * @param {string} otp - 6-digit OTP
 * @returns {Promise<Object>} - Send result
 */
const sendViaMSG91 = async (phone, otp) => {
  try {
    const { authKey, templateId } = SMS_CONFIG.msg91;
    
    if (!authKey) {
      throw new Error('MSG91 auth key not configured');
    }

    // Clean phone number (remove +91 if present, MSG91 expects 10 digits)
    let cleanPhone = phone.replace(/\s+/g, '').replace(/^\+91/, '').replace(/^91/, '');
    if (cleanPhone.length !== 10) {
      cleanPhone = phone.replace(/\s+/g, '').replace(/^\+/, '');
    }

    const response = await fetch(`${SMS_CONFIG.msg91.baseUrl}/otp?template_id=${templateId}&mobile=91${cleanPhone}&authkey=${authKey}&otp=${otp}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const result = await response.json();

    if (result.type === 'success' || result.type === 'error' && result.message === 'OTP already sent') {
      console.log(`[SMS] OTP sent via MSG91 to ${phone}`);
      return { success: true, provider: 'msg91', messageId: result.request_id };
    }

    throw new Error(result.message || 'MSG91 send failed');
  } catch (error) {
    console.error('[SMS] MSG91 error:', error.message);
    throw error;
  }
};

/**
 * Send OTP via Twilio
 * @param {string} phone - Phone number with country code
 * @param {string} otp - 6-digit OTP
 * @returns {Promise<Object>} - Send result
 */
const sendViaTwilio = async (phone, otp) => {
  try {
    const { accountSid, authToken, phoneNumber } = SMS_CONFIG.twilio;
    
    if (!accountSid || !authToken || !phoneNumber) {
      throw new Error('Twilio credentials not configured');
    }

    // Ensure phone has country code
    let formattedPhone = phone;
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = `+91${formattedPhone.replace(/^91/, '')}`;
    }

    const client = require('twilio')(accountSid, authToken);
    
    const message = await client.messages.create({
      body: `Your Kheti Sahayak verification code is: ${otp}. Valid for 10 minutes. Do not share this code.`,
      from: phoneNumber,
      to: formattedPhone,
    });

    console.log(`[SMS] OTP sent via Twilio to ${phone}: ${message.sid}`);
    return { success: true, provider: 'twilio', messageId: message.sid };
  } catch (error) {
    console.error('[SMS] Twilio error:', error.message);
    throw error;
  }
};

/**
 * Send OTP to console (development mode)
 * @param {string} phone - Phone number
 * @param {string} otp - 6-digit OTP
 * @returns {Promise<Object>} - Mock result
 */
const sendToConsole = async (phone, otp) => {
  console.log('');
  console.log('='.repeat(50));
  console.log('[SMS SERVICE - DEVELOPMENT MODE]');
  console.log(`Phone: ${phone}`);
  console.log(`OTP: ${otp}`);
  console.log('='.repeat(50));
  console.log('');
  
  return { success: true, provider: 'console', mock: true };
};

/**
 * Send OTP SMS
 * @param {string} phone - Phone number (with or without country code)
 * @param {string} otp - 6-digit OTP
 * @returns {Promise<Object>} - Send result
 */
const sendOTP = async (phone, otp) => {
  const provider = SMS_CONFIG.provider;
  
  console.log(`[SMS] Sending OTP to ${phone} via ${provider}`);

  switch (provider) {
    case 'msg91':
      return sendViaMSG91(phone, otp);
      
    case 'twilio':
      return sendViaTwilio(phone, otp);
      
    case 'console':
    default:
      return sendToConsole(phone, otp);
  }
};

/**
 * Send general SMS message
 * @param {string} phone - Phone number
 * @param {string} message - SMS message content
 * @returns {Promise<Object>} - Send result
 */
const sendSMS = async (phone, message) => {
  const provider = SMS_CONFIG.provider;

  if (provider === 'console') {
    console.log('');
    console.log('='.repeat(50));
    console.log('[SMS SERVICE - DEVELOPMENT MODE]');
    console.log(`Phone: ${phone}`);
    console.log(`Message: ${message}`);
    console.log('='.repeat(50));
    console.log('');
    return { success: true, provider: 'console', mock: true };
  }

  if (provider === 'twilio') {
    try {
      const { accountSid, authToken, phoneNumber } = SMS_CONFIG.twilio;
      const client = require('twilio')(accountSid, authToken);
      
      let formattedPhone = phone;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = `+91${formattedPhone.replace(/^91/, '')}`;
      }

      const result = await client.messages.create({
        body: message,
        from: phoneNumber,
        to: formattedPhone,
      });

      return { success: true, provider: 'twilio', messageId: result.sid };
    } catch (error) {
      console.error('[SMS] Send error:', error.message);
      throw error;
    }
  }

  // MSG91 transactional SMS would need different API endpoint
  console.log(`[SMS] General SMS not implemented for ${provider}, falling back to console`);
  return sendToConsole(phone, message);
};

/**
 * Send order notification SMS
 * @param {string} phone - Customer phone number
 * @param {Object} order - Order details
 * @param {string} status - Order status
 */
const sendOrderNotification = async (phone, order, status) => {
  const statusMessages = {
    confirmed: `Your Kheti Sahayak order #${order.id.substring(0, 8).toUpperCase()} is confirmed! We'll notify you when it ships.`,
    shipped: `Great news! Your order #${order.id.substring(0, 8).toUpperCase()} has been shipped. Track it in the app.`,
    delivered: `Your Kheti Sahayak order #${order.id.substring(0, 8).toUpperCase()} has been delivered. Enjoy!`,
    cancelled: `Your order #${order.id.substring(0, 8).toUpperCase()} has been cancelled. Contact support for details.`,
  };

  const message = statusMessages[status] || `Your order #${order.id.substring(0, 8).toUpperCase()} status: ${status}`;
  
  return sendSMS(phone, message);
};

module.exports = {
  sendOTP,
  sendSMS,
  sendOrderNotification,
  SMS_CONFIG,
};

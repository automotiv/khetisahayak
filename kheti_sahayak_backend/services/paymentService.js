/**
 * Payment Service - Razorpay Integration
 *
 * Setup Instructions:
 * 1. Create Razorpay account at https://dashboard.razorpay.com
 * 2. Get API keys from Settings > API Keys
 * 3. Set environment variables:
 *    - RAZORPAY_KEY_ID=rzp_test_xxxxx
 *    - RAZORPAY_KEY_SECRET=xxxxx
 *    - RAZORPAY_WEBHOOK_SECRET=xxxxx (from Webhooks settings)
 */

const crypto = require('crypto');

// Conditional Razorpay initialization
let razorpay = null;
let isRazorpayEnabled = false;

const initializeRazorpay = () => {
  if (razorpay) return razorpay;

  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;

  if (keyId && keySecret) {
    try {
      const Razorpay = require('razorpay');
      razorpay = new Razorpay({
        key_id: keyId,
        key_secret: keySecret
      });
      isRazorpayEnabled = true;
      console.log('Razorpay initialized successfully');
    } catch (error) {
      console.error('Failed to initialize Razorpay:', error.message);
    }
  } else {
    console.warn('Razorpay credentials not found. Payment processing will be simulated.');
  }

  return razorpay;
};

/**
 * Check if Razorpay is enabled
 */
const isEnabled = () => {
  initializeRazorpay();
  return isRazorpayEnabled;
};

/**
 * Get Razorpay Key ID (for frontend)
 */
const getKeyId = () => {
  return process.env.RAZORPAY_KEY_ID || 'rzp_test_mock';
};

/**
 * Create a Razorpay order for payment
 * @param {number} amount - Amount in INR
 * @param {string} orderId - Internal order ID
 * @param {object} notes - Additional notes
 * @returns {Promise<object>} Razorpay order object
 */
const createPaymentOrder = async (amount, orderId, notes = {}) => {
  initializeRazorpay();

  const options = {
    amount: Math.round(amount * 100), // Convert to paise
    currency: 'INR',
    receipt: orderId,
    notes: {
      orderNumber: orderId,
      ...notes
    }
  };

  if (!isRazorpayEnabled) {
    // Mock response for development
    console.log('[MOCK RAZORPAY] Creating payment order:', options);
    return {
      id: `order_mock_${Date.now()}`,
      entity: 'order',
      amount: options.amount,
      amount_paid: 0,
      amount_due: options.amount,
      currency: 'INR',
      receipt: orderId,
      status: 'created',
      notes: options.notes,
      created_at: Math.floor(Date.now() / 1000),
      mock: true
    };
  }

  try {
    const order = await razorpay.orders.create(options);
    return order;
  } catch (error) {
    console.error('Razorpay order creation failed:', error);
    throw new Error(`Payment order creation failed: ${error.message}`);
  }
};

/**
 * Verify payment signature
 * @param {string} razorpayOrderId - Razorpay order ID
 * @param {string} razorpayPaymentId - Razorpay payment ID
 * @param {string} razorpaySignature - Signature from Razorpay
 * @returns {boolean} Is signature valid
 */
const verifyPaymentSignature = (razorpayOrderId, razorpayPaymentId, razorpaySignature) => {
  if (!isRazorpayEnabled) {
    // In mock mode, accept any signature that starts with 'mock_'
    console.log('[MOCK RAZORPAY] Verifying signature');
    return razorpaySignature?.startsWith('mock_') || razorpayOrderId?.includes('mock');
  }

  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  if (!keySecret) {
    throw new Error('Razorpay key secret not configured');
  }

  const body = razorpayOrderId + '|' + razorpayPaymentId;
  const expectedSignature = crypto
    .createHmac('sha256', keySecret)
    .update(body)
    .digest('hex');

  return expectedSignature === razorpaySignature;
};

/**
 * Verify webhook signature
 * @param {string} body - Raw request body
 * @param {string} signature - X-Razorpay-Signature header
 * @returns {boolean} Is webhook authentic
 */
const verifyWebhookSignature = (body, signature) => {
  if (!isRazorpayEnabled) {
    console.log('[MOCK RAZORPAY] Verifying webhook signature');
    return true;
  }

  const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
  if (!webhookSecret) {
    console.warn('Razorpay webhook secret not configured');
    return false;
  }

  const expectedSignature = crypto
    .createHmac('sha256', webhookSecret)
    .update(body)
    .digest('hex');

  return expectedSignature === signature;
};

/**
 * Fetch payment details
 * @param {string} paymentId - Razorpay payment ID
 * @returns {Promise<object>} Payment details
 */
const fetchPayment = async (paymentId) => {
  initializeRazorpay();

  if (!isRazorpayEnabled) {
    console.log('[MOCK RAZORPAY] Fetching payment:', paymentId);
    return {
      id: paymentId,
      entity: 'payment',
      amount: 100000,
      currency: 'INR',
      status: 'captured',
      method: 'upi',
      email: 'test@example.com',
      contact: '+919999999999',
      mock: true
    };
  }

  try {
    const payment = await razorpay.payments.fetch(paymentId);
    return payment;
  } catch (error) {
    console.error('Failed to fetch payment:', error);
    throw new Error(`Failed to fetch payment: ${error.message}`);
  }
};

/**
 * Fetch order details
 * @param {string} orderId - Razorpay order ID
 * @returns {Promise<object>} Order details
 */
const fetchOrder = async (orderId) => {
  initializeRazorpay();

  if (!isRazorpayEnabled) {
    console.log('[MOCK RAZORPAY] Fetching order:', orderId);
    return {
      id: orderId,
      entity: 'order',
      amount: 100000,
      amount_paid: 100000,
      amount_due: 0,
      currency: 'INR',
      status: 'paid',
      mock: true
    };
  }

  try {
    const order = await razorpay.orders.fetch(orderId);
    return order;
  } catch (error) {
    console.error('Failed to fetch order:', error);
    throw new Error(`Failed to fetch order: ${error.message}`);
  }
};

/**
 * Initiate refund
 * @param {string} paymentId - Razorpay payment ID
 * @param {number} amount - Refund amount (optional, full refund if not provided)
 * @returns {Promise<object>} Refund details
 */
const initiateRefund = async (paymentId, amount = null) => {
  initializeRazorpay();

  const refundOptions = {};
  if (amount) {
    refundOptions.amount = Math.round(amount * 100); // Convert to paise
  }

  if (!isRazorpayEnabled) {
    console.log('[MOCK RAZORPAY] Initiating refund for:', paymentId);
    return {
      id: `rfnd_mock_${Date.now()}`,
      entity: 'refund',
      amount: refundOptions.amount || 100000,
      currency: 'INR',
      payment_id: paymentId,
      status: 'processed',
      mock: true
    };
  }

  try {
    const refund = await razorpay.payments.refund(paymentId, refundOptions);
    return refund;
  } catch (error) {
    console.error('Refund initiation failed:', error);
    throw new Error(`Refund failed: ${error.message}`);
  }
};

// Payment status constants
const PaymentStatus = {
  PENDING: 'pending',
  CREATED: 'created',
  AUTHORIZED: 'authorized',
  CAPTURED: 'captured',
  FAILED: 'failed',
  REFUNDED: 'refunded',
  PARTIALLY_REFUNDED: 'partially_refunded'
};

// Webhook event types
const WebhookEvents = {
  PAYMENT_AUTHORIZED: 'payment.authorized',
  PAYMENT_CAPTURED: 'payment.captured',
  PAYMENT_FAILED: 'payment.failed',
  ORDER_PAID: 'order.paid',
  REFUND_CREATED: 'refund.created',
  REFUND_PROCESSED: 'refund.processed'
};

module.exports = {
  initializeRazorpay,
  isEnabled,
  getKeyId,
  createPaymentOrder,
  verifyPaymentSignature,
  verifyWebhookSignature,
  fetchPayment,
  fetchOrder,
  initiateRefund,
  PaymentStatus,
  WebhookEvents
};

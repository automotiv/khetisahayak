const db = require('../db');
const asyncHandler = require('express-async-handler');
const paymentService = require('../services/paymentService');

// @desc    Initiate payment for an order
// @route   POST /api/payments/initiate
// @access  Private
const initiatePayment = asyncHandler(async (req, res) => {
  const { order_id } = req.body;

  if (!order_id) {
    res.status(400);
    throw new Error('Order ID is required');
  }

  // Get order details
  const orderResult = await db.query(
    'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
    [order_id, req.user.id]
  );

  if (orderResult.rows.length === 0) {
    res.status(404);
    throw new Error('Order not found');
  }

  const order = orderResult.rows[0];

  // Check if order is in a payable state
  if (order.status !== 'pending' && order.payment_status !== 'pending') {
    res.status(400);
    throw new Error('Order is not in a payable state');
  }

  // Check if there's already a pending payment
  const existingPayment = await db.query(
    `SELECT * FROM payments WHERE order_id = $1 AND status IN ('created', 'authorized')`,
    [order_id]
  );

  if (existingPayment.rows.length > 0) {
    const payment = existingPayment.rows[0];
    return res.json({
      success: true,
      payment: {
        razorpay_order_id: payment.razorpay_order_id,
        amount: payment.amount,
        currency: payment.currency,
        key: paymentService.getKeyId()
      }
    });
  }

  // Create Razorpay order
  const razorpayOrder = await paymentService.createPaymentOrder(
    order.total_amount,
    order.id.toString(),
    { user_id: req.user.id }
  );

  // Store payment record
  const paymentResult = await db.query(
    `INSERT INTO payments (
      order_id, user_id, razorpay_order_id, amount, currency, status
    ) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
    [
      order_id,
      req.user.id,
      razorpayOrder.id,
      order.total_amount,
      'INR',
      'created'
    ]
  );

  res.json({
    success: true,
    payment: {
      id: paymentResult.rows[0].id,
      razorpay_order_id: razorpayOrder.id,
      amount: razorpayOrder.amount,
      currency: razorpayOrder.currency,
      key: paymentService.getKeyId()
    }
  });
});

// @desc    Verify payment after completion
// @route   POST /api/payments/verify
// @access  Private
const verifyPayment = asyncHandler(async (req, res) => {
  const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

  if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
    res.status(400);
    throw new Error('Missing required payment verification parameters');
  }

  // Verify signature
  const isValid = paymentService.verifyPaymentSignature(
    razorpay_order_id,
    razorpay_payment_id,
    razorpay_signature
  );

  if (!isValid) {
    res.status(400);
    throw new Error('Invalid payment signature');
  }

  // Get payment record
  const paymentResult = await db.query(
    'SELECT * FROM payments WHERE razorpay_order_id = $1',
    [razorpay_order_id]
  );

  if (paymentResult.rows.length === 0) {
    res.status(404);
    throw new Error('Payment record not found');
  }

  const payment = paymentResult.rows[0];

  // Verify user owns this payment
  if (payment.user_id !== req.user.id) {
    res.status(403);
    throw new Error('Unauthorized access to payment');
  }

  // Update payment record
  await db.query(
    `UPDATE payments SET
      razorpay_payment_id = $1,
      razorpay_signature = $2,
      status = 'captured',
      paid_at = CURRENT_TIMESTAMP,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = $3`,
    [razorpay_payment_id, razorpay_signature, payment.id]
  );

  // Update order status
  await db.query(
    `UPDATE orders SET
      payment_status = 'paid',
      status = 'confirmed',
      updated_at = CURRENT_TIMESTAMP
    WHERE id = $1`,
    [payment.order_id]
  );

  res.json({
    success: true,
    message: 'Payment verified successfully',
    order_id: payment.order_id
  });
});

// @desc    Handle Razorpay webhook
// @route   POST /api/payments/webhook
// @access  Public (verified by signature)
const handleWebhook = asyncHandler(async (req, res) => {
  const signature = req.headers['x-razorpay-signature'];
  const body = JSON.stringify(req.body);

  // Verify webhook signature
  if (!paymentService.verifyWebhookSignature(body, signature)) {
    res.status(400);
    throw new Error('Invalid webhook signature');
  }

  const event = req.body.event;
  const payload = req.body.payload;

  console.log('Razorpay webhook received:', event);

  switch (event) {
    case 'payment.captured': {
      const payment = payload.payment.entity;
      await handlePaymentCaptured(payment);
      break;
    }
    case 'payment.failed': {
      const payment = payload.payment.entity;
      await handlePaymentFailed(payment);
      break;
    }
    case 'refund.created':
    case 'refund.processed': {
      const refund = payload.refund.entity;
      await handleRefund(refund);
      break;
    }
    default:
      console.log('Unhandled webhook event:', event);
  }

  res.json({ status: 'ok' });
});

// Helper: Handle payment captured event
const handlePaymentCaptured = async (razorpayPayment) => {
  const paymentResult = await db.query(
    'SELECT * FROM payments WHERE razorpay_order_id = $1',
    [razorpayPayment.order_id]
  );

  if (paymentResult.rows.length === 0) {
    console.log('Payment record not found for order:', razorpayPayment.order_id);
    return;
  }

  const payment = paymentResult.rows[0];

  // Update payment
  await db.query(
    `UPDATE payments SET
      razorpay_payment_id = $1,
      status = 'captured',
      payment_method = $2,
      paid_at = CURRENT_TIMESTAMP,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = $3`,
    [razorpayPayment.id, razorpayPayment.method, payment.id]
  );

  // Update order
  await db.query(
    `UPDATE orders SET
      payment_status = 'paid',
      status = 'confirmed',
      updated_at = CURRENT_TIMESTAMP
    WHERE id = $1`,
    [payment.order_id]
  );

  console.log('Payment captured for order:', payment.order_id);
};

// Helper: Handle payment failed event
const handlePaymentFailed = async (razorpayPayment) => {
  const paymentResult = await db.query(
    'SELECT * FROM payments WHERE razorpay_order_id = $1',
    [razorpayPayment.order_id]
  );

  if (paymentResult.rows.length === 0) {
    return;
  }

  const payment = paymentResult.rows[0];

  await db.query(
    `UPDATE payments SET
      status = 'failed',
      error_message = $1,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = $2`,
    [razorpayPayment.error_description || 'Payment failed', payment.id]
  );

  console.log('Payment failed for order:', payment.order_id);
};

// Helper: Handle refund event
const handleRefund = async (refund) => {
  const paymentResult = await db.query(
    'SELECT * FROM payments WHERE razorpay_payment_id = $1',
    [refund.payment_id]
  );

  if (paymentResult.rows.length === 0) {
    return;
  }

  const payment = paymentResult.rows[0];

  // Record refund
  await db.query(
    `INSERT INTO refunds (payment_id, razorpay_refund_id, amount, status)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (razorpay_refund_id) DO UPDATE SET status = $4`,
    [payment.id, refund.id, refund.amount / 100, refund.status]
  );

  // Update payment status
  const totalRefunded = await db.query(
    'SELECT SUM(amount) as total FROM refunds WHERE payment_id = $1',
    [payment.id]
  );

  const refundedAmount = totalRefunded.rows[0].total || 0;
  const newStatus = refundedAmount >= payment.amount ? 'refunded' : 'partially_refunded';

  await db.query(
    `UPDATE payments SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`,
    [newStatus, payment.id]
  );

  console.log('Refund processed for payment:', payment.id);
};

// @desc    Get payment details
// @route   GET /api/payments/:id
// @access  Private
const getPayment = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `SELECT p.*, o.total_amount as order_total, o.status as order_status
     FROM payments p
     JOIN orders o ON p.order_id = o.id
     WHERE p.id = $1 AND p.user_id = $2`,
    [id, req.user.id]
  );

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Payment not found');
  }

  res.json({
    success: true,
    payment: result.rows[0]
  });
});

// @desc    Get payment history
// @route   GET /api/payments
// @access  Private
const getPaymentHistory = asyncHandler(async (req, res) => {
  const { page = 1, limit = 10 } = req.query;
  const offset = (page - 1) * limit;

  const result = await db.query(
    `SELECT p.*, o.total_amount as order_total
     FROM payments p
     JOIN orders o ON p.order_id = o.id
     WHERE p.user_id = $1
     ORDER BY p.created_at DESC
     LIMIT $2 OFFSET $3`,
    [req.user.id, limit, offset]
  );

  const countResult = await db.query(
    'SELECT COUNT(*) FROM payments WHERE user_id = $1',
    [req.user.id]
  );

  res.json({
    success: true,
    payments: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(countResult.rows[0].count / limit),
      total_items: parseInt(countResult.rows[0].count)
    }
  });
});

// @desc    Request refund
// @route   POST /api/payments/:id/refund
// @access  Private
const requestRefund = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { amount, reason } = req.body;

  const paymentResult = await db.query(
    'SELECT * FROM payments WHERE id = $1 AND user_id = $2',
    [id, req.user.id]
  );

  if (paymentResult.rows.length === 0) {
    res.status(404);
    throw new Error('Payment not found');
  }

  const payment = paymentResult.rows[0];

  if (payment.status !== 'captured') {
    res.status(400);
    throw new Error('Only captured payments can be refunded');
  }

  if (!payment.razorpay_payment_id) {
    res.status(400);
    throw new Error('No Razorpay payment ID found');
  }

  // Initiate refund
  const refund = await paymentService.initiateRefund(
    payment.razorpay_payment_id,
    amount
  );

  // Record refund request
  await db.query(
    `INSERT INTO refunds (payment_id, razorpay_refund_id, amount, status, reason)
     VALUES ($1, $2, $3, $4, $5)`,
    [payment.id, refund.id, (refund.amount / 100), 'pending', reason]
  );

  res.json({
    success: true,
    message: 'Refund initiated',
    refund: {
      id: refund.id,
      amount: refund.amount / 100,
      status: refund.status
    }
  });
});

module.exports = {
  initiatePayment,
  verifyPayment,
  handleWebhook,
  getPayment,
  getPaymentHistory,
  requestRefund
};

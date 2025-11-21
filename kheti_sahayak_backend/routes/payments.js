const express = require('express');
const { body } = require('express-validator');
const {
  initiatePayment,
  verifyPayment,
  handleWebhook,
  getPayment,
  getPaymentHistory,
  requestRefund
} = require('../controllers/paymentController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

/**
 * @swagger
 * tags:
 *   name: Payments
 *   description: Payment processing with Razorpay
 */

/**
 * @swagger
 * /api/payments/initiate:
 *   post:
 *     summary: Initiate payment for an order
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - order_id
 *             properties:
 *               order_id:
 *                 type: string
 *                 format: uuid
 *                 description: Order ID to pay for
 *     responses:
 *       200:
 *         description: Payment order created
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 payment:
 *                   type: object
 *                   properties:
 *                     razorpay_order_id:
 *                       type: string
 *                     amount:
 *                       type: number
 *                     currency:
 *                       type: string
 *                     key:
 *                       type: string
 */
router.post(
  '/initiate',
  protect,
  [body('order_id', 'Order ID is required').isUUID()],
  initiatePayment
);

/**
 * @swagger
 * /api/payments/verify:
 *   post:
 *     summary: Verify payment after completion
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - razorpay_order_id
 *               - razorpay_payment_id
 *               - razorpay_signature
 *             properties:
 *               razorpay_order_id:
 *                 type: string
 *               razorpay_payment_id:
 *                 type: string
 *               razorpay_signature:
 *                 type: string
 *     responses:
 *       200:
 *         description: Payment verified successfully
 *       400:
 *         description: Invalid signature or payment
 */
router.post(
  '/verify',
  protect,
  [
    body('razorpay_order_id', 'Razorpay order ID is required').notEmpty(),
    body('razorpay_payment_id', 'Razorpay payment ID is required').notEmpty(),
    body('razorpay_signature', 'Signature is required').notEmpty()
  ],
  verifyPayment
);

/**
 * @swagger
 * /api/payments/webhook:
 *   post:
 *     summary: Razorpay webhook handler
 *     tags: [Payments]
 *     description: Called by Razorpay to notify payment events
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Webhook processed
 */
router.post('/webhook', handleWebhook);

/**
 * @swagger
 * /api/payments:
 *   get:
 *     summary: Get payment history
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *     responses:
 *       200:
 *         description: List of payments
 */
router.get('/', protect, getPaymentHistory);

/**
 * @swagger
 * /api/payments/{id}:
 *   get:
 *     summary: Get payment details
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Payment details
 *       404:
 *         description: Payment not found
 */
router.get('/:id', protect, getPayment);

/**
 * @swagger
 * /api/payments/{id}/refund:
 *   post:
 *     summary: Request refund for a payment
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               amount:
 *                 type: number
 *                 description: Refund amount (optional, full refund if not provided)
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: Refund initiated
 */
router.post('/:id/refund', protect, requestRefund);

module.exports = router;

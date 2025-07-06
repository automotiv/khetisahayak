const express = require('express');
const { body } = require('express-validator');
const {
  createOrder,
  getUserOrders,
  getOrderById,
  updateOrderStatus,
  cancelOrder,
  getSellerOrders,
} = require('../controllers/orderController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Validation rules for order creation
const orderValidationRules = [
  body('items', 'Items must be an array').isArray({ min: 1 }),
  body('items.*.product_id', 'Product ID is required').isUUID(),
  body('items.*.quantity', 'Quantity must be a positive integer').isInt({ min: 1 }),
  body('shipping_address', 'Shipping address is required').not().isEmpty().trim(),
  body('payment_method', 'Payment method is required').not().isEmpty().trim(),
];

// Validation rules for order status update
const statusUpdateValidationRules = [
  body('status', 'Valid status is required').isIn(['pending', 'confirmed', 'shipped', 'delivered', 'cancelled']),
];

// All routes are protected
router.use(protect);

// Order management routes
router.post('/', orderValidationRules, createOrder);
router.get('/', getUserOrders);
router.get('/seller', getSellerOrders);
router.get('/:id', getOrderById);
router.put('/:id/status', statusUpdateValidationRules, updateOrderStatus);
router.put('/:id/cancel', cancelOrder);

module.exports = router; 
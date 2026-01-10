const express = require('express');
const { query, param, body } = require('express-validator');
const {
  getSellerDashboard,
  getSellerOrders,
  getSellerRevenue,
  getSellerAnalytics,
  getSellerInventory,
  updateInventory,
} = require('../controllers/sellerController');
const { protect } = require('../middleware/authMiddleware');
const { validateRequest } = require('../middleware/errorMiddleware');

const router = express.Router();

const ordersQueryValidation = [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('status').optional().isIn(['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'])
    .withMessage('Invalid status value'),
  query('start_date').optional().isISO8601().withMessage('Start date must be a valid ISO 8601 date'),
  query('end_date').optional().isISO8601().withMessage('End date must be a valid ISO 8601 date'),
];

const revenueQueryValidation = [
  query('period').optional().isIn(['7d', '30d', '90d', '1y']).withMessage('Period must be 7d, 30d, 90d, or 1y'),
];

const inventoryQueryValidation = [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('low_stock').optional().isIn(['true', 'false']).withMessage('low_stock must be true or false'),
  query('sort_by').optional().isIn(['name', 'price', 'stock_quantity', 'created_at', 'updated_at'])
    .withMessage('Invalid sort_by field'),
  query('sort_order').optional().isIn(['ASC', 'DESC', 'asc', 'desc']).withMessage('sort_order must be ASC or DESC'),
];

const updateInventoryValidation = [
  param('productId').isUUID().withMessage('Product ID must be a valid UUID'),
  body('stock_quantity').isInt({ min: 0 }).withMessage('Stock quantity must be a non-negative integer'),
];

router.use(protect);

router.get('/dashboard', getSellerDashboard);

router.get('/orders', ordersQueryValidation, validateRequest, getSellerOrders);

router.get('/revenue', revenueQueryValidation, validateRequest, getSellerRevenue);

router.get('/analytics', getSellerAnalytics);

router.get('/inventory', inventoryQueryValidation, validateRequest, getSellerInventory);

router.put('/inventory/:productId', updateInventoryValidation, validateRequest, updateInventory);

module.exports = router;

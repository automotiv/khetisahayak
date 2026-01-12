const express = require('express');
const asyncHandler = require('express-async-handler');
const { body, query, param, validationResult } = require('express-validator');
const { protect } = require('../middleware/authMiddleware');
const mandiPriceService = require('../services/mandiPriceService');

const router = express.Router();

const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  next();
};

/**
 * @swagger
 * /api/market-prices:
 *   get:
 *     summary: Get real-time mandi prices for commodities
 *     tags: [Market Prices]
 *     parameters:
 *       - in: query
 *         name: state
 *         schema:
 *           type: string
 *         description: State name (e.g., Maharashtra, Punjab)
 *       - in: query
 *         name: commodity
 *         schema:
 *           type: string
 *         description: Commodity name (e.g., Rice, Wheat, Cotton)
 *       - in: query
 *         name: district
 *         schema:
 *           type: string
 *         description: District name
 *       - in: query
 *         name: market
 *         schema:
 *           type: string
 *         description: Market/Mandi name
 *       - in: query
 *         name: refresh
 *         schema:
 *           type: boolean
 *         description: Force refresh from source (bypass cache)
 *     responses:
 *       200:
 *         description: List of market prices with real-time data
 */
router.get('/', asyncHandler(async (req, res) => {
  const { state, commodity, district, market, refresh } = req.query;
  
  const result = await mandiPriceService.getMandiPrices({
    state: state || 'Maharashtra',
    commodity,
    district,
    market,
    forceRefresh: refresh === 'true'
  });

  res.json(result);
}));

/**
 * @swagger
 * /api/market-prices/states:
 *   get:
 *     summary: Get list of Indian states for market price lookup
 *     tags: [Market Prices]
 *     responses:
 *       200:
 *         description: List of Indian states
 */
router.get('/states', asyncHandler(async (req, res) => {
  const states = mandiPriceService.getStates();
  res.json({
    success: true,
    count: states.length,
    data: states
  });
}));

/**
 * @swagger
 * /api/market-prices/commodities:
 *   get:
 *     summary: Get list of supported commodities
 *     tags: [Market Prices]
 *     responses:
 *       200:
 *         description: List of supported commodities with Hindi names
 */
router.get('/commodities', asyncHandler(async (req, res) => {
  const commodities = mandiPriceService.getSupportedCommodities();
  res.json({
    success: true,
    count: commodities.length,
    data: commodities
  });
}));

/**
 * @swagger
 * /api/market-prices/trends:
 *   get:
 *     summary: Get price trends for a commodity
 *     tags: [Market Prices]
 *     parameters:
 *       - in: query
 *         name: commodity
 *         required: true
 *         schema:
 *           type: string
 *         description: Commodity name
 *       - in: query
 *         name: state
 *         schema:
 *           type: string
 *         description: State name for filtering
 *       - in: query
 *         name: market
 *         schema:
 *           type: string
 *         description: Market name for filtering
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [daily, weekly, monthly]
 *           default: weekly
 *         description: Trend period
 *     responses:
 *       200:
 *         description: Price trend data with change percentages
 */
router.get('/trends', [
  query('commodity').notEmpty().withMessage('Commodity is required'),
  handleValidationErrors
], asyncHandler(async (req, res) => {
  const { commodity, state, market, period } = req.query;
  
  const result = await mandiPriceService.getPriceTrends({
    commodity,
    state,
    market,
    period: period || 'weekly'
  });

  res.json(result);
}));

/**
 * @swagger
 * /api/market-prices/msp:
 *   get:
 *     summary: Get Minimum Support Prices (MSP) for crops
 *     tags: [Market Prices]
 *     parameters:
 *       - in: query
 *         name: crop
 *         schema:
 *           type: string
 *         description: Crop name (optional, returns all if not specified)
 *       - in: query
 *         name: year
 *         schema:
 *           type: integer
 *         description: Year for MSP (defaults to current year)
 *     responses:
 *       200:
 *         description: MSP data for crops
 */
router.get('/msp', asyncHandler(async (req, res) => {
  const { crop, year } = req.query;
  
  const result = await mandiPriceService.getMSPPrices({
    crop,
    year: year ? parseInt(year) : undefined
  });

  res.json(result);
}));

/**
 * @swagger
 * /api/market-prices/compare-msp:
 *   get:
 *     summary: Compare current market prices with MSP
 *     tags: [Market Prices]
 *     parameters:
 *       - in: query
 *         name: commodity
 *         required: true
 *         schema:
 *           type: string
 *         description: Commodity name to compare
 *       - in: query
 *         name: state
 *         schema:
 *           type: string
 *         description: State for market prices
 *       - in: query
 *         name: market
 *         schema:
 *           type: string
 *         description: Specific market
 *     responses:
 *       200:
 *         description: Comparison of market prices vs MSP with recommendations
 */
router.get('/compare-msp', [
  query('commodity').notEmpty().withMessage('Commodity is required'),
  handleValidationErrors
], asyncHandler(async (req, res) => {
  const { commodity, state, market } = req.query;
  
  const result = await mandiPriceService.comparePriceWithMSP({
    commodity,
    state,
    market
  });

  res.json(result);
}));

router.use(protect);

/**
 * @swagger
 * /api/market-prices/alerts:
 *   get:
 *     summary: Get user's price alert subscriptions
 *     tags: [Market Prices]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of user's price alerts
 */
router.get('/alerts', asyncHandler(async (req, res) => {
  const result = await mandiPriceService.getUserPriceAlerts(req.user.id);
  res.json(result);
}));

/**
 * @swagger
 * /api/market-prices/alerts:
 *   post:
 *     summary: Create a price alert subscription
 *     tags: [Market Prices]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - commodity
 *             properties:
 *               commodity:
 *                 type: string
 *                 description: Commodity to monitor
 *               state:
 *                 type: string
 *                 description: State for filtering
 *               district:
 *                 type: string
 *               market:
 *                 type: string
 *               alert_type:
 *                 type: string
 *                 enum: [threshold, percentage_change, msp_comparison]
 *                 default: threshold
 *               threshold_price:
 *                 type: number
 *                 description: Price threshold (per quintal)
 *               threshold_direction:
 *                 type: string
 *                 enum: [above, below, both]
 *                 default: above
 *               percentage_change:
 *                 type: number
 *                 description: Alert on X% change
 *               compare_to_msp:
 *                 type: boolean
 *                 default: false
 *               msp_threshold_percent:
 *                 type: number
 *                 default: 100
 *                 description: Alert when price is below X% of MSP
 *               notification_channels:
 *                 type: array
 *                 items:
 *                   type: string
 *                   enum: [push, sms, email, in_app]
 *                 default: [push, in_app]
 *     responses:
 *       201:
 *         description: Price alert created successfully
 */
router.post('/alerts', [
  body('commodity').notEmpty().withMessage('Commodity is required'),
  body('alert_type').optional().isIn(['threshold', 'percentage_change', 'msp_comparison']),
  body('threshold_direction').optional().isIn(['above', 'below', 'both']),
  body('threshold_price').optional().isFloat({ min: 0 }),
  body('percentage_change').optional().isFloat({ min: 0, max: 100 }),
  body('msp_threshold_percent').optional().isFloat({ min: 0, max: 200 }),
  handleValidationErrors
], asyncHandler(async (req, res) => {
  const result = await mandiPriceService.createPriceAlert(req.user.id, req.body);
  
  if (result.success) {
    res.status(201).json(result);
  } else {
    res.status(400).json(result);
  }
}));

/**
 * @swagger
 * /api/market-prices/alerts/{id}:
 *   put:
 *     summary: Update a price alert subscription
 *     tags: [Market Prices]
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
 *               threshold_price:
 *                 type: number
 *               threshold_direction:
 *                 type: string
 *               percentage_change:
 *                 type: number
 *               compare_to_msp:
 *                 type: boolean
 *               msp_threshold_percent:
 *                 type: number
 *               notification_channels:
 *                 type: array
 *               is_active:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Alert updated successfully
 */
router.put('/alerts/:id', [
  param('id').isUUID().withMessage('Invalid alert ID'),
  handleValidationErrors
], asyncHandler(async (req, res) => {
  const result = await mandiPriceService.updatePriceAlert(req.user.id, req.params.id, req.body);
  
  if (result.success) {
    res.json(result);
  } else {
    res.status(404).json(result);
  }
}));

/**
 * @swagger
 * /api/market-prices/alerts/{id}:
 *   delete:
 *     summary: Delete a price alert subscription
 *     tags: [Market Prices]
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
 *         description: Alert deleted successfully
 */
router.delete('/alerts/:id', [
  param('id').isUUID().withMessage('Invalid alert ID'),
  handleValidationErrors
], asyncHandler(async (req, res) => {
  const result = await mandiPriceService.deletePriceAlert(req.user.id, req.params.id);
  
  if (result.success) {
    res.json(result);
  } else {
    res.status(404).json(result);
  }
}));

/**
 * @swagger
 * /api/market-prices/alerts/history:
 *   get:
 *     summary: Get triggered alert history
 *     tags: [Market Prices]
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
 *           default: 20
 *       - in: query
 *         name: is_read
 *         schema:
 *           type: boolean
 *     responses:
 *       200:
 *         description: Alert history with pagination
 */
router.get('/alerts/history', asyncHandler(async (req, res) => {
  const { page, limit, is_read } = req.query;
  
  const result = await mandiPriceService.getPriceAlertHistory(req.user.id, {
    page: page ? parseInt(page) : 1,
    limit: limit ? parseInt(limit) : 20,
    is_read: is_read !== undefined ? is_read === 'true' : undefined
  });

  res.json(result);
}));

module.exports = router;

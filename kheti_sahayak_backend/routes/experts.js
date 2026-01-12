const express = require('express');
const { query, param, body } = require('express-validator');
const router = express.Router();
const db = require('../db');
const asyncHandler = require('express-async-handler');
const { protect, authorize } = require('../middleware/authMiddleware');
const {
  handleValidationErrors,
  validateUUID,
  validatePagination,
  validateDate
} = require('../middleware/validationMiddleware');

const expertQueryValidation = [
  ...validatePagination,
  query('specialization').optional().trim().isLength({ max: 100 }),
  query('min_rating').optional().isFloat({ min: 0, max: 5 }).toFloat(),
  query('language').optional().trim().isLength({ max: 50 }),
  query('is_verified').optional().isBoolean().toBoolean(),
  query('is_online').optional().isBoolean().toBoolean(),
  query('max_fee').optional().isFloat({ min: 0 }).toFloat(),
  query('sort').optional().isIn(['rating', 'consultations', 'fee_low', 'fee_high', 'experience']),
  handleValidationErrors
];

const getExperts = asyncHandler(async (req, res) => {
  const { 
    page = 1, 
    limit = 10, 
    specialization, 
    min_rating, 
    language, 
    is_verified, 
    is_online,
    max_fee,
    sort = 'rating' 
  } = req.query;

  let query = `
    SELECT 
      ep.id,
      ep.user_id,
      ep.specialization,
      ep.expertise_areas,
      ep.qualification,
      ep.experience_years,
      ep.bio,
      ep.languages,
      ep.consultation_fee,
      ep.rating,
      ep.total_reviews,
      ep.total_consultations,
      ep.is_verified,
      ep.is_active,
      ep.profile_image_url,
      u.username,
      u.first_name,
      u.last_name,
      u.profile_image,
      CASE WHEN ea.expert_id IS NOT NULL THEN true ELSE false END as is_online
    FROM expert_profiles ep
    JOIN users u ON ep.user_id = u.id
    LEFT JOIN (
      SELECT DISTINCT expert_id FROM expert_availability 
      WHERE is_available = true 
      AND day_of_week = EXTRACT(DOW FROM CURRENT_DATE)::integer
    ) ea ON ea.expert_id = ep.user_id
    WHERE ep.is_active = true
  `;
  
  const queryParams = [];
  let paramCount = 0;

  if (specialization) {
    paramCount++;
    query += ` AND LOWER(ep.specialization) LIKE LOWER($${paramCount})`;
    queryParams.push(`%${specialization}%`);
  }

  if (min_rating) {
    paramCount++;
    query += ` AND ep.rating >= $${paramCount}`;
    queryParams.push(parseFloat(min_rating));
  }

  if (language) {
    paramCount++;
    query += ` AND $${paramCount} = ANY(ep.languages)`;
    queryParams.push(language);
  }

  if (is_verified !== undefined) {
    paramCount++;
    query += ` AND ep.is_verified = $${paramCount}`;
    queryParams.push(is_verified);
  }

  if (max_fee) {
    paramCount++;
    query += ` AND ep.consultation_fee <= $${paramCount}`;
    queryParams.push(parseFloat(max_fee));
  }

  const sortOptions = {
    rating: 'ep.rating DESC, ep.total_consultations DESC',
    consultations: 'ep.total_consultations DESC, ep.rating DESC',
    fee_low: 'ep.consultation_fee ASC',
    fee_high: 'ep.consultation_fee DESC',
    experience: 'ep.experience_years DESC'
  };

  query += ` ORDER BY ${sortOptions[sort] || sortOptions.rating}`;

  const offset = (parseInt(page) - 1) * parseInt(limit);
  paramCount++;
  query += ` LIMIT $${paramCount}`;
  queryParams.push(parseInt(limit));
  
  paramCount++;
  query += ` OFFSET $${paramCount}`;
  queryParams.push(offset);

  const result = await db.query(query, queryParams);

  let countQuery = `
    SELECT COUNT(*) FROM expert_profiles ep
    JOIN users u ON ep.user_id = u.id
    WHERE ep.is_active = true
  `;
  const countParams = [];
  let countParamIdx = 0;

  if (specialization) {
    countParamIdx++;
    countQuery += ` AND LOWER(ep.specialization) LIKE LOWER($${countParamIdx})`;
    countParams.push(`%${specialization}%`);
  }

  if (min_rating) {
    countParamIdx++;
    countQuery += ` AND ep.rating >= $${countParamIdx}`;
    countParams.push(parseFloat(min_rating));
  }

  if (language) {
    countParamIdx++;
    countQuery += ` AND $${countParamIdx} = ANY(ep.languages)`;
    countParams.push(language);
  }

  if (is_verified !== undefined) {
    countParamIdx++;
    countQuery += ` AND ep.is_verified = $${countParamIdx}`;
    countParams.push(is_verified);
  }

  if (max_fee) {
    countParamIdx++;
    countQuery += ` AND ep.consultation_fee <= $${countParamIdx}`;
    countParams.push(parseFloat(max_fee));
  }

  const countResult = await db.query(countQuery, countParams);
  const totalCount = parseInt(countResult.rows[0].count);

  res.json({
    success: true,
    experts: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(totalCount / parseInt(limit)),
      total_items: totalCount,
      items_per_page: parseInt(limit)
    }
  });
});

const getExpertById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `SELECT 
      ep.*,
      u.username,
      u.first_name,
      u.last_name,
      u.email,
      u.phone,
      u.profile_image
    FROM expert_profiles ep
    JOIN users u ON ep.user_id = u.id
    WHERE ep.user_id = $1 AND ep.is_active = true`,
    [id]
  );

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Expert not found');
  }

  const availabilityResult = await db.query(
    `SELECT * FROM expert_availability WHERE expert_id = $1 ORDER BY day_of_week`,
    [id]
  );

  const recentReviewsResult = await db.query(
    `SELECT cr.rating, cr.review_text, cr.created_at, u.first_name, u.last_name
     FROM consultation_reviews cr
     JOIN users u ON cr.farmer_id = u.id
     WHERE cr.expert_id = $1
     ORDER BY cr.created_at DESC
     LIMIT 5`,
    [id]
  );

  res.json({
    success: true,
    expert: {
      ...result.rows[0],
      availability: availabilityResult.rows,
      recent_reviews: recentReviewsResult.rows
    }
  });
});

const getExpertSpecializations = asyncHandler(async (req, res) => {
  const result = await db.query(
    `SELECT DISTINCT specialization, COUNT(*) as expert_count
     FROM expert_profiles
     WHERE is_active = true
     GROUP BY specialization
     ORDER BY expert_count DESC`
  );

  res.json({
    success: true,
    specializations: result.rows
  });
});

const getTopExperts = asyncHandler(async (req, res) => {
  const { limit = 5 } = req.query;

  const result = await db.query(
    `SELECT 
      ep.user_id,
      ep.specialization,
      ep.rating,
      ep.total_consultations,
      ep.consultation_fee,
      ep.profile_image_url,
      u.first_name,
      u.last_name,
      u.profile_image
    FROM expert_profiles ep
    JOIN users u ON ep.user_id = u.id
    WHERE ep.is_active = true AND ep.is_verified = true
    ORDER BY ep.rating DESC, ep.total_consultations DESC
    LIMIT $1`,
    [parseInt(limit)]
  );

  res.json({
    success: true,
    top_experts: result.rows
  });
});

const getExpertDashboard = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const profileResult = await db.query(
    `SELECT * FROM expert_profiles WHERE user_id = $1`,
    [userId]
  );

  if (profileResult.rows.length === 0) {
    res.status(404);
    throw new Error('Expert profile not found');
  }

  const earningsResult = await db.query(
    `SELECT 
      COALESCE(SUM(amount), 0) as total_earnings,
      COALESCE(SUM(CASE WHEN DATE(completed_at) >= DATE_TRUNC('month', CURRENT_DATE) THEN amount ELSE 0 END), 0) as month_earnings,
      COALESCE(SUM(CASE WHEN DATE(completed_at) >= CURRENT_DATE - INTERVAL '7 days' THEN amount ELSE 0 END), 0) as week_earnings
     FROM consultations
     WHERE expert_id = $1 AND status = 'completed' AND payment_status = 'paid'`,
    [userId]
  );

  const consultationStatsResult = await db.query(
    `SELECT 
      COUNT(*) FILTER (WHERE status = 'completed') as completed,
      COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled,
      COUNT(*) FILTER (WHERE status = 'pending') as pending,
      COUNT(*) FILTER (WHERE status = 'confirmed') as upcoming,
      COUNT(*) FILTER (WHERE DATE(scheduled_at) = CURRENT_DATE AND status IN ('confirmed', 'in_progress')) as today
     FROM consultations
     WHERE expert_id = $1`,
    [userId]
  );

  const upcomingConsultations = await db.query(
    `SELECT c.id, c.scheduled_at, c.duration_minutes, c.consultation_type, c.issue_description,
            u.first_name, u.last_name, u.profile_image
     FROM consultations c
     JOIN users u ON c.farmer_id = u.id
     WHERE c.expert_id = $1 AND c.status IN ('confirmed', 'pending') AND c.scheduled_at > NOW()
     ORDER BY c.scheduled_at ASC
     LIMIT 5`,
    [userId]
  );

  const platformFeePercent = 0.10;
  const earnings = earningsResult.rows[0];
  const expertEarnings = {
    total: Math.round(parseFloat(earnings.total_earnings) * (1 - platformFeePercent) * 100) / 100,
    this_month: Math.round(parseFloat(earnings.month_earnings) * (1 - platformFeePercent) * 100) / 100,
    this_week: Math.round(parseFloat(earnings.week_earnings) * (1 - platformFeePercent) * 100) / 100
  };

  res.json({
    success: true,
    dashboard: {
      profile: profileResult.rows[0],
      earnings: expertEarnings,
      consultation_stats: consultationStatsResult.rows[0],
      upcoming_consultations: upcomingConsultations.rows
    }
  });
});

const getExpertEarnings = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { period = 'month', page = 1, limit = 20 } = req.query;

  let dateFilter = '';
  if (period === 'week') {
    dateFilter = `AND c.call_ended_at >= CURRENT_DATE - INTERVAL '7 days'`;
  } else if (period === 'month') {
    dateFilter = `AND c.call_ended_at >= DATE_TRUNC('month', CURRENT_DATE)`;
  } else if (period === 'year') {
    dateFilter = `AND c.call_ended_at >= DATE_TRUNC('year', CURRENT_DATE)`;
  }

  const transactionsResult = await db.query(
    `SELECT 
      c.id,
      c.scheduled_at,
      c.call_ended_at as completed_at,
      c.amount as gross_amount,
      c.amount * 0.90 as net_amount,
      c.duration_minutes,
      u.first_name,
      u.last_name
     FROM consultations c
     JOIN users u ON c.farmer_id = u.id
     WHERE c.expert_id = $1 AND c.status = 'completed' AND c.payment_status = 'paid' ${dateFilter}
     ORDER BY c.call_ended_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, parseInt(limit), (parseInt(page) - 1) * parseInt(limit)]
  );

  const summaryResult = await db.query(
    `SELECT 
      COALESCE(SUM(amount * 0.90), 0) as total_earnings,
      COUNT(*) as total_consultations,
      COALESCE(AVG(amount * 0.90), 0) as avg_per_consultation
     FROM consultations
     WHERE expert_id = $1 AND status = 'completed' AND payment_status = 'paid' ${dateFilter}`,
    [userId]
  );

  res.json({
    success: true,
    period,
    summary: {
      total_earnings: Math.round(parseFloat(summaryResult.rows[0].total_earnings) * 100) / 100,
      total_consultations: parseInt(summaryResult.rows[0].total_consultations),
      avg_per_consultation: Math.round(parseFloat(summaryResult.rows[0].avg_per_consultation) * 100) / 100
    },
    transactions: transactionsResult.rows
  });
});

const setDateOverride = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { date, is_available, reason } = req.body;

  const expertResult = await db.query(
    `SELECT id FROM expert_profiles WHERE user_id = $1`,
    [userId]
  );

  if (expertResult.rows.length === 0) {
    res.status(404);
    throw new Error('Expert profile not found');
  }

  const result = await db.query(
    `INSERT INTO expert_date_overrides (expert_id, date, is_available, reason)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (expert_id, date) DO UPDATE SET
       is_available = EXCLUDED.is_available,
       reason = EXCLUDED.reason,
       updated_at = CURRENT_TIMESTAMP
     RETURNING *`,
    [userId, date, is_available, reason]
  );

  res.json({
    success: true,
    message: is_available ? 'Date marked as available' : 'Date marked as unavailable',
    override: result.rows[0]
  });
});

const getDateOverrides = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { start_date, end_date } = req.query;

  let query = `SELECT * FROM expert_date_overrides WHERE expert_id = $1`;
  const params = [userId];

  if (start_date) {
    query += ` AND date >= $${params.length + 1}`;
    params.push(start_date);
  }

  if (end_date) {
    query += ` AND date <= $${params.length + 1}`;
    params.push(end_date);
  }

  query += ` ORDER BY date`;

  const result = await db.query(query, params);

  res.json({
    success: true,
    overrides: result.rows
  });
});

const deleteDateOverride = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { date } = req.params;

  const result = await db.query(
    `DELETE FROM expert_date_overrides WHERE expert_id = $1 AND date = $2 RETURNING id`,
    [userId, date]
  );

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Date override not found');
  }

  res.json({
    success: true,
    message: 'Date override removed'
  });
});

router.get('/', expertQueryValidation, getExperts);

router.get('/specializations', getExpertSpecializations);

router.get('/top', [
  query('limit').optional().isInt({ min: 1, max: 20 }).toInt(),
  handleValidationErrors
], getTopExperts);

router.get('/dashboard', protect, getExpertDashboard);

router.get('/earnings', protect, [
  query('period').optional().isIn(['week', 'month', 'year', 'all']),
  ...validatePagination,
  handleValidationErrors
], getExpertEarnings);

router.get('/date-overrides', protect, [
  query('start_date').optional().isISO8601(),
  query('end_date').optional().isISO8601(),
  handleValidationErrors
], getDateOverrides);

router.post('/date-override', protect, [
  body('date').isISO8601().withMessage('Date must be in YYYY-MM-DD format'),
  body('is_available').isBoolean().toBoolean(),
  body('reason').optional().trim().isLength({ max: 500 }),
  handleValidationErrors
], setDateOverride);

router.delete('/date-override/:date', protect, [
  param('date').isISO8601().withMessage('Date must be in YYYY-MM-DD format'),
  handleValidationErrors
], deleteDateOverride);

router.get('/:id', [validateUUID('id', 'param'), handleValidationErrors], getExpertById);

module.exports = router;

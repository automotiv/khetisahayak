const { uploadFileToS3 } = require('../s3');
const db = require('../db');
const asyncHandler = require('express-async-handler');

// Placeholder for AI/ML service integration
const analyzeImageWithAI = async (imageUrl, cropType) => {
  // In a real application, this would call an external AI/ML service
  // For now, we'll simulate different responses based on crop type
  const mockResponses = {
    'tomato': {
      disease: 'Early Blight',
      confidence: 0.85,
      recommendations: 'Apply fungicide containing chlorothalonil. Improve air circulation and avoid overhead watering.',
      severity: 'moderate'
    },
    'potato': {
      disease: 'Late Blight',
      confidence: 0.92,
      recommendations: 'Remove infected plants immediately. Apply copper-based fungicide. Ensure proper drainage.',
      severity: 'high'
    },
    'corn': {
      disease: 'Common Rust',
      confidence: 0.78,
      recommendations: 'Apply fungicide with active ingredients like azoxystrobin. Plant resistant varieties next season.',
      severity: 'low'
    },
    'wheat': {
      disease: 'Powdery Mildew',
      confidence: 0.88,
      recommendations: 'Apply sulfur-based fungicide. Increase plant spacing for better air circulation.',
      severity: 'moderate'
    }
  };

  const response = mockResponses[cropType.toLowerCase()] || {
    disease: 'Unknown Disease',
    confidence: 0.65,
    recommendations: 'Please consult with an agricultural expert for proper diagnosis.',
    severity: 'unknown'
  };

  return response;
};

// @desc    Upload image for crop diagnosis
// @route   POST /api/diagnostics/upload
// @access  Private
const uploadForDiagnosis = asyncHandler(async (req, res) => {
  if (!req.file) {
    res.status(400);
    throw new Error('No image file provided');
  }

  const { crop_type, issue_description } = req.body;
  if (!crop_type || !issue_description) {
    res.status(400);
    throw new Error('Crop type and issue description are required.');
  }

  const file = req.file;
  const fileName = `diagnostics/${req.user.id}/${Date.now()}-${file.originalname}`;

  const imageUrl = await uploadFileToS3(file.buffer, fileName, file.mimetype);
  const aiResults = await analyzeImageWithAI(imageUrl, crop_type);

  const diagnosisResultText = `Disease: ${aiResults.disease} (Confidence: ${(aiResults.confidence * 100).toFixed(1)}%)`;

  // Save diagnostic record to database
  const result = await db.query(
    `INSERT INTO diagnostics (
      user_id, crop_type, issue_description, image_urls, 
      diagnosis_result, recommendations, confidence_score, status
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
    [
      req.user.id, 
      crop_type, 
      issue_description, 
      [imageUrl], 
      diagnosisResultText, 
      aiResults.recommendations,
      aiResults.confidence,
      'analyzed'
    ]
  );

  res.status(200).json({
    message: 'Image uploaded and analyzed successfully',
    diagnosticRecord: result.rows[0],
    aiAnalysis: aiResults
  });
});

// @desc    Get user's diagnostic history
// @route   GET /api/diagnostics
// @access  Private
const getDiagnosticHistory = asyncHandler(async (req, res) => {
  const { page = 1, limit = 10, status, crop_type } = req.query;

  let query = `
    SELECT d.*, u.username as expert_name, u.first_name as expert_first_name, u.last_name as expert_last_name
    FROM diagnostics d
    LEFT JOIN users u ON d.expert_review_id = u.id
    WHERE d.user_id = $1
  `;
  
  const queryParams = [req.user.id];
  let paramCount = 1;

  if (status) {
    paramCount++;
    query += ` AND d.status = $${paramCount}`;
    queryParams.push(status);
  }

  if (crop_type) {
    paramCount++;
    query += ` AND d.crop_type ILIKE $${paramCount}`;
    queryParams.push(`%${crop_type}%`);
  }

  query += ` ORDER BY d.created_at DESC`;

  // Add pagination
  const offset = (page - 1) * limit;
  paramCount++;
  query += ` LIMIT $${paramCount}`;
  queryParams.push(parseInt(limit));
  
  paramCount++;
  query += ` OFFSET $${paramCount}`;
  queryParams.push(offset);

  const result = await db.query(query, queryParams);

  // Get total count
  let countQuery = 'SELECT COUNT(*) FROM diagnostics WHERE user_id = $1';
  const countParams = [req.user.id];

  if (status) {
    countQuery += ' AND status = $2';
    countParams.push(status);
  }

  if (crop_type) {
    countQuery += ' AND crop_type ILIKE $3';
    countParams.push(`%${crop_type}%`);
  }

  const countResult = await db.query(countQuery, countParams);
  const totalCount = parseInt(countResult.rows[0].count);

  res.json({
    diagnostics: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(totalCount / limit),
      total_items: totalCount,
      items_per_page: parseInt(limit)
    }
  });
});

// @desc    Get diagnostic by ID
// @route   GET /api/diagnostics/:id
// @access  Private
const getDiagnosticById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `SELECT d.*, 
            u.username as expert_name, u.first_name as expert_first_name, u.last_name as expert_last_name,
            u.phone as expert_phone
     FROM diagnostics d
     LEFT JOIN users u ON d.expert_review_id = u.id
     WHERE d.id = $1 AND d.user_id = $2`,
    [id, req.user.id]
  );

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Diagnostic record not found');
  }

  res.json(result.rows[0]);
});

// @desc    Request expert review
// @route   POST /api/diagnostics/:id/expert-review
// @access  Private
const requestExpertReview = asyncHandler(async (req, res) => {
  const { id } = req.params;

  // Check if diagnostic exists and belongs to user
  const diagnosticResult = await db.query(
    'SELECT * FROM diagnostics WHERE id = $1 AND user_id = $2',
    [id, req.user.id]
  );

  if (diagnosticResult.rows.length === 0) {
    res.status(404);
    throw new Error('Diagnostic record not found');
  }

  const diagnostic = diagnosticResult.rows[0];

  if (diagnostic.status === 'resolved') {
    res.status(400);
    throw new Error('Cannot request review for resolved diagnostic');
  }

  // Find available experts
  const expertsResult = await db.query(
    'SELECT id, username, first_name, last_name FROM users WHERE role = $1',
    ['expert']
  );

  if (expertsResult.rows.length === 0) {
    res.status(503);
    throw new Error('No experts available at the moment');
  }

  // For now, assign to the first available expert
  // In a real system, you might want to implement expert selection logic
  const expert = expertsResult.rows[0];

  const result = await db.query(
    `UPDATE diagnostics 
     SET expert_review_id = $1, status = $2, updated_at = CURRENT_TIMESTAMP 
     WHERE id = $3 RETURNING *`,
    [expert.id, 'pending', id]
  );

  // Create notification for expert
  await db.query(
    `INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [
      expert.id,
      'New Diagnostic Review Request',
      `New crop diagnostic review requested for ${diagnostic.crop_type}`,
      'info',
      'diagnostic',
      id
    ]
  );

  res.json({
    message: 'Expert review requested successfully',
    diagnostic: result.rows[0],
    assigned_expert: {
      id: expert.id,
      name: `${expert.first_name} ${expert.last_name}`,
      username: expert.username
    }
  });
});

// @desc    Expert review submission
// @route   PUT /api/diagnostics/:id/expert-review
// @access  Private (Expert only)
const submitExpertReview = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { expert_diagnosis, expert_recommendations, severity_level } = req.body;

  if (!expert_diagnosis || !expert_recommendations) {
    res.status(400);
    throw new Error('Expert diagnosis and recommendations are required');
  }

  // Check if diagnostic exists and is assigned to this expert
  const diagnosticResult = await db.query(
    'SELECT * FROM diagnostics WHERE id = $1 AND expert_review_id = $2',
    [id, req.user.id]
  );

  if (diagnosticResult.rows.length === 0) {
    res.status(404);
    throw new Error('Diagnostic record not found or not assigned to you');
  }

  const diagnostic = diagnosticResult.rows[0];

  if (diagnostic.status === 'resolved') {
    res.status(400);
    throw new Error('Diagnostic is already resolved');
  }

  const result = await db.query(
    `UPDATE diagnostics 
     SET diagnosis_result = $1, recommendations = $2, status = $3, updated_at = CURRENT_TIMESTAMP 
     WHERE id = $4 RETURNING *`,
    [
      `Expert Diagnosis: ${expert_diagnosis}`,
      expert_recommendations,
      'resolved',
      id
    ]
  );

  // Create notification for user
  await db.query(
    `INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [
      diagnostic.user_id,
      'Expert Review Complete',
      `Your crop diagnostic for ${diagnostic.crop_type} has been reviewed by an expert`,
      'success',
      'diagnostic',
      id
    ]
  );

  res.json({
    message: 'Expert review submitted successfully',
    diagnostic: result.rows[0]
  });
});

// @desc    Get expert's assigned diagnostics
// @route   GET /api/diagnostics/expert/assigned
// @access  Private (Expert only)
const getExpertAssignedDiagnostics = asyncHandler(async (req, res) => {
  const { page = 1, limit = 10, status } = req.query;

  let query = `
    SELECT d.*, u.username, u.first_name, u.last_name, u.phone
    FROM diagnostics d
    JOIN users u ON d.user_id = u.id
    WHERE d.expert_review_id = $1
  `;
  
  const queryParams = [req.user.id];
  let paramCount = 1;

  if (status) {
    paramCount++;
    query += ` AND d.status = $${paramCount}`;
    queryParams.push(status);
  }

  query += ` ORDER BY d.created_at DESC`;

  // Add pagination
  const offset = (page - 1) * limit;
  paramCount++;
  query += ` LIMIT $${paramCount}`;
  queryParams.push(parseInt(limit));
  
  paramCount++;
  query += ` OFFSET $${paramCount}`;
  queryParams.push(offset);

  const result = await db.query(query, queryParams);

  res.json({
    diagnostics: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(result.rows.length / limit),
      items_per_page: parseInt(limit)
    }
  });
});

// @desc    Get crop recommendations
// @route   GET /api/diagnostics/recommendations
// @access  Public
const getCropRecommendations = asyncHandler(async (req, res) => {
  const { season, soil_type, climate_zone } = req.query;

  let query = 'SELECT * FROM crop_recommendations WHERE 1=1';
  const queryParams = [];
  let paramCount = 0;

  if (season) {
    paramCount++;
    query += ` AND season = $${paramCount}`;
    queryParams.push(season);
  }

  if (soil_type) {
    paramCount++;
    query += ` AND soil_type ILIKE $${paramCount}`;
    queryParams.push(`%${soil_type}%`);
  }

  if (climate_zone) {
    paramCount++;
    query += ` AND climate_zone ILIKE $${paramCount}`;
    queryParams.push(`%${climate_zone}%`);
  }

  query += ' ORDER BY crop_name';

  const result = await db.query(query, queryParams);

  res.json(result.rows);
});

module.exports = {
  uploadForDiagnosis,
  getDiagnosticHistory,
  getDiagnosticById,
  requestExpertReview,
  submitExpertReview,
  getExpertAssignedDiagnostics,
  getCropRecommendations,
};
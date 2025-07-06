const { uploadFileToS3 } = require('../s3');
const db = require('../db');
const asyncHandler = require('express-async-handler');

// Enhanced AI/ML service integration with more realistic responses
const analyzeImageWithAI = async (imageUrl, cropType, issueDescription) => {
  // In a real application, this would call an external AI/ML service
  // For now, we'll simulate different responses based on crop type and issue description
  const mockResponses = {
    'tomato': {
      'yellow leaves': {
        disease: 'Early Blight',
        confidence: 0.85,
        recommendations: 'Apply fungicide containing chlorothalonil. Improve air circulation and avoid overhead watering. Remove infected leaves immediately.',
        severity: 'moderate',
        symptoms: ['Yellow leaves with brown spots', 'Circular lesions on leaves', 'Stem cankers'],
        treatment_steps: [
          'Remove and destroy infected plant parts',
          'Apply copper-based fungicide every 7-10 days',
          'Improve plant spacing for better air circulation',
          'Avoid overhead irrigation'
        ]
      },
      'wilting': {
        disease: 'Bacterial Wilt',
        confidence: 0.92,
        recommendations: 'Remove infected plants immediately. Disinfect tools. Plant resistant varieties next season.',
        severity: 'high',
        symptoms: ['Sudden wilting', 'Brown vascular tissue', 'No recovery after watering'],
        treatment_steps: [
          'Remove and destroy infected plants',
          'Disinfect all gardening tools',
          'Rotate crops next season',
          'Plant resistant varieties'
        ]
      },
      'spots on leaves': {
        disease: 'Septoria Leaf Spot',
        confidence: 0.78,
        recommendations: 'Apply fungicide with active ingredients like azoxystrobin. Remove infected leaves.',
        severity: 'low',
        symptoms: ['Small brown spots with gray centers', 'Yellow halos around spots'],
        treatment_steps: [
          'Remove infected leaves',
          'Apply fungicide every 7-10 days',
          'Improve air circulation',
          'Avoid overhead watering'
        ]
      }
    },
    'potato': {
      'brown spots': {
        disease: 'Late Blight',
        confidence: 0.95,
        recommendations: 'Remove infected plants immediately. Apply copper-based fungicide. Ensure proper drainage.',
        severity: 'high',
        symptoms: ['Dark brown spots on leaves', 'White fungal growth on underside', 'Rapid spread'],
        treatment_steps: [
          'Remove and destroy infected plants',
          'Apply copper fungicide immediately',
          'Improve field drainage',
          'Plant resistant varieties next season'
        ]
      },
      'yellow leaves': {
        disease: 'Early Blight',
        confidence: 0.88,
        recommendations: 'Apply fungicide and improve air circulation. Remove infected leaves.',
        severity: 'moderate',
        symptoms: ['Target-like lesions', 'Yellowing leaves', 'Stem lesions'],
        treatment_steps: [
          'Remove infected leaves',
          'Apply fungicide every 7-10 days',
          'Improve plant spacing',
          'Avoid overhead irrigation'
        ]
      }
    },
    'corn': {
      'rust colored': {
        disease: 'Common Rust',
        confidence: 0.82,
        recommendations: 'Apply fungicide with active ingredients like azoxystrobin. Plant resistant varieties next season.',
        severity: 'moderate',
        symptoms: ['Rust-colored pustules on leaves', 'Yellow halos around lesions'],
        treatment_steps: [
          'Apply fungicide at first sign',
          'Plant resistant varieties next season',
          'Remove crop debris after harvest',
          'Monitor weather conditions'
        ]
      },
      'gray spots': {
        disease: 'Gray Leaf Spot',
        confidence: 0.75,
        recommendations: 'Apply fungicide and improve air circulation. Plant resistant varieties.',
        severity: 'moderate',
        symptoms: ['Gray to tan rectangular lesions', 'Lesions with parallel edges'],
        treatment_steps: [
          'Apply fungicide when lesions appear',
          'Improve field drainage',
          'Plant resistant varieties',
          'Rotate crops'
        ]
      }
    },
    'wheat': {
      'white powder': {
        disease: 'Powdery Mildew',
        confidence: 0.90,
        recommendations: 'Apply sulfur-based fungicide. Increase plant spacing for better air circulation.',
        severity: 'moderate',
        symptoms: ['White powdery growth on leaves', 'Yellowing of leaves', 'Stunted growth'],
        treatment_steps: [
          'Apply sulfur fungicide',
          'Improve air circulation',
          'Avoid excessive nitrogen fertilization',
          'Plant resistant varieties'
        ]
      },
      'brown spots': {
        disease: 'Septoria Leaf Blotch',
        confidence: 0.85,
        recommendations: 'Apply fungicide and remove infected plant debris. Improve field drainage.',
        severity: 'moderate',
        symptoms: ['Brown lesions with yellow halos', 'Small black dots in lesions'],
        treatment_steps: [
          'Apply fungicide at flag leaf stage',
          'Remove crop debris',
          'Improve field drainage',
          'Plant resistant varieties'
        ]
      }
    }
  };

  // Find the best matching response based on crop type and issue description
  const cropResponses = mockResponses[cropType.toLowerCase()] || {};
  let bestMatch = null;
  let highestConfidence = 0;

  for (const [key, response] of Object.entries(cropResponses)) {
    if (issueDescription.toLowerCase().includes(key) && response.confidence > highestConfidence) {
      bestMatch = response;
      highestConfidence = response.confidence;
    }
  }

  // If no specific match found, return a generic response
  if (!bestMatch) {
    bestMatch = {
      disease: 'Unknown Disease',
      confidence: 0.65,
      recommendations: 'Please consult with an agricultural expert for proper diagnosis. The symptoms may indicate multiple possible issues.',
      severity: 'unknown',
      symptoms: ['Various symptoms observed', 'Requires expert examination'],
      treatment_steps: [
        'Consult with agricultural expert',
        'Take detailed photos of symptoms',
        'Monitor plant development',
        'Consider soil testing'
      ]
    };
  }

  return bestMatch;
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

  try {
    const imageUrl = await uploadFileToS3(file.buffer, fileName, file.mimetype);
    const aiResults = await analyzeImageWithAI(imageUrl, crop_type, issue_description);

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

    res.status(201).json({
      success: true,
      message: 'Image uploaded and analyzed successfully',
      diagnostic: result.rows[0],
      aiAnalysis: {
        disease: aiResults.disease,
        confidence: aiResults.confidence,
        severity: aiResults.severity,
        symptoms: aiResults.symptoms,
        treatment_steps: aiResults.treatment_steps,
        recommendations: aiResults.recommendations
      }
    });
  } catch (error) {
    console.error('Error in uploadForDiagnosis:', error);
    res.status(500);
    throw new Error('Failed to process image. Please try again.');
  }
});

// @desc    Get user's diagnostic history
// @route   GET /api/diagnostics
// @access  Private
const getDiagnosticHistory = asyncHandler(async (req, res) => {
  const { page = 1, limit = 10, status, crop_type, severity } = req.query;

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
    success: true,
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

  res.json({
    success: true,
    diagnostic: result.rows[0]
  });
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

  if (diagnostic.expert_review_id) {
    res.status(400);
    throw new Error('Expert review already requested for this diagnostic');
  }

  // Find available experts
  const expertsResult = await db.query(
    'SELECT id, username, first_name, last_name FROM users WHERE role = $1',
    ['expert']
  );

  if (expertsResult.rows.length === 0) {
    res.status(503);
    throw new Error('No experts available at the moment. Please try again later.');
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
    success: true,
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
  const { expert_diagnosis, expert_recommendations, severity_level, treatment_plan } = req.body;

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
    success: true,
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

  // Get total count for pagination
  let countQuery = 'SELECT COUNT(*) FROM diagnostics WHERE expert_review_id = $1';
  const countParams = [req.user.id];

  if (status) {
    countQuery += ' AND status = $2';
    countParams.push(status);
  }

  const countResult = await db.query(countQuery, countParams);
  const totalCount = parseInt(countResult.rows[0].count);

  res.json({
    success: true,
    diagnostics: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(totalCount / limit),
      total_items: totalCount,
      items_per_page: parseInt(limit)
    }
  });
});

// @desc    Get crop recommendations
// @route   GET /api/diagnostics/recommendations
// @access  Public
const getCropRecommendations = asyncHandler(async (req, res) => {
  const { season, soil_type, climate_zone, water_availability } = req.query;

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

  if (water_availability) {
    paramCount++;
    query += ` AND water_requirement = $${paramCount}`;
    queryParams.push(water_availability);
  }

  query += ' ORDER BY crop_name';

  const result = await db.query(query, queryParams);

  res.json({
    success: true,
    recommendations: result.rows
  });
});

// @desc    Get diagnostic statistics
// @route   GET /api/diagnostics/stats
// @access  Private
const getDiagnosticStats = asyncHandler(async (req, res) => {
  // Get total diagnostics for user
  const totalDiagnostics = await db.query(
    'SELECT COUNT(*) FROM diagnostics WHERE user_id = $1',
    [req.user.id]
  );

  // Get diagnostics by status
  const statusStats = await db.query(
    `SELECT status, COUNT(*) as count 
     FROM diagnostics 
     WHERE user_id = $1 
     GROUP BY status`,
    [req.user.id]
  );

  // Get diagnostics by crop type
  const cropStats = await db.query(
    `SELECT crop_type, COUNT(*) as count 
     FROM diagnostics 
     WHERE user_id = $1 
     GROUP BY crop_type 
     ORDER BY count DESC 
     LIMIT 5`,
    [req.user.id]
  );

  // Get recent diagnostics
  const recentDiagnostics = await db.query(
    `SELECT crop_type, status, created_at 
     FROM diagnostics 
     WHERE user_id = $1 
     ORDER BY created_at DESC 
     LIMIT 5`,
    [req.user.id]
  );

  res.json({
    success: true,
    stats: {
      total_diagnostics: parseInt(totalDiagnostics.rows[0].count),
      by_status: statusStats.rows,
      by_crop_type: cropStats.rows,
      recent_diagnostics: recentDiagnostics.rows
    }
  });
});

module.exports = {
  uploadForDiagnosis,
  getDiagnosticHistory,
  getDiagnosticById,
  requestExpertReview,
  submitExpertReview,
  getExpertAssignedDiagnostics,
  getCropRecommendations,
  getDiagnosticStats,
};
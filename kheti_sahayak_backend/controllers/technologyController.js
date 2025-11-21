/**
 * Technology Controller
 *
 * Handles New Technology Adoption Hub operations (Epic #396)
 */

const asyncHandler = require('express-async-handler');
const db = require('../db');

/**
 * Get all technology categories
 */
const getCategories = asyncHandler(async (req, res) => {
  const result = await db.query(`
    SELECT
      tc.*,
      (SELECT COUNT(*) FROM agricultural_technologies at WHERE at.category_id = tc.id AND at.is_active = true) as technology_count
    FROM technology_categories tc
    WHERE tc.is_active = true
    ORDER BY tc.display_order, tc.name
  `);

  res.json({
    success: true,
    data: result.rows
  });
});

/**
 * Create technology category (Admin only)
 */
const createCategory = asyncHandler(async (req, res) => {
  const { name, name_hi, description, icon, display_order } = req.body;

  if (!name) {
    res.status(400);
    throw new Error('Category name is required');
  }

  const result = await db.query(`
    INSERT INTO technology_categories (name, name_hi, description, icon, display_order)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *
  `, [name, name_hi, description, icon, display_order || 0]);

  res.status(201).json({
    success: true,
    data: result.rows[0]
  });
});

/**
 * Get technologies with filters
 */
const getTechnologies = asyncHandler(async (req, res) => {
  const {
    category_id,
    difficulty_level,
    min_cost,
    max_cost,
    is_featured,
    search,
    page = 1,
    limit = 20
  } = req.query;

  const offset = (page - 1) * limit;
  const conditions = ['at.is_active = true'];
  const params = [];

  if (category_id) {
    params.push(category_id);
    conditions.push(`at.category_id = $${params.length}`);
  }

  if (difficulty_level) {
    params.push(difficulty_level);
    conditions.push(`at.difficulty_level = $${params.length}`);
  }

  if (min_cost) {
    params.push(min_cost);
    conditions.push(`at.implementation_cost_min >= $${params.length}`);
  }

  if (max_cost) {
    params.push(max_cost);
    conditions.push(`at.implementation_cost_max <= $${params.length}`);
  }

  if (is_featured === 'true') {
    conditions.push('at.is_featured = true');
  }

  if (search) {
    params.push(`%${search}%`);
    conditions.push(`(at.name ILIKE $${params.length} OR at.description ILIKE $${params.length})`);
  }

  params.push(limit, offset);

  const query = `
    SELECT
      at.*,
      tc.name as category_name,
      tc.name_hi as category_name_hi,
      (SELECT COUNT(*) FROM courses c WHERE c.technology_id = at.id AND c.is_active = true) as course_count
    FROM agricultural_technologies at
    JOIN technology_categories tc ON at.category_id = tc.id
    WHERE ${conditions.join(' AND ')}
    ORDER BY at.is_featured DESC, at.adoption_count DESC, at.created_at DESC
    LIMIT $${params.length - 1} OFFSET $${params.length}
  `;

  const countQuery = `
    SELECT COUNT(*) FROM agricultural_technologies at WHERE ${conditions.slice(0, -2).join(' AND ')}
  `;

  const [techResult, countResult] = await Promise.all([
    db.query(query, params),
    db.query(countQuery, params.slice(0, -2))
  ]);

  res.json({
    success: true,
    data: techResult.rows,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: parseInt(countResult.rows[0].count),
      pages: Math.ceil(countResult.rows[0].count / limit)
    }
  });
});

/**
 * Get single technology by ID or slug
 */
const getTechnologyById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  // Check if id is UUID or slug
  const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
  const whereClause = isUUID ? 'at.id = $1' : 'at.slug = $1';

  const result = await db.query(`
    SELECT
      at.*,
      tc.name as category_name,
      tc.name_hi as category_name_hi
    FROM agricultural_technologies at
    JOIN technology_categories tc ON at.category_id = tc.id
    WHERE ${whereClause}
  `, [id]);

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Technology not found');
  }

  // Get related courses
  const coursesResult = await db.query(`
    SELECT id, title, title_hi, thumbnail_url, duration_minutes, difficulty_level, is_free, average_rating
    FROM courses
    WHERE technology_id = $1 AND is_active = true
    ORDER BY is_featured DESC, enrollment_count DESC
    LIMIT 5
  `, [result.rows[0].id]);

  // Get recent experiences
  const experiencesResult = await db.query(`
    SELECT
      te.*,
      u.full_name as user_name
    FROM technology_experiences te
    JOIN users u ON te.user_id = u.id
    WHERE te.technology_id = $1
    ORDER BY te.created_at DESC
    LIMIT 5
  `, [result.rows[0].id]);

  res.json({
    success: true,
    data: {
      ...result.rows[0],
      courses: coursesResult.rows,
      experiences: experiencesResult.rows
    }
  });
});

/**
 * Create technology (Admin only)
 */
const createTechnology = asyncHandler(async (req, res) => {
  const {
    category_id, name, name_hi, slug, description, description_hi,
    benefits, suitable_crops, suitable_farm_sizes,
    implementation_cost_min, implementation_cost_max,
    expected_roi_percent, payback_period_months, difficulty_level,
    images, video_url, implementation_steps, required_resources,
    government_subsidies, is_featured
  } = req.body;

  if (!category_id || !name) {
    res.status(400);
    throw new Error('Category and name are required');
  }

  const result = await db.query(`
    INSERT INTO agricultural_technologies (
      category_id, name, name_hi, slug, description, description_hi,
      benefits, suitable_crops, suitable_farm_sizes,
      implementation_cost_min, implementation_cost_max,
      expected_roi_percent, payback_period_months, difficulty_level,
      images, video_url, implementation_steps, required_resources,
      government_subsidies, is_featured
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
    RETURNING *
  `, [
    category_id, name, name_hi, slug || name.toLowerCase().replace(/\s+/g, '-'),
    description, description_hi,
    JSON.stringify(benefits || []), JSON.stringify(suitable_crops || []),
    JSON.stringify(suitable_farm_sizes || []),
    implementation_cost_min, implementation_cost_max,
    expected_roi_percent, payback_period_months, difficulty_level || 'medium',
    JSON.stringify(images || []), video_url,
    JSON.stringify(implementation_steps || []), JSON.stringify(required_resources || []),
    JSON.stringify(government_subsidies || []), is_featured || false
  ]);

  res.status(201).json({
    success: true,
    data: result.rows[0]
  });
});

/**
 * Calculate ROI for a technology
 */
const calculateROI = asyncHandler(async (req, res) => {
  const { technology_id, farm_size_acres, current_yield, current_income, implementation_cost } = req.body;

  // Get technology data
  const techResult = await db.query(
    'SELECT * FROM agricultural_technologies WHERE id = $1',
    [technology_id]
  );

  if (techResult.rows.length === 0) {
    res.status(404);
    throw new Error('Technology not found');
  }

  const tech = techResult.rows[0];

  // Calculate estimated values
  const estimatedROI = tech.expected_roi_percent || 25;
  const estimatedIncrease = (current_income * estimatedROI) / 100;
  const actualCost = implementation_cost || tech.implementation_cost_min || 50000;
  const paybackMonths = tech.payback_period_months || Math.ceil((actualCost / estimatedIncrease) * 12);

  const roi = {
    technology_name: tech.name,
    input_data: {
      farm_size_acres,
      current_yield,
      current_income,
      implementation_cost: actualCost
    },
    projections: {
      estimated_roi_percent: estimatedROI,
      estimated_annual_increase: Math.round(estimatedIncrease),
      estimated_payback_months: paybackMonths,
      estimated_5_year_benefit: Math.round(estimatedIncrease * 5 - actualCost),
      break_even_date: new Date(Date.now() + paybackMonths * 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    },
    recommendations: [
      paybackMonths <= 12 ? 'Quick payback period - highly recommended' : 'Consider phased implementation',
      estimatedROI >= 30 ? 'High ROI potential' : 'Moderate returns expected',
      'Check for government subsidies to reduce initial cost'
    ]
  };

  res.json({
    success: true,
    data: roi
  });
});

/**
 * Get courses list
 */
const getCourses = asyncHandler(async (req, res) => {
  const {
    technology_id,
    difficulty_level,
    is_free,
    language,
    page = 1,
    limit = 20
  } = req.query;

  const offset = (page - 1) * limit;
  const conditions = ['c.is_active = true'];
  const params = [];

  if (technology_id) {
    params.push(technology_id);
    conditions.push(`c.technology_id = $${params.length}`);
  }

  if (difficulty_level) {
    params.push(difficulty_level);
    conditions.push(`c.difficulty_level = $${params.length}`);
  }

  if (is_free !== undefined) {
    params.push(is_free === 'true');
    conditions.push(`c.is_free = $${params.length}`);
  }

  if (language) {
    params.push(language);
    conditions.push(`c.language = $${params.length}`);
  }

  params.push(limit, offset);

  const result = await db.query(`
    SELECT
      c.*,
      at.name as technology_name,
      (SELECT COUNT(*) FROM course_modules cm WHERE cm.course_id = c.id) as module_count
    FROM courses c
    LEFT JOIN agricultural_technologies at ON c.technology_id = at.id
    WHERE ${conditions.join(' AND ')}
    ORDER BY c.is_featured DESC, c.enrollment_count DESC
    LIMIT $${params.length - 1} OFFSET $${params.length}
  `, params);

  res.json({
    success: true,
    data: result.rows
  });
});

/**
 * Get course details with modules and lessons
 */
const getCourseById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user?.id;

  // Check if id is UUID or slug
  const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
  const whereClause = isUUID ? 'c.id = $1' : 'c.slug = $1';

  const courseResult = await db.query(`
    SELECT
      c.*,
      at.name as technology_name
    FROM courses c
    LEFT JOIN agricultural_technologies at ON c.technology_id = at.id
    WHERE ${whereClause}
  `, [id]);

  if (courseResult.rows.length === 0) {
    res.status(404);
    throw new Error('Course not found');
  }

  const course = courseResult.rows[0];

  // Get modules with lessons
  const modulesResult = await db.query(`
    SELECT * FROM course_modules
    WHERE course_id = $1
    ORDER BY order_index
  `, [course.id]);

  const modules = await Promise.all(modulesResult.rows.map(async (module) => {
    const lessonsResult = await db.query(`
      SELECT id, title, title_hi, content_type, duration_minutes, order_index, is_preview
      FROM course_lessons
      WHERE module_id = $1
      ORDER BY order_index
    `, [module.id]);

    return {
      ...module,
      lessons: lessonsResult.rows
    };
  }));

  // Get user enrollment if authenticated
  let enrollment = null;
  if (userId) {
    const enrollmentResult = await db.query(`
      SELECT * FROM course_enrollments
      WHERE course_id = $1 AND user_id = $2
    `, [course.id, userId]);
    enrollment = enrollmentResult.rows[0] || null;
  }

  res.json({
    success: true,
    data: {
      ...course,
      modules,
      enrollment
    }
  });
});

/**
 * Enroll in a course
 */
const enrollInCourse = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { course_id } = req.body;

  if (!course_id) {
    res.status(400);
    throw new Error('Course ID is required');
  }

  // Check if course exists
  const courseResult = await db.query(
    'SELECT * FROM courses WHERE id = $1 AND is_active = true',
    [course_id]
  );

  if (courseResult.rows.length === 0) {
    res.status(404);
    throw new Error('Course not found');
  }

  // Check if already enrolled
  const existingEnrollment = await db.query(
    'SELECT id FROM course_enrollments WHERE course_id = $1 AND user_id = $2',
    [course_id, userId]
  );

  if (existingEnrollment.rows.length > 0) {
    res.status(400);
    throw new Error('Already enrolled in this course');
  }

  // Create enrollment
  const result = await db.query(`
    INSERT INTO course_enrollments (course_id, user_id)
    VALUES ($1, $2)
    RETURNING *
  `, [course_id, userId]);

  // Increment enrollment count
  await db.query(`
    UPDATE courses SET enrollment_count = enrollment_count + 1 WHERE id = $1
  `, [course_id]);

  res.status(201).json({
    success: true,
    data: result.rows[0]
  });
});

/**
 * Update course progress
 */
const updateCourseProgress = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { course_id, lesson_id } = req.body;

  // Get enrollment
  const enrollmentResult = await db.query(`
    SELECT * FROM course_enrollments WHERE course_id = $1 AND user_id = $2
  `, [course_id, userId]);

  if (enrollmentResult.rows.length === 0) {
    res.status(400);
    throw new Error('Not enrolled in this course');
  }

  const enrollment = enrollmentResult.rows[0];
  let completedLessons = enrollment.completed_lessons || [];

  // Add lesson to completed if not already
  if (!completedLessons.includes(lesson_id)) {
    completedLessons.push(lesson_id);
  }

  // Calculate progress
  const totalLessonsResult = await db.query(`
    SELECT COUNT(*) FROM course_lessons cl
    JOIN course_modules cm ON cl.module_id = cm.id
    WHERE cm.course_id = $1
  `, [course_id]);

  const totalLessons = parseInt(totalLessonsResult.rows[0].count);
  const progressPercent = totalLessons > 0 ? (completedLessons.length / totalLessons) * 100 : 0;
  const status = progressPercent >= 100 ? 'completed' : 'in_progress';

  const updates = {
    completed_lessons: JSON.stringify(completedLessons),
    last_lesson_id: lesson_id,
    progress_percent: progressPercent,
    status
  };

  if (status === 'completed' && enrollment.status !== 'completed') {
    updates.completed_at = new Date().toISOString();
    // Increment completion count
    await db.query('UPDATE courses SET completion_count = completion_count + 1 WHERE id = $1', [course_id]);
  }

  const result = await db.query(`
    UPDATE course_enrollments
    SET completed_lessons = $1, last_lesson_id = $2, progress_percent = $3, status = $4,
        completed_at = $5
    WHERE id = $6
    RETURNING *
  `, [updates.completed_lessons, updates.last_lesson_id, updates.progress_percent, updates.status,
      updates.completed_at || enrollment.completed_at, enrollment.id]);

  res.json({
    success: true,
    data: result.rows[0]
  });
});

/**
 * Get user's enrolled courses
 */
const getMyCourses = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { status, page = 1, limit = 20 } = req.query;
  const offset = (page - 1) * limit;

  const conditions = ['ce.user_id = $1'];
  const params = [userId];

  if (status) {
    params.push(status);
    conditions.push(`ce.status = $${params.length}`);
  }

  params.push(limit, offset);

  const result = await db.query(`
    SELECT
      ce.*,
      c.title, c.title_hi, c.thumbnail_url, c.duration_minutes,
      c.difficulty_level, c.certificate_available
    FROM course_enrollments ce
    JOIN courses c ON ce.course_id = c.id
    WHERE ${conditions.join(' AND ')}
    ORDER BY ce.updated_at DESC
    LIMIT $${params.length - 1} OFFSET $${params.length}
  `, params);

  res.json({
    success: true,
    data: result.rows
  });
});

/**
 * Share technology experience
 */
const shareExperience = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const {
    technology_id, title, experience_text, implementation_cost,
    roi_achieved_percent, time_to_implement_days, farm_size_acres,
    crop_type, rating, would_recommend, images
  } = req.body;

  if (!technology_id || !title || !experience_text || !rating) {
    res.status(400);
    throw new Error('Technology ID, title, experience text, and rating are required');
  }

  const result = await db.query(`
    INSERT INTO technology_experiences (
      technology_id, user_id, title, experience_text, implementation_cost,
      roi_achieved_percent, time_to_implement_days, farm_size_acres,
      crop_type, rating, would_recommend, images
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
    RETURNING *
  `, [
    technology_id, userId, title, experience_text, implementation_cost,
    roi_achieved_percent, time_to_implement_days, farm_size_acres,
    crop_type, rating, would_recommend !== false, JSON.stringify(images || [])
  ]);

  // Update technology stats
  await db.query(`
    UPDATE agricultural_technologies at SET
      adoption_count = adoption_count + 1,
      average_rating = (
        SELECT AVG(rating) FROM technology_experiences WHERE technology_id = at.id
      ),
      review_count = (
        SELECT COUNT(*) FROM technology_experiences WHERE technology_id = at.id
      )
    WHERE id = $1
  `, [technology_id]);

  res.status(201).json({
    success: true,
    data: result.rows[0]
  });
});

/**
 * Get technology experiences
 */
const getTechnologyExperiences = asyncHandler(async (req, res) => {
  const { technology_id } = req.params;
  const { page = 1, limit = 20 } = req.query;
  const offset = (page - 1) * limit;

  const result = await db.query(`
    SELECT
      te.*,
      u.full_name as user_name
    FROM technology_experiences te
    JOIN users u ON te.user_id = u.id
    WHERE te.technology_id = $1
    ORDER BY te.created_at DESC
    LIMIT $2 OFFSET $3
  `, [technology_id, limit, offset]);

  res.json({
    success: true,
    data: result.rows
  });
});

/**
 * Request technology demo
 */
const requestDemo = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const {
    technology_id, preferred_date, preferred_time, location,
    farm_size_acres, current_crops, contact_phone, notes
  } = req.body;

  if (!technology_id) {
    res.status(400);
    throw new Error('Technology ID is required');
  }

  const result = await db.query(`
    INSERT INTO technology_demo_requests (
      technology_id, user_id, preferred_date, preferred_time, location,
      farm_size_acres, current_crops, contact_phone, notes
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    RETURNING *
  `, [
    technology_id, userId, preferred_date, preferred_time, location,
    farm_size_acres, current_crops, contact_phone, notes
  ]);

  res.status(201).json({
    success: true,
    data: result.rows[0]
  });
});

/**
 * Get my demo requests
 */
const getMyDemoRequests = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const result = await db.query(`
    SELECT
      tdr.*,
      at.name as technology_name,
      at.name_hi as technology_name_hi
    FROM technology_demo_requests tdr
    JOIN agricultural_technologies at ON tdr.technology_id = at.id
    WHERE tdr.user_id = $1
    ORDER BY tdr.created_at DESC
  `, [userId]);

  res.json({
    success: true,
    data: result.rows
  });
});

module.exports = {
  getCategories,
  createCategory,
  getTechnologies,
  getTechnologyById,
  createTechnology,
  calculateROI,
  getCourses,
  getCourseById,
  enrollInCourse,
  updateCourseProgress,
  getMyCourses,
  shareExperience,
  getTechnologyExperiences,
  requestDemo,
  getMyDemoRequests
};

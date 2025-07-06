const db = require('../db');
const asyncHandler = require('express-async-handler');

// @desc    Get all educational content with filtering and pagination
// @route   GET /api/educational-content
// @access  Public
const getAllContent = asyncHandler(async (req, res) => {
  const { 
    page = 1, 
    limit = 10, 
    category, 
    subcategory, 
    difficulty_level, 
    search,
    sort_by = 'created_at',
    sort_order = 'DESC'
  } = req.query;

  let query = `
    SELECT ec.*, 
           u.first_name as author_first_name, 
           u.last_name as author_last_name,
           u.username as author_username
    FROM educational_content ec
    LEFT JOIN users u ON ec.author_id = u.id
    WHERE ec.is_published = true
  `;
  
  const queryParams = [];
  let paramCount = 0;

  if (category) {
    paramCount++;
    query += ` AND ec.category ILIKE $${paramCount}`;
    queryParams.push(`%${category}%`);
  }

  if (subcategory) {
    paramCount++;
    query += ` AND ec.subcategory ILIKE $${paramCount}`;
    queryParams.push(`%${subcategory}%`);
  }

  if (difficulty_level) {
    paramCount++;
    query += ` AND ec.difficulty_level = $${paramCount}`;
    queryParams.push(difficulty_level);
  }

  if (search) {
    paramCount++;
    query += ` AND (ec.title ILIKE $${paramCount} OR ec.content ILIKE $${paramCount} OR ec.summary ILIKE $${paramCount})`;
    queryParams.push(`%${search}%`);
  }

  // Validate sort parameters
  const allowedSortFields = ['created_at', 'updated_at', 'title', 'view_count', 'difficulty_level'];
  const allowedSortOrders = ['ASC', 'DESC'];
  
  if (!allowedSortFields.includes(sort_by)) {
    sort_by = 'created_at';
  }
  if (!allowedSortOrders.includes(sort_order.toUpperCase())) {
    sort_order = 'DESC';
  }

  query += ` ORDER BY ec.${sort_by} ${sort_order}`;

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
  let countQuery = 'SELECT COUNT(*) FROM educational_content WHERE is_published = true';
  const countParams = [];
  paramCount = 0;

  if (category) {
    paramCount++;
    countQuery += ` AND category ILIKE $${paramCount}`;
    countParams.push(`%${category}%`);
  }

  if (subcategory) {
    paramCount++;
    countQuery += ` AND subcategory ILIKE $${paramCount}`;
    countParams.push(`%${subcategory}%`);
  }

  if (difficulty_level) {
    paramCount++;
    countQuery += ` AND difficulty_level = $${paramCount}`;
    countParams.push(difficulty_level);
  }

  if (search) {
    paramCount++;
    countQuery += ` AND (title ILIKE $${paramCount} OR content ILIKE $${paramCount} OR summary ILIKE $${paramCount})`;
    countParams.push(`%${search}%`);
  }

  const countResult = await db.query(countQuery, countParams);
  const totalCount = parseInt(countResult.rows[0].count);

  res.json({
    success: true,
    content: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(totalCount / limit),
      total_items: totalCount,
      items_per_page: parseInt(limit)
    }
  });
});

// @desc    Get a single educational content by ID
// @route   GET /api/educational-content/:id
// @access  Public
const getContentById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  // Increment view count
  await db.query(
    'UPDATE educational_content SET view_count = view_count + 1 WHERE id = $1',
    [id]
  );

  const result = await db.query(`
    SELECT ec.*, 
           u.first_name as author_first_name, 
           u.last_name as author_last_name,
           u.username as author_username
    FROM educational_content ec
    LEFT JOIN users u ON ec.author_id = u.id
    WHERE ec.id = $1 AND ec.is_published = true
  `, [id]);

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Content not found');
  }

  res.json({
    success: true,
    content: result.rows[0]
  });
});

// @desc    Add new educational content
// @route   POST /api/educational-content
// @access  Private (Admin/Creator)
const addContent = asyncHandler(async (req, res) => {
  const { 
    title, 
    content, 
    summary,
    category, 
    subcategory,
    difficulty_level,
    image_url,
    video_url,
    tags
  } = req.body;

  if (!title || !content || !category) {
    res.status(400);
    throw new Error('Title, content, and category are required');
  }

  const result = await db.query(
    `INSERT INTO educational_content (
      title, content, summary, category, subcategory, difficulty_level, 
      author_id, image_url, video_url, tags
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *`,
    [
      title, 
      content, 
      summary || null,
      category, 
      subcategory || null,
      difficulty_level || 'beginner',
      req.user.id,
      image_url || null,
      video_url || null,
      tags || []
    ]
  );

  res.status(201).json({
    success: true,
    message: 'Educational content added successfully',
    content: result.rows[0]
  });
});

// @desc    Update educational content
// @route   PUT /api/educational-content/:id
// @access  Private (Admin/Creator/Owner)
const updateContent = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { 
    title, 
    content, 
    summary,
    category, 
    subcategory,
    difficulty_level,
    image_url,
    video_url,
    tags,
    is_published
  } = req.body;

  // Check if content exists and user has permission to edit
  const existingContent = await db.query(
    'SELECT * FROM educational_content WHERE id = $1',
    [id]
  );

  if (existingContent.rows.length === 0) {
    res.status(404);
    throw new Error('Content not found');
  }

  const contentItem = existingContent.rows[0];
  
  // Only author, admin, or content-creator can edit
  if (contentItem.author_id !== req.user.id && 
      !['admin', 'content-creator'].includes(req.user.role)) {
    res.status(403);
    throw new Error('Not authorized to edit this content');
  }

  const result = await db.query(
    `UPDATE educational_content SET 
      title = COALESCE($1, title),
      content = COALESCE($2, content),
      summary = COALESCE($3, summary),
      category = COALESCE($4, category),
      subcategory = COALESCE($5, subcategory),
      difficulty_level = COALESCE($6, difficulty_level),
      image_url = COALESCE($7, image_url),
      video_url = COALESCE($8, video_url),
      tags = COALESCE($9, tags),
      is_published = COALESCE($10, is_published),
      updated_at = CURRENT_TIMESTAMP
     WHERE id = $11 RETURNING *`,
    [
      title, 
      content, 
      summary,
      category, 
      subcategory,
      difficulty_level,
      image_url,
      video_url,
      tags,
      is_published,
      id
    ]
  );

  res.json({
    success: true,
    message: 'Educational content updated successfully',
    content: result.rows[0]
  });
});

// @desc    Delete educational content
// @route   DELETE /api/educational-content/:id
// @access  Private (Admin/Creator/Owner)
const deleteContent = asyncHandler(async (req, res) => {
  const { id } = req.params;

  // Check if content exists and user has permission to delete
  const existingContent = await db.query(
    'SELECT * FROM educational_content WHERE id = $1',
    [id]
  );

  if (existingContent.rows.length === 0) {
    res.status(404);
    throw new Error('Content not found');
  }

  const contentItem = existingContent.rows[0];
  
  // Only author, admin, or content-creator can delete
  if (contentItem.author_id !== req.user.id && 
      !['admin', 'content-creator'].includes(req.user.role)) {
    res.status(403);
    throw new Error('Not authorized to delete this content');
  }

  await db.query('DELETE FROM educational_content WHERE id = $1', [id]);

  res.json({
    success: true,
    message: 'Educational content deleted successfully'
  });
});

// @desc    Get content categories
// @route   GET /api/educational-content/categories
// @access  Public
const getCategories = asyncHandler(async (req, res) => {
  const result = await db.query(`
    SELECT DISTINCT category, 
           COUNT(*) as content_count,
           ARRAY_AGG(DISTINCT subcategory) FILTER (WHERE subcategory IS NOT NULL) as subcategories
    FROM educational_content 
    WHERE is_published = true 
    GROUP BY category 
    ORDER BY category
  `);

  res.json({
    success: true,
    categories: result.rows
  });
});

// @desc    Get content by category
// @route   GET /api/educational-content/category/:category
// @access  Public
const getContentByCategory = asyncHandler(async (req, res) => {
  const { category } = req.params;
  const { page = 1, limit = 10 } = req.query;

  const offset = (page - 1) * limit;

  const result = await db.query(`
    SELECT ec.*, 
           u.first_name as author_first_name, 
           u.last_name as author_last_name,
           u.username as author_username
    FROM educational_content ec
    LEFT JOIN users u ON ec.author_id = u.id
    WHERE ec.category ILIKE $1 AND ec.is_published = true
    ORDER BY ec.created_at DESC
    LIMIT $2 OFFSET $3
  `, [`%${category}%`, parseInt(limit), offset]);

  const countResult = await db.query(
    'SELECT COUNT(*) FROM educational_content WHERE category ILIKE $1 AND is_published = true',
    [`%${category}%`]
  );

  const totalCount = parseInt(countResult.rows[0].count);

  res.json({
    success: true,
    category: category,
    content: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(totalCount / limit),
      total_items: totalCount,
      items_per_page: parseInt(limit)
    }
  });
});

// @desc    Get popular content
// @route   GET /api/educational-content/popular
// @access  Public
const getPopularContent = asyncHandler(async (req, res) => {
  const { limit = 5 } = req.query;

  const result = await db.query(`
    SELECT ec.*, 
           u.first_name as author_first_name, 
           u.last_name as author_last_name,
           u.username as author_username
    FROM educational_content ec
    LEFT JOIN users u ON ec.author_id = u.id
    WHERE ec.is_published = true
    ORDER BY ec.view_count DESC, ec.created_at DESC
    LIMIT $1
  `, [parseInt(limit)]);

  res.json({
    success: true,
    content: result.rows
  });
});

// @desc    Get content analytics (for authors/admins)
// @route   GET /api/educational-content/analytics
// @access  Private (Admin/Creator)
const getContentAnalytics = asyncHandler(async (req, res) => {
  if (!['admin', 'content-creator'].includes(req.user.role)) {
    res.status(403);
    throw new Error('Not authorized to view analytics');
  }

  // Get total content count
  const totalContent = await db.query('SELECT COUNT(*) FROM educational_content');
  
  // Get published content count
  const publishedContent = await db.query('SELECT COUNT(*) FROM educational_content WHERE is_published = true');
  
  // Get total views
  const totalViews = await db.query('SELECT SUM(view_count) FROM educational_content');
  
  // Get content by category
  const contentByCategory = await db.query(`
    SELECT category, COUNT(*) as count
    FROM educational_content
    GROUP BY category
    ORDER BY count DESC
  `);

  // Get most viewed content
  const mostViewed = await db.query(`
    SELECT title, view_count, category
    FROM educational_content
    WHERE is_published = true
    ORDER BY view_count DESC
    LIMIT 10
  `);

  // Get recent content
  const recentContent = await db.query(`
    SELECT title, created_at, category
    FROM educational_content
    ORDER BY created_at DESC
    LIMIT 10
  `);

  res.json({
    success: true,
    analytics: {
      total_content: parseInt(totalContent.rows[0].count),
      published_content: parseInt(publishedContent.rows[0].count),
      total_views: parseInt(totalViews.rows[0].sum) || 0,
      content_by_category: contentByCategory.rows,
      most_viewed: mostViewed.rows,
      recent_content: recentContent.rows
    }
  });
});

module.exports = {
  getAllContent,
  getContentById,
  addContent,
  updateContent,
  deleteContent,
  getCategories,
  getContentByCategory,
  getPopularContent,
  getContentAnalytics,
};
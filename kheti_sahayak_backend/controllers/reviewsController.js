const db = require('../db');
const asyncHandler = require('express-async-handler');
const { uploadFileToS3 } = require('../s3');

/**
 * @desc    Create a product review
 * @route   POST /api/reviews/:productId
 * @access  Private
 */
const createReview = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const { rating, title, review_text } = req.body;
  const userId = req.user.id;

  // Validate rating
  if (!rating || rating < 1 || rating > 5) {
    res.status(400);
    throw new Error('Rating must be between 1 and 5');
  }

  // Check if product exists
  const productResult = await db.query(
    'SELECT id FROM products WHERE id = $1',
    [productId]
  );

  if (productResult.rows.length === 0) {
    res.status(404);
    throw new Error('Product not found');
  }

  // Check if user has already reviewed this product
  const existingReview = await db.query(
    'SELECT id FROM product_reviews WHERE user_id = $1 AND product_id = $2',
    [userId, productId]
  );

  if (existingReview.rows.length > 0) {
    res.status(400);
    throw new Error('You have already reviewed this product. Please update your existing review instead.');
  }

  // Check if this is a verified purchase
  const purchaseResult = await db.query(
    `SELECT o.id
     FROM orders o
     JOIN order_items oi ON o.id = oi.order_id
     WHERE o.buyer_id = $1
     AND oi.product_id = $2
     AND o.status IN ('delivered', 'completed')`,
    [userId, productId]
  );

  const verifiedPurchase = purchaseResult.rows.length > 0;

  // Handle image uploads if present
  let imageUrls = [];
  if (req.files && req.files.length > 0) {
    const uploadPromises = req.files.map(async (file) => {
      const fileName = `reviews/${productId}/${userId}/${Date.now()}-${file.originalname}`;
      return await uploadFileToS3(file.buffer, fileName, file.mimetype);
    });
    imageUrls = await Promise.all(uploadPromises);
  }

  // Create the review
  const result = await db.query(
    `INSERT INTO product_reviews
     (product_id, user_id, rating, title, review_text, images, verified_purchase)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [productId, userId, rating, title, review_text, imageUrls, verifiedPurchase]
  );

  res.status(201).json({
    success: true,
    message: 'Review created successfully',
    review: result.rows[0],
  });
});

/**
 * @desc    Get all reviews for a product
 * @route   GET /api/reviews/:productId
 * @access  Public
 */
const getProductReviews = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const { page = 1, limit = 10, rating, sort = 'recent' } = req.query;

  let query = `
    SELECT
      pr.*,
      u.username,
      u.first_name,
      u.last_name,
      u.profile_image
    FROM product_reviews pr
    JOIN users u ON pr.user_id = u.id
    WHERE pr.product_id = $1
    AND pr.status = 'active'
  `;

  const queryParams = [productId];
  let paramCount = 1;

  // Filter by rating if specified
  if (rating) {
    paramCount++;
    query += ` AND pr.rating = $${paramCount}`;
    queryParams.push(parseInt(rating));
  }

  // Sorting
  switch (sort) {
    case 'recent':
      query += ' ORDER BY pr.created_at DESC';
      break;
    case 'oldest':
      query += ' ORDER BY pr.created_at ASC';
      break;
    case 'highest':
      query += ' ORDER BY pr.rating DESC, pr.created_at DESC';
      break;
    case 'lowest':
      query += ' ORDER BY pr.rating ASC, pr.created_at DESC';
      break;
    case 'helpful':
      query += ' ORDER BY pr.helpful_count DESC, pr.created_at DESC';
      break;
    default:
      query += ' ORDER BY pr.created_at DESC';
  }

  // Pagination
  const offset = (page - 1) * limit;
  paramCount++;
  query += ` LIMIT $${paramCount}`;
  queryParams.push(parseInt(limit));

  paramCount++;
  query += ` OFFSET $${paramCount}`;
  queryParams.push(offset);

  const result = await db.query(query, queryParams);

  // Get total count and rating distribution
  const statsResult = await db.query(
    `SELECT
      COUNT(*) as total_reviews,
      AVG(rating)::numeric(3,2) as average_rating,
      COUNT(CASE WHEN rating = 5 THEN 1 END) as five_star,
      COUNT(CASE WHEN rating = 4 THEN 1 END) as four_star,
      COUNT(CASE WHEN rating = 3 THEN 1 END) as three_star,
      COUNT(CASE WHEN rating = 2 THEN 1 END) as two_star,
      COUNT(CASE WHEN rating = 1 THEN 1 END) as one_star,
      COUNT(CASE WHEN verified_purchase = true THEN 1 END) as verified_purchases
     FROM product_reviews
     WHERE product_id = $1 AND status = 'active'`,
    [productId]
  );

  res.json({
    success: true,
    reviews: result.rows,
    statistics: statsResult.rows[0],
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(statsResult.rows[0].total_reviews / limit),
      total_items: parseInt(statsResult.rows[0].total_reviews),
      items_per_page: parseInt(limit),
    },
  });
});

/**
 * @desc    Get a single review by ID
 * @route   GET /api/reviews/review/:reviewId
 * @access  Public
 */
const getReviewById = asyncHandler(async (req, res) => {
  const { reviewId } = req.params;

  const result = await db.query(
    `SELECT
      pr.*,
      u.username,
      u.first_name,
      u.last_name,
      u.profile_image
     FROM product_reviews pr
     JOIN users u ON pr.user_id = u.id
     WHERE pr.id = $1`,
    [reviewId]
  );

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Review not found');
  }

  res.json({
    success: true,
    review: result.rows[0],
  });
});

/**
 * @desc    Update a review
 * @route   PUT /api/reviews/review/:reviewId
 * @access  Private
 */
const updateReview = asyncHandler(async (req, res) => {
  const { reviewId } = req.params;
  const { rating, title, review_text } = req.body;
  const userId = req.user.id;

  // Check if review exists and belongs to user
  const reviewResult = await db.query(
    'SELECT * FROM product_reviews WHERE id = $1',
    [reviewId]
  );

  if (reviewResult.rows.length === 0) {
    res.status(404);
    throw new Error('Review not found');
  }

  const review = reviewResult.rows[0];

  if (review.user_id !== userId) {
    res.status(403);
    throw new Error('Not authorized to update this review');
  }

  // Validate rating if provided
  if (rating && (rating < 1 || rating > 5)) {
    res.status(400);
    throw new Error('Rating must be between 1 and 5');
  }

  // Handle image uploads if present
  let imageUrls = review.images || [];
  if (req.files && req.files.length > 0) {
    const uploadPromises = req.files.map(async (file) => {
      const fileName = `reviews/${review.product_id}/${userId}/${Date.now()}-${file.originalname}`;
      return await uploadFileToS3(file.buffer, fileName, file.mimetype);
    });
    const newImageUrls = await Promise.all(uploadPromises);
    imageUrls = [...imageUrls, ...newImageUrls];
  }

  // Update the review
  const result = await db.query(
    `UPDATE product_reviews
     SET rating = COALESCE($1, rating),
         title = COALESCE($2, title),
         review_text = COALESCE($3, review_text),
         images = $4,
         updated_at = CURRENT_TIMESTAMP
     WHERE id = $5
     RETURNING *`,
    [rating, title, review_text, imageUrls, reviewId]
  );

  res.json({
    success: true,
    message: 'Review updated successfully',
    review: result.rows[0],
  });
});

/**
 * @desc    Delete a review
 * @route   DELETE /api/reviews/review/:reviewId
 * @access  Private
 */
const deleteReview = asyncHandler(async (req, res) => {
  const { reviewId } = req.params;
  const userId = req.user.id;

  // Check if review exists and belongs to user
  const reviewResult = await db.query(
    'SELECT * FROM product_reviews WHERE id = $1',
    [reviewId]
  );

  if (reviewResult.rows.length === 0) {
    res.status(404);
    throw new Error('Review not found');
  }

  const review = reviewResult.rows[0];

  // Allow deletion by review owner or admin
  if (review.user_id !== userId && req.user.role !== 'admin') {
    res.status(403);
    throw new Error('Not authorized to delete this review');
  }

  // Soft delete by updating status
  await db.query(
    "UPDATE product_reviews SET status = 'deleted', updated_at = CURRENT_TIMESTAMP WHERE id = $1",
    [reviewId]
  );

  res.json({
    success: true,
    message: 'Review deleted successfully',
  });
});

/**
 * @desc    Mark review as helpful
 * @route   POST /api/reviews/review/:reviewId/helpful
 * @access  Private
 */
const markReviewHelpful = asyncHandler(async (req, res) => {
  const { reviewId } = req.params;
  const userId = req.user.id;

  // Check if review exists
  const reviewResult = await db.query(
    'SELECT id FROM product_reviews WHERE id = $1',
    [reviewId]
  );

  if (reviewResult.rows.length === 0) {
    res.status(404);
    throw new Error('Review not found');
  }

  // Check if user has already marked this review as helpful
  const existingMark = await db.query(
    'SELECT id FROM review_helpful WHERE review_id = $1 AND user_id = $2',
    [reviewId, userId]
  );

  if (existingMark.rows.length > 0) {
    // Unmark as helpful (toggle)
    await db.query(
      'DELETE FROM review_helpful WHERE review_id = $1 AND user_id = $2',
      [reviewId, userId]
    );

    await db.query(
      'UPDATE product_reviews SET helpful_count = helpful_count - 1 WHERE id = $1',
      [reviewId]
    );

    res.json({
      success: true,
      message: 'Review unmarked as helpful',
      helpful: false,
    });
  } else {
    // Mark as helpful
    await db.query(
      'INSERT INTO review_helpful (review_id, user_id) VALUES ($1, $2)',
      [reviewId, userId]
    );

    await db.query(
      'UPDATE product_reviews SET helpful_count = helpful_count + 1 WHERE id = $1',
      [reviewId]
    );

    res.json({
      success: true,
      message: 'Review marked as helpful',
      helpful: true,
    });
  }
});

/**
 * @desc    Get user's own reviews
 * @route   GET /api/reviews/my-reviews
 * @access  Private
 */
const getMyReviews = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { page = 1, limit = 10 } = req.query;

  const query = `
    SELECT
      pr.*,
      p.name as product_name,
      p.image_urls as product_images
    FROM product_reviews pr
    JOIN products p ON pr.product_id = p.id
    WHERE pr.user_id = $1
    AND pr.status != 'deleted'
    ORDER BY pr.created_at DESC
    LIMIT $2 OFFSET $3
  `;

  const offset = (page - 1) * limit;
  const result = await db.query(query, [userId, parseInt(limit), offset]);

  // Get total count
  const countResult = await db.query(
    "SELECT COUNT(*) FROM product_reviews WHERE user_id = $1 AND status != 'deleted'",
    [userId]
  );

  res.json({
    success: true,
    reviews: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(countResult.rows[0].count / limit),
      total_items: parseInt(countResult.rows[0].count),
      items_per_page: parseInt(limit),
    },
  });
});

/**
 * @desc    Flag a review as inappropriate
 * @route   POST /api/reviews/review/:reviewId/flag
 * @access  Private
 */
const flagReview = asyncHandler(async (req, res) => {
  const { reviewId } = req.params;
  const { reason } = req.body;

  if (!reason) {
    res.status(400);
    throw new Error('Please provide a reason for flagging this review');
  }

  // Check if review exists
  const reviewResult = await db.query(
    'SELECT id FROM product_reviews WHERE id = $1',
    [reviewId]
  );

  if (reviewResult.rows.length === 0) {
    res.status(404);
    throw new Error('Review not found');
  }

  // Update review status to flagged
  await db.query(
    "UPDATE product_reviews SET status = 'flagged' WHERE id = $1",
    [reviewId]
  );

  // In a real application, you'd want to log the flag reason and user
  // For now, we'll just update the status

  res.json({
    success: true,
    message: 'Review has been flagged for moderation',
  });
});

module.exports = {
  createReview,
  getProductReviews,
  getReviewById,
  updateReview,
  deleteReview,
  markReviewHelpful,
  getMyReviews,
  flagReview,
};

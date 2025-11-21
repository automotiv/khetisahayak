/**
 * Equipment Controller
 *
 * Handles Farm Machinery Lending & Rental Platform operations (Epic #395)
 */

const asyncHandler = require('express-async-handler');
const db = require('../db');

/**
 * Get all equipment categories
 */
const getCategories = asyncHandler(async (req, res) => {
  const result = await db.query(`
    SELECT
      c.*,
      (SELECT COUNT(*) FROM equipment_listings el WHERE el.category_id = c.id AND el.is_active = true) as listing_count
    FROM equipment_categories c
    WHERE c.is_active = true
    ORDER BY c.name
  `);

  res.json({
    success: true,
    data: result.rows
  });
});

/**
 * Create equipment category (Admin only)
 */
const createCategory = asyncHandler(async (req, res) => {
  const { name, name_hi, description, icon, parent_id } = req.body;

  if (!name) {
    res.status(400);
    throw new Error('Category name is required');
  }

  const result = await db.query(`
    INSERT INTO equipment_categories (name, name_hi, description, icon, parent_id)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *
  `, [name, name_hi, description, icon, parent_id]);

  res.status(201).json({
    success: true,
    data: result.rows[0]
  });
});

/**
 * Get equipment listings with filters
 */
const getListings = asyncHandler(async (req, res) => {
  const {
    category_id,
    availability_status,
    min_daily_rate,
    max_daily_rate,
    condition,
    lat,
    lng,
    radius_km = 50,
    page = 1,
    limit = 20
  } = req.query;

  const offset = (page - 1) * limit;
  const conditions = ['el.is_active = true'];
  const params = [];

  if (category_id) {
    params.push(category_id);
    conditions.push(`el.category_id = $${params.length}`);
  }

  if (availability_status) {
    params.push(availability_status);
    conditions.push(`el.availability_status = $${params.length}`);
  }

  if (min_daily_rate) {
    params.push(min_daily_rate);
    conditions.push(`el.daily_rate >= $${params.length}`);
  }

  if (max_daily_rate) {
    params.push(max_daily_rate);
    conditions.push(`el.daily_rate <= $${params.length}`);
  }

  if (condition) {
    params.push(condition);
    conditions.push(`el.condition = $${params.length}`);
  }

  // Location-based filtering with Haversine formula
  let distanceSelect = '';
  let orderBy = 'ORDER BY el.created_at DESC';

  if (lat && lng) {
    params.push(lat, lng, radius_km);
    const latParam = params.length - 2;
    const lngParam = params.length - 1;
    const radiusParam = params.length;

    distanceSelect = `,
      (6371 * acos(cos(radians($${latParam})) * cos(radians(el.location_lat))
      * cos(radians(el.location_lng) - radians($${lngParam}))
      + sin(radians($${latParam})) * sin(radians(el.location_lat)))) AS distance_km`;

    conditions.push(`
      el.location_lat IS NOT NULL
      AND el.location_lng IS NOT NULL
      AND (6371 * acos(cos(radians($${latParam})) * cos(radians(el.location_lat))
      * cos(radians(el.location_lng) - radians($${lngParam}))
      + sin(radians($${latParam})) * sin(radians(el.location_lat)))) <= $${radiusParam}
    `);

    orderBy = 'ORDER BY distance_km ASC';
  }

  params.push(limit, offset);
  const limitParam = params.length - 1;
  const offsetParam = params.length;

  const query = `
    SELECT
      el.*,
      ec.name as category_name,
      ec.name_hi as category_name_hi,
      u.full_name as owner_name,
      u.phone as owner_phone
      ${distanceSelect}
    FROM equipment_listings el
    JOIN equipment_categories ec ON el.category_id = ec.id
    JOIN users u ON el.owner_id = u.id
    WHERE ${conditions.join(' AND ')}
    ${orderBy}
    LIMIT $${limitParam} OFFSET $${offsetParam}
  `;

  const countQuery = `
    SELECT COUNT(*)
    FROM equipment_listings el
    WHERE ${conditions.slice(0, -2).join(' AND ')}
  `;

  const [listingsResult, countResult] = await Promise.all([
    db.query(query, params),
    db.query(countQuery, params.slice(0, -2))
  ]);

  res.json({
    success: true,
    data: listingsResult.rows,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: parseInt(countResult.rows[0].count),
      pages: Math.ceil(countResult.rows[0].count / limit)
    }
  });
});

/**
 * Get single equipment listing by ID
 */
const getListingById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(`
    SELECT
      el.*,
      ec.name as category_name,
      ec.name_hi as category_name_hi,
      u.full_name as owner_name,
      u.phone as owner_phone,
      u.email as owner_email
    FROM equipment_listings el
    JOIN equipment_categories ec ON el.category_id = ec.id
    JOIN users u ON el.owner_id = u.id
    WHERE el.id = $1
  `, [id]);

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Equipment listing not found');
  }

  // Get reviews for this equipment
  const reviewsResult = await db.query(`
    SELECT
      er.*,
      u.full_name as reviewer_name
    FROM equipment_reviews er
    JOIN users u ON er.reviewer_id = u.id
    WHERE er.equipment_id = $1
    ORDER BY er.created_at DESC
    LIMIT 10
  `, [id]);

  res.json({
    success: true,
    data: {
      ...result.rows[0],
      reviews: reviewsResult.rows
    }
  });
});

/**
 * Create equipment listing
 */
const createListing = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const {
    category_id,
    name,
    description,
    brand,
    model,
    year_of_manufacture,
    condition,
    hourly_rate,
    daily_rate,
    weekly_rate,
    deposit_amount,
    location_address,
    location_lat,
    location_lng,
    service_radius_km,
    images,
    specifications,
    is_operator_included,
    operator_rate_per_day,
    minimum_rental_days,
    maximum_rental_days
  } = req.body;

  if (!category_id || !name || !daily_rate) {
    res.status(400);
    throw new Error('Category, name, and daily rate are required');
  }

  const result = await db.query(`
    INSERT INTO equipment_listings (
      owner_id, category_id, name, description, brand, model,
      year_of_manufacture, condition, hourly_rate, daily_rate, weekly_rate,
      deposit_amount, location_address, location_lat, location_lng,
      service_radius_km, images, specifications, is_operator_included,
      operator_rate_per_day, minimum_rental_days, maximum_rental_days
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22)
    RETURNING *
  `, [
    userId, category_id, name, description, brand, model,
    year_of_manufacture, condition || 'good', hourly_rate, daily_rate, weekly_rate,
    deposit_amount, location_address, location_lat, location_lng,
    service_radius_km || 50, JSON.stringify(images || []), JSON.stringify(specifications || {}),
    is_operator_included || false, operator_rate_per_day, minimum_rental_days || 1, maximum_rental_days
  ]);

  res.status(201).json({
    success: true,
    data: result.rows[0]
  });
});

/**
 * Update equipment listing
 */
const updateListing = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  // Verify ownership
  const checkResult = await db.query(
    'SELECT owner_id FROM equipment_listings WHERE id = $1',
    [id]
  );

  if (checkResult.rows.length === 0) {
    res.status(404);
    throw new Error('Equipment listing not found');
  }

  if (checkResult.rows[0].owner_id !== userId && req.user.role !== 'admin') {
    res.status(403);
    throw new Error('Not authorized to update this listing');
  }

  const updates = [];
  const values = [];
  const allowedFields = [
    'name', 'description', 'brand', 'model', 'year_of_manufacture',
    'condition', 'hourly_rate', 'daily_rate', 'weekly_rate', 'deposit_amount',
    'location_address', 'location_lat', 'location_lng', 'service_radius_km',
    'availability_status', 'is_operator_included', 'operator_rate_per_day',
    'minimum_rental_days', 'maximum_rental_days', 'is_active'
  ];

  allowedFields.forEach(field => {
    if (req.body[field] !== undefined) {
      values.push(req.body[field]);
      updates.push(`${field} = $${values.length}`);
    }
  });

  // Handle JSON fields separately
  if (req.body.images !== undefined) {
    values.push(JSON.stringify(req.body.images));
    updates.push(`images = $${values.length}`);
  }
  if (req.body.specifications !== undefined) {
    values.push(JSON.stringify(req.body.specifications));
    updates.push(`specifications = $${values.length}`);
  }

  if (updates.length === 0) {
    res.status(400);
    throw new Error('No fields to update');
  }

  values.push(id);
  const result = await db.query(`
    UPDATE equipment_listings
    SET ${updates.join(', ')}
    WHERE id = $${values.length}
    RETURNING *
  `, values);

  res.json({
    success: true,
    data: result.rows[0]
  });
});

/**
 * Delete equipment listing
 */
const deleteListing = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;

  // Verify ownership
  const checkResult = await db.query(
    'SELECT owner_id FROM equipment_listings WHERE id = $1',
    [id]
  );

  if (checkResult.rows.length === 0) {
    res.status(404);
    throw new Error('Equipment listing not found');
  }

  if (checkResult.rows[0].owner_id !== userId && req.user.role !== 'admin') {
    res.status(403);
    throw new Error('Not authorized to delete this listing');
  }

  await db.query('DELETE FROM equipment_listings WHERE id = $1', [id]);

  res.json({
    success: true,
    message: 'Listing deleted successfully'
  });
});

/**
 * Get user's equipment listings (as owner)
 */
const getMyListings = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { page = 1, limit = 20 } = req.query;
  const offset = (page - 1) * limit;

  const [listingsResult, countResult] = await Promise.all([
    db.query(`
      SELECT
        el.*,
        ec.name as category_name,
        (SELECT COUNT(*) FROM equipment_bookings eb WHERE eb.equipment_id = el.id) as booking_count
      FROM equipment_listings el
      JOIN equipment_categories ec ON el.category_id = ec.id
      WHERE el.owner_id = $1
      ORDER BY el.created_at DESC
      LIMIT $2 OFFSET $3
    `, [userId, limit, offset]),
    db.query('SELECT COUNT(*) FROM equipment_listings WHERE owner_id = $1', [userId])
  ]);

  res.json({
    success: true,
    data: listingsResult.rows,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: parseInt(countResult.rows[0].count)
    }
  });
});

/**
 * Create booking request
 */
const createBooking = asyncHandler(async (req, res) => {
  const renterId = req.user.id;
  const {
    equipment_id,
    start_date,
    end_date,
    operator_included,
    delivery_address,
    delivery_lat,
    delivery_lng,
    notes
  } = req.body;

  if (!equipment_id || !start_date || !end_date) {
    res.status(400);
    throw new Error('Equipment ID, start date, and end date are required');
  }

  // Get equipment details
  const equipmentResult = await db.query(`
    SELECT * FROM equipment_listings WHERE id = $1 AND is_active = true
  `, [equipment_id]);

  if (equipmentResult.rows.length === 0) {
    res.status(404);
    throw new Error('Equipment not found or not available');
  }

  const equipment = equipmentResult.rows[0];

  // Check for conflicting bookings
  const conflictResult = await db.query(`
    SELECT id FROM equipment_bookings
    WHERE equipment_id = $1
    AND status NOT IN ('cancelled', 'completed')
    AND (
      (start_date <= $2 AND end_date >= $2)
      OR (start_date <= $3 AND end_date >= $3)
      OR (start_date >= $2 AND end_date <= $3)
    )
  `, [equipment_id, start_date, end_date]);

  if (conflictResult.rows.length > 0) {
    res.status(400);
    throw new Error('Equipment is not available for the selected dates');
  }

  // Calculate costs
  const startDate = new Date(start_date);
  const endDate = new Date(end_date);
  const rentalDays = Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24)) + 1;

  if (rentalDays < equipment.minimum_rental_days) {
    res.status(400);
    throw new Error(`Minimum rental period is ${equipment.minimum_rental_days} days`);
  }

  if (equipment.maximum_rental_days && rentalDays > equipment.maximum_rental_days) {
    res.status(400);
    throw new Error(`Maximum rental period is ${equipment.maximum_rental_days} days`);
  }

  const dailyRate = parseFloat(equipment.daily_rate);
  const subtotal = dailyRate * rentalDays;
  const operatorCost = operator_included && equipment.operator_rate_per_day
    ? parseFloat(equipment.operator_rate_per_day) * rentalDays
    : 0;
  const serviceFee = subtotal * 0.05; // 5% service fee
  const depositAmount = equipment.deposit_amount ? parseFloat(equipment.deposit_amount) : 0;
  const totalAmount = subtotal + operatorCost + serviceFee;

  const result = await db.query(`
    INSERT INTO equipment_bookings (
      equipment_id, renter_id, owner_id, start_date, end_date, rental_days,
      daily_rate, operator_included, operator_rate, subtotal, deposit_amount,
      service_fee, total_amount, delivery_address, delivery_lat, delivery_lng, notes
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
    RETURNING *
  `, [
    equipment_id, renterId, equipment.owner_id, start_date, end_date, rentalDays,
    dailyRate, operator_included || false, operator_included ? equipment.operator_rate_per_day : null,
    subtotal, depositAmount, serviceFee, totalAmount,
    delivery_address, delivery_lat, delivery_lng, notes
  ]);

  res.status(201).json({
    success: true,
    data: result.rows[0]
  });
});

/**
 * Get user's bookings (as renter)
 */
const getMyBookings = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { status, page = 1, limit = 20 } = req.query;
  const offset = (page - 1) * limit;

  const conditions = ['eb.renter_id = $1'];
  const params = [userId];

  if (status) {
    params.push(status);
    conditions.push(`eb.status = $${params.length}`);
  }

  params.push(limit, offset);

  const result = await db.query(`
    SELECT
      eb.*,
      el.name as equipment_name,
      el.images as equipment_images,
      u.full_name as owner_name,
      u.phone as owner_phone
    FROM equipment_bookings eb
    JOIN equipment_listings el ON eb.equipment_id = el.id
    JOIN users u ON eb.owner_id = u.id
    WHERE ${conditions.join(' AND ')}
    ORDER BY eb.created_at DESC
    LIMIT $${params.length - 1} OFFSET $${params.length}
  `, params);

  res.json({
    success: true,
    data: result.rows
  });
});

/**
 * Get bookings for owner's equipment
 */
const getOwnerBookings = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { status, page = 1, limit = 20 } = req.query;
  const offset = (page - 1) * limit;

  const conditions = ['eb.owner_id = $1'];
  const params = [userId];

  if (status) {
    params.push(status);
    conditions.push(`eb.status = $${params.length}`);
  }

  params.push(limit, offset);

  const result = await db.query(`
    SELECT
      eb.*,
      el.name as equipment_name,
      el.images as equipment_images,
      u.full_name as renter_name,
      u.phone as renter_phone
    FROM equipment_bookings eb
    JOIN equipment_listings el ON eb.equipment_id = el.id
    JOIN users u ON eb.renter_id = u.id
    WHERE ${conditions.join(' AND ')}
    ORDER BY eb.created_at DESC
    LIMIT $${params.length - 1} OFFSET $${params.length}
  `, params);

  res.json({
    success: true,
    data: result.rows
  });
});

/**
 * Update booking status (for owners)
 */
const updateBookingStatus = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;
  const { status, cancellation_reason } = req.body;

  const validStatuses = ['confirmed', 'in_progress', 'completed', 'cancelled'];
  if (!validStatuses.includes(status)) {
    res.status(400);
    throw new Error('Invalid status');
  }

  // Verify ownership or renter
  const bookingResult = await db.query(
    'SELECT * FROM equipment_bookings WHERE id = $1',
    [id]
  );

  if (bookingResult.rows.length === 0) {
    res.status(404);
    throw new Error('Booking not found');
  }

  const booking = bookingResult.rows[0];
  const isOwner = booking.owner_id === userId;
  const isRenter = booking.renter_id === userId;
  const isAdmin = req.user.role === 'admin';

  if (!isOwner && !isRenter && !isAdmin) {
    res.status(403);
    throw new Error('Not authorized to update this booking');
  }

  // Only owners can confirm or complete, both can cancel
  if ((status === 'confirmed' || status === 'completed') && !isOwner && !isAdmin) {
    res.status(403);
    throw new Error('Only the equipment owner can confirm or complete bookings');
  }

  const updates = ['status = $1'];
  const params = [status];

  if (status === 'cancelled') {
    params.push(cancellation_reason);
    updates.push(`cancellation_reason = $${params.length}`);
    params.push(userId);
    updates.push(`cancelled_by = $${params.length}`);

    // Update equipment availability if was in_progress
    if (booking.status === 'in_progress' || booking.status === 'confirmed') {
      await db.query(`
        UPDATE equipment_listings SET availability_status = 'available' WHERE id = $1
      `, [booking.equipment_id]);
    }
  }

  if (status === 'in_progress') {
    // Mark equipment as rented
    await db.query(`
      UPDATE equipment_listings SET availability_status = 'rented' WHERE id = $1
    `, [booking.equipment_id]);
  }

  if (status === 'completed') {
    // Mark equipment as available and increment rental count
    await db.query(`
      UPDATE equipment_listings
      SET availability_status = 'available', total_rentals = total_rentals + 1
      WHERE id = $1
    `, [booking.equipment_id]);
  }

  params.push(id);
  const result = await db.query(`
    UPDATE equipment_bookings
    SET ${updates.join(', ')}
    WHERE id = $${params.length}
    RETURNING *
  `, params);

  res.json({
    success: true,
    data: result.rows[0]
  });
});

/**
 * Add review for completed booking
 */
const addReview = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { booking_id, rating, review_text, condition_rating, owner_rating, value_rating } = req.body;

  if (!booking_id || !rating) {
    res.status(400);
    throw new Error('Booking ID and rating are required');
  }

  // Verify booking belongs to user and is completed
  const bookingResult = await db.query(`
    SELECT * FROM equipment_bookings WHERE id = $1 AND renter_id = $2 AND status = 'completed'
  `, [booking_id, userId]);

  if (bookingResult.rows.length === 0) {
    res.status(400);
    throw new Error('Can only review completed bookings');
  }

  const booking = bookingResult.rows[0];

  // Check if already reviewed
  const existingReview = await db.query(
    'SELECT id FROM equipment_reviews WHERE booking_id = $1',
    [booking_id]
  );

  if (existingReview.rows.length > 0) {
    res.status(400);
    throw new Error('Booking already reviewed');
  }

  const result = await db.query(`
    INSERT INTO equipment_reviews (
      booking_id, equipment_id, reviewer_id, rating, review_text,
      condition_rating, owner_rating, value_rating
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING *
  `, [booking_id, booking.equipment_id, userId, rating, review_text, condition_rating, owner_rating, value_rating]);

  // Update equipment average rating
  await db.query(`
    UPDATE equipment_listings el SET
      average_rating = (
        SELECT AVG(rating) FROM equipment_reviews WHERE equipment_id = el.id
      ),
      review_count = (
        SELECT COUNT(*) FROM equipment_reviews WHERE equipment_id = el.id
      )
    WHERE id = $1
  `, [booking.equipment_id]);

  res.status(201).json({
    success: true,
    data: result.rows[0]
  });
});

/**
 * Get equipment reviews
 */
const getEquipmentReviews = asyncHandler(async (req, res) => {
  const { equipment_id } = req.params;
  const { page = 1, limit = 20 } = req.query;
  const offset = (page - 1) * limit;

  const result = await db.query(`
    SELECT
      er.*,
      u.full_name as reviewer_name
    FROM equipment_reviews er
    JOIN users u ON er.reviewer_id = u.id
    WHERE er.equipment_id = $1
    ORDER BY er.created_at DESC
    LIMIT $2 OFFSET $3
  `, [equipment_id, limit, offset]);

  res.json({
    success: true,
    data: result.rows
  });
});

module.exports = {
  getCategories,
  createCategory,
  getListings,
  getListingById,
  createListing,
  updateListing,
  deleteListing,
  getMyListings,
  createBooking,
  getMyBookings,
  getOwnerBookings,
  updateBookingStatus,
  addReview,
  getEquipmentReviews
};

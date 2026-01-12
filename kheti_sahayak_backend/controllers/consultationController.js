const db = require('../db');
const asyncHandler = require('express-async-handler');
const paymentService = require('../services/paymentService');
const consultationService = require('../services/consultationService');
const agoraService = require('../services/agoraService');

const getExperts = asyncHandler(async (req, res) => {
  const { page = 1, limit = 10, specialization, min_rating, language, is_verified, sort = 'rating' } = req.query;

  let query = `
    SELECT ep.*, u.username, u.first_name, u.last_name, u.email, u.phone, u.profile_image
    FROM expert_profiles ep
    JOIN users u ON ep.user_id = u.id
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
    queryParams.push(is_verified === 'true');
  }

  const sortOptions = {
    rating: 'ep.rating DESC, ep.total_consultations DESC',
    consultations: 'ep.total_consultations DESC, ep.rating DESC',
    fee_low: 'ep.consultation_fee ASC',
    fee_high: 'ep.consultation_fee DESC',
    experience: 'ep.experience_years DESC'
  };

  query += ` ORDER BY ${sortOptions[sort] || sortOptions.rating}`;

  const offset = (page - 1) * limit;
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
    countParams.push(is_verified === 'true');
  }

  const countResult = await db.query(countQuery, countParams);
  const totalCount = parseInt(countResult.rows[0].count);

  res.json({
    success: true,
    experts: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(totalCount / limit),
      total_items: totalCount,
      items_per_page: parseInt(limit)
    }
  });
});

const getExpertById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `SELECT ep.*, u.username, u.first_name, u.last_name, u.email, u.phone, u.profile_image
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

  res.json({
    success: true,
    expert: {
      ...result.rows[0],
      availability: availabilityResult.rows
    }
  });
});

const getExpertAvailability = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { date } = req.query;

  if (!date) {
    res.status(400);
    throw new Error('Date parameter is required (YYYY-MM-DD)');
  }

  const expertResult = await db.query(
    `SELECT user_id FROM expert_profiles WHERE user_id = $1 AND is_active = true`,
    [id]
  );

  if (expertResult.rows.length === 0) {
    res.status(404);
    throw new Error('Expert not found');
  }

  const availabilityResult = await db.query(
    `SELECT * FROM expert_availability WHERE expert_id = $1 AND is_available = true`,
    [id]
  );

  const slots = await consultationService.generateTimeSlots(availabilityResult.rows, date, id);

  res.json({
    success: true,
    date: date,
    expert_id: id,
    available_slots: slots
  });
});

const registerAsExpert = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const {
    specialization,
    expertise_areas,
    qualification,
    experience_years,
    bio,
    languages,
    consultation_fee,
    profile_image_url
  } = req.body;

  if (!specialization) {
    res.status(400);
    throw new Error('Specialization is required');
  }

  const existingProfile = await db.query(
    `SELECT id FROM expert_profiles WHERE user_id = $1`,
    [userId]
  );

  if (existingProfile.rows.length > 0) {
    res.status(400);
    throw new Error('You are already registered as an expert');
  }

  const client = await db.pool.connect();

  try {
    await client.query('BEGIN');

    const profileResult = await client.query(
      `INSERT INTO expert_profiles 
       (user_id, specialization, expertise_areas, qualification, experience_years, bio, languages, consultation_fee, profile_image_url)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        userId,
        specialization,
        expertise_areas || [],
        qualification,
        experience_years || 0,
        bio,
        languages || ['Hindi', 'English'],
        consultation_fee || 200,
        profile_image_url
      ]
    );

    await client.query(
      `UPDATE users SET role = 'expert' WHERE id = $1`,
      [userId]
    );

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      message: 'Successfully registered as expert. Your profile is pending verification.',
      expert_profile: profileResult.rows[0]
    });

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

const updateExpertProfile = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const {
    specialization,
    expertise_areas,
    qualification,
    experience_years,
    bio,
    languages,
    consultation_fee,
    profile_image_url,
    is_active
  } = req.body;

  const existingProfile = await db.query(
    `SELECT id FROM expert_profiles WHERE user_id = $1`,
    [userId]
  );

  if (existingProfile.rows.length === 0) {
    res.status(404);
    throw new Error('Expert profile not found');
  }

  const result = await db.query(
    `UPDATE expert_profiles SET
       specialization = COALESCE($2, specialization),
       expertise_areas = COALESCE($3, expertise_areas),
       qualification = COALESCE($4, qualification),
       experience_years = COALESCE($5, experience_years),
       bio = COALESCE($6, bio),
       languages = COALESCE($7, languages),
       consultation_fee = COALESCE($8, consultation_fee),
       profile_image_url = COALESCE($9, profile_image_url),
       is_active = COALESCE($10, is_active),
       updated_at = CURRENT_TIMESTAMP
     WHERE user_id = $1
     RETURNING *`,
    [
      userId,
      specialization,
      expertise_areas,
      qualification,
      experience_years,
      bio,
      languages,
      consultation_fee,
      profile_image_url,
      is_active
    ]
  );

  res.json({
    success: true,
    message: 'Expert profile updated successfully',
    expert_profile: result.rows[0]
  });
});

const setAvailability = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { availability } = req.body;

  if (!availability || !Array.isArray(availability)) {
    res.status(400);
    throw new Error('Availability must be an array');
  }

  const expertResult = await db.query(
    `SELECT id FROM expert_profiles WHERE user_id = $1`,
    [userId]
  );

  if (expertResult.rows.length === 0) {
    res.status(404);
    throw new Error('Expert profile not found');
  }

  const client = await db.pool.connect();

  try {
    await client.query('BEGIN');

    await client.query(
      `DELETE FROM expert_availability WHERE expert_id = $1`,
      [userId]
    );

    const insertedAvailability = [];

    for (const slot of availability) {
      const { day_of_week, start_time, end_time, slot_duration_minutes, is_available } = slot;

      if (day_of_week < 0 || day_of_week > 6) {
        throw new Error('day_of_week must be between 0 (Sunday) and 6 (Saturday)');
      }

      const result = await client.query(
        `INSERT INTO expert_availability 
         (expert_id, day_of_week, start_time, end_time, slot_duration_minutes, is_available)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [
          userId,
          day_of_week,
          start_time,
          end_time,
          slot_duration_minutes || 30,
          is_available !== false
        ]
      );

      insertedAvailability.push(result.rows[0]);
    }

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Availability updated successfully',
      availability: insertedAvailability
    });

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

const bookConsultation = asyncHandler(async (req, res) => {
  const farmerId = req.user.id;
  const {
    expert_id,
    scheduled_at,
    duration_minutes,
    consultation_type,
    issue_description,
    issue_images,
    diagnosis_id
  } = req.body;

  if (!expert_id || !scheduled_at) {
    res.status(400);
    throw new Error('Expert ID and scheduled time are required');
  }

  const expertResult = await db.query(
    `SELECT ep.*, u.username as expert_name 
     FROM expert_profiles ep 
     JOIN users u ON ep.user_id = u.id
     WHERE ep.user_id = $1 AND ep.is_active = true`,
    [expert_id]
  );

  if (expertResult.rows.length === 0) {
    res.status(404);
    throw new Error('Expert not found or inactive');
  }

  const slotCheck = await consultationService.isSlotAvailable(
    expert_id,
    scheduled_at,
    duration_minutes || 30
  );

  if (!slotCheck.available) {
    res.status(400);
    throw new Error(slotCheck.reason);
  }

  const feeDetails = await consultationService.calculateConsultationFee(
    expert_id,
    duration_minutes || 30
  );

  const client = await db.pool.connect();

  try {
    await client.query('BEGIN');

    const consultationResult = await client.query(
      `INSERT INTO consultations 
       (farmer_id, expert_id, scheduled_at, duration_minutes, consultation_type, 
        issue_description, issue_images, diagnosis_id, amount, status, payment_status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending', 'pending')
       RETURNING *`,
      [
        farmerId,
        expert_id,
        scheduled_at,
        duration_minutes || 30,
        consultation_type || 'video',
        issue_description,
        issue_images || [],
        diagnosis_id,
        feeDetails.total_fee
      ]
    );

    const consultation = consultationResult.rows[0];

    const paymentOrder = await paymentService.createPaymentOrder(
      feeDetails.total_fee,
      consultation.id,
      {
        consultation_id: consultation.id,
        farmer_id: farmerId,
        expert_id: expert_id
      }
    );

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      message: 'Consultation booking initiated. Please complete payment within 30 minutes.',
      consultation: consultation,
      fee_details: feeDetails,
      payment: {
        order_id: paymentOrder.id,
        amount: paymentOrder.amount,
        currency: paymentOrder.currency,
        key_id: paymentService.getKeyId()
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

const getMyConsultations = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { page = 1, limit = 10, status, role } = req.query;

  const userRole = role || (req.user.role === 'expert' ? 'expert' : 'farmer');
  const userColumn = userRole === 'expert' ? 'expert_id' : 'farmer_id';
  const otherColumn = userRole === 'expert' ? 'farmer_id' : 'expert_id';
  const otherUserLabel = userRole === 'expert' ? 'farmer' : 'expert';

  let query = `
    SELECT c.*, 
           u.username as ${otherUserLabel}_name,
           u.first_name as ${otherUserLabel}_first_name,
           u.last_name as ${otherUserLabel}_last_name,
           u.profile_image as ${otherUserLabel}_profile_image
    FROM consultations c
    JOIN users u ON c.${otherColumn} = u.id
    WHERE c.${userColumn} = $1
  `;

  const queryParams = [userId];
  let paramCount = 1;

  if (status) {
    paramCount++;
    query += ` AND c.status = $${paramCount}`;
    queryParams.push(status);
  }

  query += ` ORDER BY c.scheduled_at DESC`;

  const offset = (page - 1) * limit;
  paramCount++;
  query += ` LIMIT $${paramCount}`;
  queryParams.push(parseInt(limit));
  
  paramCount++;
  query += ` OFFSET $${paramCount}`;
  queryParams.push(offset);

  const result = await db.query(query, queryParams);

  let countQuery = `SELECT COUNT(*) FROM consultations WHERE ${userColumn} = $1`;
  const countParams = [userId];

  if (status) {
    countQuery += ' AND status = $2';
    countParams.push(status);
  }

  const countResult = await db.query(countQuery, countParams);
  const totalCount = parseInt(countResult.rows[0].count);

  res.json({
    success: true,
    consultations: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(totalCount / limit),
      total_items: totalCount,
      items_per_page: parseInt(limit)
    }
  });
});

const getConsultationById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const result = await db.query(
    `SELECT c.*,
            f.username as farmer_name, f.first_name as farmer_first_name, 
            f.last_name as farmer_last_name, f.profile_image as farmer_profile_image,
            e.username as expert_name, e.first_name as expert_first_name,
            e.last_name as expert_last_name, e.profile_image as expert_profile_image,
            ep.specialization, ep.qualification
     FROM consultations c
     JOIN users f ON c.farmer_id = f.id
     JOIN users e ON c.expert_id = e.id
     LEFT JOIN expert_profiles ep ON c.expert_id = ep.user_id
     WHERE c.id = $1 AND (c.farmer_id = $2 OR c.expert_id = $2)`,
    [id, userId]
  );

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Consultation not found');
  }

  res.json({
    success: true,
    consultation: result.rows[0]
  });
});

const rescheduleConsultation = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { new_scheduled_at } = req.body;

  if (!new_scheduled_at) {
    res.status(400);
    throw new Error('New scheduled time is required');
  }

  const consultationResult = await db.query(
    `SELECT * FROM consultations WHERE id = $1 AND (farmer_id = $2 OR expert_id = $2)`,
    [id, userId]
  );

  if (consultationResult.rows.length === 0) {
    res.status(404);
    throw new Error('Consultation not found');
  }

  const consultation = consultationResult.rows[0];

  if (!['pending', 'confirmed'].includes(consultation.status)) {
    res.status(400);
    throw new Error('Only pending or confirmed consultations can be rescheduled');
  }

  const slotCheck = await consultationService.isSlotAvailable(
    consultation.expert_id,
    new_scheduled_at,
    consultation.duration_minutes
  );

  if (!slotCheck.available) {
    res.status(400);
    throw new Error(slotCheck.reason);
  }

  const result = await db.query(
    `UPDATE consultations 
     SET scheduled_at = $2, updated_at = CURRENT_TIMESTAMP
     WHERE id = $1
     RETURNING *`,
    [id, new_scheduled_at]
  );

  consultationService.sendStatusNotification(id, 'rescheduled', 'both').catch(console.error);

  res.json({
    success: true,
    message: 'Consultation rescheduled successfully',
    consultation: result.rows[0]
  });
});

const cancelConsultation = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { reason } = req.body;

  const consultationResult = await db.query(
    `SELECT * FROM consultations WHERE id = $1 AND (farmer_id = $2 OR expert_id = $2)`,
    [id, userId]
  );

  if (consultationResult.rows.length === 0) {
    res.status(404);
    throw new Error('Consultation not found');
  }

  const consultation = consultationResult.rows[0];

  if (!['pending', 'confirmed'].includes(consultation.status)) {
    res.status(400);
    throw new Error('Only pending or confirmed consultations can be cancelled');
  }

  const refundInfo = consultationService.calculateRefundAmount(
    consultation.scheduled_at,
    parseFloat(consultation.amount)
  );

  const client = await db.pool.connect();

  try {
    await client.query('BEGIN');

    await client.query(
      `UPDATE consultations 
       SET status = 'cancelled', 
           cancellation_reason = $2,
           cancelled_by = $3,
           cancelled_at = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [id, reason, userId]
    );

    if (consultation.payment_status === 'paid' && refundInfo.refund_amount > 0) {
      if (consultation.payment_id) {
        await paymentService.initiateRefund(
          consultation.payment_id,
          refundInfo.refund_amount
        );
      }

      await client.query(
        `UPDATE consultations SET payment_status = 'refunded' WHERE id = $1`,
        [id]
      );
    }

    await client.query('COMMIT');

    consultationService.sendStatusNotification(id, consultationService.ConsultationStatus.CANCELLED, 'both').catch(console.error);

    res.json({
      success: true,
      message: 'Consultation cancelled successfully',
      refund: refundInfo
    });

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

const startConsultation = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const consultationResult = await db.query(
    `SELECT * FROM consultations WHERE id = $1 AND expert_id = $2`,
    [id, userId]
  );

  if (consultationResult.rows.length === 0) {
    res.status(404);
    throw new Error('Consultation not found or you are not the expert for this consultation');
  }

  const consultation = consultationResult.rows[0];

  if (consultation.status !== 'confirmed') {
    res.status(400);
    throw new Error('Only confirmed consultations can be started');
  }

  if (consultation.payment_status !== 'paid') {
    res.status(400);
    throw new Error('Consultation payment is not completed');
  }

  const callRoomId = consultationService.generateCallRoomId();

  const result = await db.query(
    `UPDATE consultations 
     SET status = 'in_progress',
         call_room_id = $2,
         call_started_at = CURRENT_TIMESTAMP,
         updated_at = CURRENT_TIMESTAMP
     WHERE id = $1
     RETURNING *`,
    [id, callRoomId]
  );

  const expertJoinUrl = consultationService.generateCallJoinUrl(callRoomId, 'expert', userId);
  const farmerJoinUrl = consultationService.generateCallJoinUrl(callRoomId, 'farmer', consultation.farmer_id);

  consultationService.sendStatusNotification(id, consultationService.ConsultationStatus.IN_PROGRESS, 'farmer').catch(console.error);

  res.json({
    success: true,
    message: 'Consultation started',
    consultation: result.rows[0],
    call: {
      room_id: callRoomId,
      expert_join_url: expertJoinUrl,
      farmer_join_url: farmerJoinUrl
    }
  });
});

const completeConsultation = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { expert_notes, recommendations, follow_up_required, follow_up_date } = req.body;

  const consultationResult = await db.query(
    `SELECT * FROM consultations WHERE id = $1 AND expert_id = $2`,
    [id, userId]
  );

  if (consultationResult.rows.length === 0) {
    res.status(404);
    throw new Error('Consultation not found or you are not the expert for this consultation');
  }

  const consultation = consultationResult.rows[0];

  if (consultation.status !== 'in_progress') {
    res.status(400);
    throw new Error('Only in-progress consultations can be completed');
  }

  let actualDuration = null;
  if (consultation.call_started_at) {
    const startTime = new Date(consultation.call_started_at);
    const endTime = new Date();
    actualDuration = Math.round((endTime - startTime) / (1000 * 60));
  }

  const result = await db.query(
    `UPDATE consultations 
     SET status = 'completed',
         call_ended_at = CURRENT_TIMESTAMP,
         actual_duration_minutes = $2,
         expert_notes = $3,
         recommendations = $4,
         follow_up_required = $5,
         follow_up_date = $6,
         updated_at = CURRENT_TIMESTAMP
     WHERE id = $1
     RETURNING *`,
    [id, actualDuration, expert_notes, recommendations, follow_up_required || false, follow_up_date]
  );

  consultationService.incrementExpertConsultations(userId).catch(console.error);
  consultationService.sendStatusNotification(id, consultationService.ConsultationStatus.COMPLETED, 'farmer').catch(console.error);

  res.json({
    success: true,
    message: 'Consultation completed successfully',
    consultation: result.rows[0]
  });
});

const addReview = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { rating, review_text, was_helpful, would_recommend } = req.body;

  if (!rating || rating < 1 || rating > 5) {
    res.status(400);
    throw new Error('Rating must be between 1 and 5');
  }

  const consultationResult = await db.query(
    `SELECT * FROM consultations WHERE id = $1 AND farmer_id = $2`,
    [id, userId]
  );

  if (consultationResult.rows.length === 0) {
    res.status(404);
    throw new Error('Consultation not found or you are not the farmer for this consultation');
  }

  const consultation = consultationResult.rows[0];

  if (consultation.status !== 'completed') {
    res.status(400);
    throw new Error('You can only review completed consultations');
  }

  const existingReview = await db.query(
    `SELECT id FROM consultation_reviews WHERE consultation_id = $1`,
    [id]
  );

  if (existingReview.rows.length > 0) {
    res.status(400);
    throw new Error('You have already reviewed this consultation');
  }

  const client = await db.pool.connect();

  try {
    await client.query('BEGIN');

    const reviewResult = await client.query(
      `INSERT INTO consultation_reviews 
       (consultation_id, farmer_id, expert_id, rating, review_text, was_helpful, would_recommend)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        id,
        userId,
        consultation.expert_id,
        rating,
        review_text,
        was_helpful,
        would_recommend
      ]
    );

    await consultationService.updateExpertRating(consultation.expert_id, rating);

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      message: 'Review submitted successfully',
      review: reviewResult.rows[0]
    });

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

const getExpertReviews = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { page = 1, limit = 10, sort = 'recent' } = req.query;

  const expertResult = await db.query(
    `SELECT user_id FROM expert_profiles WHERE user_id = $1`,
    [id]
  );

  if (expertResult.rows.length === 0) {
    res.status(404);
    throw new Error('Expert not found');
  }

  let query = `
    SELECT cr.*, u.username as farmer_name, u.first_name, u.last_name
    FROM consultation_reviews cr
    JOIN users u ON cr.farmer_id = u.id
    WHERE cr.expert_id = $1
  `;

  const sortOptions = {
    recent: 'cr.created_at DESC',
    oldest: 'cr.created_at ASC',
    highest: 'cr.rating DESC',
    lowest: 'cr.rating ASC'
  };

  query += ` ORDER BY ${sortOptions[sort] || sortOptions.recent}`;

  const offset = (page - 1) * limit;
  query += ` LIMIT $2 OFFSET $3`;

  const result = await db.query(query, [id, parseInt(limit), offset]);

  const statsResult = await db.query(
    `SELECT 
       COUNT(*) as total_reviews,
       AVG(rating)::numeric(3,2) as average_rating,
       COUNT(CASE WHEN rating = 5 THEN 1 END) as five_star,
       COUNT(CASE WHEN rating = 4 THEN 1 END) as four_star,
       COUNT(CASE WHEN rating = 3 THEN 1 END) as three_star,
       COUNT(CASE WHEN rating = 2 THEN 1 END) as two_star,
       COUNT(CASE WHEN rating = 1 THEN 1 END) as one_star,
       COUNT(CASE WHEN was_helpful = true THEN 1 END) as helpful_count,
       COUNT(CASE WHEN would_recommend = true THEN 1 END) as recommend_count
     FROM consultation_reviews
     WHERE expert_id = $1`,
    [id]
  );

  const totalCount = parseInt(statsResult.rows[0].total_reviews);

  res.json({
    success: true,
    reviews: result.rows,
    statistics: statsResult.rows[0],
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(totalCount / limit),
      total_items: totalCount,
      items_per_page: parseInt(limit)
    }
  });
});

const confirmConsultation = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const consultationResult = await db.query(
    `SELECT * FROM consultations WHERE id = $1 AND expert_id = $2`,
    [id, userId]
  );

  if (consultationResult.rows.length === 0) {
    res.status(404);
    throw new Error('Consultation not found or you are not the expert for this consultation');
  }

  const consultation = consultationResult.rows[0];

  if (consultation.status !== 'pending') {
    res.status(400);
    throw new Error('Only pending consultations can be confirmed');
  }

  if (consultation.payment_status !== 'paid') {
    res.status(400);
    throw new Error('Cannot confirm consultation - payment not completed');
  }

  const result = await db.query(
    `UPDATE consultations 
     SET status = 'confirmed', updated_at = CURRENT_TIMESTAMP
     WHERE id = $1
     RETURNING *`,
    [id]
  );

  consultationService.sendStatusNotification(id, consultationService.ConsultationStatus.CONFIRMED, 'farmer').catch(console.error);

  res.json({
    success: true,
    message: 'Consultation confirmed successfully',
    consultation: result.rows[0]
  });
});

const rejectConsultation = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { reason } = req.body;

  const consultationResult = await db.query(
    `SELECT * FROM consultations WHERE id = $1 AND expert_id = $2`,
    [id, userId]
  );

  if (consultationResult.rows.length === 0) {
    res.status(404);
    throw new Error('Consultation not found or you are not the expert for this consultation');
  }

  const consultation = consultationResult.rows[0];

  if (consultation.status !== 'pending') {
    res.status(400);
    throw new Error('Only pending consultations can be rejected');
  }

  const client = await db.pool.connect();

  try {
    await client.query('BEGIN');

    await client.query(
      `UPDATE consultations 
       SET status = 'cancelled',
           cancellation_reason = $2,
           cancelled_by = $3,
           cancelled_at = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [id, reason || 'Rejected by expert', userId]
    );

    if (consultation.payment_status === 'paid' && consultation.payment_id) {
      await paymentService.initiateRefund(consultation.payment_id, parseFloat(consultation.amount));
      await client.query(
        `UPDATE consultations SET payment_status = 'refunded' WHERE id = $1`,
        [id]
      );
    }

    await client.query('COMMIT');

    consultationService.sendStatusNotification(id, consultationService.ConsultationStatus.CANCELLED, 'farmer').catch(console.error);

    res.json({
      success: true,
      message: 'Consultation rejected. Full refund initiated for the farmer.',
      refund_amount: parseFloat(consultation.amount)
    });

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

const getVideoTokens = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const consultationResult = await db.query(
    `SELECT * FROM consultations WHERE id = $1 AND (farmer_id = $2 OR expert_id = $2)`,
    [id, userId]
  );

  if (consultationResult.rows.length === 0) {
    res.status(404);
    throw new Error('Consultation not found');
  }

  const consultation = consultationResult.rows[0];

  if (!['confirmed', 'in_progress'].includes(consultation.status)) {
    res.status(400);
    throw new Error('Video tokens are only available for confirmed or in-progress consultations');
  }

  if (consultation.payment_status !== 'paid') {
    res.status(400);
    throw new Error('Payment must be completed before joining the video call');
  }

  const scheduledTime = new Date(consultation.scheduled_at);
  const now = new Date();
  const minutesUntilStart = (scheduledTime - now) / (1000 * 60);

  if (minutesUntilStart > 15) {
    res.status(400);
    throw new Error(`Video call can only be joined within 15 minutes of scheduled time. Time remaining: ${Math.round(minutesUntilStart)} minutes`);
  }

  let channelName = consultation.call_room_id;
  if (!channelName) {
    channelName = agoraService.generateChannelName(consultation.id);
    await db.query(
      `UPDATE consultations SET call_room_id = $2 WHERE id = $1`,
      [id, channelName]
    );
  }

  const userRole = userId === consultation.expert_id ? 'expert' : 'farmer';
  const rtcToken = agoraService.generateRtcToken(channelName, userId, 'publisher', 7200);
  const rtmToken = agoraService.generateRtmToken(userId, 7200);

  res.json({
    success: true,
    video_session: {
      channel_name: channelName,
      app_id: agoraService.getAppId(),
      rtc_token: rtcToken.token,
      rtm_token: rtmToken.token,
      uid: rtcToken.uid,
      role: userRole,
      expires_at: rtcToken.expiresAt,
      consultation_type: consultation.consultation_type,
      duration_minutes: consultation.duration_minutes
    }
  });
});

const joinConsultation = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const consultationResult = await db.query(
    `SELECT c.*, 
            f.first_name as farmer_first_name, f.last_name as farmer_last_name,
            e.first_name as expert_first_name, e.last_name as expert_last_name,
            ep.specialization
     FROM consultations c
     JOIN users f ON c.farmer_id = f.id
     JOIN users e ON c.expert_id = e.id
     LEFT JOIN expert_profiles ep ON c.expert_id = ep.user_id
     WHERE c.id = $1 AND (c.farmer_id = $2 OR c.expert_id = $2)`,
    [id, userId]
  );

  if (consultationResult.rows.length === 0) {
    res.status(404);
    throw new Error('Consultation not found');
  }

  const consultation = consultationResult.rows[0];

  if (!['confirmed', 'in_progress'].includes(consultation.status)) {
    res.status(400);
    throw new Error('Cannot join - consultation is not active');
  }

  if (consultation.payment_status !== 'paid') {
    res.status(400);
    throw new Error('Cannot join - payment not completed');
  }

  let channelName = consultation.call_room_id;
  if (!channelName) {
    channelName = agoraService.generateChannelName(consultation.id);
  }

  const tokens = agoraService.generateConsultationTokens(
    channelName,
    consultation.farmer_id,
    consultation.expert_id,
    7200
  );

  const isExpert = userId === consultation.expert_id;
  const userTokens = isExpert ? tokens.expert : tokens.farmer;

  if (consultation.status === 'confirmed' && isExpert) {
    await db.query(
      `UPDATE consultations 
       SET status = 'in_progress',
           call_room_id = $2,
           call_started_at = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [id, channelName]
    );

    consultationService.sendStatusNotification(id, consultationService.ConsultationStatus.IN_PROGRESS, 'farmer').catch(console.error);
  }

  res.json({
    success: true,
    session: {
      consultation_id: id,
      channel_name: channelName,
      app_id: tokens.appId,
      rtc_token: userTokens.rtcToken,
      rtm_token: userTokens.rtmToken,
      uid: userTokens.uid,
      expires_at: userTokens.expiresAt,
      role: isExpert ? 'expert' : 'farmer',
      participant: isExpert 
        ? { name: `${consultation.farmer_first_name} ${consultation.farmer_last_name}`, role: 'farmer' }
        : { name: `${consultation.expert_first_name} ${consultation.expert_last_name}`, role: 'expert', specialization: consultation.specialization },
      consultation_type: consultation.consultation_type,
      duration_minutes: consultation.duration_minutes,
      issue_description: consultation.issue_description,
      issue_images: consultation.issue_images
    }
  });
});

const getPendingConsultations = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { page = 1, limit = 10 } = req.query;

  const expertResult = await db.query(
    `SELECT id FROM expert_profiles WHERE user_id = $1`,
    [userId]
  );

  if (expertResult.rows.length === 0) {
    res.status(404);
    throw new Error('Expert profile not found');
  }

  const result = await db.query(
    `SELECT c.*, u.first_name, u.last_name, u.profile_image
     FROM consultations c
     JOIN users u ON c.farmer_id = u.id
     WHERE c.expert_id = $1 AND c.status = 'pending' AND c.payment_status = 'paid'
     ORDER BY c.scheduled_at ASC
     LIMIT $2 OFFSET $3`,
    [userId, parseInt(limit), (parseInt(page) - 1) * parseInt(limit)]
  );

  const countResult = await db.query(
    `SELECT COUNT(*) FROM consultations WHERE expert_id = $1 AND status = 'pending' AND payment_status = 'paid'`,
    [userId]
  );

  const totalCount = parseInt(countResult.rows[0].count);

  res.json({
    success: true,
    consultations: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(totalCount / parseInt(limit)),
      total_items: totalCount,
      items_per_page: parseInt(limit)
    }
  });
});

const markNoShow = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const consultationResult = await db.query(
    `SELECT * FROM consultations WHERE id = $1 AND expert_id = $2`,
    [id, userId]
  );

  if (consultationResult.rows.length === 0) {
    res.status(404);
    throw new Error('Consultation not found or you are not the expert');
  }

  const consultation = consultationResult.rows[0];

  if (consultation.status !== 'confirmed') {
    res.status(400);
    throw new Error('Only confirmed consultations can be marked as no-show');
  }

  const scheduledTime = new Date(consultation.scheduled_at);
  const now = new Date();
  const minutesPastScheduled = (now - scheduledTime) / (1000 * 60);

  if (minutesPastScheduled < 10) {
    res.status(400);
    throw new Error('Cannot mark as no-show until 10 minutes after scheduled time');
  }

  const result = await db.query(
    `UPDATE consultations 
     SET status = 'no_show', updated_at = CURRENT_TIMESTAMP
     WHERE id = $1
     RETURNING *`,
    [id]
  );

  res.json({
    success: true,
    message: 'Consultation marked as no-show',
    consultation: result.rows[0]
  });
});

module.exports = {
  getExperts,
  getExpertById,
  getExpertAvailability,
  registerAsExpert,
  updateExpertProfile,
  setAvailability,
  bookConsultation,
  getMyConsultations,
  getConsultationById,
  rescheduleConsultation,
  cancelConsultation,
  startConsultation,
  completeConsultation,
  addReview,
  getExpertReviews,
  confirmConsultation,
  rejectConsultation,
  getVideoTokens,
  joinConsultation,
  getPendingConsultations,
  markNoShow
};

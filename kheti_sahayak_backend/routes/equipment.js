/**
 * Equipment Routes
 *
 * Farm Machinery Lending & Rental Platform API (Epic #395)
 */

const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const {
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
} = require('../controllers/equipmentController');

/**
 * @swagger
 * components:
 *   schemas:
 *     EquipmentCategory:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         name:
 *           type: string
 *         name_hi:
 *           type: string
 *         description:
 *           type: string
 *         icon:
 *           type: string
 *         listing_count:
 *           type: integer
 *     EquipmentListing:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         owner_id:
 *           type: string
 *           format: uuid
 *         category_id:
 *           type: string
 *           format: uuid
 *         name:
 *           type: string
 *         description:
 *           type: string
 *         brand:
 *           type: string
 *         model:
 *           type: string
 *         condition:
 *           type: string
 *           enum: [excellent, good, fair, needs_repair]
 *         daily_rate:
 *           type: number
 *         availability_status:
 *           type: string
 *           enum: [available, rented, maintenance, unavailable]
 *         images:
 *           type: array
 *           items:
 *             type: string
 *         average_rating:
 *           type: number
 *     EquipmentBooking:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         equipment_id:
 *           type: string
 *           format: uuid
 *         renter_id:
 *           type: string
 *           format: uuid
 *         start_date:
 *           type: string
 *           format: date
 *         end_date:
 *           type: string
 *           format: date
 *         rental_days:
 *           type: integer
 *         total_amount:
 *           type: number
 *         status:
 *           type: string
 *           enum: [pending, confirmed, in_progress, completed, cancelled, disputed]
 */

/**
 * @swagger
 * tags:
 *   name: Equipment
 *   description: Farm machinery rental platform
 */

/**
 * @swagger
 * /api/equipment/categories:
 *   get:
 *     summary: Get all equipment categories
 *     tags: [Equipment]
 *     responses:
 *       200:
 *         description: List of equipment categories
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/EquipmentCategory'
 */
router.get('/categories', getCategories);

/**
 * @swagger
 * /api/equipment/categories:
 *   post:
 *     summary: Create equipment category (Admin only)
 *     tags: [Equipment]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *             properties:
 *               name:
 *                 type: string
 *               name_hi:
 *                 type: string
 *               description:
 *                 type: string
 *               icon:
 *                 type: string
 *               parent_id:
 *                 type: string
 *                 format: uuid
 *     responses:
 *       201:
 *         description: Category created
 */
router.post('/categories', protect, authorize('admin'), createCategory);

/**
 * @swagger
 * /api/equipment/listings:
 *   get:
 *     summary: Get equipment listings with filters
 *     tags: [Equipment]
 *     parameters:
 *       - in: query
 *         name: category_id
 *         schema:
 *           type: string
 *       - in: query
 *         name: availability_status
 *         schema:
 *           type: string
 *           enum: [available, rented, maintenance, unavailable]
 *       - in: query
 *         name: min_daily_rate
 *         schema:
 *           type: number
 *       - in: query
 *         name: max_daily_rate
 *         schema:
 *           type: number
 *       - in: query
 *         name: condition
 *         schema:
 *           type: string
 *       - in: query
 *         name: lat
 *         schema:
 *           type: number
 *         description: Latitude for location-based search
 *       - in: query
 *         name: lng
 *         schema:
 *           type: number
 *         description: Longitude for location-based search
 *       - in: query
 *         name: radius_km
 *         schema:
 *           type: integer
 *           default: 50
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
 *     responses:
 *       200:
 *         description: List of equipment listings
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/EquipmentListing'
 *                 pagination:
 *                   type: object
 */
router.get('/listings', getListings);

/**
 * @swagger
 * /api/equipment/listings/{id}:
 *   get:
 *     summary: Get equipment listing by ID
 *     tags: [Equipment]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Equipment listing details
 *       404:
 *         description: Listing not found
 */
router.get('/listings/:id', getListingById);

/**
 * @swagger
 * /api/equipment/listings:
 *   post:
 *     summary: Create new equipment listing
 *     tags: [Equipment]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - category_id
 *               - name
 *               - daily_rate
 *             properties:
 *               category_id:
 *                 type: string
 *                 format: uuid
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               brand:
 *                 type: string
 *               model:
 *                 type: string
 *               year_of_manufacture:
 *                 type: integer
 *               condition:
 *                 type: string
 *                 enum: [excellent, good, fair, needs_repair]
 *               hourly_rate:
 *                 type: number
 *               daily_rate:
 *                 type: number
 *               weekly_rate:
 *                 type: number
 *               deposit_amount:
 *                 type: number
 *               location_address:
 *                 type: string
 *               location_lat:
 *                 type: number
 *               location_lng:
 *                 type: number
 *               service_radius_km:
 *                 type: integer
 *               images:
 *                 type: array
 *                 items:
 *                   type: string
 *               specifications:
 *                 type: object
 *               is_operator_included:
 *                 type: boolean
 *               operator_rate_per_day:
 *                 type: number
 *               minimum_rental_days:
 *                 type: integer
 *               maximum_rental_days:
 *                 type: integer
 *     responses:
 *       201:
 *         description: Listing created
 */
router.post('/listings', protect, createListing);

/**
 * @swagger
 * /api/equipment/listings/{id}:
 *   put:
 *     summary: Update equipment listing
 *     tags: [Equipment]
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
 *     responses:
 *       200:
 *         description: Listing updated
 *       403:
 *         description: Not authorized
 *       404:
 *         description: Listing not found
 */
router.put('/listings/:id', protect, updateListing);

/**
 * @swagger
 * /api/equipment/listings/{id}:
 *   delete:
 *     summary: Delete equipment listing
 *     tags: [Equipment]
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
 *         description: Listing deleted
 *       403:
 *         description: Not authorized
 *       404:
 *         description: Listing not found
 */
router.delete('/listings/:id', protect, deleteListing);

/**
 * @swagger
 * /api/equipment/my-listings:
 *   get:
 *     summary: Get current user's equipment listings
 *     tags: [Equipment]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: User's equipment listings
 */
router.get('/my-listings', protect, getMyListings);

/**
 * @swagger
 * /api/equipment/bookings:
 *   post:
 *     summary: Create booking request
 *     tags: [Equipment]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - equipment_id
 *               - start_date
 *               - end_date
 *             properties:
 *               equipment_id:
 *                 type: string
 *                 format: uuid
 *               start_date:
 *                 type: string
 *                 format: date
 *               end_date:
 *                 type: string
 *                 format: date
 *               operator_included:
 *                 type: boolean
 *               delivery_address:
 *                 type: string
 *               delivery_lat:
 *                 type: number
 *               delivery_lng:
 *                 type: number
 *               notes:
 *                 type: string
 *     responses:
 *       201:
 *         description: Booking created
 *       400:
 *         description: Equipment not available for selected dates
 */
router.post('/bookings', protect, createBooking);

/**
 * @swagger
 * /api/equipment/bookings/my:
 *   get:
 *     summary: Get current user's bookings (as renter)
 *     tags: [Equipment]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, confirmed, in_progress, completed, cancelled, disputed]
 *     responses:
 *       200:
 *         description: User's bookings
 */
router.get('/bookings/my', protect, getMyBookings);

/**
 * @swagger
 * /api/equipment/bookings/owner:
 *   get:
 *     summary: Get bookings for owner's equipment
 *     tags: [Equipment]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, confirmed, in_progress, completed, cancelled, disputed]
 *     responses:
 *       200:
 *         description: Bookings for owner's equipment
 */
router.get('/bookings/owner', protect, getOwnerBookings);

/**
 * @swagger
 * /api/equipment/bookings/{id}/status:
 *   patch:
 *     summary: Update booking status
 *     tags: [Equipment]
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
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [confirmed, in_progress, completed, cancelled]
 *               cancellation_reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: Booking status updated
 *       403:
 *         description: Not authorized
 */
router.patch('/bookings/:id/status', protect, updateBookingStatus);

/**
 * @swagger
 * /api/equipment/reviews:
 *   post:
 *     summary: Add review for completed booking
 *     tags: [Equipment]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - booking_id
 *               - rating
 *             properties:
 *               booking_id:
 *                 type: string
 *                 format: uuid
 *               rating:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *               review_text:
 *                 type: string
 *               condition_rating:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *               owner_rating:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *               value_rating:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *     responses:
 *       201:
 *         description: Review added
 *       400:
 *         description: Can only review completed bookings
 */
router.post('/reviews', protect, addReview);

/**
 * @swagger
 * /api/equipment/reviews/{equipment_id}:
 *   get:
 *     summary: Get reviews for equipment
 *     tags: [Equipment]
 *     parameters:
 *       - in: path
 *         name: equipment_id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Equipment reviews
 */
router.get('/reviews/:equipment_id', getEquipmentReviews);

module.exports = router;

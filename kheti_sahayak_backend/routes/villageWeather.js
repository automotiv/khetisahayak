const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
  searchVillages,
  getVillageWeather,
  getVillageForecast,
  saveVillagePreference,
  getMyVillages,
  deleteVillagePreference,
  getCropCalendar
} = require('../controllers/villageWeatherController');

const router = express.Router();

/**
 * @swagger
 * tags:
 *   name: Village Weather
 *   description: Hyperlocal village-level weather forecasts and crop calendars for Indian farmers
 */

/**
 * @swagger
 * /api/village-weather/search:
 *   get:
 *     summary: Search for Indian villages by name
 *     description: Search for villages, towns, and cities in India with geocoding
 *     tags: [Village Weather]
 *     parameters:
 *       - in: query
 *         name: q
 *         required: true
 *         schema:
 *           type: string
 *         description: Village/town name to search (minimum 2 characters)
 *       - in: query
 *         name: state
 *         schema:
 *           type: string
 *         description: State name to narrow search (e.g., Maharashtra, Uttar Pradesh)
 *       - in: query
 *         name: district
 *         schema:
 *           type: string
 *         description: District name to narrow search
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Maximum number of results (max 20)
 *     responses:
 *       200:
 *         description: List of matching villages with coordinates
 *       400:
 *         description: Invalid search query
 */
router.get('/search', searchVillages);

/**
 * @swagger
 * /api/village-weather/current:
 *   get:
 *     summary: Get hyperlocal weather for a village
 *     description: Get current weather, seasonal info, crop calendar, and agricultural advisory for a specific location
 *     tags: [Village Weather]
 *     parameters:
 *       - in: query
 *         name: lat
 *         schema:
 *           type: number
 *         description: Latitude of the village
 *       - in: query
 *         name: lon
 *         schema:
 *           type: number
 *         description: Longitude of the village
 *       - in: query
 *         name: village
 *         schema:
 *           type: string
 *         description: Village name (alternative to lat/lon - will be geocoded)
 *     responses:
 *       200:
 *         description: Village weather with crop calendar and advisory
 *       400:
 *         description: Missing required parameters
 */
router.get('/current', getVillageWeather);

/**
 * @swagger
 * /api/village-weather/forecast:
 *   get:
 *     summary: Get multi-day forecast for a village
 *     description: Get up to 14-day forecast with agricultural suitability ratings for farming activities
 *     tags: [Village Weather]
 *     parameters:
 *       - in: query
 *         name: lat
 *         required: true
 *         schema:
 *           type: number
 *         description: Latitude of the village
 *       - in: query
 *         name: lon
 *         required: true
 *         schema:
 *           type: number
 *         description: Longitude of the village
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 7
 *         description: Number of forecast days (max 14)
 *     responses:
 *       200:
 *         description: Multi-day forecast with farming recommendations
 *       400:
 *         description: Missing required parameters
 */
router.get('/forecast', getVillageForecast);

/**
 * @swagger
 * /api/village-weather/crop-calendar:
 *   get:
 *     summary: Get seasonal crop calendar for a location
 *     description: Get state-specific crop calendar with current season, sowing/harvesting times, and recommendations
 *     tags: [Village Weather]
 *     parameters:
 *       - in: query
 *         name: lat
 *         required: true
 *         schema:
 *           type: number
 *         description: Latitude
 *       - in: query
 *         name: lon
 *         required: true
 *         schema:
 *           type: number
 *         description: Longitude
 *       - in: query
 *         name: state
 *         schema:
 *           type: string
 *         description: State code or name (optional - will be auto-detected from coordinates)
 *     responses:
 *       200:
 *         description: Seasonal crop calendar with current activities
 *       400:
 *         description: Missing required parameters
 */
router.get('/crop-calendar', getCropCalendar);

/**
 * @swagger
 * /api/village-weather/my-villages:
 *   get:
 *     summary: Get user's saved village preferences
 *     description: Get all saved village locations for the authenticated user
 *     tags: [Village Weather]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of saved villages
 *       401:
 *         description: Authentication required
 */
router.get('/my-villages', protect, getMyVillages);

/**
 * @swagger
 * /api/village-weather/my-villages:
 *   post:
 *     summary: Save a village as user preference
 *     description: Save a village location for quick access. Supports multiple villages per user.
 *     tags: [Village Weather]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - lat
 *               - lon
 *             properties:
 *               lat:
 *                 type: number
 *                 description: Village latitude
 *               lon:
 *                 type: number
 *                 description: Village longitude
 *               village_name:
 *                 type: string
 *                 description: Village name (optional - will be reverse geocoded)
 *               district:
 *                 type: string
 *                 description: District name
 *               state:
 *                 type: string
 *                 description: State name
 *               is_primary:
 *                 type: boolean
 *                 description: Set as primary/home village
 *     responses:
 *       201:
 *         description: Village preference saved
 *       401:
 *         description: Authentication required
 */
router.post('/my-villages', protect, saveVillagePreference);

/**
 * @swagger
 * /api/village-weather/my-villages/{id}:
 *   delete:
 *     summary: Delete a saved village preference
 *     description: Remove a village from user's saved locations
 *     tags: [Village Weather]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Village preference ID
 *     responses:
 *       200:
 *         description: Village preference deleted
 *       401:
 *         description: Authentication required
 *       404:
 *         description: Village preference not found
 */
router.delete('/my-villages/:id', protect, deleteVillagePreference);

module.exports = router;

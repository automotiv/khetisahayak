const express = require('express');
const axios = require('axios');
const redisClient = require('../redisClient');
const { getRecommendations, getForecast: getEnhancedForecast } = require('../controllers/weatherController');

const router = express.Router();
const WEATHER_API_URL = 'https://api.openweathermap.org/data/2.5/weather';
const FORECAST_API_URL = 'https://api.openweathermap.org/data/2.5/forecast';

/**
 * @swagger
 * /api/weather/current:
 *   get:
 *     summary: Get current weather
 *     tags: [Weather]
 *     parameters:
 *       - in: query
 *         name: lat
 *         schema:
 *           type: number
 *         description: Latitude
 *       - in: query
 *         name: lon
 *         schema:
 *           type: number
 *         description: Longitude
 *       - in: query
 *         name: city
 *         schema:
 *           type: string
 *         description: City name
 *     responses:
 *       200:
 *         description: Current weather data
 *       400:
 *         description: Missing required parameters
 *       500:
 *         description: Server error
 */
router.get('/current', async (req, res) => {
  const { lat, lon, city } = req.query;

  if (!city && (!lat || !lon)) {
    return res.status(400).json({
      success: false,
      error: 'Either city name or lat/lon coordinates are required'
    });
  }

  try {
    const apiKey = process.env.WEATHER_API_KEY;
    if (!apiKey) {
      console.error('WEATHER_API_KEY is not set in .env file');
      return res.status(500).json({
        success: false,
        error: 'Server configuration error: Missing weather API key'
      });
    }

    // Create cache key based on location
    const cacheKey = city ? `weather:${city}` : `weather:${lat},${lon}`;

    // Try to get data from Redis cache
    const cachedData = await redisClient.get(cacheKey);
    if (cachedData) {
      console.log('Serving weather data from Redis cache');
      return res.json(JSON.parse(cachedData));
    }

    // Build API parameters
    const params = {
      appid: apiKey,
      units: 'metric'
    };

    if (city) {
      params.q = city;
    } else {
      params.lat = lat;
      params.lon = lon;
    }

    // Fetch from OpenWeatherMap API
    const response = await axios.get(WEATHER_API_URL, { params });
    const weatherData = {
      success: true,
      location: {
        name: response.data.name,
        country: response.data.sys.country,
        lat: response.data.coord.lat,
        lon: response.data.coord.lon
      },
      current: {
        temp: response.data.main.temp,
        feels_like: response.data.main.feels_like,
        temp_min: response.data.main.temp_min,
        temp_max: response.data.main.temp_max,
        pressure: response.data.main.pressure,
        humidity: response.data.main.humidity,
        weather: response.data.weather[0].main,
        description: response.data.weather[0].description,
        icon: response.data.weather[0].icon,
        wind_speed: response.data.wind.speed,
        wind_deg: response.data.wind.deg,
        clouds: response.data.clouds.all,
        visibility: response.data.visibility,
        sunrise: response.data.sys.sunrise,
        sunset: response.data.sys.sunset
      },
      timestamp: response.data.dt
    };

    // Store in Redis cache with 10 minutes expiration
    await redisClient.setex(cacheKey, 600, JSON.stringify(weatherData));
    console.log('Serving weather data from API and caching');
    res.json(weatherData);
  } catch (error) {
    console.error('Error fetching weather data:', error.message);
    if (error.response) {
      res.status(error.response.status).json({
        success: false,
        error: error.response.data.message || 'Failed to fetch weather data'
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Failed to fetch weather data'
      });
    }
  }
});

/**
 * @swagger
 * /api/weather/forecast:
 *   get:
 *     summary: Get 5-day weather forecast
 *     tags: [Weather]
 *     parameters:
 *       - in: query
 *         name: lat
 *         schema:
 *           type: number
 *         description: Latitude
 *       - in: query
 *         name: lon
 *         schema:
 *           type: number
 *         description: Longitude
 *       - in: query
 *         name: city
 *         schema:
 *           type: string
 *         description: City name
 *     responses:
 *       200:
 *         description: 5-day weather forecast
 *       400:
 *         description: Missing required parameters
 *       500:
 *         description: Server error
 */
router.get('/forecast', async (req, res) => {
  const { lat, lon, city } = req.query;

  if (!city && (!lat || !lon)) {
    return res.status(400).json({
      success: false,
      error: 'Either city name or lat/lon coordinates are required'
    });
  }

  try {
    const apiKey = process.env.WEATHER_API_KEY;
    if (!apiKey) {
      console.error('WEATHER_API_KEY is not set in .env file');
      return res.status(500).json({
        success: false,
        error: 'Server configuration error: Missing weather API key'
      });
    }

    // Create cache key
    const cacheKey = city ? `forecast:${city}` : `forecast:${lat},${lon}`;

    // Try to get data from Redis cache
    const cachedData = await redisClient.get(cacheKey);
    if (cachedData) {
      console.log('Serving forecast data from Redis cache');
      return res.json(JSON.parse(cachedData));
    }

    // Build API parameters
    const params = {
      appid: apiKey,
      units: 'metric'
    };

    if (city) {
      params.q = city;
    } else {
      params.lat = lat;
      params.lon = lon;
    }

    // Fetch from OpenWeatherMap API
    const response = await axios.get(FORECAST_API_URL, { params });

    // Process forecast data - group by day
    const dailyForecasts = {};
    response.data.list.forEach(item => {
      const date = new Date(item.dt * 1000).toISOString().split('T')[0];
      if (!dailyForecasts[date]) {
        dailyForecasts[date] = [];
      }
      dailyForecasts[date].push({
        time: item.dt,
        temp: item.main.temp,
        feels_like: item.main.feels_like,
        humidity: item.main.humidity,
        weather: item.weather[0].main,
        description: item.weather[0].description,
        icon: item.weather[0].icon,
        wind_speed: item.wind.speed,
        clouds: item.clouds.all,
        rain: item.rain ? item.rain['3h'] : 0
      });
    });

    const forecastData = {
      success: true,
      location: {
        name: response.data.city.name,
        country: response.data.city.country,
        lat: response.data.city.coord.lat,
        lon: response.data.city.coord.lon
      },
      forecast: Object.keys(dailyForecasts).slice(0, 5).map(date => ({
        date,
        data: dailyForecasts[date]
      }))
    };

    // Store in Redis cache with 30 minutes expiration
    await redisClient.setex(cacheKey, 1800, JSON.stringify(forecastData));
    console.log('Serving forecast data from API and caching');
    res.json(forecastData);
  } catch (error) {
    console.error('Error fetching forecast data:', error.message);
    if (error.response) {
      res.status(error.response.status).json({
        success: false,
        error: error.response.data.message || 'Failed to fetch forecast data'
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Failed to fetch forecast data'
      });
    }
  }
});

/**
 * @swagger
 * /api/weather/recommendations:
 *   get:
 *     summary: Get weather-based farming activity recommendations
 *     description: Returns personalized farming activity recommendations based on current weather conditions
 *     tags: [Weather]
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
 *     responses:
 *       200:
 *         description: Activity recommendations based on weather
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     current_weather:
 *                       type: object
 *                     activity_recommendations:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           activity:
 *                             type: string
 *                           name:
 *                             type: string
 *                           name_hi:
 *                             type: string
 *                           severity:
 *                             type: string
 *                             enum: [ideal, caution, avoid]
 *                           suitability_score:
 *                             type: integer
 *                           message:
 *                             type: string
 *                           issues:
 *                             type: array
 *                             items:
 *                               type: string
 *                     daily_tips:
 *                       type: array
 *                       items:
 *                         type: object
 *       400:
 *         description: Missing required parameters
 */
router.get('/recommendations', getRecommendations);

/**
 * @swagger
 * /api/weather/forecast-enhanced:
 *   get:
 *     summary: Get 5-day forecast with activity recommendations
 *     tags: [Weather]
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
 *     responses:
 *       200:
 *         description: 5-day forecast with daily activity recommendations
 */
router.get('/forecast-enhanced', getEnhancedForecast);

/**
 * @swagger
 * /api/weather/:city:
 *   get:
 *     summary: Get current weather by city name (legacy endpoint)
 *     tags: [Weather]
 *     parameters:
 *       - in: path
 *         name: city
 *         required: true
 *         schema:
 *           type: string
 *         description: City name
 *     responses:
 *       200:
 *         description: Current weather data
 *       500:
 *         description: Server error
 */
router.get('/:city', async (req, res) => {
  const city = req.params.city;

  // Redirect to new /current endpoint
  req.query.city = city;
  return router.handle({ ...req, url: '/current', query: req.query }, res);
});

module.exports = router;
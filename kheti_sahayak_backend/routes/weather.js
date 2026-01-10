const express = require('express');
const axios = require('axios');
const redisClient = require('../redisClient');
const { protect } = require('../middleware/authMiddleware');
const {
  getRecommendations,
  getForecast: getEnhancedForecast,
  getHourlyForecast,
  getWeatherAlerts,
  getSeasonalAdvisory,
  subscribeToAlerts,
  unsubscribeFromAlerts,
  getMyAlertSubscriptions,
} = require('../controllers/weatherController');

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

  if (!lat || !lon) {
    if (!city) {
      return res.status(400).json({
        success: false,
        error: 'Either city name or lat/lon coordinates are required'
      });
    }
  }

  try {
    const apiKey = process.env.WEATHER_API_KEY;
    const cacheKey = city ? `weather:${city}` : `weather:${lat},${lon}`;

    // Try to get data from Redis cache
    try {
      const cachedData = await redisClient.get(cacheKey);
      if (cachedData) {
        console.log('Serving weather data from Redis cache');
        return res.json(JSON.parse(cachedData));
      }
    } catch (redisError) {
      console.warn('Redis error:', redisError.message);
    }

    let weatherData = null;

    // PRIMARY: OpenWeatherMap (if key exists)
    if (apiKey) {
      try {
        const params = { appid: apiKey, units: 'metric' };
        if (city) params.q = city;
        else { params.lat = lat; params.lon = lon; }

        const response = await axios.get(WEATHER_API_URL, { params });
        weatherData = {
          success: true,
          source: 'OpenWeatherMap',
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
      } catch (err) {
        console.warn('OpenWeatherMap failed, falling back to Open-Meteo', err.message);
      }
    }

    // FALLBACK / DEFAULT: Open-Meteo (Free, No Key)
    if (!weatherData) {
      // Open-Meteo requires lat/lon. If only city provided, we'd need a geocoding step.
      // For now, assume lat/lon is passed (common for mobile apps) or default to a central location if city only.
      // NOTE: In a real "best way" scenario, we'd add a Geocoding service here.

      let targetLat = lat;
      let targetLon = lon;

      if (!targetLat && city) {
        // Quick Geocoding Fallback using Open-Meteo Geocoding API
        try {
          const geoRes = await axios.get(`https://geocoding-api.open-meteo.com/v1/search?name=${city}&count=1&language=en&format=json`);
          if (geoRes.data.results && geoRes.data.results.length > 0) {
            targetLat = geoRes.data.results[0].latitude;
            targetLon = geoRes.data.results[0].longitude;
          }
        } catch (geoErr) {
          console.warn('Geocoding failed for city:', city);
        }
      }

      if (!targetLat || !targetLon) {
        throw new Error('Could not resolve location for Open-Meteo');
      }

      const omUrl = 'https://api.open-meteo.com/v1/forecast';
      const omParams = {
        latitude: targetLat,
        longitude: targetLon,
        current: 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m',
        daily: 'sunrise,sunset',
        timezone: 'auto'
      };

      const omResponse = await axios.get(omUrl, { params: omParams });
      const current = omResponse.data.current;
      const daily = omResponse.data.daily;

      // Map Open-Meteo WMO codes to text/icons
      // This is a simplified mapping
      const wmoCodeToText = (code) => {
        if (code === 0) return { main: 'Clear', desc: 'Clear sky', icon: '01d' };
        if (code <= 3) return { main: 'Clouds', desc: 'Partly cloudy', icon: '02d' };
        if (code <= 48) return { main: 'Fog', desc: 'Foggy', icon: '50d' };
        if (code <= 67) return { main: 'Rain', desc: 'Rain', icon: '10d' };
        if (code <= 77) return { main: 'Snow', desc: 'Snow', icon: '13d' };
        if (code <= 82) return { main: 'Rain', desc: 'Showers', icon: '09d' };
        if (code <= 99) return { main: 'Thunderstorm', desc: 'Thunderstorm', icon: '11d' };
        return { main: 'Unknown', desc: 'Unknown', icon: '01d' };
      };

      const weatherInfo = wmoCodeToText(current.weather_code);

      weatherData = {
        success: true,
        source: 'Open-Meteo (Public API)',
        location: {
          name: city || 'Unknown Location',
          country: '',
          lat: targetLat,
          lon: targetLon
        },
        current: {
          temp: current.temperature_2m,
          feels_like: current.apparent_temperature,
          temp_min: current.temperature_2m, // Open-Meteo current doesn't give min/max for *now*, use daily for that if needed
          temp_max: current.temperature_2m,
          pressure: current.pressure_msl,
          humidity: current.relative_humidity_2m,
          weather: weatherInfo.main,
          description: weatherInfo.desc,
          icon: weatherInfo.icon,
          wind_speed: current.wind_speed_10m,
          wind_deg: current.wind_direction_10m,
          clouds: current.cloud_cover,
          visibility: 10000, // Default good visibility
          sunrise: daily.sunrise[0] ? new Date(daily.sunrise[0]).getTime() / 1000 : 0,
          sunset: daily.sunset[0] ? new Date(daily.sunset[0]).getTime() / 1000 : 0
        },
        timestamp: Math.floor(Date.now() / 1000)
      };
    }

    // Store in Redis cache with 10 minutes expiration
    if (weatherData) {
      try {
        await redisClient.setex(cacheKey, 600, JSON.stringify(weatherData));
        console.log('Serving weather data from APIs and caching');
      } catch (redisError) {
        console.warn('Redis set error:', redisError.message);
      }
      return res.json(weatherData);
    }

    throw new Error('No weather data providers available');

  } catch (error) {
    console.error('Error fetching weather data:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch weather data: ' + error.message
    });
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
 * /api/weather/hourly:
 *   get:
 *     summary: Get 24-hour hourly forecast with agricultural suitability
 *     description: Returns hourly weather forecast for the next 24 hours including agricultural suitability ratings for spraying, irrigation, harvesting, and field work
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
 *         description: 24-hour hourly forecast with agricultural suitability
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
 *                     location:
 *                       type: object
 *                     hourly_forecast:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           datetime:
 *                             type: string
 *                           temp:
 *                             type: number
 *                           humidity:
 *                             type: number
 *                           wind_speed:
 *                             type: number
 *                           precipitation_probability:
 *                             type: number
 *                           agricultural_suitability:
 *                             type: object
 *                             properties:
 *                               spraying:
 *                                 type: string
 *                                 enum: [good, moderate, poor]
 *                               irrigation:
 *                                 type: string
 *                                 enum: [good, moderate, poor]
 *                               harvesting:
 *                                 type: string
 *                                 enum: [good, moderate, poor]
 *                               field_work:
 *                                 type: string
 *                                 enum: [good, moderate, poor]
 *       400:
 *         description: Missing required parameters
 */
router.get('/hourly', getHourlyForecast);

/**
 * @swagger
 * /api/weather/alerts:
 *   get:
 *     summary: Get active weather alerts for location
 *     description: Returns active weather alerts including heat wave, heavy rain, frost, storm, and drought warnings
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
 *         description: Active weather alerts
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
 *                     alerts:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           alert_type:
 *                             type: string
 *                             enum: [heat_wave, heavy_rain, frost, storm, drought]
 *                           severity:
 *                             type: string
 *                             enum: [low, moderate, high, severe]
 *                           title:
 *                             type: string
 *                           description:
 *                             type: string
 *                           start_time:
 *                             type: string
 *                           end_time:
 *                             type: string
 *                           recommendations:
 *                             type: array
 *                             items:
 *                               type: string
 *                     alert_count:
 *                       type: integer
 *                     has_severe_alerts:
 *                       type: boolean
 *       400:
 *         description: Missing required parameters
 */
router.get('/alerts', getWeatherAlerts);

/**
 * @swagger
 * /api/weather/seasonal-advisory:
 *   get:
 *     summary: Get seasonal farming advisory
 *     description: Returns crop-specific advisories based on current agricultural season (Kharif, Rabi, Zaid)
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
 *       - in: query
 *         name: crop
 *         schema:
 *           type: string
 *         description: Specific crop for targeted advisory (e.g., rice, wheat, cotton)
 *     responses:
 *       200:
 *         description: Seasonal farming advisory
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
 *                     season:
 *                       type: object
 *                       properties:
 *                         name:
 *                           type: string
 *                         phase:
 *                           type: string
 *                           enum: [early, mid, late]
 *                     advisory:
 *                       type: object
 *                       properties:
 *                         general_advisory:
 *                           type: array
 *                         crop_specific:
 *                           type: object
 *                     recommended_crops:
 *                       type: array
 *                       items:
 *                         type: string
 *       400:
 *         description: Missing required parameters
 */
router.get('/seasonal-advisory', getSeasonalAdvisory);

/**
 * @swagger
 * /api/weather/alerts/subscribe:
 *   post:
 *     summary: Subscribe to weather alerts for a location
 *     description: Subscribe to receive weather alerts for a specific location. Requires authentication.
 *     tags: [Weather]
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
 *                 description: Latitude
 *               lon:
 *                 type: number
 *                 description: Longitude
 *               alert_types:
 *                 type: array
 *                 items:
 *                   type: string
 *                   enum: [heat_wave, heavy_rain, frost, storm, drought]
 *                 description: Types of alerts to subscribe to (defaults to all)
 *     responses:
 *       201:
 *         description: Successfully subscribed to alerts
 *       400:
 *         description: Missing required parameters
 *       401:
 *         description: Authentication required
 */
router.post('/alerts/subscribe', protect, subscribeToAlerts);

/**
 * @swagger
 * /api/weather/alerts/unsubscribe:
 *   delete:
 *     summary: Unsubscribe from weather alerts
 *     description: Unsubscribe from weather alerts for a specific location or all locations. Requires authentication.
 *     tags: [Weather]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               lat:
 *                 type: number
 *                 description: Latitude (optional - if not provided, unsubscribes from all)
 *               lon:
 *                 type: number
 *                 description: Longitude (optional - if not provided, unsubscribes from all)
 *     responses:
 *       200:
 *         description: Successfully unsubscribed from alerts
 *       401:
 *         description: Authentication required
 *       404:
 *         description: No subscription found
 */
router.delete('/alerts/unsubscribe', protect, unsubscribeFromAlerts);

/**
 * @swagger
 * /api/weather/alerts/subscriptions:
 *   get:
 *     summary: Get user's alert subscriptions
 *     description: Returns all weather alert subscriptions for the authenticated user
 *     tags: [Weather]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User's alert subscriptions
 *       401:
 *         description: Authentication required
 */
router.get('/alerts/subscriptions', protect, getMyAlertSubscriptions);

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

  req.query.city = city;
  return router.handle({ ...req, url: '/current', query: req.query }, res);
});

module.exports = router;
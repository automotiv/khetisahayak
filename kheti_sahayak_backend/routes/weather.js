const express = require('express');
const axios = require('axios');
const redisClient = require('../redisClient');

const router = express.Router();
const WEATHER_API_URL = 'http://api.openweathermap.org/data/2.5/weather';

router.get('/:city', async (req, res) => {
  const city = req.params.city;
  const cacheKey = `weather:${city}`;

  try {
    // Try to get data from Redis cache
    const cachedData = await redisClient.get(cacheKey);
    if (cachedData) {
      console.log('Serving from Redis cache');
      return res.json(JSON.parse(cachedData));
    }

    // If not in cache, fetch from OpenWeatherMap API
    const response = await axios.get(WEATHER_API_URL, {
      params: {
        q: city,
        appid: process.env.WEATHER_API_KEY,
        units: 'metric' // or 'imperial'
      }
    });

    const weatherData = response.data;

    // Store data in Redis cache with an expiration time (e.g., 10 minutes)
    await redisClient.setex(cacheKey, 600, JSON.stringify(weatherData));
    console.log('Serving from OpenWeatherMap API and caching');
    res.json(weatherData);
  } catch (error) {
    console.error('Error fetching weather data:', error.message);
    if (error.response) {
      res.status(error.response.status).json({ error: error.response.data.message });
    } else {
      res.status(500).json({ error: 'Failed to fetch weather data' });
    }
  }
});

module.exports = router;
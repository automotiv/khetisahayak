const axios = require('axios');

// @desc    Get weather forecast for a given location
// @route   GET /api/weather
// @access  Public
const getWeather = async (req, res) => {
  const { lat, lon } = req.query;

  if (!lat || !lon) {
    return res.status(400).json({ error: 'Latitude and longitude query parameters are required' });
  }

  try {
    const apiKey = process.env.WEATHER_API_KEY;
    if (!apiKey) {
      console.error('WEATHER_API_KEY is not set in .env file');
      return res.status(500).json({ error: 'Server configuration error: Missing weather API key' });
    }

    // Example using OpenWeatherMap API, as suggested in feature docs
    const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric`;

    const weatherResponse = await axios.get(url);
    res.json(weatherResponse.data);
  } catch (err) {
    // Log the actual error from the weather API if available for better debugging
    if (err.response) {
      console.error('Error fetching weather data:', err.response.data);
      res.status(err.response.status).json({ error: 'Failed to fetch weather data', details: err.response.data });
    } else {
      console.error('Error fetching weather data:', err.message);
      res.status(500).json({ error: 'Failed to fetch weather data' });
    }
  }
};

module.exports = {
  getWeather,
};
const axios = require('axios');
const {
  getActivityRecommendations,
  getDailyTips,
  getOptimalTimeWindows,
} = require('../services/weatherRecommendationService');

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

// @desc    Get activity recommendations based on weather
// @route   GET /api/weather/recommendations
// @access  Public
const getRecommendations = async (req, res) => {
  const { lat, lon } = req.query;

  if (!lat || !lon) {
    return res.status(400).json({ error: 'Latitude and longitude query parameters are required' });
  }

  try {
    const apiKey = process.env.WEATHER_API_KEY;

    // Fetch current weather
    let weatherData;
    if (apiKey) {
      const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric`;
      const weatherResponse = await axios.get(url);
      weatherData = {
        temperature: weatherResponse.data.main.temp,
        humidity: weatherResponse.data.main.humidity,
        wind_speed: weatherResponse.data.wind.speed * 3.6, // Convert m/s to km/h
        rain_chance: weatherResponse.data.clouds?.all || 0,
        rain_amount: weatherResponse.data.rain?.['1h'] || 0,
        weather_condition: weatherResponse.data.weather[0]?.main || 'Clear',
      };
    } else {
      // Mock data for development
      weatherData = {
        temperature: 28,
        humidity: 65,
        wind_speed: 12,
        rain_chance: 30,
        rain_amount: 0,
        weather_condition: 'Partly Cloudy',
      };
    }

    // Get activity recommendations
    const activityRecommendations = getActivityRecommendations(weatherData);

    // Get daily tips
    const dailyTips = getDailyTips([weatherData]);

    res.json({
      success: true,
      data: {
        current_weather: weatherData,
        activity_recommendations: activityRecommendations,
        daily_tips: dailyTips,
        generated_at: new Date().toISOString(),
      },
    });
  } catch (err) {
    console.error('Error getting weather recommendations:', err.message);

    // Fallback to mock recommendations
    const mockWeather = {
      temperature: 28,
      humidity: 65,
      wind_speed: 12,
      rain_chance: 30,
      rain_amount: 0,
    };

    res.json({
      success: true,
      data: {
        current_weather: mockWeather,
        activity_recommendations: getActivityRecommendations(mockWeather),
        daily_tips: getDailyTips([mockWeather]),
        generated_at: new Date().toISOString(),
        is_mock: true,
      },
    });
  }
};

// @desc    Get 5-day forecast with recommendations
// @route   GET /api/weather/forecast
// @access  Public
const getForecast = async (req, res) => {
  const { lat, lon } = req.query;

  if (!lat || !lon) {
    return res.status(400).json({ error: 'Latitude and longitude query parameters are required' });
  }

  try {
    const apiKey = process.env.WEATHER_API_KEY;

    if (apiKey) {
      const url = `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric`;
      const forecastResponse = await axios.get(url);

      // Process forecast data
      const forecasts = forecastResponse.data.list.map((item) => ({
        datetime: item.dt_txt,
        temperature: item.main.temp,
        humidity: item.main.humidity,
        wind_speed: item.wind.speed * 3.6,
        rain_chance: item.clouds?.all || 0,
        rain_amount: item.rain?.['3h'] || 0,
        weather_condition: item.weather[0]?.main || 'Clear',
        weather_description: item.weather[0]?.description || '',
        icon: item.weather[0]?.icon,
      }));

      // Get daily aggregated forecasts
      const dailyForecasts = aggregateDailyForecasts(forecasts);

      res.json({
        success: true,
        data: {
          city: forecastResponse.data.city.name,
          forecasts: dailyForecasts,
          hourly: forecasts.slice(0, 24), // Next 24 hours
        },
      });
    } else {
      // Mock forecast data
      res.json({
        success: true,
        data: getMockForecast(),
        is_mock: true,
      });
    }
  } catch (err) {
    console.error('Error fetching forecast:', err.message);
    res.json({
      success: true,
      data: getMockForecast(),
      is_mock: true,
    });
  }
};

// Helper to aggregate hourly forecasts into daily
function aggregateDailyForecasts(hourlyData) {
  const dailyMap = {};

  hourlyData.forEach((hour) => {
    const date = hour.datetime.split(' ')[0];
    if (!dailyMap[date]) {
      dailyMap[date] = {
        date,
        temps: [],
        humidity: [],
        conditions: [],
        rain: [],
      };
    }
    dailyMap[date].temps.push(hour.temperature);
    dailyMap[date].humidity.push(hour.humidity);
    dailyMap[date].conditions.push(hour.weather_condition);
    dailyMap[date].rain.push(hour.rain_amount);
  });

  return Object.values(dailyMap).map((day) => ({
    date: day.date,
    temp_min: Math.min(...day.temps),
    temp_max: Math.max(...day.temps),
    humidity_avg: Math.round(day.humidity.reduce((a, b) => a + b, 0) / day.humidity.length),
    condition: getMostCommon(day.conditions),
    rain_total: day.rain.reduce((a, b) => a + b, 0).toFixed(1),
    activity_recommendations: getActivityRecommendations({
      temperature: (Math.min(...day.temps) + Math.max(...day.temps)) / 2,
      humidity: Math.round(day.humidity.reduce((a, b) => a + b, 0) / day.humidity.length),
      wind_speed: 10,
      rain_amount: day.rain.reduce((a, b) => a + b, 0),
      rain_chance: day.rain.reduce((a, b) => a + b, 0) > 0 ? 60 : 20,
    }).slice(0, 4), // Top 4 recommendations
  }));
}

function getMostCommon(arr) {
  const counts = {};
  arr.forEach((item) => {
    counts[item] = (counts[item] || 0) + 1;
  });
  return Object.entries(counts).sort((a, b) => b[1] - a[1])[0][0];
}

function getMockForecast() {
  const today = new Date();
  const forecasts = [];

  for (let i = 0; i < 5; i++) {
    const date = new Date(today);
    date.setDate(date.getDate() + i);

    forecasts.push({
      date: date.toISOString().split('T')[0],
      temp_min: 20 + Math.random() * 5,
      temp_max: 30 + Math.random() * 5,
      humidity_avg: 50 + Math.random() * 30,
      condition: ['Clear', 'Partly Cloudy', 'Cloudy', 'Rain'][Math.floor(Math.random() * 4)],
      rain_total: (Math.random() * 10).toFixed(1),
      activity_recommendations: getActivityRecommendations({
        temperature: 25,
        humidity: 60,
        wind_speed: 10,
        rain_amount: Math.random() * 5,
        rain_chance: Math.random() * 50,
      }).slice(0, 4),
    });
  }

  return { city: 'Your Location', forecasts };
}

module.exports = {
  getWeather,
  getRecommendations,
  getForecast,
};
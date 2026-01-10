const axios = require('axios');
const {
  getActivityRecommendations,
  getDailyTips,
  getOptimalTimeWindows,
} = require('../services/weatherRecommendationService');
const {
  checkForAlerts,
  getSeasonInfo,
  generateAgricultureAdvisory,
  evaluateHourlySuitability,
  subscribeToAlerts: subscribeToAlertsService,
  unsubscribeFromAlerts: unsubscribeFromAlertsService,
  getUserSubscriptions,
} = require('../services/weatherAlertService');
const redisClient = require('../redisClient');

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

const CACHE_TTL_30_MINUTES = 1800;
const CACHE_TTL_15_MINUTES = 900;

const getHourlyForecast = async (req, res) => {
  const { lat, lon } = req.query;

  if (!lat || !lon) {
    return res.status(400).json({ error: 'Latitude and longitude query parameters are required' });
  }

  try {
    const cacheKey = `hourly:${lat},${lon}`;

    try {
      const cachedData = await redisClient.get(cacheKey);
      if (cachedData) {
        return res.json(JSON.parse(cachedData));
      }
    } catch (redisError) {
      console.warn('Redis error:', redisError.message);
    }

    const apiKey = process.env.WEATHER_API_KEY;

    if (apiKey) {
      const url = `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric&cnt=24`;
      const response = await axios.get(url);

      const hourlyData = response.data.list.map((item) => {
        const hourData = {
          datetime: item.dt_txt,
          timestamp: item.dt,
          temp: item.main.temp,
          feels_like: item.main.feels_like,
          humidity: item.main.humidity,
          wind_speed: item.wind.speed * 3.6, // m/s to km/h
          wind_direction: item.wind.deg,
          precipitation_probability: (item.pop || 0) * 100,
          rain_amount: item.rain?.['3h'] || 0,
          weather_condition: item.weather[0]?.main || 'Clear',
          weather_description: item.weather[0]?.description || '',
          icon: item.weather[0]?.icon,
        };

        hourData.agricultural_suitability = evaluateHourlySuitability({
          temp: hourData.temp,
          humidity: hourData.humidity,
          wind_speed: hourData.wind_speed,
          rain_probability: hourData.precipitation_probability,
        });

        return hourData;
      });

      const responseData = {
        success: true,
        data: {
          location: {
            name: response.data.city.name,
            country: response.data.city.country,
            lat: response.data.city.coord.lat,
            lon: response.data.city.coord.lon,
          },
          hourly_forecast: hourlyData,
          generated_at: new Date().toISOString(),
        },
      };

      try {
        await redisClient.setex(cacheKey, CACHE_TTL_30_MINUTES, JSON.stringify(responseData));
      } catch (redisError) {
        console.warn('Redis cache set error:', redisError.message);
      }

      return res.json(responseData);
    }

    const mockHourly = generateMockHourlyForecast();
    res.json({
      success: true,
      data: {
        location: { name: 'Mock Location', country: 'IN', lat: parseFloat(lat), lon: parseFloat(lon) },
        hourly_forecast: mockHourly,
        generated_at: new Date().toISOString(),
      },
      is_mock: true,
    });
  } catch (err) {
    console.error('Error fetching hourly forecast:', err.message);
    const mockHourly = generateMockHourlyForecast();
    res.json({
      success: true,
      data: {
        location: { name: 'Mock Location', country: 'IN', lat: parseFloat(lat), lon: parseFloat(lon) },
        hourly_forecast: mockHourly,
        generated_at: new Date().toISOString(),
      },
      is_mock: true,
    });
  }
};

function generateMockHourlyForecast() {
  const hourly = [];
  const now = new Date();

  for (let i = 0; i < 24; i++) {
    const time = new Date(now.getTime() + i * 60 * 60 * 1000);
    const hour = time.getHours();
    const isDay = hour >= 6 && hour <= 18;

    const temp = isDay ? 25 + Math.random() * 10 : 18 + Math.random() * 5;
    const humidity = 50 + Math.random() * 30;
    const wind_speed = 5 + Math.random() * 15;
    const rain_probability = Math.random() * 40;

    hourly.push({
      datetime: time.toISOString().replace('T', ' ').slice(0, 19),
      timestamp: Math.floor(time.getTime() / 1000),
      temp: parseFloat(temp.toFixed(1)),
      feels_like: parseFloat((temp - 2 + Math.random() * 4).toFixed(1)),
      humidity: Math.round(humidity),
      wind_speed: parseFloat(wind_speed.toFixed(1)),
      wind_direction: Math.floor(Math.random() * 360),
      precipitation_probability: Math.round(rain_probability),
      rain_amount: rain_probability > 50 ? parseFloat((Math.random() * 5).toFixed(1)) : 0,
      weather_condition: rain_probability > 60 ? 'Rain' : isDay ? 'Clear' : 'Clouds',
      weather_description: rain_probability > 60 ? 'light rain' : isDay ? 'clear sky' : 'few clouds',
      icon: rain_probability > 60 ? '10d' : isDay ? '01d' : '02n',
      agricultural_suitability: evaluateHourlySuitability({
        temp,
        humidity,
        wind_speed,
        rain_probability,
      }),
    });
  }

  return hourly;
}

const getWeatherAlerts = async (req, res) => {
  const { lat, lon } = req.query;

  if (!lat || !lon) {
    return res.status(400).json({ error: 'Latitude and longitude query parameters are required' });
  }

  try {
    const cacheKey = `alerts:${lat},${lon}`;

    try {
      const cachedData = await redisClient.get(cacheKey);
      if (cachedData) {
        return res.json(JSON.parse(cachedData));
      }
    } catch (redisError) {
      console.warn('Redis error:', redisError.message);
    }

    const alerts = await checkForAlerts(parseFloat(lat), parseFloat(lon));

    const responseData = {
      success: true,
      data: {
        location: { lat: parseFloat(lat), lon: parseFloat(lon) },
        alerts,
        alert_count: alerts.length,
        has_severe_alerts: alerts.some((a) => a.severity === 'severe' || a.severity === 'high'),
        checked_at: new Date().toISOString(),
      },
    };

    try {
      await redisClient.setex(cacheKey, CACHE_TTL_15_MINUTES, JSON.stringify(responseData));
    } catch (redisError) {
      console.warn('Redis cache set error:', redisError.message);
    }

    res.json(responseData);
  } catch (err) {
    console.error('Error fetching weather alerts:', err.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch weather alerts',
    });
  }
};

const getSeasonalAdvisory = async (req, res) => {
  const { lat, lon, crop } = req.query;

  if (!lat || !lon) {
    return res.status(400).json({ error: 'Latitude and longitude query parameters are required' });
  }

  try {
    const cacheKey = `seasonal:${lat},${lon}:${crop || 'general'}`;

    try {
      const cachedData = await redisClient.get(cacheKey);
      if (cachedData) {
        return res.json(JSON.parse(cachedData));
      }
    } catch (redisError) {
      console.warn('Redis error:', redisError.message);
    }

    const apiKey = process.env.WEATHER_API_KEY;
    let weatherData = { temp: 28, humidity: 65, wind_speed: 12, rain_chance: 30 };

    if (apiKey) {
      try {
        const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric`;
        const response = await axios.get(url);
        weatherData = {
          temp: response.data.main.temp,
          humidity: response.data.main.humidity,
          wind_speed: response.data.wind.speed * 3.6,
          rain_chance: response.data.clouds?.all || 0,
        };
      } catch (apiError) {
        console.warn('Weather API error, using defaults:', apiError.message);
      }
    }

    const seasonInfo = getSeasonInfo();
    const advisory = generateAgricultureAdvisory(weatherData, crop);

    const responseData = {
      success: true,
      data: {
        location: { lat: parseFloat(lat), lon: parseFloat(lon) },
        current_weather: weatherData,
        season: seasonInfo,
        advisory: advisory,
        recommended_crops: seasonInfo.crops,
        generated_at: new Date().toISOString(),
      },
    };

    try {
      await redisClient.setex(cacheKey, CACHE_TTL_30_MINUTES, JSON.stringify(responseData));
    } catch (redisError) {
      console.warn('Redis cache set error:', redisError.message);
    }

    res.json(responseData);
  } catch (err) {
    console.error('Error getting seasonal advisory:', err.message);
    res.status(500).json({
      success: false,
      error: 'Failed to get seasonal advisory',
    });
  }
};

const subscribeToAlerts = async (req, res) => {
  const { lat, lon, alert_types } = req.body;

  if (!lat || !lon) {
    return res.status(400).json({ error: 'Latitude and longitude are required in request body' });
  }

  if (!req.user || !req.user.id) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  try {
    const subscription = subscribeToAlertsService(
      req.user.id,
      parseFloat(lat),
      parseFloat(lon),
      alert_types
    );

    res.status(201).json({
      success: true,
      message: 'Successfully subscribed to weather alerts',
      data: subscription,
    });
  } catch (err) {
    console.error('Error subscribing to alerts:', err.message);
    res.status(500).json({
      success: false,
      error: 'Failed to subscribe to alerts',
    });
  }
};

const unsubscribeFromAlerts = async (req, res) => {
  const { lat, lon } = req.body;

  if (!req.user || !req.user.id) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  try {
    const success = unsubscribeFromAlertsService(
      req.user.id,
      lat ? parseFloat(lat) : null,
      lon ? parseFloat(lon) : null
    );

    if (success) {
      res.json({
        success: true,
        message: 'Successfully unsubscribed from weather alerts',
      });
    } else {
      res.status(404).json({
        success: false,
        error: 'No subscription found for the given location',
      });
    }
  } catch (err) {
    console.error('Error unsubscribing from alerts:', err.message);
    res.status(500).json({
      success: false,
      error: 'Failed to unsubscribe from alerts',
    });
  }
};

const getMyAlertSubscriptions = async (req, res) => {
  if (!req.user || !req.user.id) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  try {
    const subscriptions = getUserSubscriptions(req.user.id);

    res.json({
      success: true,
      data: {
        subscriptions,
        count: subscriptions.length,
      },
    });
  } catch (err) {
    console.error('Error fetching subscriptions:', err.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch subscriptions',
    });
  }
};

module.exports = {
  getWeather,
  getRecommendations,
  getForecast,
  getHourlyForecast,
  getWeatherAlerts,
  getSeasonalAdvisory,
  subscribeToAlerts,
  unsubscribeFromAlerts,
  getMyAlertSubscriptions,
};
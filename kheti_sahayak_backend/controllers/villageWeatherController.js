const axios = require('axios');
const db = require('../db');
const redisClient = require('../redisClient');
const geocodingService = require('../services/geocodingService');
const seasonalCalendarService = require('../services/seasonalCropCalendarService');
const { generateAgricultureAdvisory, getSeasonInfo } = require('../services/weatherAlertService');

const CACHE_TTL = {
  VILLAGE_WEATHER: 15 * 60,
  VILLAGE_FORECAST: 30 * 60,
  VILLAGE_SEARCH: 24 * 60 * 60
};

const searchVillages = async (req, res) => {
  const { q, state, district, limit = 10 } = req.query;

  if (!q || q.trim().length < 2) {
    return res.status(400).json({
      success: false,
      error: 'Search query must be at least 2 characters'
    });
  }

  try {
    const results = await geocodingService.searchVillage(q, {
      state,
      district,
      limit: Math.min(parseInt(limit), 20)
    });

    res.json({
      success: true,
      query: q,
      count: results.length,
      results: results.map(r => ({
        id: r.id,
        name: r.name,
        display_name: r.display_name,
        latitude: r.latitude,
        longitude: r.longitude,
        village: r.address?.village,
        district: r.address?.district,
        state: r.address?.state,
        state_code: r.address?.state_code,
        type: r.type
      }))
    });
  } catch (error) {
    console.error('Village search error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to search villages'
    });
  }
};

const getVillageWeather = async (req, res) => {
  const { lat, lon, village } = req.query;

  if (!lat || !lon) {
    if (!village) {
      return res.status(400).json({
        success: false,
        error: 'Either coordinates (lat, lon) or village name is required'
      });
    }

    try {
      const geocoded = await geocodingService.geocode(village);
      req.query.lat = geocoded.latitude;
      req.query.lon = geocoded.longitude;
      req.query._geocoded = geocoded;
    } catch (geoError) {
      return res.status(400).json({
        success: false,
        error: `Could not find village: ${village}`
      });
    }
  }

  const latitude = parseFloat(req.query.lat);
  const longitude = parseFloat(req.query.lon);

  const validation = geocodingService.validateCoordinates(latitude, longitude);
  if (!validation.valid) {
    return res.status(400).json({
      success: false,
      error: validation.error
    });
  }

  try {
    const cacheKey = `village-weather:${latitude.toFixed(4)},${longitude.toFixed(4)}`;

    try {
      const cachedData = await redisClient.get(cacheKey);
      if (cachedData) {
        const parsed = JSON.parse(cachedData);
        parsed.cache = { hit: true };
        return res.json(parsed);
      }
    } catch (redisError) {
      console.warn('Redis error:', redisError.message);
    }

    let locationInfo = req.query._geocoded;
    if (!locationInfo) {
      locationInfo = await geocodingService.reverseGeocode(latitude, longitude);
    }

    const weatherData = await fetchWeatherForLocation(latitude, longitude);
    const seasonInfo = getSeasonInfo();
    const stateCode = locationInfo.address?.state_code || locationInfo.state_code;
    const cropCalendar = seasonalCalendarService.getSeasonalCropCalendar(
      latitude, longitude, stateCode
    );

    const advisory = generateAgricultureAdvisory({
      temp: weatherData.current.temp,
      humidity: weatherData.current.humidity,
      wind_speed: weatherData.current.wind_speed,
      rain_chance: weatherData.current.precipitation_probability || 0
    });

    const response = {
      success: true,
      location: {
        latitude,
        longitude,
        village: locationInfo.name || locationInfo.address?.village,
        district: locationInfo.address?.district,
        state: locationInfo.address?.state,
        state_code: stateCode,
        display_name: locationInfo.display_name,
        is_within_india: geocodingService.isWithinIndia(latitude, longitude),
        agro_climatic_zone: locationInfo.agro_climatic_zone || cropCalendar.location?.agro_climatic_zone
      },
      weather: weatherData,
      season: seasonInfo,
      crop_calendar: {
        current_season: cropCalendar.season,
        crops: cropCalendar.crops.slice(0, 5),
        upcoming_tasks: cropCalendar.upcoming_tasks,
        summary: cropCalendar.summary
      },
      advisory: advisory,
      generated_at: new Date().toISOString()
    };

    try {
      await redisClient.setex(cacheKey, CACHE_TTL.VILLAGE_WEATHER, JSON.stringify(response));
    } catch (redisError) {
      console.warn('Redis cache error:', redisError.message);
    }

    res.json(response);
  } catch (error) {
    console.error('Village weather error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch village weather data'
    });
  }
};

const getVillageForecast = async (req, res) => {
  const { lat, lon, days = 7 } = req.query;

  if (!lat || !lon) {
    return res.status(400).json({
      success: false,
      error: 'Latitude and longitude are required'
    });
  }

  const latitude = parseFloat(lat);
  const longitude = parseFloat(lon);

  const validation = geocodingService.validateCoordinates(latitude, longitude);
  if (!validation.valid) {
    return res.status(400).json({
      success: false,
      error: validation.error
    });
  }

  try {
    const cacheKey = `village-forecast:${latitude.toFixed(4)},${longitude.toFixed(4)}:${days}`;

    try {
      const cachedData = await redisClient.get(cacheKey);
      if (cachedData) {
        const parsed = JSON.parse(cachedData);
        parsed.cache = { hit: true };
        return res.json(parsed);
      }
    } catch (redisError) {
      console.warn('Redis error:', redisError.message);
    }

    const locationInfo = await geocodingService.reverseGeocode(latitude, longitude);

    const forecastData = await fetchForecastForLocation(latitude, longitude, Math.min(parseInt(days), 14));
    const stateCode = locationInfo.address?.state_code;
    const cropCalendar = seasonalCalendarService.getSeasonalCropCalendar(
      latitude, longitude, stateCode
    );

    const dailyForecasts = forecastData.daily.map(day => {
      const suitability = evaluateDaySuitability(day);
      return {
        ...day,
        agricultural_suitability: suitability
      };
    });

    const response = {
      success: true,
      location: {
        latitude,
        longitude,
        village: locationInfo.name || locationInfo.address?.village,
        district: locationInfo.address?.district,
        state: locationInfo.address?.state,
        state_code: stateCode,
        display_name: locationInfo.display_name
      },
      forecast: {
        daily: dailyForecasts,
        source: forecastData.source
      },
      crop_calendar: {
        current_season: cropCalendar.season,
        upcoming_tasks: cropCalendar.upcoming_tasks
      },
      farming_recommendations: generateFarmingRecommendations(dailyForecasts, cropCalendar),
      generated_at: new Date().toISOString()
    };

    try {
      await redisClient.setex(cacheKey, CACHE_TTL.VILLAGE_FORECAST, JSON.stringify(response));
    } catch (redisError) {
      console.warn('Redis cache error:', redisError.message);
    }

    res.json(response);
  } catch (error) {
    console.error('Village forecast error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch village forecast data'
    });
  }
};

const saveVillagePreference = async (req, res) => {
  const { lat, lon, village_name, district, state, is_primary } = req.body;

  if (!lat || !lon) {
    return res.status(400).json({
      success: false,
      error: 'Latitude and longitude are required'
    });
  }

  const userId = req.user?.id;
  if (!userId) {
    return res.status(401).json({
      success: false,
      error: 'Authentication required'
    });
  }

  const latitude = parseFloat(lat);
  const longitude = parseFloat(lon);

  try {
    if (is_primary) {
      await db.query(
        'UPDATE user_village_preferences SET is_primary = false WHERE user_id = $1',
        [userId]
      );
    }

    let locationInfo;
    try {
      locationInfo = await geocodingService.reverseGeocode(latitude, longitude);
    } catch (geoError) {
      locationInfo = { address: {} };
    }

    const stateCode = locationInfo.address?.state_code || 
      geocodingService.getStateInfo(state)?.code;
    const agroZone = geocodingService.getAgroClimaticZone(latitude, longitude, stateCode);

    const result = await db.query(`
      INSERT INTO user_village_preferences 
      (user_id, village_name, district, state, state_code, latitude, longitude, 
       display_name, is_primary, agro_climatic_zone, source)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      ON CONFLICT (user_id, latitude, longitude)
      DO UPDATE SET
        village_name = COALESCE(EXCLUDED.village_name, user_village_preferences.village_name),
        district = COALESCE(EXCLUDED.district, user_village_preferences.district),
        state = COALESCE(EXCLUDED.state, user_village_preferences.state),
        state_code = COALESCE(EXCLUDED.state_code, user_village_preferences.state_code),
        display_name = COALESCE(EXCLUDED.display_name, user_village_preferences.display_name),
        is_primary = EXCLUDED.is_primary,
        agro_climatic_zone = COALESCE(EXCLUDED.agro_climatic_zone, user_village_preferences.agro_climatic_zone),
        updated_at = CURRENT_TIMESTAMP
      RETURNING *
    `, [
      userId,
      village_name || locationInfo.name || locationInfo.address?.village,
      district || locationInfo.address?.district,
      state || locationInfo.address?.state,
      stateCode,
      latitude,
      longitude,
      locationInfo.display_name,
      is_primary || false,
      agroZone?.name,
      'nominatim'
    ]);

    res.status(201).json({
      success: true,
      message: 'Village preference saved',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Save village preference error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to save village preference'
    });
  }
};

const getMyVillages = async (req, res) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(401).json({
      success: false,
      error: 'Authentication required'
    });
  }

  try {
    const result = await db.query(
      `SELECT * FROM user_village_preferences 
       WHERE user_id = $1 
       ORDER BY is_primary DESC, created_at DESC`,
      [userId]
    );

    res.json({
      success: true,
      count: result.rows.length,
      villages: result.rows
    });
  } catch (error) {
    console.error('Get villages error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch saved villages'
    });
  }
};

const deleteVillagePreference = async (req, res) => {
  const { id } = req.params;
  const userId = req.user?.id;

  if (!userId) {
    return res.status(401).json({
      success: false,
      error: 'Authentication required'
    });
  }

  try {
    const result = await db.query(
      'DELETE FROM user_village_preferences WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Village preference not found'
      });
    }

    res.json({
      success: true,
      message: 'Village preference deleted'
    });
  } catch (error) {
    console.error('Delete village error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to delete village preference'
    });
  }
};

const getCropCalendar = async (req, res) => {
  const { lat, lon, state } = req.query;

  if (!lat || !lon) {
    return res.status(400).json({
      success: false,
      error: 'Latitude and longitude are required'
    });
  }

  const latitude = parseFloat(lat);
  const longitude = parseFloat(lon);

  try {
    let stateCode = state;
    if (!stateCode) {
      const locationInfo = await geocodingService.reverseGeocode(latitude, longitude);
      stateCode = locationInfo.address?.state_code;
    } else {
      const stateInfo = geocodingService.getStateInfo(state);
      stateCode = stateInfo?.code || state;
    }

    const calendar = seasonalCalendarService.getSeasonalCropCalendar(
      latitude, longitude, stateCode
    );

    res.json({
      success: true,
      ...calendar
    });
  } catch (error) {
    console.error('Crop calendar error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch crop calendar'
    });
  }
};

async function fetchWeatherForLocation(lat, lon) {
  const apiKey = process.env.WEATHER_API_KEY;

  if (apiKey) {
    try {
      const response = await axios.get('https://api.openweathermap.org/data/2.5/weather', {
        params: { lat, lon, appid: apiKey, units: 'metric' },
        timeout: 10000
      });

      return {
        current: {
          temp: response.data.main.temp,
          feels_like: response.data.main.feels_like,
          temp_min: response.data.main.temp_min,
          temp_max: response.data.main.temp_max,
          humidity: response.data.main.humidity,
          pressure: response.data.main.pressure,
          wind_speed: response.data.wind.speed * 3.6,
          wind_direction: response.data.wind.deg,
          clouds: response.data.clouds.all,
          weather: response.data.weather[0].main,
          description: response.data.weather[0].description,
          icon: response.data.weather[0].icon,
          visibility: response.data.visibility,
          precipitation: response.data.rain?.['1h'] || 0
        },
        source: 'OpenWeatherMap',
        timestamp: response.data.dt
      };
    } catch (error) {
      console.warn('OpenWeatherMap error, falling back to Open-Meteo:', error.message);
    }
  }

  const response = await axios.get('https://api.open-meteo.com/v1/forecast', {
    params: {
      latitude: lat,
      longitude: lon,
      current: 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,cloud_cover,wind_speed_10m,wind_direction_10m',
      timezone: 'auto'
    },
    timeout: 10000
  });

  const current = response.data.current;
  const weatherInfo = wmoCodeToWeather(current.weather_code);

  return {
    current: {
      temp: current.temperature_2m,
      feels_like: current.apparent_temperature,
      humidity: current.relative_humidity_2m,
      wind_speed: current.wind_speed_10m,
      wind_direction: current.wind_direction_10m,
      clouds: current.cloud_cover,
      weather: weatherInfo.main,
      description: weatherInfo.description,
      icon: weatherInfo.icon,
      precipitation: current.precipitation
    },
    source: 'Open-Meteo',
    timestamp: Math.floor(Date.now() / 1000)
  };
}

async function fetchForecastForLocation(lat, lon, days) {
  const response = await axios.get('https://api.open-meteo.com/v1/forecast', {
    params: {
      latitude: lat,
      longitude: lon,
      daily: 'temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,wind_speed_10m_max,weather_code,sunrise,sunset',
      timezone: 'auto',
      forecast_days: days
    },
    timeout: 10000
  });

  const daily = response.data.daily;

  return {
    daily: daily.time.map((date, i) => ({
      date,
      temp_max: daily.temperature_2m_max[i],
      temp_min: daily.temperature_2m_min[i],
      precipitation: daily.precipitation_sum[i],
      precipitation_probability: daily.precipitation_probability_max[i],
      wind_speed_max: daily.wind_speed_10m_max[i],
      weather_code: daily.weather_code[i],
      weather: wmoCodeToWeather(daily.weather_code[i]),
      sunrise: daily.sunrise[i],
      sunset: daily.sunset[i]
    })),
    source: 'Open-Meteo'
  };
}

function wmoCodeToWeather(code) {
  const codes = {
    0: { main: 'Clear', description: 'Clear sky', icon: '01d' },
    1: { main: 'Clear', description: 'Mainly clear', icon: '01d' },
    2: { main: 'Clouds', description: 'Partly cloudy', icon: '02d' },
    3: { main: 'Clouds', description: 'Overcast', icon: '03d' },
    45: { main: 'Fog', description: 'Fog', icon: '50d' },
    48: { main: 'Fog', description: 'Depositing rime fog', icon: '50d' },
    51: { main: 'Drizzle', description: 'Light drizzle', icon: '09d' },
    53: { main: 'Drizzle', description: 'Moderate drizzle', icon: '09d' },
    55: { main: 'Drizzle', description: 'Dense drizzle', icon: '09d' },
    61: { main: 'Rain', description: 'Slight rain', icon: '10d' },
    63: { main: 'Rain', description: 'Moderate rain', icon: '10d' },
    65: { main: 'Rain', description: 'Heavy rain', icon: '10d' },
    71: { main: 'Snow', description: 'Slight snow', icon: '13d' },
    73: { main: 'Snow', description: 'Moderate snow', icon: '13d' },
    75: { main: 'Snow', description: 'Heavy snow', icon: '13d' },
    80: { main: 'Rain', description: 'Slight showers', icon: '09d' },
    81: { main: 'Rain', description: 'Moderate showers', icon: '09d' },
    82: { main: 'Rain', description: 'Violent showers', icon: '09d' },
    95: { main: 'Thunderstorm', description: 'Thunderstorm', icon: '11d' },
    96: { main: 'Thunderstorm', description: 'Thunderstorm with hail', icon: '11d' },
    99: { main: 'Thunderstorm', description: 'Thunderstorm with heavy hail', icon: '11d' }
  };
  return codes[code] || { main: 'Unknown', description: 'Unknown', icon: '01d' };
}

function evaluateDaySuitability(dayForecast) {
  const { temp_max, temp_min, precipitation_probability, wind_speed_max, precipitation } = dayForecast;
  const avgTemp = (temp_max + temp_min) / 2;

  const suitability = {
    spraying: 'good',
    irrigation: 'good',
    harvesting: 'good',
    field_work: 'good',
    sowing: 'good'
  };

  if (precipitation_probability > 60 || precipitation > 5) {
    suitability.spraying = 'poor';
    suitability.harvesting = 'poor';
    suitability.irrigation = 'poor';
  } else if (precipitation_probability > 30) {
    suitability.spraying = 'moderate';
    suitability.harvesting = 'moderate';
  }

  if (wind_speed_max > 25) {
    suitability.spraying = 'poor';
    suitability.field_work = 'moderate';
  } else if (wind_speed_max > 15) {
    suitability.spraying = 'moderate';
  }

  if (avgTemp > 38 || avgTemp < 10) {
    suitability.field_work = 'poor';
    suitability.sowing = 'poor';
  } else if (avgTemp > 35 || avgTemp < 15) {
    suitability.field_work = 'moderate';
  }

  return suitability;
}

function generateFarmingRecommendations(forecasts, cropCalendar) {
  const recommendations = [];
  const next3Days = forecasts.slice(0, 3);

  const rainDays = next3Days.filter(d => d.precipitation_probability > 50);
  const hotDays = next3Days.filter(d => d.temp_max > 38);
  const goodSprayDays = next3Days.filter(d => 
    d.agricultural_suitability.spraying === 'good'
  );

  if (rainDays.length > 0) {
    recommendations.push({
      type: 'rain_alert',
      priority: 'high',
      message: `Rain expected on ${rainDays.length} of next 3 days. Complete harvesting and outdoor work beforehand.`,
      message_hi: `अगले 3 दिनों में ${rainDays.length} दिन बारिश की संभावना। पहले कटाई और बाहरी काम पूरा करें।`
    });
  }

  if (hotDays.length > 0) {
    recommendations.push({
      type: 'heat_alert',
      priority: 'high',
      message: 'High temperatures expected. Irrigate early morning or evening. Avoid field work during peak heat.',
      message_hi: 'उच्च तापमान की संभावना। सुबह जल्दी या शाम को सिंचाई करें। चरम गर्मी में खेत का काम टालें।'
    });
  }

  if (goodSprayDays.length > 0) {
    recommendations.push({
      type: 'spraying_window',
      priority: 'medium',
      message: `Good conditions for spraying on: ${goodSprayDays.map(d => d.date).join(', ')}`,
      message_hi: `छिड़काव के लिए अच्छी स्थिति: ${goodSprayDays.map(d => d.date).join(', ')}`
    });
  }

  if (cropCalendar.upcoming_tasks) {
    recommendations.push(...cropCalendar.upcoming_tasks.map(task => ({
      type: task.type,
      priority: task.priority,
      message: task.message,
      message_hi: task.message_hi
    })));
  }

  return recommendations;
}

module.exports = {
  searchVillages,
  getVillageWeather,
  getVillageForecast,
  saveVillagePreference,
  getMyVillages,
  deleteVillagePreference,
  getCropCalendar
};

/**
 * Weather Service - Real API Integration
 * 
 * Provides weather data with fallback chain:
 * 1. IMD (India Meteorological Department) - Primary for India
 * 2. OpenWeatherMap - Global fallback
 * 3. Cached data - If APIs fail
 * 4. Mock data - Development fallback
 * 
 * Features:
 * - Hyperlocal forecasts using lat/lon
 * - Agricultural weather advisories
 * - Village-level forecasts
 * - Redis caching with 1-hour TTL
 */

const axios = require('axios');
const redisClient = require('../redisClient');

// Cache TTL constants (in seconds)
const CACHE_TTL = {
  CURRENT_WEATHER: 3600,      // 1 hour
  FORECAST: 3600,              // 1 hour
  VILLAGE_FORECAST: 3600,      // 1 hour
  AGRICULTURAL_ADVISORY: 1800, // 30 minutes
  ALERTS: 900,                 // 15 minutes
};

// API URLs
const OPENWEATHER_API = {
  CURRENT: 'https://api.openweathermap.org/data/2.5/weather',
  FORECAST: 'https://api.openweathermap.org/data/2.5/forecast',
  ONECALL: 'https://api.openweathermap.org/data/3.0/onecall',
  GEOCODING: 'https://api.openweathermap.org/geo/1.0/direct',
  REVERSE_GEOCODING: 'https://api.openweathermap.org/geo/1.0/reverse',
};

// IMD API URLs (Note: IMD doesn't have a public API, using data.gov.in portal)
const IMD_API = {
  DISTRICTS: 'https://api.data.gov.in/resource/3b01bcb8-0b14-4abf-b6f2-c1bfd384ba69',
  FORECAST: 'https://api.data.gov.in/resource/0e75e9f6-2f6b-4731-a7e2-3b70e67e6b1b',
};

// Open-Meteo API (Free, no key required - good fallback)
const OPEN_METEO_API = {
  FORECAST: 'https://api.open-meteo.com/v1/forecast',
  GEOCODING: 'https://geocoding-api.open-meteo.com/v1/search',
};

/**
 * Weather condition mappings for agricultural advisories
 */
const WEATHER_CONDITIONS = {
  CLEAR: 'Clear',
  CLOUDS: 'Clouds',
  RAIN: 'Rain',
  DRIZZLE: 'Drizzle',
  THUNDERSTORM: 'Thunderstorm',
  SNOW: 'Snow',
  MIST: 'Mist',
  FOG: 'Fog',
  HAZE: 'Haze',
  DUST: 'Dust',
};

/**
 * Agricultural activity suitability levels
 */
const SUITABILITY = {
  EXCELLENT: { level: 'excellent', score: 100, color: '#22c55e' },
  GOOD: { level: 'good', score: 80, color: '#84cc16' },
  MODERATE: { level: 'moderate', score: 60, color: '#eab308' },
  POOR: { level: 'poor', score: 40, color: '#f97316' },
  AVOID: { level: 'avoid', score: 20, color: '#ef4444' },
};

/**
 * Main Weather Service Class
 */
class WeatherService {
  constructor() {
    this.openWeatherApiKey = process.env.OPENWEATHER_API_KEY || process.env.WEATHER_API_KEY;
    this.imdApiKey = process.env.IMD_API_KEY;
    this.dataGovApiKey = process.env.DATA_GOV_API_KEY;
  }

  /**
   * Get current weather with fallback chain
   * @param {number} lat - Latitude
   * @param {number} lon - Longitude
   * @param {string} city - City name (optional)
   * @returns {Object} Current weather data
   */
  async getCurrentWeather(lat, lon, city = null) {
    const cacheKey = city ? `weather:current:${city}` : `weather:current:${lat},${lon}`;

    // Try cache first
    const cached = await this._getFromCache(cacheKey);
    if (cached) {
      return { ...cached, cached: true };
    }

    let weatherData = null;
    let source = null;

    // Fallback chain: IMD → OpenWeather → Open-Meteo → Mock
    
    // 1. Try IMD (for Indian locations)
    if (this._isIndianLocation(lat, lon)) {
      weatherData = await this._fetchFromIMD(lat, lon);
      if (weatherData) source = 'IMD';
    }

    // 2. Try OpenWeatherMap
    if (!weatherData && this.openWeatherApiKey) {
      weatherData = await this._fetchFromOpenWeather(lat, lon, city);
      if (weatherData) source = 'OpenWeatherMap';
    }

    // 3. Try Open-Meteo (free, no key required)
    if (!weatherData) {
      weatherData = await this._fetchFromOpenMeteo(lat, lon);
      if (weatherData) source = 'Open-Meteo';
    }

    // 4. Fall back to mock data
    if (!weatherData) {
      weatherData = this._getMockCurrentWeather(lat, lon, city);
      source = 'Mock';
    }

    // Add metadata
    const result = {
      success: true,
      source,
      ...weatherData,
      fetched_at: new Date().toISOString(),
    };

    // Cache the result
    await this._setToCache(cacheKey, result, CACHE_TTL.CURRENT_WEATHER);

    return result;
  }

  /**
   * Get 5-day weather forecast with fallback chain
   * @param {number} lat - Latitude
   * @param {number} lon - Longitude
   * @param {string} city - City name (optional)
   * @returns {Object} 5-day forecast data
   */
  async getForecast(lat, lon, city = null) {
    const cacheKey = city ? `weather:forecast:${city}` : `weather:forecast:${lat},${lon}`;

    // Try cache first
    const cached = await this._getFromCache(cacheKey);
    if (cached) {
      return { ...cached, cached: true };
    }

    let forecastData = null;
    let source = null;

    // Fallback chain
    
    // 1. Try OpenWeatherMap (better 5-day forecast)
    if (this.openWeatherApiKey) {
      forecastData = await this._fetchForecastFromOpenWeather(lat, lon, city);
      if (forecastData) source = 'OpenWeatherMap';
    }

    // 2. Try Open-Meteo
    if (!forecastData) {
      forecastData = await this._fetchForecastFromOpenMeteo(lat, lon);
      if (forecastData) source = 'Open-Meteo';
    }

    // 3. Fall back to mock data
    if (!forecastData) {
      forecastData = this._getMockForecast(lat, lon, city);
      source = 'Mock';
    }

    // Add agricultural advisories to each day
    if (forecastData && forecastData.daily) {
      forecastData.daily = forecastData.daily.map(day => ({
        ...day,
        agricultural_advisory: this.generateDailyAgricultureAdvisory(day),
      }));
    }

    const result = {
      success: true,
      source,
      ...forecastData,
      fetched_at: new Date().toISOString(),
    };

    // Cache the result
    await this._setToCache(cacheKey, result, CACHE_TTL.FORECAST);

    return result;
  }

  /**
   * Get village-level hyperlocal forecast
   * @param {number} lat - Latitude
   * @param {number} lon - Longitude
   * @param {string} villageName - Village name (optional)
   * @returns {Object} Village-level forecast with agricultural advisories
   */
  async getVillageForecast(lat, lon, villageName = null) {
    const cacheKey = `weather:village:${lat},${lon}`;

    // Try cache first
    const cached = await this._getFromCache(cacheKey);
    if (cached) {
      return { ...cached, cached: true };
    }

    // Get location details via reverse geocoding
    const locationInfo = await this._reverseGeocode(lat, lon);
    
    // Get current weather
    const currentWeather = await this.getCurrentWeather(lat, lon);
    
    // Get forecast
    const forecast = await this.getForecast(lat, lon);

    // Generate comprehensive agricultural advisory
    const agriculturalAdvisory = this.generateComprehensiveAgricultureAdvisory(
      currentWeather,
      forecast
    );

    const result = {
      success: true,
      location: {
        name: villageName || locationInfo?.name || 'Unknown Location',
        district: locationInfo?.district || locationInfo?.state || '',
        state: locationInfo?.state || '',
        country: locationInfo?.country || 'India',
        lat: parseFloat(lat),
        lon: parseFloat(lon),
      },
      current: currentWeather.current || currentWeather,
      forecast: forecast.daily || [],
      hourly: forecast.hourly || [],
      agricultural_advisory: agriculturalAdvisory,
      alerts: await this._checkWeatherAlerts(currentWeather, forecast),
      fetched_at: new Date().toISOString(),
    };

    // Cache the result
    await this._setToCache(cacheKey, result, CACHE_TTL.VILLAGE_FORECAST);

    return result;
  }

  /**
   * Generate agricultural weather advisory based on current conditions
   * @param {Object} weather - Current weather data
   * @returns {Object} Agricultural advisory with activity recommendations
   */
  generateAgricultureAdvisory(weather) {
    const temp = weather.temp || weather.temperature || 25;
    const humidity = weather.humidity || 60;
    const windSpeed = weather.wind_speed || 10;
    const rainProbability = weather.rain_probability || weather.rain_chance || 0;
    const rainAmount = weather.rain_amount || weather.precipitation || 0;
    const weatherCondition = weather.weather || weather.weather_condition || 'Clear';

    const advisory = {
      overall_suitability: this._calculateOverallSuitability(temp, humidity, windSpeed, rainProbability),
      activities: {},
      warnings: [],
      tips: [],
      best_activities: [],
      avoid_activities: [],
    };

    // Evaluate each farming activity
    advisory.activities = {
      sowing: this._evaluateSowingSuitability(temp, humidity, windSpeed, rainProbability, rainAmount),
      irrigation: this._evaluateIrrigationSuitability(temp, humidity, rainProbability, rainAmount),
      spraying: this._evaluateSprayingSuitability(temp, humidity, windSpeed, rainProbability),
      harvesting: this._evaluateHarvestingSuitability(temp, humidity, rainProbability, weatherCondition),
      ploughing: this._evaluatePloughingSuitability(temp, humidity, rainAmount, weatherCondition),
      fertilizer_application: this._evaluateFertilizerSuitability(temp, humidity, windSpeed, rainProbability),
      weeding: this._evaluateWeedingSuitability(temp, humidity, rainAmount),
      pest_control: this._evaluatePestControlSuitability(temp, humidity, windSpeed, rainProbability),
    };

    // Generate warnings based on conditions
    advisory.warnings = this._generateWeatherWarnings(temp, humidity, windSpeed, rainProbability, weatherCondition);

    // Generate helpful tips
    advisory.tips = this._generateFarmingTips(temp, humidity, windSpeed, rainProbability, weatherCondition);

    // Categorize activities
    for (const [activity, data] of Object.entries(advisory.activities)) {
      if (data.suitability.score >= 80) {
        advisory.best_activities.push({
          activity,
          name: data.name,
          name_hi: data.name_hi,
          score: data.suitability.score,
        });
      } else if (data.suitability.score <= 40) {
        advisory.avoid_activities.push({
          activity,
          name: data.name,
          name_hi: data.name_hi,
          reason: data.reason,
        });
      }
    }

    return advisory;
  }

  /**
   * Generate daily agriculture advisory for forecast day
   * @param {Object} dayForecast - Forecast data for a single day
   * @returns {Object} Daily agricultural advisory
   */
  generateDailyAgricultureAdvisory(dayForecast) {
    const temp = dayForecast.temp_max || dayForecast.temp || 30;
    const tempMin = dayForecast.temp_min || temp - 8;
    const humidity = dayForecast.humidity || dayForecast.humidity_avg || 60;
    const rainProb = dayForecast.rain_probability || dayForecast.pop || 0;
    const condition = dayForecast.condition || dayForecast.weather || 'Clear';

    const advisory = {
      day_rating: this._getDayRating(temp, humidity, rainProb, condition),
      recommended_activities: [],
      avoid_activities: [],
      optimal_time_windows: this._getOptimalTimeWindows(tempMin, temp, humidity),
      precautions: [],
    };

    // Determine best activities for the day
    if (rainProb < 30 && humidity < 70 && temp < 35) {
      advisory.recommended_activities.push(
        { activity: 'spraying', name: 'Pesticide/Fertilizer Spraying', name_hi: 'कीटनाशक/उर्वरक छिड़काव' },
        { activity: 'harvesting', name: 'Harvesting', name_hi: 'कटाई' }
      );
    }
    
    if (rainProb > 60 || condition === 'Rain') {
      advisory.avoid_activities.push(
        { activity: 'spraying', reason: 'Rain will wash away chemicals' },
        { activity: 'harvesting', reason: 'Wet conditions damage crops' }
      );
      advisory.precautions.push('Ensure proper drainage in fields');
    }

    if (temp > 35) {
      advisory.avoid_activities.push(
        { activity: 'field_work', reason: 'High temperature risk for workers' }
      );
      advisory.precautions.push('Work during cooler morning or evening hours');
      advisory.precautions.push('Ensure adequate hydration');
    }

    if (humidity > 80) {
      advisory.precautions.push('High humidity increases disease risk - monitor crops');
    }

    return advisory;
  }

  /**
   * Generate comprehensive agriculture advisory combining current and forecast
   * @param {Object} current - Current weather data
   * @param {Object} forecast - Forecast data
   * @returns {Object} Comprehensive agricultural advisory
   */
  generateComprehensiveAgricultureAdvisory(current, forecast) {
    const currentAdvisory = this.generateAgricultureAdvisory(
      current.current || current
    );

    // Get season info
    const seasonInfo = this._getSeasonInfo();

    // Analyze forecast trend
    const forecastTrend = this._analyzeForecastTrend(forecast.daily || []);

    return {
      current_conditions: currentAdvisory,
      season: seasonInfo,
      forecast_trend: forecastTrend,
      weekly_outlook: this._generateWeeklyOutlook(forecast.daily || []),
      crop_specific_advice: this._getCropSpecificAdvice(seasonInfo, currentAdvisory),
      irrigation_schedule: this._suggestIrrigationSchedule(current, forecast),
      pest_disease_risk: this._assessPestDiseaseRisk(current, forecast),
    };
  }

  // ==================== Private Methods ====================

  /**
   * Check if location is in India (for IMD preference)
   */
  _isIndianLocation(lat, lon) {
    // India's approximate bounding box
    return lat >= 6 && lat <= 38 && lon >= 68 && lon <= 98;
  }

  /**
   * Fetch weather from IMD (via data.gov.in)
   */
  async _fetchFromIMD(lat, lon) {
    if (!this.dataGovApiKey) return null;

    try {
      const response = await axios.get(IMD_API.DISTRICTS, {
        params: {
          'api-key': this.dataGovApiKey,
          format: 'json',
          limit: 10,
        },
        timeout: 5000,
      });

      if (response.data && response.data.records) {
        // Process IMD data - this would need actual IMD API structure
        // For now, return null to use fallback
        console.log('IMD data available but requires specific parsing');
        return null;
      }
    } catch (error) {
      console.warn('IMD API error:', error.message);
    }
    return null;
  }

  /**
   * Fetch current weather from OpenWeatherMap
   */
  async _fetchFromOpenWeather(lat, lon, city = null) {
    try {
      const params = {
        appid: this.openWeatherApiKey,
        units: 'metric',
      };

      if (city) {
        params.q = city;
      } else {
        params.lat = lat;
        params.lon = lon;
      }

      const response = await axios.get(OPENWEATHER_API.CURRENT, {
        params,
        timeout: 10000,
      });

      const data = response.data;
      return {
        location: {
          name: data.name,
          country: data.sys.country,
          lat: data.coord.lat,
          lon: data.coord.lon,
        },
        current: {
          temp: data.main.temp,
          feels_like: data.main.feels_like,
          temp_min: data.main.temp_min,
          temp_max: data.main.temp_max,
          pressure: data.main.pressure,
          humidity: data.main.humidity,
          weather: data.weather[0].main,
          description: data.weather[0].description,
          icon: data.weather[0].icon,
          wind_speed: data.wind.speed * 3.6, // m/s to km/h
          wind_deg: data.wind.deg,
          clouds: data.clouds.all,
          visibility: data.visibility,
          sunrise: data.sys.sunrise,
          sunset: data.sys.sunset,
          rain_1h: data.rain?.['1h'] || 0,
          rain_3h: data.rain?.['3h'] || 0,
        },
        timestamp: data.dt,
      };
    } catch (error) {
      console.warn('OpenWeatherMap current weather error:', error.message);
      return null;
    }
  }

  /**
   * Fetch forecast from OpenWeatherMap
   */
  async _fetchForecastFromOpenWeather(lat, lon, city = null) {
    try {
      const params = {
        appid: this.openWeatherApiKey,
        units: 'metric',
      };

      if (city) {
        params.q = city;
      } else {
        params.lat = lat;
        params.lon = lon;
      }

      const response = await axios.get(OPENWEATHER_API.FORECAST, {
        params,
        timeout: 10000,
      });

      const data = response.data;

      // Process 3-hour intervals into daily forecasts
      const dailyMap = {};
      const hourly = [];

      data.list.forEach((item, index) => {
        const date = item.dt_txt.split(' ')[0];
        
        // Add to hourly (first 24 entries = 3 days of 3-hour intervals)
        if (index < 24) {
          hourly.push({
            datetime: item.dt_txt,
            timestamp: item.dt,
            temp: item.main.temp,
            feels_like: item.main.feels_like,
            humidity: item.main.humidity,
            weather: item.weather[0].main,
            description: item.weather[0].description,
            icon: item.weather[0].icon,
            wind_speed: item.wind.speed * 3.6,
            wind_deg: item.wind.deg,
            clouds: item.clouds.all,
            rain_probability: (item.pop || 0) * 100,
            rain_3h: item.rain?.['3h'] || 0,
          });
        }

        // Aggregate into daily
        if (!dailyMap[date]) {
          dailyMap[date] = {
            date,
            temps: [],
            humidity: [],
            conditions: [],
            rain: [],
            rain_prob: [],
            wind: [],
          };
        }

        dailyMap[date].temps.push(item.main.temp);
        dailyMap[date].humidity.push(item.main.humidity);
        dailyMap[date].conditions.push(item.weather[0].main);
        dailyMap[date].rain.push(item.rain?.['3h'] || 0);
        dailyMap[date].rain_prob.push((item.pop || 0) * 100);
        dailyMap[date].wind.push(item.wind.speed * 3.6);
      });

      // Convert daily map to array
      const daily = Object.values(dailyMap).slice(0, 5).map(day => ({
        date: day.date,
        temp_min: Math.min(...day.temps),
        temp_max: Math.max(...day.temps),
        temp_avg: Math.round(day.temps.reduce((a, b) => a + b, 0) / day.temps.length * 10) / 10,
        humidity: Math.round(day.humidity.reduce((a, b) => a + b, 0) / day.humidity.length),
        condition: this._getMostCommon(day.conditions),
        rain_probability: Math.round(Math.max(...day.rain_prob)),
        rain_total: Math.round(day.rain.reduce((a, b) => a + b, 0) * 10) / 10,
        wind_speed: Math.round(day.wind.reduce((a, b) => a + b, 0) / day.wind.length * 10) / 10,
      }));

      return {
        location: {
          name: data.city.name,
          country: data.city.country,
          lat: data.city.coord.lat,
          lon: data.city.coord.lon,
        },
        daily,
        hourly,
      };
    } catch (error) {
      console.warn('OpenWeatherMap forecast error:', error.message);
      return null;
    }
  }

  /**
   * Fetch weather from Open-Meteo (free, no API key required)
   */
  async _fetchFromOpenMeteo(lat, lon) {
    try {
      const response = await axios.get(OPEN_METEO_API.FORECAST, {
        params: {
          latitude: lat,
          longitude: lon,
          current: 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,cloud_cover,pressure_msl,wind_speed_10m,wind_direction_10m',
          daily: 'sunrise,sunset',
          timezone: 'auto',
        },
        timeout: 10000,
      });

      const data = response.data;
      const current = data.current;
      const daily = data.daily;

      const weatherInfo = this._wmoCodeToWeather(current.weather_code);

      return {
        location: {
          name: 'Location',
          lat: parseFloat(lat),
          lon: parseFloat(lon),
        },
        current: {
          temp: current.temperature_2m,
          feels_like: current.apparent_temperature,
          humidity: current.relative_humidity_2m,
          pressure: current.pressure_msl,
          weather: weatherInfo.main,
          description: weatherInfo.description,
          icon: weatherInfo.icon,
          wind_speed: current.wind_speed_10m,
          wind_deg: current.wind_direction_10m,
          clouds: current.cloud_cover,
          precipitation: current.precipitation,
          sunrise: daily.sunrise?.[0] ? Math.floor(new Date(daily.sunrise[0]).getTime() / 1000) : null,
          sunset: daily.sunset?.[0] ? Math.floor(new Date(daily.sunset[0]).getTime() / 1000) : null,
        },
        timestamp: Math.floor(Date.now() / 1000),
      };
    } catch (error) {
      console.warn('Open-Meteo error:', error.message);
      return null;
    }
  }

  /**
   * Fetch forecast from Open-Meteo
   */
  async _fetchForecastFromOpenMeteo(lat, lon) {
    try {
      const response = await axios.get(OPEN_METEO_API.FORECAST, {
        params: {
          latitude: lat,
          longitude: lon,
          daily: 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,wind_speed_10m_max,relative_humidity_2m_mean',
          hourly: 'temperature_2m,relative_humidity_2m,precipitation_probability,precipitation,weather_code,wind_speed_10m',
          timezone: 'auto',
          forecast_days: 7,
        },
        timeout: 10000,
      });

      const data = response.data;

      // Process daily forecast
      const daily = data.daily.time.slice(0, 5).map((date, i) => {
        const weatherInfo = this._wmoCodeToWeather(data.daily.weather_code[i]);
        return {
          date,
          temp_min: data.daily.temperature_2m_min[i],
          temp_max: data.daily.temperature_2m_max[i],
          temp_avg: Math.round((data.daily.temperature_2m_min[i] + data.daily.temperature_2m_max[i]) / 2 * 10) / 10,
          humidity: data.daily.relative_humidity_2m_mean[i],
          condition: weatherInfo.main,
          rain_probability: data.daily.precipitation_probability_max[i] || 0,
          rain_total: data.daily.precipitation_sum[i] || 0,
          wind_speed: data.daily.wind_speed_10m_max[i],
        };
      });

      // Process hourly forecast (next 24 hours)
      const hourly = data.hourly.time.slice(0, 24).map((datetime, i) => {
        const weatherInfo = this._wmoCodeToWeather(data.hourly.weather_code[i]);
        return {
          datetime,
          timestamp: Math.floor(new Date(datetime).getTime() / 1000),
          temp: data.hourly.temperature_2m[i],
          humidity: data.hourly.relative_humidity_2m[i],
          weather: weatherInfo.main,
          description: weatherInfo.description,
          icon: weatherInfo.icon,
          wind_speed: data.hourly.wind_speed_10m[i],
          rain_probability: data.hourly.precipitation_probability[i] || 0,
          precipitation: data.hourly.precipitation[i] || 0,
        };
      });

      return {
        location: {
          lat: parseFloat(lat),
          lon: parseFloat(lon),
        },
        daily,
        hourly,
      };
    } catch (error) {
      console.warn('Open-Meteo forecast error:', error.message);
      return null;
    }
  }

  /**
   * Reverse geocode coordinates to location name
   */
  async _reverseGeocode(lat, lon) {
    if (this.openWeatherApiKey) {
      try {
        const response = await axios.get(OPENWEATHER_API.REVERSE_GEOCODING, {
          params: {
            lat,
            lon,
            limit: 1,
            appid: this.openWeatherApiKey,
          },
          timeout: 5000,
        });

        if (response.data && response.data.length > 0) {
          const loc = response.data[0];
          return {
            name: loc.name,
            state: loc.state,
            country: loc.country,
          };
        }
      } catch (error) {
        console.warn('Reverse geocoding error:', error.message);
      }
    }

    // Try Open-Meteo geocoding
    try {
      const response = await axios.get(OPEN_METEO_API.GEOCODING, {
        params: {
          name: `${lat},${lon}`,
          count: 1,
          language: 'en',
        },
        timeout: 5000,
      });

      if (response.data?.results?.length > 0) {
        const loc = response.data.results[0];
        return {
          name: loc.name,
          state: loc.admin1,
          country: loc.country,
        };
      }
    } catch (error) {
      console.warn('Open-Meteo geocoding error:', error.message);
    }

    return null;
  }

  /**
   * Check for weather alerts
   */
  async _checkWeatherAlerts(current, forecast) {
    const alerts = [];
    const currentData = current.current || current;
    const temp = currentData.temp || 25;
    const humidity = currentData.humidity || 60;
    const windSpeed = currentData.wind_speed || 10;

    // Heat wave alert
    if (temp >= 40) {
      alerts.push({
        type: 'heat_wave',
        severity: temp >= 45 ? 'severe' : 'high',
        title: 'Heat Wave Warning',
        title_hi: 'लू की चेतावनी',
        message: `Extreme heat at ${temp.toFixed(1)}°C. Avoid outdoor work during peak hours.`,
        message_hi: `${temp.toFixed(1)}°C पर अत्यधिक गर्मी। चरम घंटों में बाहरी काम से बचें।`,
      });
    }

    // Frost alert
    if (temp <= 4) {
      alerts.push({
        type: 'frost',
        severity: temp <= 0 ? 'severe' : 'moderate',
        title: 'Frost Warning',
        title_hi: 'पाला चेतावनी',
        message: `Frost conditions at ${temp.toFixed(1)}°C. Protect sensitive crops.`,
        message_hi: `${temp.toFixed(1)}°C पर पाले की स्थिति। संवेदनशील फसलों की रक्षा करें।`,
      });
    }

    // High wind alert
    if (windSpeed >= 50) {
      alerts.push({
        type: 'high_wind',
        severity: windSpeed >= 80 ? 'severe' : 'high',
        title: 'High Wind Alert',
        title_hi: 'तेज हवा चेतावनी',
        message: `Strong winds at ${windSpeed.toFixed(1)} km/h. Secure loose materials.`,
        message_hi: `${windSpeed.toFixed(1)} किमी/घंटा की तेज हवा। ढीली सामग्री सुरक्षित करें।`,
      });
    }

    // Check forecast for upcoming rain
    if (forecast.daily) {
      const rainDays = forecast.daily.filter(d => d.rain_probability > 70 || d.rain_total > 20);
      if (rainDays.length > 0) {
        alerts.push({
          type: 'rain_forecast',
          severity: 'moderate',
          title: 'Rain Expected',
          title_hi: 'बारिश की संभावना',
          message: `Rain expected on ${rainDays.length} day(s). Plan harvesting accordingly.`,
          message_hi: `${rainDays.length} दिन(ों) में बारिश की संभावना। तदनुसार कटाई की योजना बनाएं।`,
        });
      }
    }

    return alerts;
  }

  // ==================== Activity Evaluation Methods ====================

  _evaluateSowingSuitability(temp, humidity, windSpeed, rainProb, rainAmount) {
    let score = 100;
    const issues = [];

    if (temp < 15) { score -= 30; issues.push('Temperature too low for germination'); }
    if (temp > 35) { score -= 25; issues.push('High temperature may stress seedlings'); }
    if (humidity < 40) { score -= 20; issues.push('Low humidity - soil may dry quickly'); }
    if (humidity > 80) { score -= 15; issues.push('High humidity increases disease risk'); }
    if (windSpeed > 20) { score -= 20; issues.push('Wind may disturb seedbeds'); }
    if (rainProb > 60) { score -= 25; issues.push('Rain expected - delay sowing'); }
    if (rainAmount > 5) { score -= 30; issues.push('Waterlogged soil not suitable'); }

    return {
      name: 'Sowing/Planting',
      name_hi: 'बुवाई',
      suitability: this._getScoreLevel(score),
      score,
      issues,
      reason: issues.length > 0 ? issues[0] : 'Good conditions for sowing',
    };
  }

  _evaluateIrrigationSuitability(temp, humidity, rainProb, rainAmount) {
    let score = 100;
    const issues = [];

    if (rainProb > 50) { score -= 40; issues.push('Rain expected - skip irrigation'); }
    if (rainAmount > 2) { score -= 50; issues.push('Recent/ongoing rain - no irrigation needed'); }
    if (humidity > 85) { score -= 20; issues.push('High humidity - reduce irrigation'); }
    if (temp > 38) { score -= 15; issues.push('High evaporation - irrigate early morning/evening'); }

    return {
      name: 'Irrigation',
      name_hi: 'सिंचाई',
      suitability: this._getScoreLevel(score),
      score,
      issues,
      reason: issues.length > 0 ? issues[0] : 'Suitable for irrigation',
      best_time: temp > 30 ? 'Early morning (5-8 AM) or evening (5-7 PM)' : 'Any time',
    };
  }

  _evaluateSprayingSuitability(temp, humidity, windSpeed, rainProb) {
    let score = 100;
    const issues = [];

    if (windSpeed > 10) { score -= 35; issues.push('Wind will cause spray drift'); }
    if (windSpeed > 15) { score -= 30; } // Additional penalty
    if (rainProb > 30) { score -= 30; issues.push('Rain may wash off chemicals'); }
    if (rainProb > 60) { score -= 30; }
    if (temp > 32) { score -= 20; issues.push('High temp causes rapid evaporation'); }
    if (humidity > 80) { score -= 15; issues.push('Poor coverage in high humidity'); }
    if (humidity < 40) { score -= 15; issues.push('Low humidity increases drift'); }

    return {
      name: 'Spraying',
      name_hi: 'छिड़काव',
      suitability: this._getScoreLevel(score),
      score,
      issues,
      reason: issues.length > 0 ? issues[0] : 'Good conditions for spraying',
      best_time: 'Early morning (6-9 AM) when wind is calm',
    };
  }

  _evaluateHarvestingSuitability(temp, humidity, rainProb, condition) {
    let score = 100;
    const issues = [];

    if (rainProb > 40) { score -= 35; issues.push('Rain risk - harvest before it rains'); }
    if (humidity > 75) { score -= 25; issues.push('High humidity affects grain quality'); }
    if (condition === 'Rain' || condition === 'Thunderstorm') { 
      score -= 50; 
      issues.push('Wet conditions damage harvest'); 
    }
    if (temp > 40) { score -= 15; issues.push('Extreme heat - harvest early morning'); }

    return {
      name: 'Harvesting',
      name_hi: 'कटाई',
      suitability: this._getScoreLevel(score),
      score,
      issues,
      reason: issues.length > 0 ? issues[0] : 'Good conditions for harvesting',
    };
  }

  _evaluatePloughingSuitability(temp, humidity, rainAmount, condition) {
    let score = 100;
    const issues = [];

    if (rainAmount > 10) { score -= 40; issues.push('Soil too wet - wait 2-3 days'); }
    if (humidity > 85 && condition === 'Rain') { score -= 30; issues.push('Wet soil causes compaction'); }
    if (temp > 38) { score -= 20; issues.push('Hard soil in extreme heat'); }

    return {
      name: 'Ploughing',
      name_hi: 'जुताई',
      suitability: this._getScoreLevel(score),
      score,
      issues,
      reason: issues.length > 0 ? issues[0] : 'Suitable for ploughing',
    };
  }

  _evaluateFertilizerSuitability(temp, humidity, windSpeed, rainProb) {
    let score = 100;
    const issues = [];

    if (rainProb > 50) { score -= 35; issues.push('Rain will wash away fertilizer'); }
    if (windSpeed > 15) { score -= 25; issues.push('Wind causes uneven distribution'); }
    if (temp > 35) { score -= 20; issues.push('High temp may burn plants'); }
    if (humidity < 30) { score -= 15; issues.push('Dry conditions reduce absorption'); }

    return {
      name: 'Fertilizer Application',
      name_hi: 'उर्वरक प्रयोग',
      suitability: this._getScoreLevel(score),
      score,
      issues,
      reason: issues.length > 0 ? issues[0] : 'Good conditions for fertilizer application',
    };
  }

  _evaluateWeedingSuitability(temp, humidity, rainAmount) {
    let score = 100;
    const issues = [];

    if (temp > 35) { score -= 25; issues.push('High heat - weed in cooler hours'); }
    if (rainAmount > 5) { score -= 20; issues.push('Wet soil makes weeding difficult'); }

    return {
      name: 'Weeding',
      name_hi: 'निराई',
      suitability: this._getScoreLevel(score),
      score,
      issues,
      reason: issues.length > 0 ? issues[0] : 'Good conditions for weeding',
    };
  }

  _evaluatePestControlSuitability(temp, humidity, windSpeed, rainProb) {
    // Similar to spraying
    return this._evaluateSprayingSuitability(temp, humidity, windSpeed, rainProb);
  }

  // ==================== Helper Methods ====================

  _getScoreLevel(score) {
    if (score >= 90) return SUITABILITY.EXCELLENT;
    if (score >= 70) return SUITABILITY.GOOD;
    if (score >= 50) return SUITABILITY.MODERATE;
    if (score >= 30) return SUITABILITY.POOR;
    return SUITABILITY.AVOID;
  }

  _calculateOverallSuitability(temp, humidity, windSpeed, rainProb) {
    let score = 100;
    
    // Temperature penalty
    if (temp < 15 || temp > 38) score -= 20;
    else if (temp < 20 || temp > 35) score -= 10;
    
    // Humidity penalty
    if (humidity > 85 || humidity < 30) score -= 15;
    
    // Wind penalty
    if (windSpeed > 20) score -= 15;
    
    // Rain probability penalty
    if (rainProb > 70) score -= 25;
    else if (rainProb > 50) score -= 15;

    return {
      score,
      level: this._getScoreLevel(score).level,
      description: score >= 70 ? 'Good farming conditions' : 
                   score >= 50 ? 'Moderate - some activities may be affected' :
                   'Poor - limit outdoor activities',
    };
  }

  _generateWeatherWarnings(temp, humidity, windSpeed, rainProb, condition) {
    const warnings = [];

    if (temp >= 40) {
      warnings.push({
        type: 'heat',
        severity: 'high',
        message: 'Extreme heat - take precautions for workers and livestock',
        message_hi: 'अत्यधिक गर्मी - श्रमिकों और पशुओं के लिए सावधानी बरतें',
      });
    }

    if (temp <= 5) {
      warnings.push({
        type: 'frost',
        severity: 'high',
        message: 'Frost risk - protect sensitive crops',
        message_hi: 'पाले का खतरा - संवेदनशील फसलों की रक्षा करें',
      });
    }

    if (windSpeed > 30) {
      warnings.push({
        type: 'wind',
        severity: 'moderate',
        message: 'High winds - secure structures and postpone spraying',
        message_hi: 'तेज हवा - संरचनाओं को सुरक्षित करें और छिड़काव स्थगित करें',
      });
    }

    if (rainProb > 70) {
      warnings.push({
        type: 'rain',
        severity: 'moderate',
        message: 'Rain likely - complete outdoor work early',
        message_hi: 'बारिश की संभावना - बाहरी काम जल्दी पूरा करें',
      });
    }

    if (humidity > 85) {
      warnings.push({
        type: 'disease',
        severity: 'moderate',
        message: 'High humidity increases disease risk - monitor crops',
        message_hi: 'उच्च आर्द्रता से रोग का खतरा बढ़ता है - फसलों की निगरानी करें',
      });
    }

    return warnings;
  }

  _generateFarmingTips(temp, humidity, windSpeed, rainProb, condition) {
    const tips = [];

    if (temp > 35) {
      tips.push({
        tip: 'Irrigate crops during early morning or late evening to minimize evaporation',
        tip_hi: 'वाष्पीकरण को कम करने के लिए सुबह जल्दी या शाम को देर से फसलों की सिंचाई करें',
      });
    }

    if (humidity > 70) {
      tips.push({
        tip: 'Increase spacing between plants to improve air circulation',
        tip_hi: 'हवा के संचार को बेहतर बनाने के लिए पौधों के बीच की दूरी बढ़ाएं',
      });
    }

    if (rainProb < 30 && humidity < 50) {
      tips.push({
        tip: 'Good conditions for post-emergence herbicide application',
        tip_hi: 'अंकुरण के बाद शाकनाशी प्रयोग के लिए अच्छी स्थिति',
      });
    }

    if (windSpeed < 10 && rainProb < 20) {
      tips.push({
        tip: 'Ideal conditions for pesticide spraying - spray early morning',
        tip_hi: 'कीटनाशक छिड़काव के लिए आदर्श स्थिति - सुबह जल्दी छिड़काव करें',
      });
    }

    // Add general tip
    tips.push({
      tip: 'Check soil moisture before irrigation to avoid overwatering',
      tip_hi: 'अधिक पानी देने से बचने के लिए सिंचाई से पहले मिट्टी की नमी जांचें',
    });

    return tips;
  }

  _getDayRating(temp, humidity, rainProb, condition) {
    let rating = 'good';
    let score = 100;

    if (condition === 'Rain' || condition === 'Thunderstorm') {
      score -= 40;
    }
    if (rainProb > 70) score -= 30;
    if (temp > 38 || temp < 10) score -= 25;
    if (humidity > 85) score -= 15;

    if (score >= 70) rating = 'good';
    else if (score >= 50) rating = 'moderate';
    else rating = 'poor';

    return {
      rating,
      score,
      description: rating === 'good' ? 'Good day for farming activities' :
                   rating === 'moderate' ? 'Some limitations for outdoor work' :
                   'Consider postponing non-essential activities',
    };
  }

  _getOptimalTimeWindows(tempMin, tempMax, humidity) {
    const windows = {
      spraying: [],
      irrigation: [],
      field_work: [],
    };

    // Early morning window
    if (tempMin < 30) {
      windows.spraying.push({ start: '06:00', end: '09:00', reason: 'Low wind, cooler temps' });
      windows.irrigation.push({ start: '05:00', end: '08:00', reason: 'Minimal evaporation' });
    }

    // Field work
    if (tempMax < 35) {
      windows.field_work.push({ start: '07:00', end: '11:00', reason: 'Comfortable working conditions' });
      windows.field_work.push({ start: '16:00', end: '18:00', reason: 'Cooler afternoon' });
    } else {
      windows.field_work.push({ start: '06:00', end: '10:00', reason: 'Before peak heat' });
    }

    // Evening irrigation
    windows.irrigation.push({ start: '17:00', end: '19:00', reason: 'Evening absorption' });

    return windows;
  }

  _getSeasonInfo() {
    const month = new Date().getMonth() + 1;
    
    if (month >= 6 && month <= 10) {
      return {
        name: 'Kharif',
        name_hi: 'खरीफ',
        description: 'Monsoon cropping season',
        crops: ['rice', 'maize', 'cotton', 'soybean', 'groundnut'],
      };
    } else if (month >= 11 || month <= 3) {
      return {
        name: 'Rabi',
        name_hi: 'रबी',
        description: 'Winter cropping season',
        crops: ['wheat', 'barley', 'mustard', 'gram', 'potato'],
      };
    } else {
      return {
        name: 'Zaid',
        name_hi: 'जायद',
        description: 'Summer cropping season',
        crops: ['watermelon', 'muskmelon', 'cucumber', 'vegetables'],
      };
    }
  }

  _analyzeForecastTrend(daily) {
    if (!daily || daily.length < 3) {
      return { trend: 'stable', description: 'Insufficient data for trend analysis' };
    }

    const temps = daily.map(d => d.temp_max || d.temp_avg);
    const rainProbs = daily.map(d => d.rain_probability);

    const tempTrend = temps[temps.length - 1] - temps[0];
    const avgRainProb = rainProbs.reduce((a, b) => a + b, 0) / rainProbs.length;

    let trend = 'stable';
    let description = 'Weather expected to remain stable';

    if (tempTrend > 5) {
      trend = 'warming';
      description = 'Temperature expected to rise';
    } else if (tempTrend < -5) {
      trend = 'cooling';
      description = 'Temperature expected to drop';
    }

    if (avgRainProb > 60) {
      trend = 'rainy';
      description = 'Wet conditions expected';
    }

    return { trend, description, temp_change: tempTrend, avg_rain_probability: avgRainProb };
  }

  _generateWeeklyOutlook(daily) {
    if (!daily || daily.length === 0) {
      return { summary: 'No forecast data available' };
    }

    const goodDays = daily.filter(d => d.rain_probability < 40 && (d.temp_max || 30) < 38);
    const rainyDays = daily.filter(d => d.rain_probability > 60);

    return {
      total_days: daily.length,
      good_farming_days: goodDays.length,
      rainy_days: rainyDays.length,
      best_days: goodDays.slice(0, 3).map(d => d.date),
      summary: goodDays.length >= 3 
        ? 'Good week for farming activities'
        : rainyDays.length >= 3
          ? 'Rainy week - plan indoor activities'
          : 'Mixed conditions - check daily forecast',
    };
  }

  _getCropSpecificAdvice(seasonInfo, advisory) {
    const advice = {};
    
    for (const crop of seasonInfo.crops.slice(0, 3)) {
      advice[crop] = {
        crop,
        general: `Monitor ${crop} crop health regularly`,
        irrigation: advisory.activities.irrigation?.suitability.level === 'good' 
          ? 'Good conditions for irrigation'
          : 'Consider irrigation timing based on weather',
        pest_control: advisory.activities.spraying?.suitability.level === 'good'
          ? 'Favorable for pest control spraying'
          : 'Postpone spraying if possible',
      };
    }

    return advice;
  }

  _suggestIrrigationSchedule(current, forecast) {
    const suggestions = [];
    const currentData = current.current || current;
    
    if (!forecast.daily) {
      return { suggestions: ['Check forecast before planning irrigation'] };
    }

    for (let i = 0; i < Math.min(3, forecast.daily.length); i++) {
      const day = forecast.daily[i];
      if (day.rain_probability < 30) {
        suggestions.push({
          date: day.date,
          recommended: true,
          reason: 'Low rain probability - irrigation recommended',
        });
      } else if (day.rain_probability > 70) {
        suggestions.push({
          date: day.date,
          recommended: false,
          reason: 'Rain expected - skip irrigation',
        });
      }
    }

    return { suggestions };
  }

  _assessPestDiseaseRisk(current, forecast) {
    const currentData = current.current || current;
    const humidity = currentData.humidity || 60;
    const temp = currentData.temp || 28;
    
    const risks = [];

    if (humidity > 80 && temp > 25) {
      risks.push({
        type: 'fungal',
        risk_level: 'high',
        diseases: ['Blast', 'Blight', 'Rust'],
        advice: 'Apply preventive fungicide if not done recently',
      });
    }

    if (temp > 30 && humidity > 60) {
      risks.push({
        type: 'pest',
        risk_level: 'moderate',
        pests: ['Aphids', 'Whitefly', 'Thrips'],
        advice: 'Monitor crop for pest infestation',
      });
    }

    return {
      overall_risk: risks.some(r => r.risk_level === 'high') ? 'high' : 'moderate',
      risks,
    };
  }

  // ==================== Cache Methods ====================

  async _getFromCache(key) {
    try {
      const cached = await redisClient.get(key);
      if (cached) {
        console.log(`Cache hit: ${key}`);
        return JSON.parse(cached);
      }
    } catch (error) {
      console.warn('Cache get error:', error.message);
    }
    return null;
  }

  async _setToCache(key, data, ttl) {
    try {
      await redisClient.setex(key, ttl, JSON.stringify(data));
      console.log(`Cached: ${key} (TTL: ${ttl}s)`);
    } catch (error) {
      console.warn('Cache set error:', error.message);
    }
  }

  // ==================== Mock Data Methods ====================

  _getMockCurrentWeather(lat, lon, city) {
    return {
      location: {
        name: city || 'Mock Location',
        lat: parseFloat(lat),
        lon: parseFloat(lon),
      },
      current: {
        temp: 28 + Math.random() * 5,
        feels_like: 30 + Math.random() * 3,
        humidity: 60 + Math.random() * 20,
        pressure: 1013,
        weather: 'Clear',
        description: 'clear sky',
        icon: '01d',
        wind_speed: 10 + Math.random() * 10,
        wind_deg: Math.floor(Math.random() * 360),
        clouds: Math.floor(Math.random() * 50),
        visibility: 10000,
      },
      timestamp: Math.floor(Date.now() / 1000),
      is_mock: true,
    };
  }

  _getMockForecast(lat, lon, city) {
    const daily = [];
    const hourly = [];
    const now = new Date();

    for (let i = 0; i < 5; i++) {
      const date = new Date(now);
      date.setDate(date.getDate() + i);
      
      daily.push({
        date: date.toISOString().split('T')[0],
        temp_min: 20 + Math.random() * 5,
        temp_max: 30 + Math.random() * 5,
        humidity: 50 + Math.random() * 30,
        condition: ['Clear', 'Clouds', 'Rain'][Math.floor(Math.random() * 3)],
        rain_probability: Math.floor(Math.random() * 50),
        rain_total: Math.random() * 5,
        wind_speed: 10 + Math.random() * 15,
      });
    }

    for (let i = 0; i < 24; i++) {
      const datetime = new Date(now.getTime() + i * 3600000);
      hourly.push({
        datetime: datetime.toISOString(),
        timestamp: Math.floor(datetime.getTime() / 1000),
        temp: 25 + Math.random() * 8,
        humidity: 55 + Math.random() * 25,
        weather: 'Clear',
        description: 'clear sky',
        icon: datetime.getHours() > 6 && datetime.getHours() < 18 ? '01d' : '01n',
        wind_speed: 8 + Math.random() * 12,
        rain_probability: Math.floor(Math.random() * 30),
      });
    }

    return {
      location: {
        name: city || 'Mock Location',
        lat: parseFloat(lat),
        lon: parseFloat(lon),
      },
      daily,
      hourly,
      is_mock: true,
    };
  }

  _getMostCommon(arr) {
    const counts = {};
    arr.forEach(item => {
      counts[item] = (counts[item] || 0) + 1;
    });
    return Object.entries(counts).sort((a, b) => b[1] - a[1])[0][0];
  }

  _wmoCodeToWeather(code) {
    // WMO weather codes mapping
    const mappings = {
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
      80: { main: 'Rain', description: 'Slight rain showers', icon: '09d' },
      81: { main: 'Rain', description: 'Moderate rain showers', icon: '09d' },
      82: { main: 'Rain', description: 'Violent rain showers', icon: '09d' },
      95: { main: 'Thunderstorm', description: 'Thunderstorm', icon: '11d' },
      96: { main: 'Thunderstorm', description: 'Thunderstorm with hail', icon: '11d' },
      99: { main: 'Thunderstorm', description: 'Thunderstorm with heavy hail', icon: '11d' },
    };

    return mappings[code] || { main: 'Unknown', description: 'Unknown', icon: '01d' };
  }
}

// Export singleton instance
const weatherService = new WeatherService();

module.exports = weatherService;
module.exports.WeatherService = WeatherService;
module.exports.CACHE_TTL = CACHE_TTL;
module.exports.SUITABILITY = SUITABILITY;

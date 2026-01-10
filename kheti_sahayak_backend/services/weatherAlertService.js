/**
 * Weather Alert Service
 *
 * Provides weather alerts, seasonal advisories, and agricultural recommendations
 * for hyperlocal village-level forecasts.
 */

const axios = require('axios');

/**
 * Alert thresholds for severe weather conditions
 */
const ALERT_THRESHOLDS = {
  heat_wave: { temp_min: 40 }, // Celsius
  heavy_rain: { precipitation_mm: 50 },
  frost: { temp_max: 4 },
  storm: { wind_speed_kmh: 50 },
  drought: { days_without_rain: 14 },
};

/**
 * Alert severity levels
 */
const AlertSeverity = {
  LOW: 'low',
  MODERATE: 'moderate',
  HIGH: 'high',
  SEVERE: 'severe',
};

/**
 * Agricultural seasons in India
 */
const SEASONS = {
  KHARIF: {
    name: 'Kharif',
    name_hi: 'खरीफ',
    start_month: 6, // June
    end_month: 10, // October
    crops: ['rice', 'maize', 'cotton', 'soybean', 'groundnut', 'sugarcane', 'jowar', 'bajra'],
    description: 'Monsoon cropping season',
  },
  RABI: {
    name: 'Rabi',
    name_hi: 'रबी',
    start_month: 11, // November
    end_month: 3, // March
    crops: ['wheat', 'barley', 'mustard', 'gram', 'peas', 'lentils', 'potato', 'onion'],
    description: 'Winter cropping season',
  },
  ZAID: {
    name: 'Zaid',
    name_hi: 'जायद',
    start_month: 4, // April
    end_month: 6, // June
    crops: ['watermelon', 'muskmelon', 'cucumber', 'pumpkin', 'bitter_gourd', 'fodder'],
    description: 'Summer cropping season',
  },
};

/**
 * Crop-specific advisories for each season
 */
const CROP_ADVISORIES = {
  rice: {
    kharif: {
      activities: ['Transplanting', 'Weed management', 'Pest monitoring'],
      warnings: ['Watch for blast disease in humid conditions', 'Avoid waterlogging'],
      tips: ['Maintain 2-3 inches water level', 'Apply nitrogen in split doses'],
    },
  },
  wheat: {
    rabi: {
      activities: ['Sowing', 'Irrigation scheduling', 'Fertilizer application'],
      warnings: ['Frost damage risk in December-January', 'Yellow rust monitoring'],
      tips: ['First irrigation 21 days after sowing', 'Avoid late sowing after November 25'],
    },
  },
  cotton: {
    kharif: {
      activities: ['Sowing', 'Thinning', 'Pest management'],
      warnings: ['Bollworm infestation risk', 'Whitefly monitoring'],
      tips: ['Maintain plant population', 'Use pheromone traps for monitoring'],
    },
  },
  sugarcane: {
    kharif: {
      activities: ['Planting', 'Earthing up', 'Irrigation'],
      warnings: ['Red rot disease risk', 'Borer pest attack'],
      tips: ['Deep furrow planting recommended', 'Trash mulching for moisture conservation'],
    },
  },
  mustard: {
    rabi: {
      activities: ['Sowing', 'Thinning', 'Pest control'],
      warnings: ['Aphid infestation in flowering stage', 'White rust disease'],
      tips: ['Optimal sowing in October', 'Spray neem oil for aphid control'],
    },
  },
  potato: {
    rabi: {
      activities: ['Planting', 'Earthing up', 'Irrigation'],
      warnings: ['Late blight risk in foggy weather', 'Frost damage'],
      tips: ['Use certified seed tubers', 'Avoid excess nitrogen'],
    },
  },
  watermelon: {
    zaid: {
      activities: ['Sowing', 'Training vines', 'Pollination'],
      warnings: ['Powdery mildew in humid conditions', 'Fruit fly attack'],
      tips: ['Proper spacing for vine spread', 'Mulching for weed control'],
    },
  },
};

/**
 * Agricultural suitability levels
 */
const AgriSuitability = {
  GOOD: 'good',
  MODERATE: 'moderate',
  POOR: 'poor',
};

/**
 * Get current agricultural season based on month
 * @returns {Object} Current season information
 */
function getSeasonInfo() {
  const currentMonth = new Date().getMonth() + 1; // 1-12
  const currentDate = new Date();

  let currentSeason = null;

  for (const [key, season] of Object.entries(SEASONS)) {
    if (season.start_month <= season.end_month) {
      // Normal case: start and end in same year
      if (currentMonth >= season.start_month && currentMonth <= season.end_month) {
        currentSeason = { key, ...season };
        break;
      }
    } else {
      // Wrap around case (e.g., Rabi: Nov-March)
      if (currentMonth >= season.start_month || currentMonth <= season.end_month) {
        currentSeason = { key, ...season };
        break;
      }
    }
  }

  // If no season matched, default to Zaid (transition period)
  if (!currentSeason) {
    currentSeason = { key: 'ZAID', ...SEASONS.ZAID };
  }

  // Calculate days into season
  const seasonStart = new Date(currentDate.getFullYear(), currentSeason.start_month - 1, 1);
  if (currentMonth < currentSeason.start_month && currentSeason.start_month > currentSeason.end_month) {
    seasonStart.setFullYear(seasonStart.getFullYear() - 1);
  }
  const daysIntoSeason = Math.floor((currentDate - seasonStart) / (1000 * 60 * 60 * 24));

  return {
    ...currentSeason,
    current_month: currentMonth,
    days_into_season: Math.max(0, daysIntoSeason),
    phase: daysIntoSeason < 30 ? 'early' : daysIntoSeason < 90 ? 'mid' : 'late',
  };
}

/**
 * Check weather conditions and generate alerts
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @param {Object} weatherData - Current weather data (optional, will fetch if not provided)
 * @returns {Array} Active weather alerts
 */
async function checkForAlerts(lat, lon, weatherData = null) {
  const alerts = [];

  try {
    // If weather data not provided, fetch it
    if (!weatherData) {
      const apiKey = process.env.WEATHER_API_KEY;
      if (apiKey) {
        const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric`;
        const response = await axios.get(url);
        weatherData = {
          temp: response.data.main.temp,
          humidity: response.data.main.humidity,
          wind_speed: response.data.wind.speed * 3.6, // m/s to km/h
          precipitation: response.data.rain?.['1h'] || 0,
          weather_condition: response.data.weather[0]?.main || 'Clear',
        };
      } else {
        // Use mock data for development
        weatherData = {
          temp: 28,
          humidity: 65,
          wind_speed: 15,
          precipitation: 0,
          weather_condition: 'Clear',
        };
      }
    }

    const now = new Date();
    const startTime = now.toISOString();
    const endTime = new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString(); // +24 hours

    // Check for heat wave
    if (weatherData.temp >= ALERT_THRESHOLDS.heat_wave.temp_min) {
      const severity = weatherData.temp >= 45 ? AlertSeverity.SEVERE : 
                       weatherData.temp >= 42 ? AlertSeverity.HIGH : AlertSeverity.MODERATE;
      alerts.push({
        alert_type: 'heat_wave',
        severity,
        title: 'Heat Wave Warning',
        title_hi: 'लू की चेतावनी',
        description: `Extreme heat conditions with temperature at ${weatherData.temp.toFixed(1)}°C. Avoid outdoor work during peak hours.`,
        description_hi: `${weatherData.temp.toFixed(1)}°C तापमान के साथ अत्यधिक गर्मी। चरम घंटों के दौरान बाहरी काम से बचें।`,
        start_time: startTime,
        end_time: endTime,
        recommendations: [
          'Irrigate crops early morning or late evening',
          'Provide shade to livestock',
          'Avoid pesticide application during peak heat',
          'Ensure adequate hydration for workers',
        ],
      });
    }

    // Check for frost
    if (weatherData.temp <= ALERT_THRESHOLDS.frost.temp_max) {
      const severity = weatherData.temp <= 0 ? AlertSeverity.SEVERE : 
                       weatherData.temp <= 2 ? AlertSeverity.HIGH : AlertSeverity.MODERATE;
      alerts.push({
        alert_type: 'frost',
        severity,
        title: 'Frost Warning',
        title_hi: 'पाला चेतावनी',
        description: `Frost conditions expected with temperature at ${weatherData.temp.toFixed(1)}°C. Protect sensitive crops.`,
        description_hi: `${weatherData.temp.toFixed(1)}°C तापमान के साथ पाले की स्थिति। संवेदनशील फसलों की रक्षा करें।`,
        start_time: startTime,
        end_time: endTime,
        recommendations: [
          'Cover tender crops with plastic sheets or straw',
          'Light irrigation can help protect from frost',
          'Avoid harvesting frozen produce',
          'Delay morning field work until frost melts',
        ],
      });
    }

    // Check for storm
    if (weatherData.wind_speed >= ALERT_THRESHOLDS.storm.wind_speed_kmh) {
      const severity = weatherData.wind_speed >= 80 ? AlertSeverity.SEVERE : 
                       weatherData.wind_speed >= 65 ? AlertSeverity.HIGH : AlertSeverity.MODERATE;
      alerts.push({
        alert_type: 'storm',
        severity,
        title: 'Storm Warning',
        title_hi: 'तूफान चेतावनी',
        description: `High wind speeds at ${weatherData.wind_speed.toFixed(1)} km/h. Secure loose materials and equipment.`,
        description_hi: `${weatherData.wind_speed.toFixed(1)} किमी/घंटा की तेज हवा। ढीली सामग्री और उपकरण सुरक्षित करें।`,
        start_time: startTime,
        end_time: endTime,
        recommendations: [
          'Secure greenhouse covers and temporary structures',
          'Stake tall crops to prevent lodging',
          'Postpone spraying operations',
          'Keep livestock in sheltered areas',
        ],
      });
    }

    // Check for heavy rain
    if (weatherData.precipitation >= ALERT_THRESHOLDS.heavy_rain.precipitation_mm) {
      const severity = weatherData.precipitation >= 100 ? AlertSeverity.SEVERE : 
                       weatherData.precipitation >= 75 ? AlertSeverity.HIGH : AlertSeverity.MODERATE;
      alerts.push({
        alert_type: 'heavy_rain',
        severity,
        title: 'Heavy Rain Warning',
        title_hi: 'भारी बारिश चेतावनी',
        description: `Heavy rainfall expected (${weatherData.precipitation.toFixed(1)} mm). Ensure proper drainage.`,
        description_hi: `भारी बारिश की संभावना (${weatherData.precipitation.toFixed(1)} मिमी)। उचित जल निकासी सुनिश्चित करें।`,
        start_time: startTime,
        end_time: endTime,
        recommendations: [
          'Clear drainage channels',
          'Harvest ready crops before rain',
          'Postpone irrigation and fertilizer application',
          'Protect stored grains from moisture',
        ],
      });
    }

    return alerts;
  } catch (error) {
    console.error('Error checking for weather alerts:', error.message);
    return alerts;
  }
}

/**
 * Generate agriculture advisory based on weather and crop
 * @param {Object} weather - Weather data
 * @param {string} crop - Crop name (optional)
 * @returns {Object} Agriculture advisory
 */
function generateAgricultureAdvisory(weather, crop = null) {
  const seasonInfo = getSeasonInfo();
  const advisory = {
    season: seasonInfo,
    general_advisory: [],
    crop_specific: null,
  };

  // General weather-based advisories
  if (weather.temp > 35) {
    advisory.general_advisory.push({
      type: 'heat',
      priority: 'high',
      message: 'High temperatures - irrigate during cooler hours and provide shade to sensitive crops',
      message_hi: 'उच्च तापमान - ठंडे घंटों में सिंचाई करें और संवेदनशील फसलों को छाया प्रदान करें',
    });
  }

  if (weather.humidity > 80) {
    advisory.general_advisory.push({
      type: 'disease_risk',
      priority: 'high',
      message: 'High humidity increases fungal disease risk - monitor crops closely',
      message_hi: 'उच्च आर्द्रता से फंगल रोग का खतरा बढ़ता है - फसलों की बारीकी से निगरानी करें',
    });
  }

  if (weather.wind_speed > 25) {
    advisory.general_advisory.push({
      type: 'wind',
      priority: 'medium',
      message: 'Windy conditions - postpone spraying and secure plant supports',
      message_hi: 'तेज हवा की स्थिति - छिड़काव स्थगित करें और पौधों के सहारे को सुरक्षित करें',
    });
  }

  if (weather.rain_chance > 60) {
    advisory.general_advisory.push({
      type: 'rain',
      priority: 'medium',
      message: 'Rain expected - complete harvesting of ready crops and ensure drainage',
      message_hi: 'बारिश की संभावना - तैयार फसलों की कटाई पूरी करें और जल निकासी सुनिश्चित करें',
    });
  }

  // Season-specific general advisory
  if (seasonInfo.phase === 'early') {
    advisory.general_advisory.push({
      type: 'season',
      priority: 'medium',
      message: `Early ${seasonInfo.name} season - optimal time for sowing and land preparation`,
      message_hi: `${seasonInfo.name_hi} मौसम की शुरुआत - बुवाई और भूमि तैयारी का सर्वोत्तम समय`,
    });
  } else if (seasonInfo.phase === 'mid') {
    advisory.general_advisory.push({
      type: 'season',
      priority: 'medium',
      message: `Mid ${seasonInfo.name} season - focus on crop management and pest control`,
      message_hi: `${seasonInfo.name_hi} मौसम का मध्य - फसल प्रबंधन और कीट नियंत्रण पर ध्यान दें`,
    });
  } else {
    advisory.general_advisory.push({
      type: 'season',
      priority: 'medium',
      message: `Late ${seasonInfo.name} season - prepare for harvesting and post-harvest management`,
      message_hi: `${seasonInfo.name_hi} मौसम का अंत - कटाई और कटाई के बाद प्रबंधन की तैयारी करें`,
    });
  }

  // Crop-specific advisory
  if (crop) {
    const cropLower = crop.toLowerCase();
    const seasonKey = seasonInfo.key.toLowerCase();
    
    if (CROP_ADVISORIES[cropLower] && CROP_ADVISORIES[cropLower][seasonKey]) {
      advisory.crop_specific = {
        crop: cropLower,
        ...CROP_ADVISORIES[cropLower][seasonKey],
      };
    } else {
      advisory.crop_specific = {
        crop: cropLower,
        activities: ['Monitor crop growth', 'Regular irrigation', 'Weed management'],
        warnings: ['Monitor for common pests and diseases'],
        tips: ['Follow recommended practices for your region'],
      };
    }
  }

  return advisory;
}

/**
 * Evaluate agricultural suitability for an hour
 * @param {Object} hourData - Hourly weather data
 * @returns {Object} Suitability assessment for various activities
 */
function evaluateHourlySuitability(hourData) {
  const { temp, humidity, wind_speed, rain_probability = 0 } = hourData;

  const suitability = {};

  // Spraying suitability
  if (wind_speed < 10 && rain_probability < 20 && temp >= 15 && temp <= 30 && humidity >= 40 && humidity <= 70) {
    suitability.spraying = AgriSuitability.GOOD;
  } else if (wind_speed < 15 && rain_probability < 40 && temp >= 10 && temp <= 35) {
    suitability.spraying = AgriSuitability.MODERATE;
  } else {
    suitability.spraying = AgriSuitability.POOR;
  }

  // Irrigation suitability
  if (rain_probability < 30 && temp < 35) {
    suitability.irrigation = AgriSuitability.GOOD;
  } else if (rain_probability < 50) {
    suitability.irrigation = AgriSuitability.MODERATE;
  } else {
    suitability.irrigation = AgriSuitability.POOR;
  }

  // Harvesting suitability
  if (humidity < 60 && rain_probability < 20 && temp >= 15 && temp <= 35) {
    suitability.harvesting = AgriSuitability.GOOD;
  } else if (humidity < 75 && rain_probability < 40) {
    suitability.harvesting = AgriSuitability.MODERATE;
  } else {
    suitability.harvesting = AgriSuitability.POOR;
  }

  // Field work suitability
  if (rain_probability < 20 && temp >= 15 && temp <= 32 && wind_speed < 20) {
    suitability.field_work = AgriSuitability.GOOD;
  } else if (rain_probability < 50 && temp >= 10 && temp <= 38) {
    suitability.field_work = AgriSuitability.MODERATE;
  } else {
    suitability.field_work = AgriSuitability.POOR;
  }

  return suitability;
}

/**
 * In-memory storage for alert subscriptions (use database in production)
 */
const alertSubscriptions = new Map();

/**
 * Subscribe to weather alerts for a location
 * @param {string} userId - User ID
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @param {Array} alertTypes - Types of alerts to subscribe to
 * @returns {Object} Subscription details
 */
function subscribeToAlerts(userId, lat, lon, alertTypes = ['heat_wave', 'heavy_rain', 'frost', 'storm', 'drought']) {
  const subscriptionId = `${userId}_${lat}_${lon}`;
  const subscription = {
    id: subscriptionId,
    user_id: userId,
    location: { lat, lon },
    alert_types: alertTypes,
    created_at: new Date().toISOString(),
    active: true,
  };

  alertSubscriptions.set(subscriptionId, subscription);

  return subscription;
}

/**
 * Unsubscribe from weather alerts
 * @param {string} userId - User ID
 * @param {number} lat - Latitude (optional)
 * @param {number} lon - Longitude (optional)
 * @returns {boolean} Success status
 */
function unsubscribeFromAlerts(userId, lat = null, lon = null) {
  if (lat && lon) {
    const subscriptionId = `${userId}_${lat}_${lon}`;
    return alertSubscriptions.delete(subscriptionId);
  }

  let deleted = false;
  for (const [key, subscription] of alertSubscriptions) {
    if (subscription.user_id === userId) {
      alertSubscriptions.delete(key);
      deleted = true;
    }
  }
  return deleted;
}

/**
 * Get user's alert subscriptions
 * @param {string} userId - User ID
 * @returns {Array} User's subscriptions
 */
function getUserSubscriptions(userId) {
  const subscriptions = [];
  for (const [, subscription] of alertSubscriptions) {
    if (subscription.user_id === userId) {
      subscriptions.push(subscription);
    }
  }
  return subscriptions;
}

module.exports = {
  ALERT_THRESHOLDS,
  AlertSeverity,
  SEASONS,
  AgriSuitability,
  getSeasonInfo,
  checkForAlerts,
  generateAgricultureAdvisory,
  evaluateHourlySuitability,
  subscribeToAlerts,
  unsubscribeFromAlerts,
  getUserSubscriptions,
};

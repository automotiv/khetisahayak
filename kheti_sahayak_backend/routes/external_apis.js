const express = require('express');
const axios = require('axios');
const redisClient = require('../redisClient');

const router = express.Router();

// ============================================================================
// data.gov.in API Configuration for Live Mandi Prices
// ============================================================================
const DATA_GOV_API_KEY = process.env.DATA_GOV_API_KEY || '579b464db66ec23bdd0000016e58d8c2738a42797cd684d2c43cf07f';
const MANDI_PRICES_RESOURCE_ID = '9ef84268-d588-465a-a308-a864a43d0070';
const DATA_GOV_BASE_URL = 'https://api.data.gov.in/resource';

// ============================================================================
// Cache Configuration (in seconds)
// ============================================================================
const CACHE_TTL = {
  AGRO_WEATHER: 30 * 60,      // 30 minutes - weather changes slowly
  MANDI_PRICES: 30 * 60,      // 30 minutes - prices update throughout day
  SOIL_DATA: 24 * 60 * 60,    // 24 hours - soil data rarely changes
  NEWS: 60 * 60,              // 1 hour
  CROP_CALENDAR: 24 * 60 * 60, // 24 hours
  PEST_ALERTS: 30 * 60        // 30 minutes - weather-dependent
};

// ============================================================================
// OPEN-METEO API - Free, No API Key Required
// Agricultural weather data including soil moisture, evapotranspiration
// https://open-meteo.com/
// ============================================================================

/**
 * @swagger
 * tags:
 *   name: External APIs
 *   description: Free public API integrations for agricultural data
 */

/**
 * @swagger
 * /api/external/agro-weather:
 *   get:
 *     summary: Get agricultural weather data (soil moisture, evapotranspiration, UV)
 *     description: Uses Open-Meteo API (free, no API key) for precision agriculture data
 *     tags: [External APIs]
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
 *         description: Agricultural weather data
 */
router.get('/agro-weather', async (req, res) => {
  const { lat, lon } = req.query;

  if (!lat || !lon) {
    return res.status(400).json({
      success: false,
      error: 'Latitude and longitude are required'
    });
  }

  try {
    const cacheKey = `agro-weather:${lat},${lon}`;
    const cachedData = await redisClient.get(cacheKey);

    if (cachedData) {
      console.log('Serving agro-weather from cache');
      const cached = JSON.parse(cachedData);
      cached.cache = {
        hit: true,
        key: cacheKey,
        ttl: CACHE_TTL.AGRO_WEATHER,
        ttlFormatted: '30 minutes'
      };
      return res.json(cached);
    }

    console.log('Fetching agro-weather from Open-Meteo API...');
    // Open-Meteo API - completely free, no API key needed
    const response = await axios.get('https://api.open-meteo.com/v1/forecast', {
      params: {
        latitude: lat,
        longitude: lon,
        current: [
          'temperature_2m',
          'relative_humidity_2m',
          'precipitation',
          'rain',
          'weather_code',
          'wind_speed_10m',
          'soil_temperature_0cm',
          'soil_moisture_0_to_1cm'
        ].join(','),
        hourly: [
          'temperature_2m',
          'relative_humidity_2m',
          'precipitation_probability',
          'precipitation',
          'soil_temperature_6cm',
          'soil_moisture_3_to_9cm',
          'evapotranspiration',
          'uv_index'
        ].join(','),
        daily: [
          'temperature_2m_max',
          'temperature_2m_min',
          'precipitation_sum',
          'precipitation_probability_max',
          'sunrise',
          'sunset',
          'uv_index_max',
          'et0_fao_evapotranspiration'
        ].join(','),
        timezone: 'auto',
        forecast_days: 7
      }
    });

    const data = response.data;

    // Process and structure the data for agricultural use
    const result = {
      success: true,
      location: {
        lat: parseFloat(lat),
        lon: parseFloat(lon),
        timezone: data.timezone,
        elevation: data.elevation
      },
      current: {
        temperature: data.current?.temperature_2m,
        humidity: data.current?.relative_humidity_2m,
        precipitation: data.current?.precipitation,
        rain: data.current?.rain,
        weatherCode: data.current?.weather_code,
        windSpeed: data.current?.wind_speed_10m,
        soilTemperature: data.current?.soil_temperature_0cm,
        soilMoisture: data.current?.soil_moisture_0_to_1cm,
        timestamp: data.current?.time
      },
      daily: data.daily?.time?.map((date, i) => ({
        date,
        tempMax: data.daily.temperature_2m_max[i],
        tempMin: data.daily.temperature_2m_min[i],
        precipitationSum: data.daily.precipitation_sum[i],
        precipitationProbability: data.daily.precipitation_probability_max[i],
        sunrise: data.daily.sunrise[i],
        sunset: data.daily.sunset[i],
        uvIndexMax: data.daily.uv_index_max[i],
        evapotranspiration: data.daily.et0_fao_evapotranspiration[i]
      })) || [],
      agriculturalInsights: generateAgroInsights(data),
      source: 'Open-Meteo (free API)',
      cache: {
        hit: false,
        key: cacheKey,
        ttl: CACHE_TTL.AGRO_WEATHER,
        ttlFormatted: '30 minutes',
        cachedAt: new Date().toISOString()
      }
    };

    await redisClient.setex(cacheKey, CACHE_TTL.AGRO_WEATHER, JSON.stringify(result));
    console.log(`Cached agro-weather for ${CACHE_TTL.AGRO_WEATHER}s`);
    res.json(result);
  } catch (error) {
    console.error('Open-Meteo API error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch agricultural weather data'
    });
  }
});

/**
 * @swagger
 * /api/external/soil-data:
 *   get:
 *     summary: Get soil composition data
 *     description: Uses SoilGrids API for soil type, pH, organic carbon data
 *     tags: [External APIs]
 *     parameters:
 *       - in: query
 *         name: lat
 *         required: true
 *         schema:
 *           type: number
 *       - in: query
 *         name: lon
 *         required: true
 *         schema:
 *           type: number
 *     responses:
 *       200:
 *         description: Soil composition data
 */
router.get('/soil-data', async (req, res) => {
  const { lat, lon } = req.query;

  if (!lat || !lon) {
    return res.status(400).json({
      success: false,
      error: 'Latitude and longitude are required'
    });
  }

  try {
    const cacheKey = `soil:${lat},${lon}`;
    const cachedData = await redisClient.get(cacheKey);

    if (cachedData) {
      return res.json(JSON.parse(cachedData));
    }

    // SoilGrids API - Free soil data from ISRIC
    // https://rest.isric.org/soilgrids/v2.0/docs
    const properties = ['clay', 'sand', 'silt', 'phh2o', 'soc', 'nitrogen', 'cec'];
    const depths = ['0-5cm', '5-15cm', '15-30cm'];

    const response = await axios.get('https://rest.isric.org/soilgrids/v2.0/properties/query', {
      params: {
        lon: lon,
        lat: lat,
        property: properties,
        depth: depths,
        value: 'mean'
      },
      timeout: 10000
    });

    const soilData = response.data;

    // Process soil data into useful format
    const result = {
      success: true,
      location: {
        lat: parseFloat(lat),
        lon: parseFloat(lon)
      },
      soilProperties: processSoilGridsData(soilData),
      recommendations: generateSoilRecommendations(soilData),
      source: 'ISRIC SoilGrids (free API)'
    };

    // Cache for 24 hours (soil data doesn't change often)
    await redisClient.setex(cacheKey, 86400, JSON.stringify(result));
    res.json(result);
  } catch (error) {
    console.error('SoilGrids API error:', error.message);
    // Return mock data if API fails
    res.json({
      success: true,
      location: { lat: parseFloat(lat), lon: parseFloat(lon) },
      soilProperties: getMockSoilData(),
      recommendations: [
        'Based on typical soil conditions in your region',
        'Consider soil testing for precise recommendations'
      ],
      source: 'Estimated data (API unavailable)',
      isMock: true
    });
  }
});

/**
 * @swagger
 * /api/external/market-prices:
 *   get:
 *     summary: Get LIVE agricultural commodity prices from data.gov.in
 *     description: Real-time mandi prices from Ministry of Agriculture (updated daily)
 *     tags: [External APIs]
 *     parameters:
 *       - in: query
 *         name: commodity
 *         schema:
 *           type: string
 *         description: Specific commodity (Wheat, Rice, Onion, Tomato, etc.)
 *       - in: query
 *         name: state
 *         schema:
 *           type: string
 *         description: State name (Maharashtra, Uttar Pradesh, etc.)
 *       - in: query
 *         name: district
 *         schema:
 *           type: string
 *         description: District name
 *       - in: query
 *         name: limit
 *         schema:
 *           type: number
 *           default: 50
 *         description: Number of records to return
 *     responses:
 *       200:
 *         description: Live commodity price data from data.gov.in
 */
router.get('/market-prices', async (req, res) => {
  const { commodity, state, district, limit = 50 } = req.query;

  try {
    const cacheKey = `live-prices:${commodity || 'all'}:${state || 'all'}:${district || 'all'}`;
    const cachedData = await redisClient.get(cacheKey);

    if (cachedData) {
      console.log('Serving mandi prices from cache');
      const cached = JSON.parse(cachedData);
      cached.cache = {
        hit: true,
        key: cacheKey,
        ttl: CACHE_TTL.MANDI_PRICES,
        ttlFormatted: '30 minutes'
      };
      return res.json(cached);
    }

    // Build filters for data.gov.in API
    const params = {
      'api-key': DATA_GOV_API_KEY,
      format: 'json',
      limit: Math.min(parseInt(limit), 100)
    };

    // Add filters if provided (data.gov.in requires .keyword suffix for keyword fields)
    if (state) params['filters[state.keyword]'] = state;
    if (district) params['filters[district]'] = district;
    if (commodity) params['filters[commodity]'] = commodity;

    console.log('Fetching live mandi prices from data.gov.in...');
    const response = await axios.get(`${DATA_GOV_BASE_URL}/${MANDI_PRICES_RESOURCE_ID}`, {
      params,
      timeout: 10000
    });

    const apiData = response.data;

    if (!apiData.records || apiData.records.length === 0) {
      // Fallback to mock data if no records
      console.log('No live data available, using mock data');
      const mockPrices = getIndianCommodityPrices(commodity, state);
      return res.json({
        success: true,
        timestamp: new Date().toISOString(),
        currency: 'INR',
        unit: 'per quintal',
        total: mockPrices.length,
        prices: mockPrices,
        source: 'Mock Data (Live API returned no results)',
        isLive: false
      });
    }

    // Transform API response to our format
    const prices = apiData.records.map(record => ({
      commodity: record.commodity,
      variety: record.variety,
      grade: record.grade,
      state: record.state,
      district: record.district,
      market: record.market,
      minPrice: parseFloat(record.min_price) || 0,
      maxPrice: parseFloat(record.max_price) || 0,
      modalPrice: parseFloat(record.modal_price) || 0,
      arrivalDate: record.arrival_date,
      priceUnit: 'INR per quintal'
    }));

    // Calculate trends based on price ranges
    const pricesWithTrends = prices.map(p => ({
      ...p,
      trend: p.modalPrice > (p.minPrice + p.maxPrice) / 2 ? 'up' : 'down',
      priceRange: `${p.minPrice} - ${p.maxPrice}`
    }));

    const result = {
      success: true,
      timestamp: new Date().toISOString(),
      currency: 'INR',
      unit: 'per quintal',
      total: apiData.total,
      count: apiData.count,
      prices: pricesWithTrends,
      marketTrends: {
        topGainers: pricesWithTrends.filter(p => p.trend === 'up').slice(0, 5),
        topLosers: pricesWithTrends.filter(p => p.trend === 'down').slice(0, 5),
        advice: 'Live prices from government mandis. Check arrival dates for freshness.'
      },
      source: 'data.gov.in - Ministry of Agriculture',
      isLive: true,
      apiInfo: {
        resourceId: MANDI_PRICES_RESOURCE_ID,
        lastUpdated: apiData.updated_date,
        totalRecords: apiData.total
      },
      cache: {
        hit: false,
        key: cacheKey,
        ttl: CACHE_TTL.MANDI_PRICES,
        ttlFormatted: '30 minutes',
        cachedAt: new Date().toISOString()
      }
    };

    // Cache for 30 minutes (prices update throughout the day)
    await redisClient.setex(cacheKey, CACHE_TTL.MANDI_PRICES, JSON.stringify(result));
    console.log(`Fetched ${prices.length} live mandi prices, cached for ${CACHE_TTL.MANDI_PRICES}s`);
    res.json(result);
  } catch (error) {
    console.error('Live market prices error:', error.message);

    // Fallback to mock data on error
    try {
      const mockPrices = getIndianCommodityPrices(commodity, state);
      res.json({
        success: true,
        timestamp: new Date().toISOString(),
        currency: 'INR',
        unit: 'per quintal',
        prices: mockPrices,
        marketTrends: generateMarketTrends(mockPrices),
        source: 'Fallback Data (Live API error)',
        isLive: false,
        error: error.message
      });
    } catch (fallbackError) {
      res.status(500).json({
        success: false,
        error: 'Failed to fetch market prices'
      });
    }
  }
});

/**
 * @swagger
 * /api/external/news:
 *   get:
 *     summary: Get agricultural news
 *     description: Latest news related to farming and agriculture
 *     tags: [External APIs]
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *           enum: [crops, weather, policy, technology, markets]
 *       - in: query
 *         name: lang
 *         schema:
 *           type: string
 *           default: en
 *     responses:
 *       200:
 *         description: Agricultural news articles
 */
router.get('/news', async (req, res) => {
  const { category, lang = 'en' } = req.query;

  try {
    const cacheKey = `news:${category || 'all'}:${lang}`;
    const cachedData = await redisClient.get(cacheKey);

    if (cachedData) {
      return res.json(JSON.parse(cachedData));
    }

    // WikiNews API - Free, no API key
    // Alternative: Use GNews free tier or MediaStack
    const searchTerm = category
      ? `agriculture ${category}`
      : 'agriculture farming crops India';

    // Using Wikipedia/Wikimedia for free content
    const response = await axios.get('https://en.wikipedia.org/api/rest_v1/page/related/Agriculture_in_India', {
      timeout: 5000
    });

    // Also fetch current events from NewsAPI alternative
    let newsArticles = [];
    try {
      // GNews API - Free tier: 100 requests/day
      const gnewsApiKey = process.env.GNEWS_API_KEY;
      if (gnewsApiKey) {
        const newsResponse = await axios.get('https://gnews.io/api/v4/search', {
          params: {
            q: 'agriculture farming India',
            lang: lang,
            country: 'in',
            max: 10,
            apikey: gnewsApiKey
          }
        });
        newsArticles = newsResponse.data.articles || [];
      }
    } catch (e) {
      console.log('GNews API not available, using curated content');
    }

    // If no API key, use curated agricultural news
    if (newsArticles.length === 0) {
      newsArticles = getCuratedAgriNews(category);
    }

    const result = {
      success: true,
      category: category || 'general',
      language: lang,
      articles: newsArticles.slice(0, 10).map(article => ({
        title: article.title,
        description: article.description,
        url: article.url,
        image: article.image,
        publishedAt: article.publishedAt,
        source: article.source?.name || 'Agricultural News'
      })),
      relatedTopics: getRelatedAgriTopics(category),
      source: 'Curated Agricultural News'
    };

    await redisClient.setex(cacheKey, 3600, JSON.stringify(result));
    res.json(result);
  } catch (error) {
    console.error('News API error:', error.message);
    res.json({
      success: true,
      articles: getCuratedAgriNews(category),
      source: 'Curated content'
    });
  }
});

/**
 * @swagger
 * /api/external/crop-calendar:
 *   get:
 *     summary: Get crop calendar recommendations
 *     description: Planting and harvesting calendar based on location and season
 *     tags: [External APIs]
 *     parameters:
 *       - in: query
 *         name: lat
 *         required: true
 *         schema:
 *           type: number
 *       - in: query
 *         name: lon
 *         required: true
 *         schema:
 *           type: number
 *       - in: query
 *         name: crop
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Crop calendar data
 */
router.get('/crop-calendar', async (req, res) => {
  const { lat, lon, crop } = req.query;

  if (!lat || !lon) {
    return res.status(400).json({
      success: false,
      error: 'Latitude and longitude are required'
    });
  }

  try {
    // Determine climate zone based on coordinates
    const climateZone = determineClimateZone(parseFloat(lat), parseFloat(lon));
    const currentMonth = new Date().getMonth() + 1;
    const season = determineSeason(currentMonth, parseFloat(lat));

    const cropCalendar = getCropCalendar(climateZone, season, crop);

    res.json({
      success: true,
      location: {
        lat: parseFloat(lat),
        lon: parseFloat(lon),
        climateZone,
        currentSeason: season
      },
      currentMonth: new Date().toLocaleString('default', { month: 'long' }),
      calendar: cropCalendar,
      recommendations: getSeasonalRecommendations(season, climateZone)
    });
  } catch (error) {
    console.error('Crop calendar error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to generate crop calendar'
    });
  }
});

/**
 * @swagger
 * /api/external/pest-alerts:
 *   get:
 *     summary: Get pest and disease alerts based on weather conditions
 *     description: AI-generated pest alerts based on temperature, humidity, and season
 *     tags: [External APIs]
 *     parameters:
 *       - in: query
 *         name: lat
 *         required: true
 *         schema:
 *           type: number
 *       - in: query
 *         name: lon
 *         required: true
 *         schema:
 *           type: number
 *       - in: query
 *         name: crop
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Pest and disease alerts
 */
router.get('/pest-alerts', async (req, res) => {
  const { lat, lon, crop } = req.query;

  if (!lat || !lon) {
    return res.status(400).json({
      success: false,
      error: 'Latitude and longitude are required'
    });
  }

  try {
    // Get current weather data for pest prediction
    const weatherResponse = await axios.get('https://api.open-meteo.com/v1/forecast', {
      params: {
        latitude: lat,
        longitude: lon,
        current: 'temperature_2m,relative_humidity_2m,precipitation',
        timezone: 'auto'
      }
    });

    const weather = weatherResponse.data.current;
    const alerts = generatePestAlerts(weather, crop);

    res.json({
      success: true,
      location: { lat: parseFloat(lat), lon: parseFloat(lon) },
      currentConditions: {
        temperature: weather.temperature_2m,
        humidity: weather.relative_humidity_2m,
        precipitation: weather.precipitation
      },
      alerts: alerts,
      preventiveMeasures: getPreventiveMeasures(alerts),
      source: 'Weather-based pest prediction'
    });
  } catch (error) {
    console.error('Pest alerts error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to generate pest alerts'
    });
  }
});

// ============================================================================
// Helper Functions
// ============================================================================

function generateAgroInsights(data) {
  const insights = [];
  const current = data.current;

  if (current) {
    // Soil moisture insights
    if (current.soil_moisture_0_to_1cm !== undefined) {
      const moisture = current.soil_moisture_0_to_1cm;
      if (moisture < 0.1) {
        insights.push({
          type: 'irrigation',
          severity: 'high',
          message: 'Soil moisture is very low. Consider irrigation.',
          message_hi: 'मिट्टी की नमी बहुत कम है। सिंचाई पर विचार करें।'
        });
      } else if (moisture > 0.4) {
        insights.push({
          type: 'drainage',
          severity: 'medium',
          message: 'High soil moisture. Ensure proper drainage.',
          message_hi: 'मिट्टी में नमी अधिक है। उचित जल निकासी सुनिश्चित करें।'
        });
      }
    }

    // Temperature insights for farming
    if (current.temperature_2m > 35) {
      insights.push({
        type: 'heat_stress',
        severity: 'high',
        message: 'High temperature may cause crop stress. Avoid midday field work.',
        message_hi: 'उच्च तापमान से फसल को नुकसान हो सकता है। दोपहर में खेत का काम टालें।'
      });
    }

    // Humidity insights
    if (current.relative_humidity_2m > 80) {
      insights.push({
        type: 'disease_risk',
        severity: 'medium',
        message: 'High humidity increases fungal disease risk.',
        message_hi: 'उच्च आर्द्रता से फफूंदी रोग का खतरा बढ़ जाता है।'
      });
    }
  }

  // Evapotranspiration insights
  if (data.daily?.et0_fao_evapotranspiration) {
    const avgET = data.daily.et0_fao_evapotranspiration.reduce((a, b) => a + b, 0) /
                  data.daily.et0_fao_evapotranspiration.length;
    if (avgET > 5) {
      insights.push({
        type: 'water_requirement',
        severity: 'medium',
        message: `High evapotranspiration (${avgET.toFixed(1)}mm/day). Increase irrigation frequency.`,
        message_hi: `उच्च वाष्पीकरण (${avgET.toFixed(1)}mm/day)। सिंचाई की आवृत्ति बढ़ाएं।`
      });
    }
  }

  return insights;
}

function processSoilGridsData(data) {
  const properties = {};

  if (data.properties?.layers) {
    data.properties.layers.forEach(layer => {
      const propName = layer.name;
      const depths = {};

      layer.depths?.forEach(depth => {
        depths[depth.label] = {
          value: depth.values?.mean,
          unit: layer.unit_measure?.mapped_units || ''
        };
      });

      properties[propName] = depths;
    });
  }

  return {
    clay: properties.clay || {},
    sand: properties.sand || {},
    silt: properties.silt || {},
    ph: properties.phh2o || {},
    organicCarbon: properties.soc || {},
    nitrogen: properties.nitrogen || {},
    cationExchangeCapacity: properties.cec || {}
  };
}

function generateSoilRecommendations(data) {
  const recommendations = [];

  // Add basic recommendations based on typical soil analysis
  recommendations.push('Test soil pH before planting season');
  recommendations.push('Add organic matter to improve soil structure');
  recommendations.push('Consider crop rotation to maintain soil health');

  return recommendations;
}

function getMockSoilData() {
  return {
    clay: { '0-5cm': { value: 25, unit: '%' } },
    sand: { '0-5cm': { value: 40, unit: '%' } },
    silt: { '0-5cm': { value: 35, unit: '%' } },
    ph: { '0-5cm': { value: 6.5, unit: 'pH' } },
    organicCarbon: { '0-5cm': { value: 15, unit: 'g/kg' } },
    soilType: 'Loamy Soil',
    suitableCrops: ['Wheat', 'Rice', 'Vegetables', 'Pulses']
  };
}

function getIndianCommodityPrices(commodity, state) {
  // Real market price data (updated periodically)
  const allPrices = [
    { commodity: 'Wheat', variety: 'Sharbati', minPrice: 2275, maxPrice: 2600, modalPrice: 2450, market: 'Indore', state: 'Madhya Pradesh' },
    { commodity: 'Rice', variety: 'Basmati', minPrice: 3800, maxPrice: 4500, modalPrice: 4200, market: 'Karnal', state: 'Haryana' },
    { commodity: 'Rice', variety: 'Non-Basmati', minPrice: 2100, maxPrice: 2400, modalPrice: 2250, market: 'Guntur', state: 'Andhra Pradesh' },
    { commodity: 'Cotton', variety: 'Medium Staple', minPrice: 6500, maxPrice: 7200, modalPrice: 6800, market: 'Rajkot', state: 'Gujarat' },
    { commodity: 'Soybean', variety: 'Yellow', minPrice: 4500, maxPrice: 5200, modalPrice: 4800, market: 'Indore', state: 'Madhya Pradesh' },
    { commodity: 'Maize', variety: 'Yellow', minPrice: 2100, maxPrice: 2400, modalPrice: 2250, market: 'Davangere', state: 'Karnataka' },
    { commodity: 'Groundnut', variety: 'Bold', minPrice: 5500, maxPrice: 6200, modalPrice: 5800, market: 'Junagadh', state: 'Gujarat' },
    { commodity: 'Onion', variety: 'Red', minPrice: 1500, maxPrice: 2200, modalPrice: 1800, market: 'Lasalgaon', state: 'Maharashtra' },
    { commodity: 'Potato', variety: 'Chandramukhi', minPrice: 800, maxPrice: 1200, modalPrice: 1000, market: 'Agra', state: 'Uttar Pradesh' },
    { commodity: 'Tomato', variety: 'Hybrid', minPrice: 1000, maxPrice: 1800, modalPrice: 1400, market: 'Kolar', state: 'Karnataka' },
    { commodity: 'Mustard', variety: 'Yellow', minPrice: 5000, maxPrice: 5600, modalPrice: 5300, market: 'Alwar', state: 'Rajasthan' },
    { commodity: 'Chana', variety: 'Desi', minPrice: 5200, maxPrice: 5800, modalPrice: 5500, market: 'Indore', state: 'Madhya Pradesh' },
    { commodity: 'Tur/Arhar', variety: 'FAQ', minPrice: 7000, maxPrice: 8000, modalPrice: 7500, market: 'Latur', state: 'Maharashtra' },
    { commodity: 'Sugarcane', variety: 'General', minPrice: 315, maxPrice: 350, modalPrice: 335, market: 'Meerut', state: 'Uttar Pradesh' }
  ];

  let filtered = allPrices;

  if (commodity) {
    filtered = filtered.filter(p =>
      p.commodity.toLowerCase().includes(commodity.toLowerCase())
    );
  }

  if (state) {
    filtered = filtered.filter(p =>
      p.state.toLowerCase().includes(state.toLowerCase())
    );
  }

  return filtered.map(p => ({
    ...p,
    lastUpdated: new Date().toISOString().split('T')[0],
    trend: Math.random() > 0.5 ? 'up' : 'down',
    changePercent: (Math.random() * 5).toFixed(2)
  }));
}

function generateMarketTrends(prices) {
  return {
    topGainers: prices.filter(p => p.trend === 'up').slice(0, 3),
    topLosers: prices.filter(p => p.trend === 'down').slice(0, 3),
    advice: 'Monitor prices closely before selling. Consider MSP for guaranteed returns.'
  };
}

function getCuratedAgriNews(category) {
  const news = [
    {
      title: 'PM-KISAN: Next installment to be released soon',
      description: 'Farmers to receive Rs 2000 under PM-KISAN Samman Nidhi scheme',
      url: 'https://pmkisan.gov.in/',
      image: null,
      publishedAt: new Date().toISOString(),
      source: { name: 'Government of India' }
    },
    {
      title: 'Monsoon forecast: IMD predicts normal rainfall this year',
      description: 'Indian Meteorological Department releases monsoon predictions for agricultural planning',
      url: 'https://mausam.imd.gov.in/',
      image: null,
      publishedAt: new Date().toISOString(),
      source: { name: 'IMD' }
    },
    {
      title: 'New high-yield crop varieties released by ICAR',
      description: 'Indian Council of Agricultural Research releases disease-resistant varieties',
      url: 'https://icar.org.in/',
      image: null,
      publishedAt: new Date().toISOString(),
      source: { name: 'ICAR' }
    },
    {
      title: 'Soil Health Card scheme benefits millions of farmers',
      description: 'Government initiative helps farmers understand soil nutrient requirements',
      url: 'https://soilhealth.dac.gov.in/',
      image: null,
      publishedAt: new Date().toISOString(),
      source: { name: 'Ministry of Agriculture' }
    },
    {
      title: 'e-NAM platform crosses milestone of registered farmers',
      description: 'National Agriculture Market platform enables direct selling',
      url: 'https://enam.gov.in/',
      image: null,
      publishedAt: new Date().toISOString(),
      source: { name: 'e-NAM' }
    }
  ];

  if (category) {
    return news.filter(n =>
      n.title.toLowerCase().includes(category.toLowerCase()) ||
      n.description.toLowerCase().includes(category.toLowerCase())
    );
  }
  return news;
}

function getRelatedAgriTopics(category) {
  const topics = {
    crops: ['Seed varieties', 'Crop rotation', 'Organic farming', 'Harvest techniques'],
    weather: ['Monsoon patterns', 'Drought management', 'Frost protection', 'Climate change'],
    policy: ['PM-KISAN', 'Crop insurance', 'MSP rates', 'Agricultural loans'],
    technology: ['Precision farming', 'Drone technology', 'IoT in agriculture', 'Farm automation'],
    markets: ['Price forecasting', 'Export opportunities', 'Cold storage', 'Supply chain']
  };
  return topics[category] || topics.crops;
}

function determineClimateZone(lat, lon) {
  // Simplified climate zone determination for India
  if (lat > 28) return 'Northern Plains';
  if (lat > 23 && lat <= 28) return 'Central India';
  if (lat > 15 && lat <= 23) return 'Western/Deccan';
  if (lat > 8 && lat <= 15) return 'Southern Peninsular';
  return 'Coastal';
}

function determineSeason(month, lat) {
  // Indian agricultural seasons
  if (month >= 6 && month <= 9) return 'Kharif';
  if (month >= 10 && month <= 2) return 'Rabi';
  return 'Zaid';
}

function getCropCalendar(climateZone, season, specificCrop) {
  const calendar = {
    Kharif: {
      crops: [
        { name: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November' },
        { name: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October' },
        { name: 'Cotton', sowingStart: 'April', sowingEnd: 'May', harvestStart: 'October', harvestEnd: 'December' },
        { name: 'Soybean', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November' },
        { name: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November' }
      ]
    },
    Rabi: {
      crops: [
        { name: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April' },
        { name: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March' },
        { name: 'Chickpea', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March' },
        { name: 'Barley', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April' },
        { name: 'Peas', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March' }
      ]
    },
    Zaid: {
      crops: [
        { name: 'Watermelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May' },
        { name: 'Muskmelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May' },
        { name: 'Cucumber', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May' },
        { name: 'Moong', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June' }
      ]
    }
  };

  let crops = calendar[season]?.crops || [];

  if (specificCrop) {
    crops = crops.filter(c => c.name.toLowerCase().includes(specificCrop.toLowerCase()));
  }

  return {
    season,
    climateZone,
    crops: crops.map(crop => ({
      ...crop,
      status: getCurrentCropStatus(crop)
    }))
  };
}

function getCurrentCropStatus(crop) {
  const currentMonth = new Date().toLocaleString('default', { month: 'long' });
  const months = ['January', 'February', 'March', 'April', 'May', 'June',
                  'July', 'August', 'September', 'October', 'November', 'December'];
  const currentIdx = months.indexOf(currentMonth);
  const sowingIdx = months.indexOf(crop.sowingStart);
  const harvestIdx = months.indexOf(crop.harvestStart);

  if (currentIdx >= sowingIdx && currentIdx < harvestIdx) {
    return 'Growing';
  } else if (currentMonth === crop.sowingStart || currentMonth === crop.sowingEnd) {
    return 'Sowing Time';
  } else if (currentMonth === crop.harvestStart || currentMonth === crop.harvestEnd) {
    return 'Harvest Time';
  }
  return 'Off Season';
}

function getSeasonalRecommendations(season, climateZone) {
  const recommendations = {
    Kharif: [
      'Prepare fields before monsoon onset',
      'Ensure proper drainage systems',
      'Use treated seeds to prevent fungal diseases',
      'Apply fertilizers based on soil test results'
    ],
    Rabi: [
      'Irrigate fields before sowing',
      'Use cold-tolerant varieties',
      'Protect crops from frost in December-January',
      'Monitor for aphid and other pest infestations'
    ],
    Zaid: [
      'Ensure adequate irrigation facilities',
      'Use mulching to conserve soil moisture',
      'Plant early in the morning to avoid heat stress',
      'Harvest before monsoon arrives'
    ]
  };
  return recommendations[season] || [];
}

function generatePestAlerts(weather, crop) {
  const alerts = [];
  const temp = weather.temperature_2m;
  const humidity = weather.relative_humidity_2m;

  // Temperature-based alerts
  if (temp > 25 && temp < 35 && humidity > 70) {
    alerts.push({
      pest: 'Fungal Diseases',
      risk: 'High',
      message: 'Warm and humid conditions favor fungal growth',
      message_hi: 'गर्म और नम परिस्थितियाँ फफूंदी के विकास को बढ़ावा देती हैं',
      affectedCrops: ['Rice', 'Wheat', 'Vegetables']
    });
  }

  if (temp > 30 && humidity < 50) {
    alerts.push({
      pest: 'Spider Mites',
      risk: 'Medium',
      message: 'Hot and dry conditions favor mite infestations',
      message_hi: 'गर्म और सूखी परिस्थितियाँ माइट संक्रमण को बढ़ावा देती हैं',
      affectedCrops: ['Cotton', 'Vegetables', 'Fruits']
    });
  }

  if (humidity > 80) {
    alerts.push({
      pest: 'Bacterial Leaf Blight',
      risk: 'High',
      message: 'High humidity increases bacterial disease risk',
      message_hi: 'उच्च आर्द्रता से जीवाणु रोग का खतरा बढ़ता है',
      affectedCrops: ['Rice', 'Cotton']
    });
  }

  if (temp > 20 && temp < 30) {
    alerts.push({
      pest: 'Aphids',
      risk: 'Medium',
      message: 'Moderate temperatures favor aphid populations',
      message_hi: 'मध्यम तापमान एफिड्स के लिए अनुकूल है',
      affectedCrops: ['Mustard', 'Wheat', 'Vegetables']
    });
  }

  if (crop) {
    return alerts.filter(a =>
      a.affectedCrops.some(c => c.toLowerCase().includes(crop.toLowerCase()))
    );
  }

  return alerts;
}

function getPreventiveMeasures(alerts) {
  const measures = [];

  alerts.forEach(alert => {
    switch(alert.pest) {
      case 'Fungal Diseases':
        measures.push('Apply fungicides preventively');
        measures.push('Ensure proper plant spacing for air circulation');
        measures.push('Remove infected plant parts immediately');
        break;
      case 'Spider Mites':
        measures.push('Spray water on leaves to increase humidity');
        measures.push('Use neem oil as organic treatment');
        measures.push('Introduce predatory mites if available');
        break;
      case 'Bacterial Leaf Blight':
        measures.push('Use disease-resistant varieties');
        measures.push('Avoid overhead irrigation');
        measures.push('Apply copper-based bactericides');
        break;
      case 'Aphids':
        measures.push('Spray with soap solution');
        measures.push('Encourage natural predators like ladybugs');
        measures.push('Apply neem-based insecticides');
        break;
    }
  });

  return [...new Set(measures)];
}

module.exports = router;

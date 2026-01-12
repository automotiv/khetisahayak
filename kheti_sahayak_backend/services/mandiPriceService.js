const axios = require('axios');
const cheerio = require('cheerio');
const db = require('../db');
const redisClient = require('../redisClient');

const CACHE_TTL = {
  REAL_TIME: 900,
  DAILY: 86400,
  WEEKLY: 604800,
  STATES_LIST: 86400,
  MSP: 2592000
};

const DATA_GOV_API_KEY = process.env.DATA_GOV_API_KEY;
const AGMARKNET_BASE_URL = 'https://agmarknet.gov.in';
const DATA_GOV_MANDI_RESOURCE = '9ef84268-d588-465a-a308-a864a43d0070';

const SUPPORTED_COMMODITIES = {
  'Rice': { hindi: 'चावल', category: 'cereals' },
  'Wheat': { hindi: 'गेहूं', category: 'cereals' },
  'Cotton': { hindi: 'कपास', category: 'commercial' },
  'Sugarcane': { hindi: 'गन्ना', category: 'commercial' },
  'Tomato': { hindi: 'टमाटर', category: 'vegetables' },
  'Onion': { hindi: 'प्याज', category: 'vegetables' },
  'Potato': { hindi: 'आलू', category: 'vegetables' },
  'Soybean': { hindi: 'सोयाबीन', category: 'oilseeds' },
  'Groundnut': { hindi: 'मूंगफली', category: 'oilseeds' },
  'Maize': { hindi: 'मक्का', category: 'cereals' },
  'Jowar': { hindi: 'ज्वार', category: 'cereals' },
  'Bajra': { hindi: 'बाजरा', category: 'cereals' },
  'Gram': { hindi: 'चना', category: 'pulses' },
  'Tur': { hindi: 'अरहर', category: 'pulses' },
  'Urad': { hindi: 'उड़द', category: 'pulses' },
  'Moong': { hindi: 'मूंग', category: 'pulses' },
  'Mustard': { hindi: 'सरसों', category: 'oilseeds' },
  'Sunflower': { hindi: 'सूरजमुखी', category: 'oilseeds' },
  'Chilli': { hindi: 'मिर्च', category: 'spices' },
  'Turmeric': { hindi: 'हल्दी', category: 'spices' }
};

const INDIAN_STATES = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
  'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
  'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
];

async function fetchFromDataGovAPI(params = {}) {
  if (!DATA_GOV_API_KEY) {
    console.log('data.gov.in API key not configured, using fallback');
    return null;
  }

  const { state, commodity, limit = 100 } = params;
  
  const queryParams = new URLSearchParams({
    'api-key': DATA_GOV_API_KEY,
    'format': 'json',
    'limit': limit.toString()
  });

  if (state) queryParams.append('filters[state]', state);
  if (commodity) queryParams.append('filters[commodity]', commodity);

  try {
    const url = `https://api.data.gov.in/resource/${DATA_GOV_MANDI_RESOURCE}?${queryParams}`;
    const response = await axios.get(url, { timeout: 10000 });
    
    if (response.data && response.data.records) {
      return response.data.records.map(record => ({
        state: record.state,
        district: record.district,
        market: record.market,
        commodity: record.commodity,
        variety: record.variety || 'Other',
        grade: record.grade,
        min_price: parseFloat(record.min_price) || null,
        max_price: parseFloat(record.max_price) || null,
        modal_price: parseFloat(record.modal_price) || null,
        arrival_date: record.arrival_date,
        source: 'data.gov.in'
      }));
    }
    return null;
  } catch (error) {
    console.error('data.gov.in API error:', error.message);
    return null;
  }
}

async function scrapeAgmarknet(params = {}) {
  const { state, commodity, district } = params;
  
  try {
    const formData = new URLSearchParams();
    formData.append('Ession', 'Price');
    if (state) formData.append('state', state);
    if (commodity) formData.append('commodity', commodity);
    if (district) formData.append('District', district);

    const response = await axios.post(
      `${AGMARKNET_BASE_URL}/SearchCmmMkt.aspx`,
      formData,
      {
        timeout: 15000,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (compatible; KhetiSahayak/1.0)'
        }
      }
    );

    const $ = cheerio.load(response.data);
    const prices = [];

    $('table.mandi-table tr').each((index, row) => {
      if (index === 0) return;
      
      const cells = $(row).find('td');
      if (cells.length >= 7) {
        prices.push({
          state: $(cells[0]).text().trim(),
          district: $(cells[1]).text().trim(),
          market: $(cells[2]).text().trim(),
          commodity: $(cells[3]).text().trim(),
          variety: $(cells[4]).text().trim() || 'Other',
          min_price: parseFloat($(cells[5]).text().replace(/,/g, '')) || null,
          max_price: parseFloat($(cells[6]).text().replace(/,/g, '')) || null,
          modal_price: parseFloat($(cells[7]).text().replace(/,/g, '')) || null,
          arrival_date: new Date().toISOString().split('T')[0],
          source: 'Agmarknet'
        });
      }
    });

    return prices.length > 0 ? prices : null;
  } catch (error) {
    console.error('Agmarknet scraping error:', error.message);
    return null;
  }
}

function generateRealisticMockData(params = {}) {
  const { state = 'Maharashtra', commodity, district } = params;
  
  const basePrices = {
    'Rice': { base: 2800, variance: 400 },
    'Wheat': { base: 2400, variance: 300 },
    'Cotton': { base: 6500, variance: 800 },
    'Sugarcane': { base: 350, variance: 50 },
    'Tomato': { base: 2500, variance: 1000 },
    'Onion': { base: 1800, variance: 600 },
    'Potato': { base: 1500, variance: 400 },
    'Soybean': { base: 4500, variance: 500 },
    'Groundnut': { base: 5500, variance: 600 },
    'Maize': { base: 2000, variance: 300 },
    'Jowar': { base: 3200, variance: 400 },
    'Bajra': { base: 2500, variance: 350 },
    'Gram': { base: 5500, variance: 600 },
    'Tur': { base: 6500, variance: 700 },
    'Urad': { base: 7000, variance: 800 },
    'Moong': { base: 7500, variance: 900 },
    'Mustard': { base: 5200, variance: 500 },
    'Sunflower': { base: 6000, variance: 600 },
    'Chilli': { base: 15000, variance: 3000 },
    'Turmeric': { base: 8000, variance: 1500 }
  };

  const stateMarkets = {
    'Maharashtra': ['Nashik', 'Pune', 'Mumbai', 'Nagpur', 'Aurangabad', 'Kolhapur', 'Solapur'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Agra', 'Varanasi', 'Allahabad', 'Meerut'],
    'Punjab': ['Amritsar', 'Ludhiana', 'Jalandhar', 'Patiala', 'Bathinda'],
    'Haryana': ['Karnal', 'Hisar', 'Rohtak', 'Sirsa', 'Panipat'],
    'Madhya Pradesh': ['Indore', 'Bhopal', 'Jabalpur', 'Ujjain', 'Gwalior'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Bikaner'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Rajkot', 'Vadodara', 'Junagadh'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Belgaum', 'Davangere'],
    'Andhra Pradesh': ['Hyderabad', 'Vijayawada', 'Guntur', 'Kurnool', 'Warangal'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Trichy']
  };

  const markets = stateMarkets[state] || ['Main Market', 'Central APMC', 'Wholesale Market'];
  const commodities = commodity ? [commodity] : Object.keys(basePrices).slice(0, 10);
  const today = new Date().toISOString().split('T')[0];

  const results = [];

  for (const comm of commodities) {
    const priceInfo = basePrices[comm] || { base: 2000, variance: 300 };
    const filteredMarkets = district ? markets.filter(m => m.toLowerCase().includes(district.toLowerCase())) : markets;
    const marketsToUse = filteredMarkets.length > 0 ? filteredMarkets : markets.slice(0, 3);

    for (const market of marketsToUse) {
      const variance = Math.floor(Math.random() * priceInfo.variance);
      const direction = Math.random() > 0.5 ? 1 : -1;
      const modalPrice = priceInfo.base + (direction * variance);
      const minPrice = Math.floor(modalPrice * 0.9);
      const maxPrice = Math.floor(modalPrice * 1.1);

      results.push({
        id: `${state}-${market}-${comm}-${Date.now()}`,
        state: state,
        district: market,
        market: `${market} APMC`,
        commodity: comm,
        variety: 'Common',
        grade: 'FAQ',
        min_price: minPrice,
        max_price: maxPrice,
        modal_price: modalPrice,
        arrival_date: today,
        arrival_quantity: Math.floor(Math.random() * 500) + 50,
        source: 'Simulated Data'
      });
    }
  }

  return results;
}

async function getMandiPrices(params = {}) {
  const { state, commodity, district, market, forceRefresh = false } = params;
  
  const cacheKey = `mandi:prices:${state || 'all'}:${commodity || 'all'}:${district || 'all'}`;
  
  if (!forceRefresh) {
    try {
      const cached = await redisClient.get(cacheKey);
      if (cached) {
        console.log('Serving mandi prices from cache');
        return JSON.parse(cached);
      }
    } catch (err) {
      console.error('Redis cache error:', err.message);
    }
  }

  let prices = await fetchFromDataGovAPI({ state, commodity, limit: 200 });
  
  if (!prices || prices.length === 0) {
    prices = await scrapeAgmarknet({ state, commodity, district });
  }
  
  if (!prices || prices.length === 0) {
    console.log('Using mock data for mandi prices');
    prices = generateRealisticMockData({ state, commodity, district });
  }

  if (market) {
    prices = prices.filter(p => 
      p.market.toLowerCase().includes(market.toLowerCase())
    );
  }

  const result = {
    success: true,
    source: prices[0]?.source || 'Unknown',
    updated_at: new Date().toISOString(),
    count: prices.length,
    data: prices
  };

  try {
    await redisClient.setex(cacheKey, CACHE_TTL.REAL_TIME, JSON.stringify(result));
  } catch (err) {
    console.error('Redis cache set error:', err.message);
  }

  await storePriceHistory(prices);

  return result;
}

async function storePriceHistory(prices) {
  if (!prices || prices.length === 0) return;

  try {
    for (const price of prices.slice(0, 50)) {
      await db.query(
        `INSERT INTO mandi_price_history 
         (state, district, market, commodity, variety, grade, min_price, max_price, modal_price, arrival_date, arrival_quantity, source)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
         ON CONFLICT DO NOTHING`,
        [
          price.state, price.district, price.market, price.commodity,
          price.variety || 'Other', price.grade, price.min_price, price.max_price,
          price.modal_price, price.arrival_date, price.arrival_quantity, price.source
        ]
      );
    }
  } catch (err) {
    console.error('Error storing price history:', err.message);
  }
}

async function getPriceTrends(params = {}) {
  const { commodity, state, market, period = 'weekly' } = params;
  
  const cacheKey = `mandi:trends:${commodity}:${state || 'all'}:${period}`;
  
  try {
    const cached = await redisClient.get(cacheKey);
    if (cached) return JSON.parse(cached);
  } catch (err) {
    console.error('Redis cache error:', err.message);
  }

  const periodDays = {
    'daily': 7,
    'weekly': 30,
    'monthly': 90
  };

  const days = periodDays[period] || 30;

  let query = `
    SELECT 
      arrival_date,
      commodity,
      state,
      AVG(modal_price) as avg_price,
      MIN(min_price) as min_price,
      MAX(max_price) as max_price,
      COUNT(*) as market_count
    FROM mandi_price_history
    WHERE arrival_date >= CURRENT_DATE - INTERVAL '${days} days'
  `;

  const queryParams = [];
  let paramIndex = 1;

  if (commodity) {
    query += ` AND commodity = $${paramIndex}`;
    queryParams.push(commodity);
    paramIndex++;
  }

  if (state) {
    query += ` AND state = $${paramIndex}`;
    queryParams.push(state);
    paramIndex++;
  }

  if (market) {
    query += ` AND market ILIKE $${paramIndex}`;
    queryParams.push(`%${market}%`);
    paramIndex++;
  }

  query += ` GROUP BY arrival_date, commodity, state ORDER BY arrival_date ASC`;

  try {
    const result = await db.query(query, queryParams);
    
    const trends = result.rows.map(row => ({
      date: row.arrival_date,
      commodity: row.commodity,
      state: row.state,
      avg_price: parseFloat(row.avg_price).toFixed(2),
      min_price: parseFloat(row.min_price),
      max_price: parseFloat(row.max_price),
      market_count: parseInt(row.market_count)
    }));

    let priceChange = null;
    let priceChangePercent = null;

    if (trends.length >= 2) {
      const firstPrice = parseFloat(trends[0].avg_price);
      const lastPrice = parseFloat(trends[trends.length - 1].avg_price);
      priceChange = (lastPrice - firstPrice).toFixed(2);
      priceChangePercent = ((priceChange / firstPrice) * 100).toFixed(2);
    }

    const trendResult = {
      success: true,
      period,
      commodity: commodity || 'all',
      state: state || 'all',
      data_points: trends.length,
      price_change: priceChange ? parseFloat(priceChange) : null,
      price_change_percent: priceChangePercent ? parseFloat(priceChangePercent) : null,
      trends
    };

    try {
      const ttl = period === 'daily' ? CACHE_TTL.REAL_TIME : CACHE_TTL.DAILY;
      await redisClient.setex(cacheKey, ttl, JSON.stringify(trendResult));
    } catch (err) {
      console.error('Redis cache set error:', err.message);
    }

    return trendResult;
  } catch (err) {
    console.error('Error fetching price trends:', err.message);
    return {
      success: false,
      error: 'Failed to fetch price trends',
      trends: []
    };
  }
}

async function getMSPPrices(params = {}) {
  const { crop, year } = params;
  const currentYear = year || new Date().getFullYear();
  
  const cacheKey = `msp:${crop || 'all'}:${currentYear}`;
  
  try {
    const cached = await redisClient.get(cacheKey);
    if (cached) return JSON.parse(cached);
  } catch (err) {
    console.error('Redis cache error:', err.message);
  }

  let query = `
    SELECT * FROM msp_prices 
    WHERE year = $1
  `;
  const queryParams = [currentYear];

  if (crop) {
    query += ` AND crop_name ILIKE $2`;
    queryParams.push(`%${crop}%`);
  }

  query += ` ORDER BY crop_name`;

  try {
    const result = await db.query(query, queryParams);
    
    const mspResult = {
      success: true,
      year: currentYear,
      count: result.rows.length,
      data: result.rows
    };

    try {
      await redisClient.setex(cacheKey, CACHE_TTL.MSP, JSON.stringify(mspResult));
    } catch (err) {
      console.error('Redis cache set error:', err.message);
    }

    return mspResult;
  } catch (err) {
    console.error('Error fetching MSP prices:', err.message);
    return { success: false, error: 'Failed to fetch MSP prices', data: [] };
  }
}

async function comparePriceWithMSP(params = {}) {
  const { commodity, state, market } = params;
  
  if (!commodity) {
    return { success: false, error: 'Commodity is required' };
  }

  const currentYear = new Date().getFullYear();
  
  const [mspResult, mandiResult] = await Promise.all([
    getMSPPrices({ crop: commodity, year: currentYear }),
    getMandiPrices({ commodity, state, market })
  ]);

  const mspPrice = mspResult.data && mspResult.data[0]?.msp_price;
  
  if (!mspPrice) {
    return {
      success: true,
      commodity,
      msp_available: false,
      message: `MSP not available for ${commodity}`,
      current_prices: mandiResult.data
    };
  }

  const comparisons = mandiResult.data.map(price => {
    const modalPrice = price.modal_price || 0;
    const difference = modalPrice - mspPrice;
    const differencePercent = ((difference / mspPrice) * 100).toFixed(2);
    
    return {
      ...price,
      msp_price: parseFloat(mspPrice),
      price_vs_msp: parseFloat(difference.toFixed(2)),
      percent_vs_msp: parseFloat(differencePercent),
      status: modalPrice >= mspPrice ? 'ABOVE_MSP' : 'BELOW_MSP',
      recommendation: modalPrice < mspPrice 
        ? 'Consider government procurement centers for MSP'
        : 'Market price is favorable'
    };
  });

  const avgModalPrice = comparisons.reduce((sum, p) => sum + (p.modal_price || 0), 0) / comparisons.length;
  const avgVsMsp = ((avgModalPrice - mspPrice) / mspPrice * 100).toFixed(2);

  return {
    success: true,
    commodity,
    msp_available: true,
    msp_price: parseFloat(mspPrice),
    msp_year: currentYear,
    average_market_price: parseFloat(avgModalPrice.toFixed(2)),
    average_vs_msp_percent: parseFloat(avgVsMsp),
    overall_status: avgModalPrice >= mspPrice ? 'ABOVE_MSP' : 'BELOW_MSP',
    comparisons
  };
}

async function createPriceAlert(userId, alertData) {
  const {
    commodity,
    state,
    district,
    market,
    alert_type = 'threshold',
    threshold_price,
    threshold_direction = 'above',
    percentage_change,
    compare_to_msp = false,
    msp_threshold_percent = 100,
    notification_channels = ['push', 'in_app']
  } = alertData;

  if (!commodity) {
    return { success: false, error: 'Commodity is required' };
  }

  try {
    const result = await db.query(
      `INSERT INTO price_alert_subscriptions 
       (user_id, commodity, state, district, market, alert_type, threshold_price, 
        threshold_direction, percentage_change, compare_to_msp, msp_threshold_percent, notification_channels)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       RETURNING *`,
      [
        userId, commodity, state, district, market, alert_type, threshold_price,
        threshold_direction, percentage_change, compare_to_msp, msp_threshold_percent,
        JSON.stringify(notification_channels)
      ]
    );

    return {
      success: true,
      message: 'Price alert created successfully',
      data: result.rows[0]
    };
  } catch (err) {
    console.error('Error creating price alert:', err.message);
    return { success: false, error: 'Failed to create price alert' };
  }
}

async function getUserPriceAlerts(userId) {
  try {
    const result = await db.query(
      `SELECT * FROM price_alert_subscriptions 
       WHERE user_id = $1 
       ORDER BY created_at DESC`,
      [userId]
    );

    return {
      success: true,
      count: result.rows.length,
      data: result.rows
    };
  } catch (err) {
    console.error('Error fetching user price alerts:', err.message);
    return { success: false, error: 'Failed to fetch price alerts', data: [] };
  }
}

async function updatePriceAlert(userId, alertId, updateData) {
  const allowedFields = [
    'threshold_price', 'threshold_direction', 'percentage_change',
    'compare_to_msp', 'msp_threshold_percent', 'notification_channels', 'is_active'
  ];

  const updates = [];
  const values = [alertId, userId];
  let paramIndex = 3;

  for (const [key, value] of Object.entries(updateData)) {
    if (allowedFields.includes(key)) {
      updates.push(`${key} = $${paramIndex}`);
      values.push(key === 'notification_channels' ? JSON.stringify(value) : value);
      paramIndex++;
    }
  }

  if (updates.length === 0) {
    return { success: false, error: 'No valid fields to update' };
  }

  try {
    const result = await db.query(
      `UPDATE price_alert_subscriptions 
       SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
       WHERE id = $1 AND user_id = $2
       RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return { success: false, error: 'Alert not found or unauthorized' };
    }

    return { success: true, data: result.rows[0] };
  } catch (err) {
    console.error('Error updating price alert:', err.message);
    return { success: false, error: 'Failed to update price alert' };
  }
}

async function deletePriceAlert(userId, alertId) {
  try {
    const result = await db.query(
      `DELETE FROM price_alert_subscriptions 
       WHERE id = $1 AND user_id = $2
       RETURNING id`,
      [alertId, userId]
    );

    if (result.rows.length === 0) {
      return { success: false, error: 'Alert not found or unauthorized' };
    }

    return { success: true, message: 'Price alert deleted successfully' };
  } catch (err) {
    console.error('Error deleting price alert:', err.message);
    return { success: false, error: 'Failed to delete price alert' };
  }
}

async function getPriceAlertHistory(userId, params = {}) {
  const { page = 1, limit = 20, is_read } = params;
  const offset = (page - 1) * limit;

  let query = `
    SELECT * FROM price_alert_history 
    WHERE user_id = $1
  `;
  const queryParams = [userId];
  let paramIndex = 2;

  if (is_read !== undefined) {
    query += ` AND is_read = $${paramIndex}`;
    queryParams.push(is_read);
    paramIndex++;
  }

  query += ` ORDER BY triggered_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
  queryParams.push(limit, offset);

  try {
    const [alertsResult, countResult] = await Promise.all([
      db.query(query, queryParams),
      db.query(`SELECT COUNT(*) FROM price_alert_history WHERE user_id = $1`, [userId])
    ]);

    return {
      success: true,
      data: alertsResult.rows,
      pagination: {
        page,
        limit,
        total: parseInt(countResult.rows[0].count),
        total_pages: Math.ceil(countResult.rows[0].count / limit)
      }
    };
  } catch (err) {
    console.error('Error fetching price alert history:', err.message);
    return { success: false, error: 'Failed to fetch alert history', data: [] };
  }
}

async function checkAndTriggerAlerts() {
  try {
    const activeAlerts = await db.query(
      `SELECT * FROM price_alert_subscriptions WHERE is_active = true`
    );

    let triggeredCount = 0;

    for (const alert of activeAlerts.rows) {
      const prices = await getMandiPrices({
        commodity: alert.commodity,
        state: alert.state,
        market: alert.market
      });

      if (!prices.data || prices.data.length === 0) continue;

      const avgPrice = prices.data.reduce((sum, p) => sum + (p.modal_price || 0), 0) / prices.data.length;

      let shouldTrigger = false;
      let alertMessage = '';
      let alertMessageHi = '';

      if (alert.alert_type === 'threshold' && alert.threshold_price) {
        if (alert.threshold_direction === 'above' && avgPrice >= alert.threshold_price) {
          shouldTrigger = true;
          alertMessage = `${alert.commodity} price (Rs.${avgPrice.toFixed(0)}/q) has crossed above your threshold of Rs.${alert.threshold_price}/q`;
          alertMessageHi = `${SUPPORTED_COMMODITIES[alert.commodity]?.hindi || alert.commodity} का भाव (रु.${avgPrice.toFixed(0)}/क्विंटल) आपकी सीमा रु.${alert.threshold_price}/क्विंटल से ऊपर है`;
        } else if (alert.threshold_direction === 'below' && avgPrice <= alert.threshold_price) {
          shouldTrigger = true;
          alertMessage = `${alert.commodity} price (Rs.${avgPrice.toFixed(0)}/q) has dropped below your threshold of Rs.${alert.threshold_price}/q`;
          alertMessageHi = `${SUPPORTED_COMMODITIES[alert.commodity]?.hindi || alert.commodity} का भाव (रु.${avgPrice.toFixed(0)}/क्विंटल) आपकी सीमा रु.${alert.threshold_price}/क्विंटल से नीचे है`;
        }
      }

      if (alert.compare_to_msp) {
        const mspResult = await getMSPPrices({ crop: alert.commodity });
        const mspPrice = mspResult.data && mspResult.data[0]?.msp_price;
        
        if (mspPrice) {
          const mspThreshold = (mspPrice * alert.msp_threshold_percent) / 100;
          if (avgPrice < mspThreshold) {
            shouldTrigger = true;
            alertMessage = `${alert.commodity} price (Rs.${avgPrice.toFixed(0)}/q) is below ${alert.msp_threshold_percent}% of MSP (Rs.${mspPrice}/q)`;
            alertMessageHi = `${SUPPORTED_COMMODITIES[alert.commodity]?.hindi || alert.commodity} का भाव (रु.${avgPrice.toFixed(0)}/क्विंटल) MSP (रु.${mspPrice}/क्विंटल) के ${alert.msp_threshold_percent}% से कम है`;
          }
        }
      }

      if (shouldTrigger) {
        await db.query(
          `INSERT INTO price_alert_history 
           (subscription_id, user_id, commodity, alert_type, message, message_hi, current_price, threshold_price, market, state)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
          [
            alert.id, alert.user_id, alert.commodity, alert.alert_type,
            alertMessage, alertMessageHi, avgPrice, alert.threshold_price,
            alert.market, alert.state
          ]
        );

        await db.query(
          `UPDATE price_alert_subscriptions 
           SET last_triggered_at = CURRENT_TIMESTAMP, trigger_count = trigger_count + 1
           WHERE id = $1`,
          [alert.id]
        );

        triggeredCount++;
      }
    }

    return { success: true, triggered_count: triggeredCount };
  } catch (err) {
    console.error('Error checking price alerts:', err.message);
    return { success: false, error: err.message };
  }
}

function getStates() {
  return INDIAN_STATES;
}

function getSupportedCommodities() {
  return Object.entries(SUPPORTED_COMMODITIES).map(([name, info]) => ({
    name,
    name_hi: info.hindi,
    category: info.category
  }));
}

module.exports = {
  getMandiPrices,
  getPriceTrends,
  getMSPPrices,
  comparePriceWithMSP,
  createPriceAlert,
  getUserPriceAlerts,
  updatePriceAlert,
  deletePriceAlert,
  getPriceAlertHistory,
  checkAndTriggerAlerts,
  getStates,
  getSupportedCommodities,
  SUPPORTED_COMMODITIES
};

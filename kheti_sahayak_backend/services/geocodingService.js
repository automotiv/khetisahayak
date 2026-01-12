/**
 * Geocoding Service for Indian Villages
 * 
 * Provides geocoding (village name to coordinates) and reverse geocoding
 * (coordinates to location details) functionality using OpenStreetMap Nominatim API.
 * 
 * Features:
 * - Village/town/city search with India focus
 * - Reverse geocoding for precise location details
 * - Coordinate validation for Indian boundaries
 * - Caching for performance optimization
 * - Fallback to Open-Meteo geocoding API
 */

const axios = require('axios');
const redisClient = require('../redisClient');

// Constants
const NOMINATIM_BASE_URL = 'https://nominatim.openstreetmap.org';
const OPEN_METEO_GEOCODING_URL = 'https://geocoding-api.open-meteo.com/v1/search';
const USER_AGENT = 'KhetiSahayak/1.0 (Agricultural App for Indian Farmers)';

// Cache TTL in seconds
const CACHE_TTL = {
  GEOCODE: 7 * 24 * 60 * 60,      // 7 days - location data rarely changes
  REVERSE_GEOCODE: 7 * 24 * 60 * 60,
  VILLAGE_SEARCH: 24 * 60 * 60     // 1 day for search results
};

// India bounding box for validation
const INDIA_BOUNDS = {
  minLat: 6.5546079,    // Southern tip (Kanyakumari)
  maxLat: 35.6745457,   // Northern tip (Siachen)
  minLon: 68.1113787,   // Western tip (Gujarat)
  maxLon: 97.395561     // Eastern tip (Arunachal Pradesh)
};

// Indian states and their approximate center coordinates
const INDIAN_STATES = {
  'andhra pradesh': { lat: 15.9129, lon: 79.7400, code: 'AP' },
  'arunachal pradesh': { lat: 28.2180, lon: 94.7278, code: 'AR' },
  'assam': { lat: 26.2006, lon: 92.9376, code: 'AS' },
  'bihar': { lat: 25.0961, lon: 85.3131, code: 'BR' },
  'chhattisgarh': { lat: 21.2787, lon: 81.8661, code: 'CG' },
  'goa': { lat: 15.2993, lon: 74.1240, code: 'GA' },
  'gujarat': { lat: 22.2587, lon: 71.1924, code: 'GJ' },
  'haryana': { lat: 29.0588, lon: 76.0856, code: 'HR' },
  'himachal pradesh': { lat: 31.1048, lon: 77.1734, code: 'HP' },
  'jharkhand': { lat: 23.6102, lon: 85.2799, code: 'JH' },
  'karnataka': { lat: 15.3173, lon: 75.7139, code: 'KA' },
  'kerala': { lat: 10.8505, lon: 76.2711, code: 'KL' },
  'madhya pradesh': { lat: 22.9734, lon: 78.6569, code: 'MP' },
  'maharashtra': { lat: 19.7515, lon: 75.7139, code: 'MH' },
  'manipur': { lat: 24.6637, lon: 93.9063, code: 'MN' },
  'meghalaya': { lat: 25.4670, lon: 91.3662, code: 'ML' },
  'mizoram': { lat: 23.1645, lon: 92.9376, code: 'MZ' },
  'nagaland': { lat: 26.1584, lon: 94.5624, code: 'NL' },
  'odisha': { lat: 20.9517, lon: 85.0985, code: 'OR' },
  'punjab': { lat: 31.1471, lon: 75.3412, code: 'PB' },
  'rajasthan': { lat: 27.0238, lon: 74.2179, code: 'RJ' },
  'sikkim': { lat: 27.5330, lon: 88.5122, code: 'SK' },
  'tamil nadu': { lat: 11.1271, lon: 78.6569, code: 'TN' },
  'telangana': { lat: 18.1124, lon: 79.0193, code: 'TG' },
  'tripura': { lat: 23.9408, lon: 91.9882, code: 'TR' },
  'uttar pradesh': { lat: 26.8467, lon: 80.9462, code: 'UP' },
  'uttarakhand': { lat: 30.0668, lon: 79.0193, code: 'UK' },
  'west bengal': { lat: 22.9868, lon: 87.8550, code: 'WB' },
  'delhi': { lat: 28.7041, lon: 77.1025, code: 'DL' },
  'jammu and kashmir': { lat: 33.7782, lon: 76.5762, code: 'JK' },
  'ladakh': { lat: 34.1526, lon: 77.5771, code: 'LA' }
};

// Agricultural zones based on agro-climatic regions
const AGRO_CLIMATIC_ZONES = {
  'western_himalayan': {
    name: 'Western Himalayan Region',
    states: ['JK', 'HP', 'UK'],
    climate: 'Temperate to Alpine',
    majorCrops: ['apple', 'walnut', 'wheat', 'maize', 'rice']
  },
  'eastern_himalayan': {
    name: 'Eastern Himalayan Region',
    states: ['AR', 'SK', 'NL', 'MN', 'MZ', 'TR', 'ML'],
    climate: 'Sub-tropical to Temperate',
    majorCrops: ['rice', 'maize', 'potato', 'ginger', 'tea']
  },
  'lower_gangetic': {
    name: 'Lower Gangetic Plains',
    states: ['WB'],
    climate: 'Humid Sub-tropical',
    majorCrops: ['rice', 'jute', 'potato', 'vegetables']
  },
  'middle_gangetic': {
    name: 'Middle Gangetic Plains',
    states: ['UP', 'BR'],
    climate: 'Sub-tropical',
    majorCrops: ['rice', 'wheat', 'sugarcane', 'pulses']
  },
  'upper_gangetic': {
    name: 'Upper Gangetic Plains',
    states: ['UP'],
    climate: 'Semi-arid to Sub-tropical',
    majorCrops: ['wheat', 'sugarcane', 'rice', 'mustard']
  },
  'trans_gangetic': {
    name: 'Trans-Gangetic Plains',
    states: ['PB', 'HR', 'DL'],
    climate: 'Semi-arid',
    majorCrops: ['wheat', 'rice', 'cotton', 'sugarcane']
  },
  'eastern_plateau': {
    name: 'Eastern Plateau and Hills',
    states: ['MP', 'OR', 'JH', 'CG'],
    climate: 'Sub-humid',
    majorCrops: ['rice', 'groundnut', 'pulses', 'coarse cereals']
  },
  'central_plateau': {
    name: 'Central Plateau and Hills',
    states: ['MP', 'RJ', 'UP'],
    climate: 'Semi-arid',
    majorCrops: ['soybean', 'wheat', 'gram', 'pulses']
  },
  'western_plateau': {
    name: 'Western Plateau and Hills',
    states: ['MH'],
    climate: 'Semi-arid',
    majorCrops: ['cotton', 'soybean', 'sugarcane', 'pulses']
  },
  'southern_plateau': {
    name: 'Southern Plateau and Hills',
    states: ['TN', 'KA', 'AP', 'TG'],
    climate: 'Semi-arid',
    majorCrops: ['rice', 'groundnut', 'cotton', 'millets']
  },
  'east_coast': {
    name: 'East Coast Plains and Hills',
    states: ['TN', 'AP', 'OR'],
    climate: 'Humid to Sub-humid',
    majorCrops: ['rice', 'groundnut', 'sugarcane', 'coconut']
  },
  'west_coast': {
    name: 'West Coast Plains and Ghats',
    states: ['KL', 'GA', 'KA', 'MH'],
    climate: 'Humid',
    majorCrops: ['rice', 'coconut', 'spices', 'cashew']
  },
  'gujarat_plains': {
    name: 'Gujarat Plains and Hills',
    states: ['GJ'],
    climate: 'Arid to Semi-arid',
    majorCrops: ['cotton', 'groundnut', 'wheat', 'tobacco']
  },
  'western_dry': {
    name: 'Western Dry Region',
    states: ['RJ'],
    climate: 'Arid',
    majorCrops: ['bajra', 'pulses', 'sesame', 'guar']
  },
  'islands': {
    name: 'Islands Region',
    states: ['AN', 'LD'],
    climate: 'Tropical',
    majorCrops: ['coconut', 'paddy', 'arecanut', 'spices']
  }
};

/**
 * Validate if coordinates are within India
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @returns {boolean} True if coordinates are within India
 */
function isWithinIndia(lat, lon) {
  return (
    lat >= INDIA_BOUNDS.minLat &&
    lat <= INDIA_BOUNDS.maxLat &&
    lon >= INDIA_BOUNDS.minLon &&
    lon <= INDIA_BOUNDS.maxLon
  );
}

/**
 * Validate coordinates
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @returns {{ valid: boolean, error?: string }}
 */
function validateCoordinates(lat, lon) {
  if (typeof lat !== 'number' || typeof lon !== 'number') {
    return { valid: false, error: 'Coordinates must be numbers' };
  }
  
  if (isNaN(lat) || isNaN(lon)) {
    return { valid: false, error: 'Invalid coordinate values' };
  }
  
  if (lat < -90 || lat > 90) {
    return { valid: false, error: 'Latitude must be between -90 and 90' };
  }
  
  if (lon < -180 || lon > 180) {
    return { valid: false, error: 'Longitude must be between -180 and 180' };
  }
  
  return { valid: true };
}

/**
 * Search for villages/towns in India by name
 * @param {string} query - Village/town name to search
 * @param {Object} options - Search options
 * @param {string} options.state - State to narrow search
 * @param {string} options.district - District to narrow search
 * @param {number} options.limit - Max results (default: 10)
 * @returns {Promise<Array>} Array of location results
 */
async function searchVillage(query, options = {}) {
  const { state, district, limit = 10 } = options;
  
  if (!query || query.trim().length < 2) {
    throw new Error('Search query must be at least 2 characters');
  }
  
  const cacheKey = `village-search:${query.toLowerCase()}:${state || ''}:${district || ''}`;
  
  try {
    const cachedData = await redisClient.get(cacheKey);
    if (cachedData) {
      console.log(`Serving village search from cache: ${query}`);
      return JSON.parse(cachedData);
    }
  } catch (redisError) {
    console.warn('Redis error:', redisError.message);
  }
  
  let searchQuery = query;
  
  // Add state/district to search for better results
  if (district) {
    searchQuery = `${query}, ${district}`;
  }
  if (state) {
    searchQuery = `${searchQuery}, ${state}`;
  }
  searchQuery = `${searchQuery}, India`;
  
  try {
    // Try Nominatim first
    const nominatimResults = await searchWithNominatim(searchQuery, limit);
    
    if (nominatimResults.length > 0) {
      const results = nominatimResults.map(processNominatimResult);
      await cacheResults(cacheKey, results, CACHE_TTL.VILLAGE_SEARCH);
      return results;
    }
    
    // Fallback to Open-Meteo geocoding
    const openMeteoResults = await searchWithOpenMeteo(query, limit);
    
    if (openMeteoResults.length > 0) {
      const results = openMeteoResults.map(processOpenMeteoResult);
      await cacheResults(cacheKey, results, CACHE_TTL.VILLAGE_SEARCH);
      return results;
    }
    
    return [];
  } catch (error) {
    console.error('Village search error:', error.message);
    
    // Try fallback API
    try {
      const openMeteoResults = await searchWithOpenMeteo(query, limit);
      return openMeteoResults.map(processOpenMeteoResult);
    } catch (fallbackError) {
      console.error('Fallback geocoding error:', fallbackError.message);
      throw new Error('Unable to search for location');
    }
  }
}

/**
 * Search using Nominatim API
 */
async function searchWithNominatim(query, limit) {
  const response = await axios.get(`${NOMINATIM_BASE_URL}/search`, {
    params: {
      q: query,
      format: 'json',
      addressdetails: 1,
      limit: limit,
      countrycodes: 'in',
      'accept-language': 'en,hi'
    },
    headers: {
      'User-Agent': USER_AGENT
    },
    timeout: 10000
  });
  
  return response.data || [];
}

/**
 * Search using Open-Meteo Geocoding API (fallback)
 */
async function searchWithOpenMeteo(query, limit) {
  const response = await axios.get(OPEN_METEO_GEOCODING_URL, {
    params: {
      name: query,
      count: limit,
      language: 'en',
      format: 'json'
    },
    timeout: 10000
  });
  
  // Filter for India results
  const results = response.data?.results || [];
  return results.filter(r => r.country_code === 'IN');
}

/**
 * Process Nominatim result into standardized format
 */
function processNominatimResult(result) {
  const address = result.address || {};
  
  return {
    id: result.place_id,
    display_name: result.display_name,
    name: address.village || address.town || address.city || address.hamlet || result.name,
    type: result.type || 'unknown',
    latitude: parseFloat(result.lat),
    longitude: parseFloat(result.lon),
    address: {
      village: address.village || address.hamlet,
      town: address.town,
      city: address.city,
      district: address.county || address.state_district,
      state: address.state,
      state_code: getStateCode(address.state),
      country: 'India',
      postcode: address.postcode
    },
    bounding_box: result.boundingbox ? {
      south: parseFloat(result.boundingbox[0]),
      north: parseFloat(result.boundingbox[1]),
      west: parseFloat(result.boundingbox[2]),
      east: parseFloat(result.boundingbox[3])
    } : null,
    source: 'nominatim'
  };
}

/**
 * Process Open-Meteo result into standardized format
 */
function processOpenMeteoResult(result) {
  return {
    id: result.id,
    display_name: `${result.name}, ${result.admin1 || ''}, India`,
    name: result.name,
    type: result.feature_code || 'place',
    latitude: result.latitude,
    longitude: result.longitude,
    address: {
      village: null,
      town: null,
      city: result.name,
      district: result.admin2 || null,
      state: result.admin1 || null,
      state_code: getStateCode(result.admin1),
      country: 'India',
      postcode: null
    },
    population: result.population,
    elevation: result.elevation,
    timezone: result.timezone,
    source: 'open-meteo'
  };
}

/**
 * Get state code from state name
 */
function getStateCode(stateName) {
  if (!stateName) return null;
  const key = stateName.toLowerCase();
  return INDIAN_STATES[key]?.code || null;
}

/**
 * Reverse geocode coordinates to get location details
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @returns {Promise<Object>} Location details
 */
async function reverseGeocode(lat, lon) {
  const validation = validateCoordinates(lat, lon);
  if (!validation.valid) {
    throw new Error(validation.error);
  }
  
  const cacheKey = `reverse-geocode:${lat.toFixed(6)},${lon.toFixed(6)}`;
  
  try {
    const cachedData = await redisClient.get(cacheKey);
    if (cachedData) {
      console.log(`Serving reverse geocode from cache: ${lat}, ${lon}`);
      return JSON.parse(cachedData);
    }
  } catch (redisError) {
    console.warn('Redis error:', redisError.message);
  }
  
  try {
    const response = await axios.get(`${NOMINATIM_BASE_URL}/reverse`, {
      params: {
        lat: lat,
        lon: lon,
        format: 'json',
        addressdetails: 1,
        zoom: 18,
        'accept-language': 'en,hi'
      },
      headers: {
        'User-Agent': USER_AGENT
      },
      timeout: 10000
    });
    
    if (!response.data || response.data.error) {
      // Return basic info if reverse geocoding fails
      return {
        latitude: lat,
        longitude: lon,
        display_name: `${lat.toFixed(4)}, ${lon.toFixed(4)}`,
        is_within_india: isWithinIndia(lat, lon),
        source: 'coordinates_only'
      };
    }
    
    const address = response.data.address || {};
    
    const result = {
      latitude: lat,
      longitude: lon,
      display_name: response.data.display_name,
      name: address.village || address.town || address.city || address.hamlet,
      address: {
        village: address.village || address.hamlet,
        town: address.town,
        city: address.city,
        district: address.county || address.state_district,
        state: address.state,
        state_code: getStateCode(address.state),
        country: address.country || 'India',
        postcode: address.postcode
      },
      is_within_india: isWithinIndia(lat, lon),
      agro_climatic_zone: getAgroClimaticZone(lat, lon, getStateCode(address.state)),
      source: 'nominatim'
    };
    
    await cacheResults(cacheKey, result, CACHE_TTL.REVERSE_GEOCODE);
    return result;
  } catch (error) {
    console.error('Reverse geocoding error:', error.message);
    
    // Return basic info on error
    return {
      latitude: lat,
      longitude: lon,
      display_name: `${lat.toFixed(4)}, ${lon.toFixed(4)}`,
      is_within_india: isWithinIndia(lat, lon),
      source: 'coordinates_only',
      error: error.message
    };
  }
}

/**
 * Geocode a location string to coordinates
 * @param {string} locationString - Address or place name
 * @returns {Promise<Object>} Coordinates and location details
 */
async function geocode(locationString) {
  if (!locationString || locationString.trim().length < 2) {
    throw new Error('Location string must be at least 2 characters');
  }
  
  const cacheKey = `geocode:${locationString.toLowerCase().trim()}`;
  
  try {
    const cachedData = await redisClient.get(cacheKey);
    if (cachedData) {
      console.log(`Serving geocode from cache: ${locationString}`);
      return JSON.parse(cachedData);
    }
  } catch (redisError) {
    console.warn('Redis error:', redisError.message);
  }
  
  // Add India to search for better results
  const searchQuery = locationString.toLowerCase().includes('india')
    ? locationString
    : `${locationString}, India`;
  
  try {
    const results = await searchWithNominatim(searchQuery, 1);
    
    if (results.length > 0) {
      const result = processNominatimResult(results[0]);
      await cacheResults(cacheKey, result, CACHE_TTL.GEOCODE);
      return result;
    }
    
    // Fallback to Open-Meteo
    const omResults = await searchWithOpenMeteo(locationString, 1);
    
    if (omResults.length > 0) {
      const result = processOpenMeteoResult(omResults[0]);
      await cacheResults(cacheKey, result, CACHE_TTL.GEOCODE);
      return result;
    }
    
    throw new Error('Location not found');
  } catch (error) {
    console.error('Geocoding error:', error.message);
    throw error;
  }
}

/**
 * Get agro-climatic zone for a location
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @param {string} stateCode - State code
 * @returns {Object|null} Agro-climatic zone info
 */
function getAgroClimaticZone(lat, lon, stateCode) {
  if (!stateCode) {
    // Try to determine based on coordinates
    for (const [key, zone] of Object.entries(AGRO_CLIMATIC_ZONES)) {
      // Simplified zone detection - in production, use proper GIS boundaries
      if (zone.states.some(s => {
        const stateInfo = Object.values(INDIAN_STATES).find(st => st.code === s);
        if (stateInfo) {
          const latDiff = Math.abs(lat - stateInfo.lat);
          const lonDiff = Math.abs(lon - stateInfo.lon);
          return latDiff < 3 && lonDiff < 4;
        }
        return false;
      })) {
        return { key, ...zone };
      }
    }
    return null;
  }
  
  // Find zone by state code
  for (const [key, zone] of Object.entries(AGRO_CLIMATIC_ZONES)) {
    if (zone.states.includes(stateCode)) {
      return { key, ...zone };
    }
  }
  
  return null;
}

/**
 * Get nearby villages within a radius
 * @param {number} lat - Center latitude
 * @param {number} lon - Center longitude
 * @param {number} radiusKm - Search radius in kilometers
 * @param {number} limit - Max results
 * @returns {Promise<Array>} Array of nearby locations
 */
async function getNearbyVillages(lat, lon, radiusKm = 10, limit = 10) {
  const validation = validateCoordinates(lat, lon);
  if (!validation.valid) {
    throw new Error(validation.error);
  }
  
  try {
    // Calculate bounding box for radius
    const latDelta = radiusKm / 111;
    const lonDelta = radiusKm / (111 * Math.cos(lat * Math.PI / 180));
    
    const viewbox = [
      lon - lonDelta,
      lat - latDelta,
      lon + lonDelta,
      lat + latDelta
    ].join(',');
    
    const response = await axios.get(`${NOMINATIM_BASE_URL}/search`, {
      params: {
        q: 'village',
        format: 'json',
        addressdetails: 1,
        limit: limit,
        countrycodes: 'in',
        viewbox: viewbox,
        bounded: 1,
        'accept-language': 'en,hi'
      },
      headers: {
        'User-Agent': USER_AGENT
      },
      timeout: 10000
    });
    
    const results = (response.data || [])
      .map(processNominatimResult)
      .map(r => ({
        ...r,
        distance_km: calculateDistance(lat, lon, r.latitude, r.longitude)
      }))
      .sort((a, b) => a.distance_km - b.distance_km);
    
    return results;
  } catch (error) {
    console.error('Nearby villages error:', error.message);
    return [];
  }
}

/**
 * Calculate distance between two coordinates using Haversine formula
 * @param {number} lat1 - First latitude
 * @param {number} lon1 - First longitude
 * @param {number} lat2 - Second latitude
 * @param {number} lon2 - Second longitude
 * @returns {number} Distance in kilometers
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return parseFloat((R * c).toFixed(2));
}

/**
 * Cache results in Redis
 */
async function cacheResults(key, data, ttl) {
  try {
    await redisClient.setex(key, ttl, JSON.stringify(data));
    console.log(`Cached geocoding result: ${key}`);
  } catch (error) {
    console.warn('Cache set error:', error.message);
  }
}

/**
 * Get state information
 * @param {string} stateNameOrCode - State name or code
 * @returns {Object|null} State information
 */
function getStateInfo(stateNameOrCode) {
  if (!stateNameOrCode) return null;
  
  const key = stateNameOrCode.toLowerCase();
  
  // Check by name
  if (INDIAN_STATES[key]) {
    return { name: stateNameOrCode, ...INDIAN_STATES[key] };
  }
  
  // Check by code
  const entry = Object.entries(INDIAN_STATES).find(
    ([, value]) => value.code.toLowerCase() === key
  );
  
  if (entry) {
    return { name: entry[0], ...entry[1] };
  }
  
  return null;
}

module.exports = {
  searchVillage,
  reverseGeocode,
  geocode,
  getAgroClimaticZone,
  getNearbyVillages,
  validateCoordinates,
  isWithinIndia,
  calculateDistance,
  getStateInfo,
  INDIAN_STATES,
  AGRO_CLIMATIC_ZONES,
  INDIA_BOUNDS
};

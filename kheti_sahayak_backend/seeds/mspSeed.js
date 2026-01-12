const db = require('../db');

const MSP_DATA_2024_25 = [
  { crop_name: 'Paddy', crop_name_hi: 'धान (सामान्य)', variety: 'Common', season: 'Kharif', msp_price: 2300, year: 2024 },
  { crop_name: 'Paddy', crop_name_hi: 'धान (ग्रेड A)', variety: 'Grade A', season: 'Kharif', msp_price: 2320, year: 2024 },
  { crop_name: 'Rice', crop_name_hi: 'चावल', variety: 'Common', season: 'Kharif', msp_price: 2300, year: 2024 },
  { crop_name: 'Jowar', crop_name_hi: 'ज्वार (हाइब्रिड)', variety: 'Hybrid', season: 'Kharif', msp_price: 3180, year: 2024 },
  { crop_name: 'Jowar', crop_name_hi: 'ज्वार (मालदंडी)', variety: 'Maldandi', season: 'Kharif', msp_price: 3225, year: 2024 },
  { crop_name: 'Bajra', crop_name_hi: 'बाजरा', variety: 'Common', season: 'Kharif', msp_price: 2625, year: 2024 },
  { crop_name: 'Maize', crop_name_hi: 'मक्का', variety: 'Common', season: 'Kharif', msp_price: 2225, year: 2024 },
  { crop_name: 'Ragi', crop_name_hi: 'रागी', variety: 'Common', season: 'Kharif', msp_price: 4290, year: 2024 },
  { crop_name: 'Tur', crop_name_hi: 'अरहर (तूर)', variety: 'Common', season: 'Kharif', msp_price: 7550, year: 2024 },
  { crop_name: 'Moong', crop_name_hi: 'मूंग', variety: 'Common', season: 'Kharif', msp_price: 8682, year: 2024 },
  { crop_name: 'Urad', crop_name_hi: 'उड़द', variety: 'Common', season: 'Kharif', msp_price: 7400, year: 2024 },
  { crop_name: 'Groundnut', crop_name_hi: 'मूंगफली', variety: 'Common', season: 'Kharif', msp_price: 6783, year: 2024 },
  { crop_name: 'Sunflower', crop_name_hi: 'सूरजमुखी', variety: 'Common', season: 'Kharif', msp_price: 7280, year: 2024 },
  { crop_name: 'Soybean', crop_name_hi: 'सोयाबीन (पीला)', variety: 'Yellow', season: 'Kharif', msp_price: 4892, year: 2024 },
  { crop_name: 'Sesamum', crop_name_hi: 'तिल', variety: 'Common', season: 'Kharif', msp_price: 9267, year: 2024 },
  { crop_name: 'Nigerseed', crop_name_hi: 'रामतिल', variety: 'Common', season: 'Kharif', msp_price: 8717, year: 2024 },
  { crop_name: 'Cotton', crop_name_hi: 'कपास (मध्यम रेशा)', variety: 'Medium Staple', season: 'Kharif', msp_price: 7121, year: 2024 },
  { crop_name: 'Cotton', crop_name_hi: 'कपास (लंबा रेशा)', variety: 'Long Staple', season: 'Kharif', msp_price: 7521, year: 2024 },

  { crop_name: 'Wheat', crop_name_hi: 'गेहूं', variety: 'Common', season: 'Rabi', msp_price: 2275, year: 2024 },
  { crop_name: 'Barley', crop_name_hi: 'जौ', variety: 'Common', season: 'Rabi', msp_price: 1850, year: 2024 },
  { crop_name: 'Gram', crop_name_hi: 'चना', variety: 'Common', season: 'Rabi', msp_price: 5440, year: 2024 },
  { crop_name: 'Masoor', crop_name_hi: 'मसूर', variety: 'Common', season: 'Rabi', msp_price: 6425, year: 2024 },
  { crop_name: 'Mustard', crop_name_hi: 'सरसों/राई', variety: 'Common', season: 'Rabi', msp_price: 5650, year: 2024 },
  { crop_name: 'Safflower', crop_name_hi: 'कुसुम', variety: 'Common', season: 'Rabi', msp_price: 5800, year: 2024 },
  
  { crop_name: 'Sugarcane', crop_name_hi: 'गन्ना', variety: 'FRP', season: 'Year-round', msp_price: 340, year: 2024 },
  
  { crop_name: 'Jute', crop_name_hi: 'जूट', variety: 'Common', season: 'Kharif', msp_price: 5335, year: 2024 },
  { crop_name: 'Copra', crop_name_hi: 'खोपरा (मिलिंग)', variety: 'Milling', season: 'Year-round', msp_price: 11582, year: 2024 },
  { crop_name: 'Copra', crop_name_hi: 'खोपरा (बॉल)', variety: 'Ball', season: 'Year-round', msp_price: 12100, year: 2024 }
];

const MSP_DATA_2025_26 = [
  { crop_name: 'Paddy', crop_name_hi: 'धान (सामान्य)', variety: 'Common', season: 'Kharif', msp_price: 2400, year: 2025 },
  { crop_name: 'Paddy', crop_name_hi: 'धान (ग्रेड A)', variety: 'Grade A', season: 'Kharif', msp_price: 2420, year: 2025 },
  { crop_name: 'Rice', crop_name_hi: 'चावल', variety: 'Common', season: 'Kharif', msp_price: 2400, year: 2025 },
  { crop_name: 'Jowar', crop_name_hi: 'ज्वार (हाइब्रिड)', variety: 'Hybrid', season: 'Kharif', msp_price: 3300, year: 2025 },
  { crop_name: 'Jowar', crop_name_hi: 'ज्वार (मालदंडी)', variety: 'Maldandi', season: 'Kharif', msp_price: 3350, year: 2025 },
  { crop_name: 'Bajra', crop_name_hi: 'बाजरा', variety: 'Common', season: 'Kharif', msp_price: 2725, year: 2025 },
  { crop_name: 'Maize', crop_name_hi: 'मक्का', variety: 'Common', season: 'Kharif', msp_price: 2325, year: 2025 },
  { crop_name: 'Ragi', crop_name_hi: 'रागी', variety: 'Common', season: 'Kharif', msp_price: 4450, year: 2025 },
  { crop_name: 'Tur', crop_name_hi: 'अरहर (तूर)', variety: 'Common', season: 'Kharif', msp_price: 7800, year: 2025 },
  { crop_name: 'Moong', crop_name_hi: 'मूंग', variety: 'Common', season: 'Kharif', msp_price: 9000, year: 2025 },
  { crop_name: 'Urad', crop_name_hi: 'उड़द', variety: 'Common', season: 'Kharif', msp_price: 7650, year: 2025 },
  { crop_name: 'Groundnut', crop_name_hi: 'मूंगफली', variety: 'Common', season: 'Kharif', msp_price: 7050, year: 2025 },
  { crop_name: 'Sunflower', crop_name_hi: 'सूरजमुखी', variety: 'Common', season: 'Kharif', msp_price: 7550, year: 2025 },
  { crop_name: 'Soybean', crop_name_hi: 'सोयाबीन (पीला)', variety: 'Yellow', season: 'Kharif', msp_price: 5100, year: 2025 },
  { crop_name: 'Sesamum', crop_name_hi: 'तिल', variety: 'Common', season: 'Kharif', msp_price: 9600, year: 2025 },
  { crop_name: 'Nigerseed', crop_name_hi: 'रामतिल', variety: 'Common', season: 'Kharif', msp_price: 9050, year: 2025 },
  { crop_name: 'Cotton', crop_name_hi: 'कपास (मध्यम रेशा)', variety: 'Medium Staple', season: 'Kharif', msp_price: 7400, year: 2025 },
  { crop_name: 'Cotton', crop_name_hi: 'कपास (लंबा रेशा)', variety: 'Long Staple', season: 'Kharif', msp_price: 7800, year: 2025 },
  
  { crop_name: 'Wheat', crop_name_hi: 'गेहूं', variety: 'Common', season: 'Rabi', msp_price: 2375, year: 2025 },
  { crop_name: 'Barley', crop_name_hi: 'जौ', variety: 'Common', season: 'Rabi', msp_price: 1950, year: 2025 },
  { crop_name: 'Gram', crop_name_hi: 'चना', variety: 'Common', season: 'Rabi', msp_price: 5650, year: 2025 },
  { crop_name: 'Masoor', crop_name_hi: 'मसूर', variety: 'Common', season: 'Rabi', msp_price: 6700, year: 2025 },
  { crop_name: 'Mustard', crop_name_hi: 'सरसों/राई', variety: 'Common', season: 'Rabi', msp_price: 5900, year: 2025 },
  { crop_name: 'Safflower', crop_name_hi: 'कुसुम', variety: 'Common', season: 'Rabi', msp_price: 6050, year: 2025 },
  
  { crop_name: 'Sugarcane', crop_name_hi: 'गन्ना', variety: 'FRP', season: 'Year-round', msp_price: 355, year: 2025 },
  
  { crop_name: 'Jute', crop_name_hi: 'जूट', variety: 'Common', season: 'Kharif', msp_price: 5550, year: 2025 },
  { crop_name: 'Copra', crop_name_hi: 'खोपरा (मिलिंग)', variety: 'Milling', season: 'Year-round', msp_price: 12000, year: 2025 },
  { crop_name: 'Copra', crop_name_hi: 'खोपरा (बॉल)', variety: 'Ball', season: 'Year-round', msp_price: 12550, year: 2025 },

  { crop_name: 'Tomato', crop_name_hi: 'टमाटर', variety: 'Common', season: 'Year-round', msp_price: null, year: 2025 },
  { crop_name: 'Onion', crop_name_hi: 'प्याज', variety: 'Common', season: 'Year-round', msp_price: null, year: 2025 },
  { crop_name: 'Potato', crop_name_hi: 'आलू', variety: 'Common', season: 'Year-round', msp_price: null, year: 2025 }
];

const MSP_DATA_2026 = [
  { crop_name: 'Paddy', crop_name_hi: 'धान (सामान्य)', variety: 'Common', season: 'Kharif', msp_price: 2500, year: 2026 },
  { crop_name: 'Paddy', crop_name_hi: 'धान (ग्रेड A)', variety: 'Grade A', season: 'Kharif', msp_price: 2520, year: 2026 },
  { crop_name: 'Rice', crop_name_hi: 'चावल', variety: 'Common', season: 'Kharif', msp_price: 2500, year: 2026 },
  { crop_name: 'Jowar', crop_name_hi: 'ज्वार (हाइब्रिड)', variety: 'Hybrid', season: 'Kharif', msp_price: 3420, year: 2026 },
  { crop_name: 'Jowar', crop_name_hi: 'ज्वार (मालदंडी)', variety: 'Maldandi', season: 'Kharif', msp_price: 3475, year: 2026 },
  { crop_name: 'Bajra', crop_name_hi: 'बाजरा', variety: 'Common', season: 'Kharif', msp_price: 2825, year: 2026 },
  { crop_name: 'Maize', crop_name_hi: 'मक्का', variety: 'Common', season: 'Kharif', msp_price: 2425, year: 2026 },
  { crop_name: 'Ragi', crop_name_hi: 'रागी', variety: 'Common', season: 'Kharif', msp_price: 4620, year: 2026 },
  { crop_name: 'Tur', crop_name_hi: 'अरहर (तूर)', variety: 'Common', season: 'Kharif', msp_price: 8050, year: 2026 },
  { crop_name: 'Moong', crop_name_hi: 'मूंग', variety: 'Common', season: 'Kharif', msp_price: 9350, year: 2026 },
  { crop_name: 'Urad', crop_name_hi: 'उड़द', variety: 'Common', season: 'Kharif', msp_price: 7920, year: 2026 },
  { crop_name: 'Groundnut', crop_name_hi: 'मूंगफली', variety: 'Common', season: 'Kharif', msp_price: 7320, year: 2026 },
  { crop_name: 'Sunflower', crop_name_hi: 'सूरजमुखी', variety: 'Common', season: 'Kharif', msp_price: 7830, year: 2026 },
  { crop_name: 'Soybean', crop_name_hi: 'सोयाबीन (पीला)', variety: 'Yellow', season: 'Kharif', msp_price: 5300, year: 2026 },
  { crop_name: 'Sesamum', crop_name_hi: 'तिल', variety: 'Common', season: 'Kharif', msp_price: 9950, year: 2026 },
  { crop_name: 'Nigerseed', crop_name_hi: 'रामतिल', variety: 'Common', season: 'Kharif', msp_price: 9400, year: 2026 },
  { crop_name: 'Cotton', crop_name_hi: 'कपास (मध्यम रेशा)', variety: 'Medium Staple', season: 'Kharif', msp_price: 7680, year: 2026 },
  { crop_name: 'Cotton', crop_name_hi: 'कपास (लंबा रेशा)', variety: 'Long Staple', season: 'Kharif', msp_price: 8100, year: 2026 },
  
  { crop_name: 'Wheat', crop_name_hi: 'गेहूं', variety: 'Common', season: 'Rabi', msp_price: 2475, year: 2026 },
  { crop_name: 'Barley', crop_name_hi: 'जौ', variety: 'Common', season: 'Rabi', msp_price: 2050, year: 2026 },
  { crop_name: 'Gram', crop_name_hi: 'चना', variety: 'Common', season: 'Rabi', msp_price: 5870, year: 2026 },
  { crop_name: 'Masoor', crop_name_hi: 'मसूर', variety: 'Common', season: 'Rabi', msp_price: 6980, year: 2026 },
  { crop_name: 'Mustard', crop_name_hi: 'सरसों/राई', variety: 'Common', season: 'Rabi', msp_price: 6150, year: 2026 },
  { crop_name: 'Safflower', crop_name_hi: 'कुसुम', variety: 'Common', season: 'Rabi', msp_price: 6300, year: 2026 },
  
  { crop_name: 'Sugarcane', crop_name_hi: 'गन्ना', variety: 'FRP', season: 'Year-round', msp_price: 370, year: 2026 },
  
  { crop_name: 'Jute', crop_name_hi: 'जूट', variety: 'Common', season: 'Kharif', msp_price: 5770, year: 2026 },
  { crop_name: 'Copra', crop_name_hi: 'खोपरा (मिलिंग)', variety: 'Milling', season: 'Year-round', msp_price: 12450, year: 2026 },
  { crop_name: 'Copra', crop_name_hi: 'खोपरा (बॉल)', variety: 'Ball', season: 'Year-round', msp_price: 13000, year: 2026 }
];

const MAJOR_MARKETS = [
  { state: 'Maharashtra', state_code: 'MH', district: 'Nashik', market_name: 'Nashik APMC', market_type: 'APMC', latitude: 19.9975, longitude: 73.7898 },
  { state: 'Maharashtra', state_code: 'MH', district: 'Pune', market_name: 'Pune Market Yard', market_type: 'APMC', latitude: 18.5204, longitude: 73.8567 },
  { state: 'Maharashtra', state_code: 'MH', district: 'Mumbai', market_name: 'Vashi APMC', market_type: 'APMC', latitude: 19.0760, longitude: 72.9987 },
  { state: 'Maharashtra', state_code: 'MH', district: 'Nagpur', market_name: 'Nagpur APMC', market_type: 'APMC', latitude: 21.1458, longitude: 79.0882 },
  { state: 'Maharashtra', state_code: 'MH', district: 'Aurangabad', market_name: 'Aurangabad APMC', market_type: 'APMC', latitude: 19.8762, longitude: 75.3433 },
  
  { state: 'Uttar Pradesh', state_code: 'UP', district: 'Lucknow', market_name: 'Lucknow Mandi', market_type: 'APMC', latitude: 26.8467, longitude: 80.9462 },
  { state: 'Uttar Pradesh', state_code: 'UP', district: 'Kanpur', market_name: 'Kanpur Mandi', market_type: 'APMC', latitude: 26.4499, longitude: 80.3319 },
  { state: 'Uttar Pradesh', state_code: 'UP', district: 'Agra', market_name: 'Agra Mandi', market_type: 'APMC', latitude: 27.1767, longitude: 78.0081 },
  
  { state: 'Punjab', state_code: 'PB', district: 'Amritsar', market_name: 'Amritsar Grain Market', market_type: 'APMC', latitude: 31.6340, longitude: 74.8723 },
  { state: 'Punjab', state_code: 'PB', district: 'Ludhiana', market_name: 'Ludhiana Mandi', market_type: 'APMC', latitude: 30.9010, longitude: 75.8573 },
  { state: 'Punjab', state_code: 'PB', district: 'Jalandhar', market_name: 'Jalandhar Grain Market', market_type: 'APMC', latitude: 31.3260, longitude: 75.5762 },
  
  { state: 'Haryana', state_code: 'HR', district: 'Karnal', market_name: 'Karnal Grain Market', market_type: 'APMC', latitude: 29.6857, longitude: 76.9905 },
  { state: 'Haryana', state_code: 'HR', district: 'Hisar', market_name: 'Hisar Mandi', market_type: 'APMC', latitude: 29.1492, longitude: 75.7217 },
  
  { state: 'Madhya Pradesh', state_code: 'MP', district: 'Indore', market_name: 'Indore Mandi', market_type: 'APMC', latitude: 22.7196, longitude: 75.8577 },
  { state: 'Madhya Pradesh', state_code: 'MP', district: 'Bhopal', market_name: 'Bhopal Mandi', market_type: 'APMC', latitude: 23.2599, longitude: 77.4126 },
  
  { state: 'Rajasthan', state_code: 'RJ', district: 'Jaipur', market_name: 'Jaipur Mandi', market_type: 'APMC', latitude: 26.9124, longitude: 75.7873 },
  { state: 'Rajasthan', state_code: 'RJ', district: 'Kota', market_name: 'Kota Mandi', market_type: 'APMC', latitude: 25.2138, longitude: 75.8648 },
  
  { state: 'Gujarat', state_code: 'GJ', district: 'Ahmedabad', market_name: 'Ahmedabad APMC', market_type: 'APMC', latitude: 23.0225, longitude: 72.5714 },
  { state: 'Gujarat', state_code: 'GJ', district: 'Rajkot', market_name: 'Rajkot Mandi', market_type: 'APMC', latitude: 22.3039, longitude: 70.8022 },
  
  { state: 'Karnataka', state_code: 'KA', district: 'Bangalore', market_name: 'Bangalore APMC', market_type: 'APMC', latitude: 12.9716, longitude: 77.5946 },
  { state: 'Karnataka', state_code: 'KA', district: 'Hubli', market_name: 'Hubli Mandi', market_type: 'APMC', latitude: 15.3647, longitude: 75.1240 },
  
  { state: 'Andhra Pradesh', state_code: 'AP', district: 'Guntur', market_name: 'Guntur Mirchi Yard', market_type: 'APMC', latitude: 16.3067, longitude: 80.4365 },
  { state: 'Andhra Pradesh', state_code: 'AP', district: 'Vijayawada', market_name: 'Vijayawada Mandi', market_type: 'APMC', latitude: 16.5062, longitude: 80.6480 },
  
  { state: 'Tamil Nadu', state_code: 'TN', district: 'Chennai', market_name: 'Koyambedu Market', market_type: 'APMC', latitude: 13.0710, longitude: 80.1955 },
  { state: 'Tamil Nadu', state_code: 'TN', district: 'Coimbatore', market_name: 'Coimbatore Mandi', market_type: 'APMC', latitude: 11.0168, longitude: 76.9558 }
];

async function seedMSPData() {
  console.log('Seeding MSP data...');
  
  const allMSPData = [...MSP_DATA_2024_25, ...MSP_DATA_2025_26, ...MSP_DATA_2026];
  
  for (const msp of allMSPData) {
    if (msp.msp_price === null) continue;
    
    try {
      await db.query(
        `INSERT INTO msp_prices (crop_name, crop_name_hi, variety, season, year, msp_price, effective_date, source)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (crop_name, year, variety) DO UPDATE SET
         msp_price = EXCLUDED.msp_price,
         crop_name_hi = EXCLUDED.crop_name_hi,
         season = EXCLUDED.season`,
        [
          msp.crop_name,
          msp.crop_name_hi,
          msp.variety,
          msp.season,
          msp.year,
          msp.msp_price,
          `${msp.year}-04-01`,
          'Ministry of Agriculture & Farmers Welfare'
        ]
      );
    } catch (err) {
      console.error(`Error inserting MSP for ${msp.crop_name} ${msp.year}:`, err.message);
    }
  }
  
  console.log(`MSP data seeded: ${allMSPData.filter(m => m.msp_price !== null).length} records`);
}

async function seedMandiMarkets() {
  console.log('Seeding mandi market data...');
  
  for (const market of MAJOR_MARKETS) {
    try {
      await db.query(
        `INSERT INTO mandi_markets (state, state_code, district, market_name, market_type, latitude, longitude)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (state, district, market_name) DO UPDATE SET
         latitude = EXCLUDED.latitude,
         longitude = EXCLUDED.longitude`,
        [
          market.state,
          market.state_code,
          market.district,
          market.market_name,
          market.market_type,
          market.latitude,
          market.longitude
        ]
      );
    } catch (err) {
      console.error(`Error inserting market ${market.market_name}:`, err.message);
    }
  }
  
  console.log(`Mandi markets seeded: ${MAJOR_MARKETS.length} markets`);
}

async function seedAllMandiData() {
  try {
    await seedMSPData();
    await seedMandiMarkets();
    console.log('All mandi-related data seeded successfully!');
  } catch (err) {
    console.error('Error seeding mandi data:', err.message);
  }
}

module.exports = {
  seedMSPData,
  seedMandiMarkets,
  seedAllMandiData
};

const db = require('./db');

const seedCropRecommendations = async () => {
  const cropData = [
    {
      crop_name: 'Tomatoes',
      season: 'summer',
      soil_type: 'loamy',
      climate_zone: 'temperate',
      water_requirement: 'moderate',
      growth_duration: 80,
      yield_per_hectare: 25.0,
      market_price_range: { min: 2.5, max: 4.0 },
      description: 'Warm-season crop requiring full sun and well-drained soil. Susceptible to various diseases including blight and wilt.'
    },
    {
      crop_name: 'Potatoes',
      season: 'spring',
      soil_type: 'sandy loam',
      climate_zone: 'temperate',
      water_requirement: 'moderate',
      growth_duration: 100,
      yield_per_hectare: 30.0,
      market_price_range: { min: 1.5, max: 2.5 },
      description: 'Cool-season crop that grows best in loose, well-drained soil. Important to rotate with other crops to prevent disease.'
    },
    {
      crop_name: 'Corn',
      season: 'summer',
      soil_type: 'clay loam',
      climate_zone: 'temperate',
      water_requirement: 'high',
      growth_duration: 90,
      yield_per_hectare: 8.5,
      market_price_range: { min: 3.0, max: 5.0 },
      description: 'Warm-season crop requiring rich soil and consistent moisture. Heavy feeder that benefits from nitrogen-rich amendments.'
    },
    {
      crop_name: 'Wheat',
      season: 'winter',
      soil_type: 'clay',
      climate_zone: 'temperate',
      water_requirement: 'low',
      growth_duration: 240,
      yield_per_hectare: 4.0,
      market_price_range: { min: 5.0, max: 7.0 },
      description: 'Cool-season grain crop that overwinters. Tolerant of various soil types but prefers well-drained conditions.'
    },
    {
      crop_name: 'Soybeans',
      season: 'summer',
      soil_type: 'loamy',
      climate_zone: 'temperate',
      water_requirement: 'moderate',
      growth_duration: 120,
      yield_per_hectare: 3.0,
      market_price_range: { min: 8.0, max: 12.0 },
      description: 'Warm-season legume that fixes nitrogen in soil. Good rotation crop and valuable for both human and animal consumption.'
    }
  ];

  for (const crop of cropData) {
    await db.query(
      `INSERT INTO crop_recommendations (
        crop_name, season, soil_type, climate_zone, water_requirement, 
        growth_duration, yield_per_hectare, market_price_range, description
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [
        crop.crop_name,
        crop.season,
        crop.soil_type,
        crop.climate_zone,
        crop.water_requirement,
        crop.growth_duration,
        crop.yield_per_hectare,
        JSON.stringify(crop.market_price_range),
        crop.description
      ]
    );
  }

  console.log('Crop recommendations seeded successfully');
};

seedCropRecommendations().catch(console.error); 
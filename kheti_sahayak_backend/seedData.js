const bcrypt = require('bcryptjs');
const db = require('./db');
const { Pool } = require('pg');

console.log('Connecting to database:', process.env.DB_NAME);

const debugPool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function debugAndSeed() {
  const columns = await debugPool.query(`SELECT column_name FROM information_schema.columns WHERE table_name = 'users' ORDER BY ordinal_position`);
  console.log('Columns in users table:', columns.rows.map(r => r.column_name));
  await debugPool.end();
  await seedData();
}

const seedData = async () => {
  try {
    console.log('🌱 Starting database seeding...');

    // Create admin user
    const adminPassword = await bcrypt.hash('admin123', 10);
    const adminResult = await db.query(
      `INSERT INTO users (username, email, password_hash, first_name, last_name, role, is_verified)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (email) DO NOTHING
       RETURNING id`,
      ['admin', 'admin@khetisahayak.com', adminPassword, 'Admin', 'User', 'admin', true]
    );

    // Create expert user
    const expertPassword = await bcrypt.hash('expert123', 10);
    const expertResult = await db.query(
      `INSERT INTO users (username, email, password_hash, first_name, last_name, role, is_verified)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (email) DO NOTHING
       RETURNING id`,
      ['expert', 'expert@khetisahayak.com', expertPassword, 'Dr. Rajesh', 'Kumar', 'expert', true]
    );

    // Create content creator
    const creatorPassword = await bcrypt.hash('creator123', 10);
    const creatorResult = await db.query(
      `INSERT INTO users (username, email, password_hash, first_name, last_name, role, is_verified)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (email) DO NOTHING
       RETURNING id`,
      ['creator', 'creator@khetisahayak.com', creatorPassword, 'Priya', 'Sharma', 'content-creator', true]
    );

    // Create regular user
    const userPassword = await bcrypt.hash('user123', 10);
    const userResult = await db.query(
      `INSERT INTO users (username, email, password_hash, first_name, last_name, role, is_verified)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (email) DO NOTHING
       RETURNING id`,
      ['farmer', 'farmer@khetisahayak.com', userPassword, 'Amit', 'Patel', 'user', true]
    );

    // Seed crop recommendations
    const cropRecommendations = [
      {
        crop_name: 'Rice',
        season: 'Kharif',
        soil_type: 'Clay loam',
        climate_zone: 'Tropical',
        water_requirement: 'High',
        growth_duration: 120,
        yield_per_hectare: 4.5,
        market_price_range: { min: 1800, max: 2200 },
        description: 'Rice is a staple food crop that requires warm and humid conditions.'
      },
      {
        crop_name: 'Wheat',
        season: 'Rabi',
        soil_type: 'Loam',
        climate_zone: 'Temperate',
        water_requirement: 'Medium',
        growth_duration: 140,
        yield_per_hectare: 3.2,
        market_price_range: { min: 2000, max: 2500 },
        description: 'Wheat is a winter crop that grows well in cool temperatures.'
      },
      {
        crop_name: 'Maize',
        season: 'Kharif',
        soil_type: 'Sandy loam',
        climate_zone: 'Tropical',
        water_requirement: 'Medium',
        growth_duration: 90,
        yield_per_hectare: 3.8,
        market_price_range: { min: 1600, max: 2000 },
        description: 'Maize is a versatile crop used for food, feed, and industrial purposes.'
      },
      {
        crop_name: 'Cotton',
        season: 'Kharif',
        soil_type: 'Black soil',
        climate_zone: 'Tropical',
        water_requirement: 'Medium',
        growth_duration: 150,
        yield_per_hectare: 2.5,
        market_price_range: { min: 5000, max: 7000 },
        description: 'Cotton is a cash crop used for fiber production.'
      },
      {
        crop_name: 'Sugarcane',
        season: 'Kharif',
        soil_type: 'Heavy clay',
        climate_zone: 'Tropical',
        water_requirement: 'High',
        growth_duration: 300,
        yield_per_hectare: 70,
        market_price_range: { min: 300, max: 400 },
        description: 'Sugarcane is a long-duration crop used for sugar production.'
      }
    ];

    for (const crop of cropRecommendations) {
      await db.query(
        `INSERT INTO crop_recommendations (
          crop_name, season, soil_type, climate_zone, water_requirement,
          growth_duration, yield_per_hectare, market_price_range, description
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          crop.crop_name, crop.season, crop.soil_type, crop.climate_zone,
          crop.water_requirement, crop.growth_duration, crop.yield_per_hectare,
          JSON.stringify(crop.market_price_range), crop.description
        ]
      );
    }

    // Seed educational content
    const educationalContent = [
      {
        title: 'Organic Farming Basics',
        content: 'Organic farming is a method of crop and livestock production that involves much more than choosing not to use pesticides, fertilizers, genetically modified organisms, antibiotics and growth hormones. Organic production is a holistic system designed to optimize the productivity and fitness of diverse communities within the agro-ecosystem, including soil organisms, plants, livestock and people.',
        summary: 'Learn the fundamentals of organic farming practices and their benefits.',
        category: 'Farming Methods',
        subcategory: 'Organic',
        difficulty_level: 'beginner',
        tags: ['organic', 'farming', 'basics', 'sustainable']
      },
      {
        title: 'Crop Rotation Techniques',
        content: 'Crop rotation is the practice of growing a series of different types of crops in the same area across a sequence of growing seasons. It reduces reliance on one set of nutrients, pest and weed pressure, and the probability of developing resistant pest and weeds. Growing the same crop in the same place for many years in a row, known as monocropping, gradually depletes the soil of certain nutrients and selects for a highly competitive pest and weed community.',
        summary: 'Understanding crop rotation for better soil health and pest management.',
        category: 'Farming Methods',
        subcategory: 'Crop Management',
        difficulty_level: 'intermediate',
        tags: ['crop rotation', 'soil health', 'pest management', 'sustainability']
      },
      {
        title: 'Pest Management Strategies',
        content: 'Integrated Pest Management (IPM) is an ecosystem-based strategy that focuses on long-term prevention of pests or their damage through a combination of techniques such as biological control, habitat manipulation, modification of cultural practices, and use of resistant varieties. Pesticides are used only after monitoring indicates they are needed according to established guidelines.',
        summary: 'Comprehensive guide to managing pests using integrated approaches.',
        category: 'Crop Protection',
        subcategory: 'Pest Management',
        difficulty_level: 'intermediate',
        tags: ['pest management', 'IPM', 'biological control', 'pesticides']
      },
      {
        title: 'Soil Testing and Analysis',
        content: 'Soil testing is a valuable tool for assessing the fertility status of your soil. It provides information on the soil\'s pH level, nutrient content, and organic matter percentage. This information helps farmers make informed decisions about fertilizer application, crop selection, and soil management practices.',
        summary: 'How to test and analyze soil for optimal crop production.',
        category: 'Soil Management',
        subcategory: 'Testing',
        difficulty_level: 'beginner',
        tags: ['soil testing', 'fertility', 'pH', 'nutrients']
      },
      {
        title: 'Water Management in Agriculture',
        content: 'Efficient water management is crucial for sustainable agriculture. This includes proper irrigation scheduling, water conservation techniques, and the use of drought-resistant crop varieties. Modern irrigation systems like drip irrigation and sprinkler systems help optimize water use.',
        summary: 'Best practices for water management in agricultural systems.',
        category: 'Water Management',
        subcategory: 'Irrigation',
        difficulty_level: 'advanced',
        tags: ['water management', 'irrigation', 'conservation', 'drought']
      }
    ];

    for (const content of educationalContent) {
      await db.query(
        `INSERT INTO educational_content (
          title, content, summary, category, subcategory, difficulty_level, tags, author_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          content.title, content.content, content.summary, content.category,
          content.subcategory, content.difficulty_level, content.tags,
          creatorResult.rows[0]?.id || null
        ]
      );
    }

    // Seed sample products
    const sampleProducts = [
      {
        name: 'Organic Neem Oil',
        description: 'Pure neem oil for natural pest control and plant protection',
        price: 450.00,
        category: 'Pesticides',
        subcategory: 'Organic',
        brand: 'NatureCare',
        stock_quantity: 50,
        unit: 'liter',
        is_organic: true,
        specifications: { volume: '1 liter', concentration: '100% pure' }
      },
      {
        name: 'NPK Fertilizer 20-20-20',
        description: 'Balanced NPK fertilizer for all types of crops',
        price: 1200.00,
        category: 'Fertilizers',
        subcategory: 'Chemical',
        brand: 'AgroMax',
        stock_quantity: 100,
        unit: 'kg',
        is_organic: false,
        specifications: { weight: '25 kg', NPK_ratio: '20-20-20' }
      },
      {
        name: 'Drip Irrigation Kit',
        description: 'Complete drip irrigation system for efficient water management',
        price: 2500.00,
        category: 'Irrigation',
        subcategory: 'Drip Systems',
        brand: 'WaterTech',
        stock_quantity: 25,
        unit: 'kit',
        is_organic: false,
        specifications: { coverage: '1 acre', components: 'pipes, emitters, filters' }
      },
      {
        name: 'Hybrid Tomato Seeds',
        description: 'High-yielding hybrid tomato seeds for commercial farming',
        price: 350.00,
        category: 'Seeds',
        subcategory: 'Vegetables',
        brand: 'SeedMaster',
        stock_quantity: 200,
        unit: 'packet',
        is_organic: false,
        specifications: { seeds_per_packet: 100, germination_rate: '95%' }
      },
      {
        name: 'Bio Compost',
        description: 'Organic compost made from farm waste and cow dung',
        price: 800.00,
        category: 'Fertilizers',
        subcategory: 'Organic',
        brand: 'EcoFarm',
        stock_quantity: 75,
        unit: 'kg',
        is_organic: true,
        specifications: { weight: '50 kg', NPK: '2-1-1', organic_matter: '40%' }
      }
    ];

    for (const product of sampleProducts) {
      await db.query(
        `INSERT INTO products (
          name, description, price, category, subcategory, brand,
          stock_quantity, unit, is_organic, specifications, seller_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
        [
          product.name, product.description, product.price, product.category,
          product.subcategory, product.brand, product.stock_quantity, product.unit,
          product.is_organic, JSON.stringify(product.specifications), userResult.rows[0]?.id || null
        ]
      );
    }

    console.log('✅ Database seeding completed successfully!');
    console.log('\n📋 Default Users:');
    console.log('Admin: admin@khetisahayak.com / admin123');
    console.log('Expert: expert@khetisahayak.com / expert123');
    console.log('Creator: creator@khetisahayak.com / creator123');
    console.log('User: farmer@khetisahayak.com / user123');

  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
};

// Run seeding if this file is executed directly
if (require.main === module) {
  debugAndSeed().then(() => {
    console.log('🎉 Seeding process finished');
    process.exit(0);
  });
}

module.exports = seedData; 
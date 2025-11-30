require('dotenv').config();
const bcrypt = require('bcryptjs');
const db = require('./db');
const { Pool } = require('pg');
const { seedEquipmentData } = require('./seeds/equipmentSeed');
const { seedTechnologyData } = require('./seeds/technologySeed');

console.log('Connecting to database:', process.env.DB_NAME);

const debugPool = new Pool(
  process.env.DATABASE_URL
    ? {
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: false,
      },
    }
    : {
      user: process.env.DB_USER,
      host: process.env.DB_HOST,
      database: process.env.DB_NAME,
      password: process.env.DB_PASSWORD,
      port: process.env.DB_PORT,
      ssl: process.env.DB_HOST === 'localhost' ? false : {
        rejectUnauthorized: false,
      },
    }
);

async function debugAndSeed() {
  const columns = await debugPool.query(`SELECT column_name FROM information_schema.columns WHERE table_name = 'users' ORDER BY ordinal_position`);
  console.log('Columns in users table:', columns.rows.map(r => r.column_name));
  await debugPool.end();
  await seedData();
}

const seedEducationalContent = async () => {
  const contentData = [
    {
      title: 'Introduction to Organic Farming',
      content: `Organic farming is a method of crop and livestock production that involves much more than choosing not to use pesticides, fertilizers, genetically modified organisms, antibiotics and growth hormones.

Organic production is a holistic system designed to optimize the productivity and fitness of diverse communities within the agro-ecosystem, including soil organisms, plants, livestock and people. The principal goal of organic production is to develop enterprises that are sustainable and harmonious with the environment.

Key Principles of Organic Farming:
1. Health - Organic agriculture should sustain and enhance the health of soil, plant, animal, human and planet as one and indivisible.
2. Ecology - Organic agriculture should be based on living ecological systems and cycles, work with them, emulate them and help sustain them.
3. Fairness - Organic agriculture should build on relationships that ensure fairness with regard to the common environment and life opportunities.
4. Care - Organic agriculture should be managed in a precautionary and responsible manner to protect the health and well-being of current and future generations and the environment.`,
      summary: 'Learn the fundamentals of organic farming practices and principles for sustainable agriculture.',
      category: 'Farming Methods',
      subcategory: 'Organic Farming',
      difficulty_level: 'beginner',
      tags: ['organic', 'sustainable', 'farming', 'beginner'],
      imageUrl: 'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=400'
    },
    {
      title: 'Crop Rotation Strategies',
      content: `Crop rotation is the practice of growing a series of different types of crops in the same area across a sequence of growing seasons. It reduces reliance on one set of nutrients, pest and weed pressure, and the probability of developing resistant pest and weeds.

Benefits of Crop Rotation:
1. Soil Health: Different crops have different nutrient needs and root structures, helping to maintain soil fertility and structure.
2. Pest Management: Rotating crops helps break pest and disease cycles.
3. Weed Control: Different crops compete with weeds in different ways.
4. Nutrient Management: Legumes can fix nitrogen, reducing the need for synthetic fertilizers.

Common Crop Rotation Patterns:
- Corn → Soybeans → Wheat → Clover
- Tomatoes → Beans → Lettuce → Carrots
- Potatoes → Peas → Cabbage → Onions

Planning Your Rotation:
1. Group crops by family (avoid planting same family consecutively)
2. Consider nutrient needs and contributions
3. Plan for 3-4 year cycles
4. Include cover crops in your rotation`,
      summary: 'Master crop rotation techniques to improve soil health and reduce pest problems.',
      category: 'Farming Methods',
      subcategory: 'Crop Management',
      difficulty_level: 'intermediate',
      tags: ['crop rotation', 'soil health', 'pest management', 'intermediate'],
      imageUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=400'
    },
    {
      title: 'Integrated Pest Management (IPM)',
      content: `Integrated Pest Management (IPM) is an ecosystem-based strategy that focuses on long-term prevention of pests or their damage through a combination of techniques such as biological control, habitat manipulation, modification of cultural practices, and use of resistant varieties.

IPM Principles:
1. Prevention - Use cultural practices to prevent pest problems
2. Monitoring - Regularly check for pests and their damage
3. Identification - Correctly identify pests and beneficial organisms
4. Action Thresholds - Determine when action is needed
5. Multiple Tactics - Use a combination of control methods
6. Evaluation - Assess the effectiveness of your IPM program

Biological Control Methods:
- Beneficial insects (ladybugs, lacewings, parasitic wasps)
- Microbial pesticides (Bacillus thuringiensis)
- Nematodes for soil pest control
- Birds and bats for flying insect control

Cultural Control Methods:
- Crop rotation
- Sanitation
- Proper planting dates
- Resistant varieties
- Trap crops

Chemical Control (as last resort):
- Use least toxic options
- Apply at optimal times
- Target specific pests
- Follow label instructions carefully`,
      summary: 'Learn IPM strategies to control pests while minimizing environmental impact.',
      category: 'Pest Management',
      subcategory: 'IPM',
      difficulty_level: 'intermediate',
      tags: ['pest management', 'IPM', 'biological control', 'intermediate'],
      imageUrl: 'https://images.unsplash.com/photo-1585314062340-f1a5a7c9328d?w=400'
    },
    {
      title: 'Soil Testing and Analysis',
      content: `Soil testing is a crucial tool for making informed decisions about fertilizer application and soil management. It provides information about soil pH, nutrient levels, organic matter content, and other important soil properties.

Why Test Your Soil?
1. Optimize fertilizer use and reduce costs
2. Identify nutrient deficiencies or excesses
3. Determine soil pH and need for lime
4. Assess soil organic matter content
5. Monitor soil health over time

Types of Soil Tests:
1. Basic Soil Test - pH, phosphorus, potassium, calcium, magnesium
2. Complete Soil Test - Includes micronutrients and organic matter
3. Specialized Tests - Salinity, heavy metals, texture analysis

How to Take Soil Samples:
1. Use a clean soil probe or shovel
2. Sample to a depth of 6-8 inches for most crops
3. Take 10-15 subsamples per field or area
4. Mix subsamples thoroughly in a clean bucket
5. Remove stones, roots, and debris
6. Air dry the sample before sending to lab

Interpreting Results:
- pH: 6.0-7.0 is ideal for most crops
- Phosphorus: 20-40 ppm is adequate for most crops
- Potassium: 150-250 ppm is adequate for most crops
- Organic Matter: 3-5% is good for most soils

Making Recommendations:
- Apply lime if pH is below 6.0
- Add phosphorus if levels are below 20 ppm
- Add potassium if levels are below 150 ppm
- Consider organic matter amendments if below 3%`,
      summary: 'Master soil testing techniques to optimize crop nutrition and soil health.',
      category: 'Soil Management',
      subcategory: 'Soil Testing',
      difficulty_level: 'beginner',
      tags: ['soil testing', 'nutrients', 'pH', 'beginner'],
      imageUrl: 'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=400'
    },
    {
      title: 'Drip Irrigation Systems',
      content: `Drip irrigation is a method of applying water directly to the root zone of plants through a network of valves, pipes, tubing, and emitters. It is one of the most efficient irrigation methods, using 30-50% less water than conventional irrigation systems.

Components of a Drip System:
1. Water Source - Well, municipal water, or storage tank
2. Pump - To provide adequate pressure
3. Filter - To remove particles that could clog emitters
4. Pressure Regulator - To maintain consistent pressure
5. Mainline - Large diameter pipe from source to field
6. Submain - Smaller pipes that distribute water to zones
7. Lateral Lines - Small diameter tubing with emitters
8. Emitters - Devices that release water at controlled rates

Types of Emitters:
- Point Source Emitters - Individual emitters for trees or large plants
- Inline Emitters - Built into the tubing at regular intervals
- Drip Tape - Thin-walled tubing with built-in emitters
- Micro-sprinklers - Small sprinklers for wider coverage

System Design Considerations:
1. Water Requirements - Calculate daily water needs
2. Soil Type - Sandy soils need more frequent, shorter applications
3. Plant Spacing - Match emitter spacing to plant spacing
4. Pressure Requirements - Ensure adequate pressure throughout system
5. Filtration Needs - Choose appropriate filter based on water quality

Installation Steps:
1. Plan your system layout
2. Install mainline and submains
3. Lay out lateral lines
4. Install emitters or drip tape
5. Test the system for leaks and proper operation
6. Cover with mulch to protect from UV damage

Maintenance:
- Check filters regularly
- Flush lines periodically
- Monitor for leaks and clogs
- Adjust for seasonal changes
- Winterize in cold climates`,
      summary: 'Design and install efficient drip irrigation systems for optimal water use.',
      category: 'Irrigation',
      subcategory: 'Drip Systems',
      difficulty_level: 'advanced',
      tags: ['irrigation', 'drip', 'water efficiency', 'advanced'],
      imageUrl: 'https://images.unsplash.com/photo-1563514227147-6d2ff665a6a0?w=400'
    },
    {
      title: 'Greenhouse Management',
      content: `Greenhouse management involves controlling the environment to optimize plant growth and production. This includes managing temperature, humidity, light, ventilation, and irrigation.

Environmental Control:
1. Temperature Management
   - Heating systems (gas, electric, geothermal)
   - Cooling systems (ventilation, evaporative cooling, shade cloth)
   - Temperature monitoring and automation
   - Seasonal adjustments

2. Humidity Control
   - Ventilation to reduce humidity
   - Humidification systems for dry conditions
   - Monitoring with hygrometers
   - Disease prevention through humidity management

3. Light Management
   - Natural light optimization
   - Supplemental lighting for short days
   - Shade cloth for light reduction
   - Light duration control for flowering

4. Ventilation Systems
   - Natural ventilation (roof vents, side vents)
   - Mechanical ventilation (fans, exhaust systems)
   - Air circulation fans
   - CO2 enrichment systems

Crop Management:
1. Planting Schedules
   - Year-round production planning
   - Succession planting
   - Crop rotation within greenhouse
   - Seasonal crop selection

2. Pest and Disease Management
   - Biological control agents
   - Sanitation practices
   - Monitoring and scouting
   - Integrated pest management

3. Nutrient Management
   - Fertigation systems
   - Soil testing and monitoring
   - pH and EC management
   - Organic amendments

4. Harvest and Post-Harvest
   - Optimal harvest timing
   - Quality control
   - Storage conditions
   - Market preparation

Economic Considerations:
- Energy costs and efficiency
- Labor requirements
- Market analysis
- Crop selection for profitability
- Season extension benefits`,
      summary: 'Master greenhouse management for year-round crop production and optimal yields.',
      category: 'Protected Agriculture',
      subcategory: 'Greenhouse',
      difficulty_level: 'advanced',
      tags: ['greenhouse', 'environmental control', 'year-round production', 'advanced'],
      imageUrl: 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=400'
    },
    {
      title: 'Modern Tractor Operations',
      content: 'Comprehensive guide on operating modern tractors safely and efficiently, covering maintenance, safety protocols, and field operations.',
      summary: 'Video tutorial on modern tractor operations and safety.',
      category: 'Farm Machinery',
      subcategory: 'Tractors',
      difficulty_level: 'intermediate',
      tags: ['tractor', 'machinery', 'safety', 'video'],
      imageUrl: 'https://images.unsplash.com/photo-1519331379826-f95209603306?w=400',
      videoUrl: 'https://www.youtube.com/watch?v=dummy_video_id'
    }
  ];

  for (const content of contentData) {
    await db.query(
      `INSERT INTO educational_content (
        title, content, summary, category, subcategory, difficulty_level, tags, is_published, image_url, video_url
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
      [
        content.title,
        content.content,
        content.summary,
        content.category,
        content.subcategory,
        content.difficulty_level,
        content.tags,
        true,
        content.imageUrl,
        content.videoUrl
      ]
    );
  }

  console.log('Educational content seeded successfully');
};

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
    },
    {
      crop_name: 'Rice',
      season: 'summer',
      soil_type: 'clay',
      climate_zone: 'tropical',
      water_requirement: 'very high',
      growth_duration: 150,
      yield_per_hectare: 6.0,
      market_price_range: { min: 4.0, max: 6.0 },
      description: 'Semi-aquatic crop requiring flooded conditions. Primary staple food in many regions. Requires warm temperatures.'
    },
    {
      crop_name: 'Cotton',
      season: 'summer',
      soil_type: 'sandy loam',
      climate_zone: 'subtropical',
      water_requirement: 'moderate',
      growth_duration: 180,
      yield_per_hectare: 1.5,
      market_price_range: { min: 15.0, max: 25.0 },
      description: 'Warm-season fiber crop requiring long growing season. Drought tolerant once established but needs adequate moisture for good yields.'
    },
    {
      crop_name: 'Sugarcane',
      season: 'year-round',
      soil_type: 'clay loam',
      climate_zone: 'tropical',
      water_requirement: 'high',
      growth_duration: 365,
      yield_per_hectare: 80.0,
      market_price_range: { min: 0.8, max: 1.2 },
      description: 'Perennial grass crop grown for sugar production. Requires tropical or subtropical climate with adequate rainfall.'
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

const seedAppMenu = async () => {
  const menuItems = [
    { label: 'Dashboard', icon_name: 'dashboard', route_id: 'dashboard', display_order: 1 },
    { label: 'Weather', icon_name: 'wb_sunny', route_id: 'weather', display_order: 2 },
    { label: 'Crop Diagnostics', icon_name: 'medical_services', route_id: 'diagnostics', display_order: 3 },
    { label: 'Marketplace', icon_name: 'store', route_id: 'marketplace', display_order: 4 },
    { label: 'Education', icon_name: 'school', route_id: 'education', display_order: 5 },
    { label: 'Expert Connect', icon_name: 'people', route_id: 'expert_connect', display_order: 6 },
    { label: 'Community', icon_name: 'forum', route_id: 'community', display_order: 7 },
    { label: 'Digital Logbook', icon_name: 'book', route_id: 'logbook', display_order: 8 },
    { label: 'Government Schemes', icon_name: 'account_balance', route_id: 'schemes', display_order: 9 },
    { label: 'Recommendations', icon_name: 'lightbulb', route_id: 'recommendations', display_order: 10 },
    { label: 'Equipment & Labor', icon_name: 'handyman', route_id: 'equipment', display_order: 11 },
    { label: 'Notifications', icon_name: 'notifications', route_id: 'notifications', display_order: 12 },
    { label: 'Profile', icon_name: 'person', route_id: 'profile', display_order: 13 },
  ];

  for (const item of menuItems) {
    await db.query(
      `INSERT INTO app_menu_items (label, icon_name, route_id, display_order)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (route_id) DO UPDATE SET
       label = EXCLUDED.label,
       icon_name = EXCLUDED.icon_name,
       display_order = EXCLUDED.display_order`,
      [item.label, item.icon_name, item.route_id, item.display_order]
    );
  }
  console.log('App menu items seeded successfully');
};

const seedExperts = async () => {
  const experts = [
    { name: 'Dr. Ramesh Gupta', specialization: 'Soil Scientist', qualification: 'PhD in Agriculture', experience_years: 15, is_online: true, rating: 4.8 },
    { name: 'Ms. Priya Sharma', specialization: 'Plant Pathologist', qualification: 'MSc in Plant Pathology', experience_years: 8, is_online: true, rating: 4.9 },
    { name: 'Mr. Suresh Patel', specialization: 'Agronomist', qualification: 'BSc Agriculture', experience_years: 10, is_online: false, rating: 4.5 },
    { name: 'Dr. Anita Desai', specialization: 'Entomologist', qualification: 'PhD Entomology', experience_years: 12, is_online: false, rating: 4.7 },
  ];

  for (const expert of experts) {
    await db.query(
      `INSERT INTO experts (name, specialization, qualification, experience_years, is_online, rating)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT DO NOTHING`,
      [expert.name, expert.specialization, expert.qualification, expert.experience_years, expert.is_online, expert.rating]
    );
  }
  console.log('Experts seeded successfully');
};

const seedCommunityPosts = async () => {
  const posts = [
    { user_name: 'Rajesh Kumar', content: 'My wheat crop is showing yellow spots. Any advice?', likes: 12, comments_count: 5 },
    { user_name: 'Sunita Devi', content: 'Just harvested my organic tomatoes! Great yield this year.', likes: 45, comments_count: 10 },
    { user_name: 'Amit Singh', content: 'Looking for best fertilizer for cotton in sandy soil.', likes: 8, comments_count: 3 },
  ];

  for (const post of posts) {
    await db.query(
      `INSERT INTO community_posts (user_name, content, likes, comments_count)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT DO NOTHING`,
      [post.user_name, post.content, post.likes, post.comments_count]
    );
  }
  console.log('Community posts seeded successfully');
};

const seedSchemes = async () => {
  const schemes = [
    {
      name: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
      description: 'Crop insurance scheme to provide financial support to farmers suffering crop loss/damage arising out of unforeseen events.',
      benefits: 'Financial support for crop loss, stabilization of income, encouragement of innovative practices.',
      eligibility: 'All farmers growing notified crops in notified areas including sharecroppers and tenant farmers.',
      category: 'Insurance',
      link: 'https://pmfby.gov.in/'
    },
    {
      name: 'Pradhan Mantri Krishi Sinchai Yojana (PMKSY)',
      description: 'Scheme to improve farm productivity and ensure better utilization of the resources in the country.',
      benefits: 'Access to irrigation, expansion of cultivable area under assured irrigation, improvement in water use efficiency.',
      eligibility: 'Farmers with cultivable land.',
      category: 'Irrigation',
      link: 'https://pmksy.gov.in/'
    },
    {
      name: 'Soil Health Card Scheme',
      description: 'Scheme to issue soil health cards to farmers which will carry crop-wise recommendations of nutrients and fertilizers.',
      benefits: 'Information on soil nutrient status, recommendations on dosage of nutrients.',
      eligibility: 'All farmers.',
      category: 'Soil Health',
      link: 'https://soilhealth.dac.gov.in/'
    },
    {
      name: 'Kisan Credit Card (KCC)',
      description: 'Scheme to provide adequate and timely credit support from the banking system under a single window.',
      benefits: 'Credit for cultivation, post-harvest expenses, consumption requirements.',
      eligibility: 'All farmers, tenant farmers, oral lessees, share croppers.',
      category: 'Credit',
      link: 'https://www.nabard.org/'
    }
  ];

  for (const scheme of schemes) {
    await db.query(
      `INSERT INTO schemes (name, description, benefits, eligibility, category, link)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT DO NOTHING`,
      [scheme.name, scheme.description, scheme.benefits, scheme.eligibility, scheme.category, scheme.link]
    );
  }
  console.log('Schemes seeded successfully');
};

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
    await seedCropRecommendations();

    // Seed educational content
    await seedEducationalContent();

    // Seed app menu
    await seedAppMenu();

    // Seed social features
    await seedExperts();
    await seedCommunityPosts();
    await seedSchemes();

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

    // Seed equipment and technology data
    try {
      console.log('\n🚜 Seeding equipment data...');
      await seedEquipmentData();
    } catch (err) {
      console.log('Equipment seed skipped (tables may not exist):', err.message);
    }

    try {
      console.log('\n🔬 Seeding technology data...');
      await seedTechnologyData();
    } catch (err) {
      console.log('Technology seed skipped (tables may not exist):', err.message);
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
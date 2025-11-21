/**
 * Agricultural Technologies and Courses Seed Data
 *
 * Addresses issue #409 - Good First Issue: Seed Agricultural Technologies Data
 */

const db = require('../db');

const technologyCategories = [
  {
    name: 'Smart Irrigation',
    name_hi: 'स्मार्ट सिंचाई',
    description: 'Water management and irrigation technologies',
    icon: 'water-drop',
    display_order: 1
  },
  {
    name: 'Precision Farming',
    name_hi: 'सटीक खेती',
    description: 'GPS-guided and data-driven farming techniques',
    icon: 'target',
    display_order: 2
  },
  {
    name: 'Protected Cultivation',
    name_hi: 'संरक्षित खेती',
    description: 'Greenhouse and polyhouse farming',
    icon: 'greenhouse',
    display_order: 3
  },
  {
    name: 'Organic Farming',
    name_hi: 'जैविक खेती',
    description: 'Chemical-free and sustainable farming methods',
    icon: 'leaf',
    display_order: 4
  },
  {
    name: 'Farm Mechanization',
    name_hi: 'कृषि यंत्रीकरण',
    description: 'Modern machinery and automation',
    icon: 'tractor',
    display_order: 5
  },
  {
    name: 'Post-Harvest Technology',
    name_hi: 'कटाई उपरांत प्रौद्योगिकी',
    description: 'Storage, processing, and value addition',
    icon: 'storage',
    display_order: 6
  },
  {
    name: 'Drone Technology',
    name_hi: 'ड्रोन प्रौद्योगिकी',
    description: 'Agricultural drones for monitoring and spraying',
    icon: 'drone',
    display_order: 7
  },
  {
    name: 'Soil Health Management',
    name_hi: 'मृदा स्वास्थ्य प्रबंधन',
    description: 'Soil testing and nutrient management',
    icon: 'soil',
    display_order: 8
  }
];

const technologies = [
  {
    categoryName: 'Smart Irrigation',
    name: 'Drip Irrigation System',
    name_hi: 'ड्रिप सिंचाई प्रणाली',
    slug: 'drip-irrigation-system',
    description: 'Drip irrigation delivers water directly to plant roots through a network of tubes and emitters. This technology can reduce water usage by 30-50% while improving crop yields.',
    description_hi: 'ड्रिप सिंचाई पौधों की जड़ों तक सीधे पानी पहुंचाती है। यह तकनीक 30-50% पानी बचाती है।',
    benefits: ['30-50% water savings', 'Higher crop yield', 'Reduced weed growth', 'Lower labor costs', 'Suitable for all terrains'],
    suitable_crops: ['Vegetables', 'Fruits', 'Cotton', 'Sugarcane', 'Grapes'],
    suitable_farm_sizes: ['Small (1-5 acres)', 'Medium (5-25 acres)', 'Large (25+ acres)'],
    implementation_cost_min: 25000,
    implementation_cost_max: 50000,
    expected_roi_percent: 35,
    payback_period_months: 18,
    difficulty_level: 'easy',
    implementation_steps: [
      { step: 1, title: 'Site Survey', description: 'Assess water source and field layout' },
      { step: 2, title: 'System Design', description: 'Plan layout based on crop spacing' },
      { step: 3, title: 'Installation', description: 'Install main lines, sub-mains, and laterals' },
      { step: 4, title: 'Testing', description: 'Check for leaks and uniform water distribution' },
      { step: 5, title: 'Training', description: 'Learn operation and maintenance' }
    ],
    required_resources: ['Water source', 'Pump (if needed)', 'Filter', 'Pressure gauge', 'Basic tools'],
    government_subsidies: [
      { scheme: 'PMKSY-PDMC', subsidy_percent: 55, description: 'Per Drop More Crop scheme provides 55% subsidy for small farmers' },
      { scheme: 'State Subsidy', subsidy_percent: 25, description: 'Additional state subsidy varies by region' }
    ],
    is_featured: true
  },
  {
    categoryName: 'Smart Irrigation',
    name: 'Solar-Powered Irrigation',
    name_hi: 'सौर ऊर्जा सिंचाई',
    slug: 'solar-powered-irrigation',
    description: 'Use solar panels to power water pumps, eliminating electricity costs and enabling irrigation in remote areas without grid connectivity.',
    benefits: ['Zero electricity cost', 'Works in remote areas', 'Low maintenance', 'Environment friendly', '25-year lifespan'],
    suitable_crops: ['All crops'],
    suitable_farm_sizes: ['Small (1-5 acres)', 'Medium (5-25 acres)'],
    implementation_cost_min: 150000,
    implementation_cost_max: 400000,
    expected_roi_percent: 40,
    payback_period_months: 36,
    difficulty_level: 'medium',
    implementation_steps: [
      { step: 1, title: 'Energy Assessment', description: 'Calculate pump power requirement' },
      { step: 2, title: 'Solar Panel Sizing', description: 'Determine panel capacity needed' },
      { step: 3, title: 'Installation', description: 'Mount panels and connect to pump' },
      { step: 4, title: 'Controller Setup', description: 'Configure automatic operation' }
    ],
    government_subsidies: [
      { scheme: 'PM-KUSUM', subsidy_percent: 60, description: '60% subsidy on solar pump installation' }
    ],
    is_featured: true
  },
  {
    categoryName: 'Precision Farming',
    name: 'Soil Testing & Nutrient Management',
    name_hi: 'मृदा परीक्षण और पोषक तत्व प्रबंधन',
    slug: 'soil-testing-nutrient-management',
    description: 'Regular soil testing helps determine exact nutrient requirements, reducing fertilizer costs while optimizing yields.',
    benefits: ['Reduced fertilizer costs', 'Optimized nutrient application', 'Better crop health', 'Environmental protection', 'Higher yields'],
    suitable_crops: ['All crops'],
    suitable_farm_sizes: ['Small (1-5 acres)', 'Medium (5-25 acres)', 'Large (25+ acres)'],
    implementation_cost_min: 500,
    implementation_cost_max: 2000,
    expected_roi_percent: 25,
    payback_period_months: 6,
    difficulty_level: 'easy',
    implementation_steps: [
      { step: 1, title: 'Sample Collection', description: 'Collect soil samples from different points' },
      { step: 2, title: 'Lab Testing', description: 'Send to soil testing lab' },
      { step: 3, title: 'Report Analysis', description: 'Understand nutrient levels and pH' },
      { step: 4, title: 'Application Plan', description: 'Create fertilizer schedule based on results' }
    ],
    government_subsidies: [
      { scheme: 'Soil Health Card', subsidy_percent: 100, description: 'Free soil testing through government labs' }
    ],
    is_featured: true
  },
  {
    categoryName: 'Protected Cultivation',
    name: 'Low-Cost Polyhouse',
    name_hi: 'कम लागत वाला पॉलीहाउस',
    slug: 'low-cost-polyhouse',
    description: 'Polyhouse cultivation protects crops from extreme weather, pests, and diseases, enabling year-round production of high-value vegetables.',
    benefits: ['Year-round cultivation', '3-5x higher yields', 'Weather protection', 'Reduced pest damage', 'Premium prices'],
    suitable_crops: ['Tomatoes', 'Capsicum', 'Cucumber', 'Flowers', 'Leafy vegetables'],
    suitable_farm_sizes: ['Small (1-5 acres)'],
    implementation_cost_min: 150000,
    implementation_cost_max: 500000,
    expected_roi_percent: 50,
    payback_period_months: 24,
    difficulty_level: 'medium',
    implementation_steps: [
      { step: 1, title: 'Site Selection', description: 'Choose level ground with good sunlight' },
      { step: 2, title: 'Structure Construction', description: 'Build bamboo/GI frame' },
      { step: 3, title: 'Covering', description: 'Install UV-stabilized polythene sheet' },
      { step: 4, title: 'Irrigation Setup', description: 'Install drip system inside' },
      { step: 5, title: 'Crop Planning', description: 'Select high-value crops' }
    ],
    government_subsidies: [
      { scheme: 'NHM', subsidy_percent: 50, description: 'National Horticulture Mission provides 50% subsidy' }
    ],
    is_featured: true
  },
  {
    categoryName: 'Organic Farming',
    name: 'Vermicomposting',
    name_hi: 'वर्मीकम्पोस्टिंग',
    slug: 'vermicomposting',
    description: 'Convert agricultural and kitchen waste into nutrient-rich organic fertilizer using earthworms. Creates self-sustaining cycle of organic inputs.',
    benefits: ['Free organic fertilizer', 'Waste recycling', 'Improved soil health', 'Additional income from sales', 'Easy to implement'],
    suitable_crops: ['All crops'],
    suitable_farm_sizes: ['Small (1-5 acres)', 'Medium (5-25 acres)'],
    implementation_cost_min: 5000,
    implementation_cost_max: 25000,
    expected_roi_percent: 200,
    payback_period_months: 6,
    difficulty_level: 'easy',
    implementation_steps: [
      { step: 1, title: 'Unit Setup', description: 'Build vermi-bed (10x3x1 ft)' },
      { step: 2, title: 'Bedding Preparation', description: 'Add coconut coir and cow dung' },
      { step: 3, title: 'Worm Introduction', description: 'Add earthworms (Eisenia fetida)' },
      { step: 4, title: 'Feeding', description: 'Add organic waste regularly' },
      { step: 5, title: 'Harvesting', description: 'Collect compost every 45-60 days' }
    ],
    government_subsidies: [
      { scheme: 'PKVY', subsidy_percent: 50, description: 'Paramparagat Krishi Vikas Yojana provides support' }
    ],
    is_featured: false
  },
  {
    categoryName: 'Drone Technology',
    name: 'Drone-Based Crop Spraying',
    name_hi: 'ड्रोन आधारित फसल छिड़काव',
    slug: 'drone-crop-spraying',
    description: 'Agricultural drones can spray pesticides, fertilizers, and nutrients with precision, covering 10-15 acres per hour with 30% less chemical usage.',
    benefits: ['10x faster than manual', '30% less chemical usage', 'Uniform coverage', 'No crop damage', 'Works in any terrain'],
    suitable_crops: ['Rice', 'Wheat', 'Cotton', 'Sugarcane', 'Orchards'],
    suitable_farm_sizes: ['Medium (5-25 acres)', 'Large (25+ acres)'],
    implementation_cost_min: 500,
    implementation_cost_max: 1500,
    expected_roi_percent: 40,
    payback_period_months: 12,
    difficulty_level: 'easy',
    implementation_steps: [
      { step: 1, title: 'Service Selection', description: 'Choose drone service provider' },
      { step: 2, title: 'Area Mapping', description: 'Provider maps your field' },
      { step: 3, title: 'Chemical Preparation', description: 'Prepare spray solution' },
      { step: 4, title: 'Spraying Operation', description: 'Drone completes spraying' }
    ],
    government_subsidies: [
      { scheme: 'Sub-Mission on Agricultural Mechanization', subsidy_percent: 50, description: 'Subsidy on drone services for small farmers' }
    ],
    is_featured: true
  },
  {
    categoryName: 'Post-Harvest Technology',
    name: 'Cold Storage Solutions',
    name_hi: 'शीत भंडारण समाधान',
    slug: 'cold-storage-solutions',
    description: 'Small-scale cold storage helps preserve perishable produce, reducing post-harvest losses and enabling better market timing.',
    benefits: ['Reduced wastage', 'Better prices', 'Extended selling window', 'Quality preservation', 'Food security'],
    suitable_crops: ['Vegetables', 'Fruits', 'Flowers', 'Dairy'],
    suitable_farm_sizes: ['Small (1-5 acres)', 'Medium (5-25 acres)'],
    implementation_cost_min: 100000,
    implementation_cost_max: 500000,
    expected_roi_percent: 30,
    payback_period_months: 36,
    difficulty_level: 'hard',
    implementation_steps: [
      { step: 1, title: 'Capacity Planning', description: 'Determine storage needs' },
      { step: 2, title: 'Technology Selection', description: 'Choose cooling system' },
      { step: 3, title: 'Construction', description: 'Build insulated structure' },
      { step: 4, title: 'Equipment Installation', description: 'Install cooling unit' },
      { step: 5, title: 'Operations Training', description: 'Learn temperature management' }
    ],
    government_subsidies: [
      { scheme: 'NHM/MIDH', subsidy_percent: 35, description: 'Subsidy for cold chain infrastructure' }
    ],
    is_featured: false
  },
  {
    categoryName: 'Farm Mechanization',
    name: 'Zero-Till Farming',
    name_hi: 'शून्य जुताई खेती',
    slug: 'zero-till-farming',
    description: 'Plant crops without plowing or tillage, preserving soil structure, reducing costs, and conserving moisture.',
    benefits: ['50% reduced tillage cost', 'Soil health preservation', 'Moisture conservation', 'Lower fuel costs', 'Faster planting'],
    suitable_crops: ['Wheat', 'Rice', 'Maize', 'Pulses'],
    suitable_farm_sizes: ['Medium (5-25 acres)', 'Large (25+ acres)'],
    implementation_cost_min: 5000,
    implementation_cost_max: 15000,
    expected_roi_percent: 25,
    payback_period_months: 12,
    difficulty_level: 'medium',
    implementation_steps: [
      { step: 1, title: 'Equipment Rental', description: 'Rent zero-till drill' },
      { step: 2, title: 'Residue Management', description: 'Manage previous crop stubble' },
      { step: 3, title: 'Direct Seeding', description: 'Plant directly into soil' },
      { step: 4, title: 'Weed Management', description: 'Use appropriate herbicides' }
    ],
    government_subsidies: [
      { scheme: 'State CHC', subsidy_percent: 80, description: 'Custom Hiring Centers provide subsidized rental' }
    ],
    is_featured: false
  }
];

const sampleCourses = [
  {
    technologySlug: 'drip-irrigation-system',
    title: 'Complete Drip Irrigation Course',
    title_hi: 'संपूर्ण ड्रिप सिंचाई कोर्स',
    description: 'Learn everything about designing, installing, and maintaining drip irrigation systems for your farm.',
    instructor_name: 'Dr. Rajesh Sharma',
    instructor_bio: 'Agricultural Engineer with 20 years of experience in irrigation systems',
    duration_minutes: 180,
    difficulty_level: 'beginner',
    language: 'en',
    is_free: true,
    certificate_available: true,
    is_featured: true,
    modules: [
      {
        title: 'Introduction to Drip Irrigation',
        order_index: 0,
        lessons: [
          { title: 'What is Drip Irrigation?', content_type: 'video', duration_minutes: 15 },
          { title: 'Benefits and ROI', content_type: 'video', duration_minutes: 10 },
          { title: 'Quiz: Basics', content_type: 'quiz', duration_minutes: 5 }
        ]
      },
      {
        title: 'System Components',
        order_index: 1,
        lessons: [
          { title: 'Main Lines and Sub-mains', content_type: 'video', duration_minutes: 20 },
          { title: 'Emitters and Drippers', content_type: 'video', duration_minutes: 15 },
          { title: 'Filters and Fittings', content_type: 'video', duration_minutes: 15 }
        ]
      },
      {
        title: 'Installation Process',
        order_index: 2,
        lessons: [
          { title: 'Site Preparation', content_type: 'video', duration_minutes: 15 },
          { title: 'Step-by-Step Installation', content_type: 'video', duration_minutes: 30 },
          { title: 'Testing and Troubleshooting', content_type: 'video', duration_minutes: 20 }
        ]
      },
      {
        title: 'Maintenance & Tips',
        order_index: 3,
        lessons: [
          { title: 'Regular Maintenance', content_type: 'video', duration_minutes: 15 },
          { title: 'Common Problems & Solutions', content_type: 'video', duration_minutes: 20 },
          { title: 'Final Quiz', content_type: 'quiz', duration_minutes: 10 }
        ]
      }
    ]
  },
  {
    technologySlug: 'vermicomposting',
    title: 'Vermicomposting for Beginners',
    title_hi: 'शुरुआती के लिए वर्मीकम्पोस्टिंग',
    description: 'Start your own vermicompost unit and produce organic fertilizer at home.',
    instructor_name: 'Sunita Devi',
    instructor_bio: 'Organic farming practitioner and trainer',
    duration_minutes: 90,
    difficulty_level: 'beginner',
    language: 'hi',
    is_free: true,
    certificate_available: false,
    is_featured: false,
    modules: [
      {
        title: 'Getting Started',
        order_index: 0,
        lessons: [
          { title: 'What is Vermicompost?', content_type: 'video', duration_minutes: 10 },
          { title: 'Materials Needed', content_type: 'video', duration_minutes: 15 },
          { title: 'Choosing Earthworms', content_type: 'video', duration_minutes: 10 }
        ]
      },
      {
        title: 'Building Your Unit',
        order_index: 1,
        lessons: [
          { title: 'Unit Construction', content_type: 'video', duration_minutes: 20 },
          { title: 'Bedding Preparation', content_type: 'video', duration_minutes: 15 },
          { title: 'Feeding Schedule', content_type: 'video', duration_minutes: 10 }
        ]
      },
      {
        title: 'Harvesting & Usage',
        order_index: 2,
        lessons: [
          { title: 'When to Harvest', content_type: 'video', duration_minutes: 10 },
          { title: 'Application Methods', content_type: 'video', duration_minutes: 10 }
        ]
      }
    ]
  }
];

async function seedTechnologyData() {
  console.log('Seeding technology categories...');

  try {
    // Insert categories
    const categoryMap = {};
    for (const category of technologyCategories) {
      const result = await db.query(`
        INSERT INTO technology_categories (name, name_hi, description, icon, display_order)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT DO NOTHING
        RETURNING id, name
      `, [category.name, category.name_hi, category.description, category.icon, category.display_order]);

      if (result.rows.length > 0) {
        categoryMap[category.name] = result.rows[0].id;
        console.log(`  Created category: ${category.name}`);
      } else {
        const existing = await db.query('SELECT id FROM technology_categories WHERE name = $1', [category.name]);
        if (existing.rows.length > 0) {
          categoryMap[category.name] = existing.rows[0].id;
        }
      }
    }

    console.log(`\nSeeded ${Object.keys(categoryMap).length} technology categories`);

    // Insert technologies
    console.log('\nSeeding agricultural technologies...');
    const technologyMap = {};

    for (const tech of technologies) {
      const categoryId = categoryMap[tech.categoryName];
      if (!categoryId) {
        console.log(`  Skipping: ${tech.name} - category not found`);
        continue;
      }

      const result = await db.query(`
        INSERT INTO agricultural_technologies (
          category_id, name, name_hi, slug, description, description_hi,
          benefits, suitable_crops, suitable_farm_sizes,
          implementation_cost_min, implementation_cost_max,
          expected_roi_percent, payback_period_months, difficulty_level,
          implementation_steps, required_resources, government_subsidies, is_featured
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
        ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name
        RETURNING id, slug
      `, [
        categoryId, tech.name, tech.name_hi, tech.slug, tech.description, tech.description_hi || null,
        JSON.stringify(tech.benefits || []), JSON.stringify(tech.suitable_crops || []),
        JSON.stringify(tech.suitable_farm_sizes || []),
        tech.implementation_cost_min, tech.implementation_cost_max,
        tech.expected_roi_percent, tech.payback_period_months, tech.difficulty_level,
        JSON.stringify(tech.implementation_steps || []), JSON.stringify(tech.required_resources || []),
        JSON.stringify(tech.government_subsidies || []), tech.is_featured
      ]);

      if (result.rows.length > 0) {
        technologyMap[tech.slug] = result.rows[0].id;
        console.log(`  Created technology: ${tech.name}`);
      }
    }

    console.log(`\nSeeded ${Object.keys(technologyMap).length} technologies`);

    // Insert courses
    console.log('\nSeeding sample courses...');
    let coursesCreated = 0;

    for (const course of sampleCourses) {
      const technologyId = technologyMap[course.technologySlug];

      const courseResult = await db.query(`
        INSERT INTO courses (
          technology_id, title, title_hi, slug, description,
          instructor_name, instructor_bio, duration_minutes,
          difficulty_level, language, is_free, certificate_available, is_featured
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        ON CONFLICT DO NOTHING
        RETURNING id
      `, [
        technologyId, course.title, course.title_hi,
        course.title.toLowerCase().replace(/\s+/g, '-'),
        course.description, course.instructor_name, course.instructor_bio,
        course.duration_minutes, course.difficulty_level, course.language,
        course.is_free, course.certificate_available, course.is_featured
      ]);

      if (courseResult.rows.length > 0) {
        const courseId = courseResult.rows[0].id;

        // Add modules and lessons
        for (const module of course.modules) {
          const moduleResult = await db.query(`
            INSERT INTO course_modules (course_id, title, order_index)
            VALUES ($1, $2, $3)
            RETURNING id
          `, [courseId, module.title, module.order_index]);

          const moduleId = moduleResult.rows[0].id;

          for (let i = 0; i < module.lessons.length; i++) {
            const lesson = module.lessons[i];
            await db.query(`
              INSERT INTO course_lessons (module_id, title, content_type, duration_minutes, order_index)
              VALUES ($1, $2, $3, $4, $5)
            `, [moduleId, lesson.title, lesson.content_type, lesson.duration_minutes, i]);
          }
        }

        console.log(`  Created course: ${course.title}`);
        coursesCreated++;
      }
    }

    console.log(`\nSeeded ${coursesCreated} courses`);

    return {
      categories: Object.keys(categoryMap).length,
      technologies: Object.keys(technologyMap).length,
      courses: coursesCreated
    };
  } catch (error) {
    console.error('Error seeding technology data:', error);
    throw error;
  }
}

module.exports = { seedTechnologyData, technologyCategories, technologies };

// Run if called directly
if (require.main === module) {
  seedTechnologyData()
    .then((result) => {
      console.log('\nTechnology seed completed:', result);
      process.exit(0);
    })
    .catch((err) => {
      console.error('Technology seed failed:', err);
      process.exit(1);
    });
}

/**
 * Equipment Categories and Sample Listings Seed Data
 *
 * Addresses issue #408 - Good First Issue: Seed Equipment Categories Data
 */

const db = require('../db');

const equipmentCategories = [
  {
    name: 'Tractors',
    name_hi: 'ट्रैक्टर',
    description: 'Agricultural tractors of various sizes and power',
    icon: 'tractor'
  },
  {
    name: 'Harvesters',
    name_hi: 'हार्वेस्टर',
    description: 'Combine harvesters and crop cutting machines',
    icon: 'harvester'
  },
  {
    name: 'Tillers & Cultivators',
    name_hi: 'टिलर और कल्टीवेटर',
    description: 'Rotavators, power tillers, and cultivators',
    icon: 'tiller'
  },
  {
    name: 'Seed Drills & Planters',
    name_hi: 'बीज ड्रिल और प्लांटर',
    description: 'Seed drilling and planting equipment',
    icon: 'seed-drill'
  },
  {
    name: 'Sprayers',
    name_hi: 'स्प्रेयर',
    description: 'Pesticide and fertilizer spraying equipment',
    icon: 'sprayer'
  },
  {
    name: 'Irrigation Equipment',
    name_hi: 'सिंचाई उपकरण',
    description: 'Pumps, pipes, and irrigation systems',
    icon: 'irrigation'
  },
  {
    name: 'Threshers',
    name_hi: 'थ्रेशर',
    description: 'Grain and crop threshing machines',
    icon: 'thresher'
  },
  {
    name: 'Transport Equipment',
    name_hi: 'परिवहन उपकरण',
    description: 'Trolleys, trailers, and transport vehicles',
    icon: 'transport'
  },
  {
    name: 'Post-Harvest Equipment',
    name_hi: 'कटाई के बाद के उपकरण',
    description: 'Grading, sorting, and storage equipment',
    icon: 'storage'
  },
  {
    name: 'Drones',
    name_hi: 'ड्रोन',
    description: 'Agricultural drones for spraying and monitoring',
    icon: 'drone'
  }
];

const sampleListings = [
  {
    categoryName: 'Tractors',
    name: 'Mahindra 575 DI XP Plus',
    description: '45 HP tractor in excellent condition. Perfect for medium-sized farms. Well-maintained with all service records.',
    brand: 'Mahindra',
    model: '575 DI XP Plus',
    year_of_manufacture: 2021,
    condition: 'excellent',
    hourly_rate: 350,
    daily_rate: 2500,
    weekly_rate: 15000,
    deposit_amount: 5000,
    location_address: 'Nashik, Maharashtra',
    location_lat: 20.0059,
    location_lng: 73.7897,
    service_radius_km: 50,
    specifications: {
      horsepower: 45,
      engine: '4-cylinder',
      fuel: 'Diesel',
      transmission: '8 Forward + 2 Reverse'
    },
    is_operator_included: true,
    operator_rate_per_day: 500,
    minimum_rental_days: 1
  },
  {
    categoryName: 'Tractors',
    name: 'Swaraj 744 FE',
    description: '48 HP tractor suitable for all farming operations. Low hours, excellent maintenance.',
    brand: 'Swaraj',
    model: '744 FE',
    year_of_manufacture: 2020,
    condition: 'good',
    hourly_rate: 400,
    daily_rate: 2800,
    weekly_rate: 16800,
    deposit_amount: 6000,
    location_address: 'Pune, Maharashtra',
    location_lat: 18.5204,
    location_lng: 73.8567,
    service_radius_km: 60,
    specifications: {
      horsepower: 48,
      engine: '3-cylinder',
      fuel: 'Diesel'
    },
    is_operator_included: false,
    minimum_rental_days: 1
  },
  {
    categoryName: 'Harvesters',
    name: 'John Deere Combine Harvester',
    description: 'Multi-crop combine harvester suitable for wheat, rice, and soybean.',
    brand: 'John Deere',
    model: 'W70',
    year_of_manufacture: 2019,
    condition: 'good',
    daily_rate: 15000,
    weekly_rate: 90000,
    deposit_amount: 25000,
    location_address: 'Indore, Madhya Pradesh',
    location_lat: 22.7196,
    location_lng: 75.8577,
    service_radius_km: 100,
    specifications: {
      grain_tank: '2500L',
      cutting_width: '14ft',
      suitable_crops: ['wheat', 'rice', 'soybean']
    },
    is_operator_included: true,
    operator_rate_per_day: 1200,
    minimum_rental_days: 2
  },
  {
    categoryName: 'Tillers & Cultivators',
    name: 'Honda FJ500 Power Tiller',
    description: 'Compact power tiller ideal for small and medium farms.',
    brand: 'Honda',
    model: 'FJ500',
    year_of_manufacture: 2022,
    condition: 'excellent',
    hourly_rate: 150,
    daily_rate: 1000,
    weekly_rate: 6000,
    deposit_amount: 2000,
    location_address: 'Nagpur, Maharashtra',
    location_lat: 21.1458,
    location_lng: 79.0882,
    service_radius_km: 30,
    specifications: {
      engine: '163cc',
      working_width: '60cm',
      weight: '52kg'
    },
    is_operator_included: false,
    minimum_rental_days: 1
  },
  {
    categoryName: 'Sprayers',
    name: 'Agricultural Drone Sprayer',
    description: 'DJI Agras T30 agricultural drone for precision spraying. Includes trained operator.',
    brand: 'DJI',
    model: 'Agras T30',
    year_of_manufacture: 2023,
    condition: 'excellent',
    daily_rate: 8000,
    deposit_amount: 20000,
    location_address: 'Hyderabad, Telangana',
    location_lat: 17.3850,
    location_lng: 78.4867,
    service_radius_km: 100,
    specifications: {
      tank_capacity: '30L',
      spray_width: '9m',
      flight_time: '15min per battery',
      coverage: '16 hectares/hour'
    },
    is_operator_included: true,
    operator_rate_per_day: 2000,
    minimum_rental_days: 1
  },
  {
    categoryName: 'Seed Drills & Planters',
    name: 'Seed Cum Fertilizer Drill',
    description: '9-row seed drill for wheat and pulses. Precision sowing capability.',
    brand: 'Fieldking',
    model: 'FSD-900',
    year_of_manufacture: 2021,
    condition: 'good',
    daily_rate: 1500,
    weekly_rate: 9000,
    deposit_amount: 3000,
    location_address: 'Jaipur, Rajasthan',
    location_lat: 26.9124,
    location_lng: 75.7873,
    service_radius_km: 50,
    specifications: {
      rows: 9,
      row_spacing: '22.5cm',
      seed_box_capacity: '60kg',
      fertilizer_box_capacity: '80kg'
    },
    is_operator_included: false,
    minimum_rental_days: 1
  },
  {
    categoryName: 'Irrigation Equipment',
    name: 'Portable Drip Irrigation Kit',
    description: 'Complete drip irrigation system for 1 acre. Easy setup and operation.',
    brand: 'Jain Irrigation',
    model: 'Micro Drip Kit',
    year_of_manufacture: 2022,
    condition: 'excellent',
    daily_rate: 500,
    weekly_rate: 3000,
    deposit_amount: 2000,
    location_address: 'Aurangabad, Maharashtra',
    location_lat: 19.8762,
    location_lng: 75.3433,
    service_radius_km: 40,
    specifications: {
      coverage: '1 acre',
      pump_included: true,
      drippers: 1000,
      main_pipe: '200m'
    },
    is_operator_included: false,
    minimum_rental_days: 7
  },
  {
    categoryName: 'Threshers',
    name: 'Multi-Crop Thresher',
    description: 'High-capacity thresher suitable for wheat, rice, soybean, and more.',
    brand: 'Shaktiman',
    model: 'MCT-3500',
    year_of_manufacture: 2020,
    condition: 'good',
    daily_rate: 3500,
    weekly_rate: 21000,
    deposit_amount: 7000,
    location_address: 'Bhopal, Madhya Pradesh',
    location_lat: 23.2599,
    location_lng: 77.4126,
    service_radius_km: 60,
    specifications: {
      capacity: '3500 kg/hr',
      power_requirement: '35-45 HP tractor',
      suitable_crops: ['wheat', 'rice', 'soybean', 'maize']
    },
    is_operator_included: true,
    operator_rate_per_day: 600,
    minimum_rental_days: 1
  }
];

async function seedEquipmentData() {
  console.log('Seeding equipment categories...');

  try {
    // Insert categories
    const categoryMap = {};
    for (const category of equipmentCategories) {
      const result = await db.query(`
        INSERT INTO equipment_categories (name, name_hi, description, icon)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT DO NOTHING
        RETURNING id, name
      `, [category.name, category.name_hi, category.description, category.icon]);

      if (result.rows.length > 0) {
        categoryMap[category.name] = result.rows[0].id;
        console.log(`  Created category: ${category.name}`);
      } else {
        // Get existing category ID
        const existing = await db.query('SELECT id FROM equipment_categories WHERE name = $1', [category.name]);
        if (existing.rows.length > 0) {
          categoryMap[category.name] = existing.rows[0].id;
        }
      }
    }

    console.log(`\nSeeded ${Object.keys(categoryMap).length} equipment categories`);

    // Get a sample user ID for listings
    const userResult = await db.query("SELECT id FROM users WHERE role = 'farmer' LIMIT 1");
    if (userResult.rows.length === 0) {
      console.log('No farmer user found. Skipping sample listings.');
      return { categories: Object.keys(categoryMap).length, listings: 0 };
    }

    const ownerId = userResult.rows[0].id;
    console.log('\nSeeding sample equipment listings...');

    let listingsCreated = 0;
    for (const listing of sampleListings) {
      const categoryId = categoryMap[listing.categoryName];
      if (!categoryId) {
        console.log(`  Skipping: ${listing.name} - category not found`);
        continue;
      }

      await db.query(`
        INSERT INTO equipment_listings (
          owner_id, category_id, name, description, brand, model,
          year_of_manufacture, condition, hourly_rate, daily_rate, weekly_rate,
          deposit_amount, location_address, location_lat, location_lng,
          service_radius_km, specifications, is_operator_included,
          operator_rate_per_day, minimum_rental_days
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
        ON CONFLICT DO NOTHING
      `, [
        ownerId, categoryId, listing.name, listing.description, listing.brand, listing.model,
        listing.year_of_manufacture, listing.condition, listing.hourly_rate, listing.daily_rate,
        listing.weekly_rate, listing.deposit_amount, listing.location_address,
        listing.location_lat, listing.location_lng, listing.service_radius_km,
        JSON.stringify(listing.specifications), listing.is_operator_included,
        listing.operator_rate_per_day, listing.minimum_rental_days
      ]);

      console.log(`  Created listing: ${listing.name}`);
      listingsCreated++;
    }

    console.log(`\nSeeded ${listingsCreated} sample equipment listings`);
    return { categories: Object.keys(categoryMap).length, listings: listingsCreated };
  } catch (error) {
    console.error('Error seeding equipment data:', error);
    throw error;
  }
}

module.exports = { seedEquipmentData, equipmentCategories };

// Run if called directly
if (require.main === module) {
  seedEquipmentData()
    .then((result) => {
      console.log('\nEquipment seed completed:', result);
      process.exit(0);
    })
    .catch((err) => {
      console.error('Equipment seed failed:', err);
      process.exit(1);
    });
}

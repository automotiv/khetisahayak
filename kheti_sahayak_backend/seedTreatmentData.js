const db = require('./db');

/**
 * Seed treatment data for top crop diseases in India
 * Data sourced from agricultural research and verified sources
 */

const cropDiseases = [
  // RICE DISEASES
  {
    disease_name: 'Rice Blast',
    scientific_name: 'Pyricularia oryzae (Magnaporthe grisea)',
    crop_type: 'Rice',
    description: 'One of the most destructive diseases of rice, causing significant yield losses worldwide.',
    symptoms: 'Diamond-shaped lesions with gray-white centers and brown margins on leaves; neck rot causing lodging; panicle infection leading to unfilled grains.',
    causes: 'Fungal pathogen favored by high humidity, moderate temperatures (20-30°C), and excessive nitrogen fertilization.',
    prevention: 'Use resistant varieties, avoid excessive nitrogen, maintain proper spacing, remove infected plant debris.',
    severity: 'high',
    ai_model_class: 'rice_blast'
  },
  {
    disease_name: 'Bacterial Leaf Blight',
    scientific_name: 'Xanthomonas oryzae pv. oryzae',
    crop_type: 'Rice',
    description: 'Major bacterial disease of rice causing significant yield losses across India.',
    symptoms: 'Water-soaked lesions turning yellow to white along leaf margins; kresek (wilting of seedlings); yellow bacterial ooze in the morning.',
    causes: 'Bacterial infection favored by high temperature (25-34°C), high humidity, and wounds from insects or wind.',
    prevention: 'Use resistant varieties, avoid injury to plants, maintain proper water management, use disease-free seeds.',
    severity: 'high',
    ai_model_class: 'bacterial_blight_rice'
  },
  {
    disease_name: 'Brown Spot',
    scientific_name: 'Bipolaris oryzae',
    crop_type: 'Rice',
    description: 'Common fungal disease often called seedling blight affecting rice at all growth stages.',
    symptoms: 'Circular to oval brown spots with gray centers on leaves; spots on panicles causing grain discoloration; seedling death.',
    causes: 'Fungal pathogen favored by nutrient-deficient soils, drought stress, and high humidity.',
    prevention: 'Use healthy seeds, apply balanced fertilizers, maintain adequate soil moisture, rotate crops.',
    severity: 'moderate',
    ai_model_class: 'brown_spot_rice'
  },
  {
    disease_name: 'Sheath Blight',
    scientific_name: 'Rhizoctonia solani',
    crop_type: 'Rice',
    description: 'Soil-borne fungal disease causing significant damage in irrigated and high-yielding rice varieties.',
    symptoms: 'Oval to irregular greenish-gray lesions on leaf sheaths near water line; lesions with brown margins; sclerotia formation.',
    causes: 'Fungal pathogen favored by high humidity, dense planting, excessive nitrogen, and standing water.',
    prevention: 'Maintain proper spacing, avoid excessive nitrogen, drain fields periodically, use resistant varieties.',
    severity: 'moderate',
    ai_model_class: 'sheath_blight'
  },

  // WHEAT DISEASES
  {
    disease_name: 'Wheat Rust (Yellow Rust)',
    scientific_name: 'Puccinia striiformis',
    crop_type: 'Wheat',
    description: 'Most widespread and destructive rust disease of wheat in India.',
    symptoms: 'Yellow-orange pustules in linear rows on leaves; chlorotic areas around pustules; premature leaf senescence.',
    causes: 'Fungal pathogen favored by cool temperatures (10-15°C), high humidity, and dew formation.',
    prevention: 'Use resistant varieties, monitor and scout early, remove volunteer wheat, timely sowing.',
    severity: 'high',
    ai_model_class: 'yellow_rust_wheat'
  },
  {
    disease_name: 'Wheat Rust (Brown Rust)',
    scientific_name: 'Puccinia recondita',
    crop_type: 'Wheat',
    description: 'Common rust disease affecting wheat during grain filling stage.',
    symptoms: 'Small circular to oval brown pustules scattered on upper leaf surface; premature drying of leaves.',
    causes: 'Fungal pathogen favored by moderate temperatures (15-25°C) and high humidity.',
    prevention: 'Use resistant varieties, early sowing, balanced fertilization, remove infected debris.',
    severity: 'moderate',
    ai_model_class: 'brown_rust_wheat'
  },
  {
    disease_name: 'Powdery Mildew (Wheat)',
    scientific_name: 'Blumeria graminis f.sp. tritici',
    crop_type: 'Wheat',
    description: 'Fungal disease common in wheat-growing areas with cool and humid conditions.',
    symptoms: 'White powdery fungal growth on leaves, stems, and spikes; yellowing and premature senescence.',
    causes: 'Fungal pathogen favored by moderate temperatures (15-22°C), high humidity, and dense canopy.',
    prevention: 'Use resistant varieties, maintain plant spacing, balanced nitrogen, avoid late sowing.',
    severity: 'moderate',
    ai_model_class: 'powdery_mildew_wheat'
  },

  // COTTON DISEASES
  {
    disease_name: 'Cotton Leaf Curl Virus',
    scientific_name: 'Begomovirus transmitted by whitefly',
    crop_type: 'Cotton',
    description: 'Devastating viral disease causing major yield losses in cotton.',
    symptoms: 'Upward and downward curling of leaves; thickening of veins; reduced leaf size; stunted plant growth.',
    causes: 'Viral infection transmitted by whiteflies; favored by warm weather and presence of alternate hosts.',
    prevention: 'Use resistant varieties, control whitefly population, remove infected plants, avoid mixed cropping.',
    severity: 'severe',
    ai_model_class: 'cotton_leaf_curl'
  },
  {
    disease_name: 'Bacterial Blight (Cotton)',
    scientific_name: 'Xanthomonas citri pv. malvacearum',
    crop_type: 'Cotton',
    description: 'Important bacterial disease affecting cotton in humid regions.',
    symptoms: 'Angular water-soaked lesions on leaves; black arm symptoms on stems and branches; boll rot.',
    causes: 'Bacterial infection favored by warm humid weather, overhead irrigation, and wounds.',
    prevention: 'Use disease-free seeds, avoid overhead irrigation, remove infected plants, crop rotation.',
    severity: 'high',
    ai_model_class: 'bacterial_blight_cotton'
  },

  // TOMATO DISEASES
  {
    disease_name: 'Early Blight (Tomato)',
    scientific_name: 'Alternaria solani',
    crop_type: 'Tomato',
    description: 'Common fungal disease of tomato causing foliar and fruit lesions.',
    symptoms: 'Circular brown spots with concentric rings (target-like) on older leaves; collar rot on seedlings; fruit lesions near stem end.',
    causes: 'Fungal pathogen favored by warm temperatures (24-29°C), high humidity, and nutrient stress.',
    prevention: 'Use disease-free seeds, crop rotation, proper spacing, balanced nutrition, drip irrigation.',
    severity: 'moderate',
    ai_model_class: 'early_blight_tomato'
  },
  {
    disease_name: 'Late Blight (Tomato)',
    scientific_name: 'Phytophthora infestans',
    crop_type: 'Tomato',
    description: 'Highly destructive disease capable of destroying entire tomato crops within days.',
    symptoms: 'Large dark brown to black water-soaked lesions on leaves; white fungal growth on underside; fruit rot.',
    causes: 'Oomycete pathogen favored by cool temperatures (15-20°C), high humidity, and leaf wetness.',
    prevention: 'Use resistant varieties, avoid overhead irrigation, proper spacing, remove volunteer plants.',
    severity: 'severe',
    ai_model_class: 'late_blight_tomato'
  },
  {
    disease_name: 'Bacterial Wilt (Tomato)',
    scientific_name: 'Ralstonia solanacearum',
    crop_type: 'Tomato',
    description: 'Devastating soil-borne bacterial disease with no effective cure.',
    symptoms: 'Sudden wilting of entire plant without yellowing; browning of vascular tissue; bacterial ooze from cut stems.',
    causes: 'Soil-borne bacteria favored by warm temperatures (24-35°C), high soil moisture, and acidic soils.',
    prevention: 'Crop rotation, soil solarization, use resistant varieties, avoid waterlogging, remove infected plants.',
    severity: 'severe',
    ai_model_class: 'bacterial_wilt_tomato'
  },

  // POTATO DISEASES
  {
    disease_name: 'Late Blight (Potato)',
    scientific_name: 'Phytophthora infestans',
    crop_type: 'Potato',
    description: 'Most destructive disease of potato capable of causing total crop loss.',
    symptoms: 'Dark brown to black lesions on leaves with white fungal growth on underside; tuber rot with reddish-brown granular decay.',
    causes: 'Oomycete pathogen favored by cool moist weather (15-20°C), high humidity, and prolonged leaf wetness.',
    prevention: 'Use certified disease-free seeds, hilling, proper drainage, fungicide sprays, early harvest.',
    severity: 'severe',
    ai_model_class: 'late_blight_potato'
  },
  {
    disease_name: 'Early Blight (Potato)',
    scientific_name: 'Alternaria solani',
    crop_type: 'Potato',
    description: 'Common foliar disease affecting potato in warm dry conditions.',
    symptoms: 'Dark brown target-like lesions on older leaves; defoliation from bottom upward; dry tuber rot.',
    causes: 'Fungal pathogen favored by warm temperatures (25-30°C), alternating wet-dry periods, and plant stress.',
    prevention: 'Use disease-free seeds, balanced nutrition, proper spacing, fungicide application.',
    severity: 'moderate',
    ai_model_class: 'early_blight_potato'
  },

  // CHILLI DISEASES
  {
    disease_name: 'Chilli Leaf Curl',
    scientific_name: 'Begomovirus',
    crop_type: 'Chilli',
    description: 'Viral disease transmitted by whiteflies causing severe yield loss.',
    symptoms: 'Upward curling and crinkling of leaves; yellowing of veins; reduced fruit size and number.',
    causes: 'Viral infection transmitted by whiteflies; favored by warm weather and presence of weed hosts.',
    prevention: 'Use virus-free seeds, control whiteflies, remove infected plants, use reflective mulch.',
    severity: 'high',
    ai_model_class: 'chilli_leaf_curl'
  },

  // MAIZE/CORN DISEASES
  {
    disease_name: 'Turcicum Leaf Blight',
    scientific_name: 'Exserohilum turcicum',
    crop_type: 'Maize',
    description: 'Major foliar disease of maize in temperate and subtropical regions.',
    symptoms: 'Long elliptical gray-green lesions with dark borders on leaves; extensive blighting in susceptible varieties.',
    causes: 'Fungal pathogen favored by moderate temperatures (18-27°C), high humidity, and dew formation.',
    prevention: 'Use resistant hybrids, crop rotation, deep plowing of crop residue, balanced fertilization.',
    severity: 'moderate',
    ai_model_class: 'turcicum_blight'
  }
];

const treatmentRecommendations = [
  // RICE BLAST TREATMENTS
  {
    disease_ref: 'Rice Blast',
    treatments: [
      {
        treatment_type: 'chemical',
        treatment_name: 'Tricyclazole',
        active_ingredient: 'Tricyclazole 75% WP',
        dosage: '0.6g per liter of water',
        application_method: 'Foliar spray covering both sides of leaves',
        timing: 'At first appearance of disease, repeat every 10-15 days',
        frequency: '2-3 applications per season',
        precautions: 'Avoid spraying during flowering. Do not mix with alkaline pesticides. PHI: 21 days',
        effectiveness_rating: 5,
        cost_estimate: '₹300-400 per acre',
        availability: 'easily_available',
        notes: 'Most effective fungicide for rice blast control'
      },
      {
        treatment_type: 'chemical',
        treatment_name: 'Carbendazim + Mancozeb',
        active_ingredient: 'Carbendazim 12% + Mancozeb 63% WP',
        dosage: '2g per liter of water',
        application_method: 'Foliar spray ensuring good coverage',
        timing: 'Preventive spray before disease onset or at first symptoms',
        frequency: '2 applications at 15-day interval',
        precautions: 'Use protective equipment. Avoid fish ponds. PHI: 15 days',
        effectiveness_rating: 4,
        cost_estimate: '₹250-350 per acre',
        availability: 'easily_available',
        notes: 'Good for both preventive and curative action'
      },
      {
        treatment_type: 'organic',
        treatment_name: 'Neem Oil + Pseudomonas',
        active_ingredient: 'Neem oil 1500 ppm + Pseudomonas fluorescens',
        dosage: '5ml neem oil + 10g Pseudomonas per liter',
        application_method: 'Foliar spray in evening hours',
        timing: 'Preventive sprays at 15-day intervals from tillering',
        frequency: '3-4 applications',
        precautions: 'Do not spray in hot sun. Mix fresh before use',
        effectiveness_rating: 3,
        cost_estimate: '₹200-300 per acre',
        availability: 'locally_available',
        notes: 'Suitable for organic farming; better as preventive measure'
      }
    ]
  },

  // RICE BACTERIAL BLIGHT TREATMENTS
  {
    disease_ref: 'Bacterial Leaf Blight',
    treatments: [
      {
        treatment_type: 'chemical',
        treatment_name: 'Copper Oxychloride',
        active_ingredient: 'Copper Oxychloride 50% WP',
        dosage: '3g per liter of water',
        application_method: 'Foliar spray ensuring thorough coverage',
        timing: 'At first disease symptoms, repeat at 10-day intervals',
        frequency: '2-3 applications',
        precautions: 'Avoid use during flowering. PHI: 7 days. May cause phytotoxicity in some varieties',
        effectiveness_rating: 4,
        cost_estimate: '₹200-300 per acre',
        availability: 'easily_available',
        notes: 'Most commonly used bactericide for bacterial diseases'
      },
      {
        treatment_type: 'chemical',
        treatment_name: 'Streptocycline',
        active_ingredient: 'Streptomycin Sulphate 90% + Tetracycline Hydrochloride 10%',
        dosage: '1g per 10 liters of water',
        application_method: 'Foliar spray in early morning or evening',
        timing: 'At disease initiation or on appearance of symptoms',
        frequency: '2 sprays at 10-day interval',
        precautions: 'Use only when necessary. Avoid frequent use to prevent resistance',
        effectiveness_rating: 4,
        cost_estimate: '₹150-250 per acre',
        availability: 'locally_available',
        notes: 'Antibiotic; use judiciously to avoid resistance development'
      },
      {
        treatment_type: 'organic',
        treatment_name: 'Pseudomonas fluorescens',
        active_ingredient: 'Pseudomonas fluorescens bacterial culture',
        dosage: '10g per liter for spray; 2.5kg/acre for soil application',
        application_method: 'Foliar spray and soil application',
        timing: 'Preventive application from nursery stage',
        frequency: '3-4 applications at 15-day intervals',
        precautions: 'Store in cool place. Use within expiry date',
        effectiveness_rating: 3,
        cost_estimate: '₹250-350 per acre',
        availability: 'locally_available',
        notes: 'Biocontrol agent; excellent for preventive management'
      }
    ]
  },

  // WHEAT YELLOW RUST TREATMENTS
  {
    disease_ref: 'Wheat Rust (Yellow Rust)',
    treatments: [
      {
        treatment_type: 'chemical',
        treatment_name: 'Propiconazole',
        active_ingredient: 'Propiconazole 25% EC',
        dosage: '1ml per liter of water (200-250ml/acre)',
        application_method: 'Foliar spray ensuring coverage of leaves',
        timing: 'At first rust appearance, repeat if necessary',
        frequency: '1-2 applications at 15-day interval',
        precautions: 'Use protective equipment. Avoid drift to other crops. PHI: 35 days',
        effectiveness_rating: 5,
        cost_estimate: '₹400-500 per acre',
        availability: 'easily_available',
        notes: 'Highly effective systemic fungicide with protective and curative action'
      },
      {
        treatment_type: 'chemical',
        treatment_name: 'Mancozeb',
        active_ingredient: 'Mancozeb 75% WP',
        dosage: '2.5g per liter of water',
        application_method: 'Foliar spray with good coverage',
        timing: 'Preventive spray before disease or at first symptoms',
        frequency: '2-3 applications at 10-15 day intervals',
        precautions: 'Use protective gear. Keep away from water bodies. PHI: 15 days',
        effectiveness_rating: 4,
        cost_estimate: '₹300-400 per acre',
        availability: 'easily_available',
        notes: 'Good contact fungicide for preventive control'
      },
      {
        treatment_type: 'organic',
        treatment_name: 'Sulfur Dust',
        active_ingredient: 'Sulfur 80% WP',
        dosage: '3g per liter for spray or 20kg/acre as dust',
        application_method: 'Dusting in morning dew or foliar spray',
        timing: 'Preventive application from boot leaf stage',
        frequency: '2-3 applications at 10-day intervals',
        precautions: 'Avoid use when temperature > 35°C. May cause phytotoxicity in hot weather',
        effectiveness_rating: 3,
        cost_estimate: '₹200-300 per acre',
        availability: 'easily_available',
        notes: 'Traditional organic fungicide; better for prevention'
      }
    ]
  },

  // COTTON LEAF CURL VIRUS TREATMENTS
  {
    disease_ref: 'Cotton Leaf Curl Virus',
    treatments: [
      {
        treatment_type: 'chemical',
        treatment_name: 'Imidacloprid (Vector Control)',
        active_ingredient: 'Imidacloprid 17.8% SL',
        dosage: '0.5ml per liter for spray; 15ml/kg for seed treatment',
        application_method: 'Foliar spray or seed treatment',
        timing: 'Seed treatment before sowing; foliar spray for whitefly control',
        frequency: '2-3 sprays at 15-day intervals',
        precautions: 'Use protective equipment. Toxic to bees - avoid spraying during flowering. PHI: 3 days',
        effectiveness_rating: 4,
        cost_estimate: '₹300-400 per acre',
        availability: 'easily_available',
        notes: 'Controls whitefly vector; no direct effect on virus. Use in rotation to avoid resistance'
      },
      {
        treatment_type: 'cultural',
        treatment_name: 'Resistant Variety + Rogue Infected Plants',
        active_ingredient: 'N/A - Cultural practice',
        dosage: 'N/A',
        application_method: 'Use virus-resistant/tolerant varieties; remove and destroy infected plants immediately',
        timing: 'Use resistant varieties from planting; rogue infected plants throughout season',
        frequency: 'Continuous monitoring and removal',
        precautions: 'Destroy infected plants by burning, do not compost',
        effectiveness_rating: 5,
        cost_estimate: '₹0 (except variety cost)',
        availability: 'easily_available',
        notes: 'Most effective long-term strategy for viral disease management'
      },
      {
        treatment_type: 'organic',
        treatment_name: 'Neem Oil + Yellow Sticky Traps',
        active_ingredient: 'Neem oil 1500ppm',
        dosage: '5ml per liter for spray; 8-10 traps per acre',
        application_method: 'Foliar spray + sticky trap installation',
        timing: 'Preventive sprays from early growth; traps from planting',
        frequency: '2-3 sprays at 10-day intervals',
        precautions: 'Spray in evening hours. Replace traps when fully covered',
        effectiveness_rating: 3,
        cost_estimate: '₹250-350 per acre',
        availability: 'locally_available',
        notes: 'Helps reduce whitefly population; suitable for organic farming'
      }
    ]
  },

  // TOMATO LATE BLIGHT TREATMENTS
  {
    disease_ref: 'Late Blight (Tomato)',
    treatments: [
      {
        treatment_type: 'chemical',
        treatment_name: 'Metalaxyl + Mancozeb',
        active_ingredient: 'Metalaxyl 8% + Mancozeb 64% WP',
        dosage: '2.5g per liter of water',
        application_method: 'Thorough foliar spray covering all plant parts',
        timing: 'Preventive sprays in cool humid weather or at first symptoms',
        frequency: '3-4 applications at 7-10 day intervals',
        precautions: 'Use protective equipment. Do not exceed recommended dose. PHI: 7 days. Rotate with other fungicides',
        effectiveness_rating: 5,
        cost_estimate: '₹400-500 per acre',
        availability: 'easily_available',
        notes: 'Most effective for late blight; systemic and contact action'
      },
      {
        treatment_type: 'chemical',
        treatment_name: 'Cymoxanil + Mancozeb',
        active_ingredient: 'Cymoxanil 8% + Mancozeb 64% WP',
        dosage: '2g per liter of water',
        application_method: 'Foliar spray ensuring good coverage',
        timing: 'At disease onset or preventive in favorable weather',
        frequency: '2-3 applications at 10-day interval',
        precautions: 'Wear protective gear. Avoid water contamination. PHI: 14 days',
        effectiveness_rating: 5,
        cost_estimate: '₹350-450 per acre',
        availability: 'easily_available',
        notes: 'Excellent curative and preventive action'
      },
      {
        treatment_type: 'organic',
        treatment_name: 'Copper Hydroxide',
        active_ingredient: 'Copper Hydroxide 77% WP',
        dosage: '2g per liter of water',
        application_method: 'Foliar spray in morning or evening',
        timing: 'Preventive sprays before disease onset',
        frequency: '3-4 applications at 7-day intervals',
        precautions: 'Avoid use during fruit ripening. May cause phytotoxicity in some varieties',
        effectiveness_rating: 3,
        cost_estimate: '₹250-350 per acre',
        availability: 'locally_available',
        notes: 'OMRI approved for organic farming; mainly preventive'
      }
    ]
  },

  // POTATO LATE BLIGHT TREATMENTS
  {
    disease_ref: 'Late Blight (Potato)',
    treatments: [
      {
        treatment_type: 'chemical',
        treatment_name: 'Dimethomorph + Mancozeb',
        active_ingredient: 'Dimethomorph 9% + Mancozeb 60% WP',
        dosage: '2g per liter of water',
        application_method: 'Thorough foliar spray covering foliage',
        timing: 'Preventive sprays before disease or at first symptoms',
        frequency: '3-4 applications at 7-10 day intervals',
        precautions: 'Rotate with other mode-of-action fungicides. PHI: 15 days',
        effectiveness_rating: 5,
        cost_estimate: '₹500-600 per acre',
        availability: 'locally_available',
        notes: 'Excellent systemic and contact activity; use in anti-resistance strategy'
      },
      {
        treatment_type: 'chemical',
        treatment_name: 'Chlorothalonil',
        active_ingredient: 'Chlorothalonil 75% WP',
        dosage: '2g per liter of water',
        application_method: 'Foliar spray with good coverage',
        timing: 'Preventive applications before disease',
        frequency: '3-4 sprays at 7-10 day intervals',
        precautions: 'Use protective equipment. Toxic to fish. PHI: 7 days',
        effectiveness_rating: 4,
        cost_estimate: '₹350-450 per acre',
        availability: 'easily_available',
        notes: 'Broad-spectrum contact fungicide; excellent for prevention'
      },
      {
        treatment_type: 'cultural',
        treatment_name: 'Certified Seeds + Hilling + Early Harvest',
        active_ingredient: 'N/A - Cultural practice',
        dosage: 'N/A',
        application_method: 'Use certified disease-free seeds; proper hilling to protect tubers; harvest early if disease severe',
        timing: 'Certified seeds at planting; hilling at proper stage; early harvest if needed',
        frequency: 'As per crop requirement',
        precautions: 'Ensure complete coverage of tubers during hilling',
        effectiveness_rating: 4,
        cost_estimate: 'Variable',
        availability: 'easily_available',
        notes: 'Critical for disease management; prevents tuber infection'
      }
    ]
  }
];

async function seedTreatmentDatabase() {
  const client = await db.pool.connect();

  try {
    await client.query('BEGIN');

    console.log('Starting to seed crop diseases and treatment data...');

    // Insert diseases and collect IDs
    const diseaseIdMap = {};

    for (const disease of cropDiseases) {
      const result = await client.query(
        `INSERT INTO crop_diseases
        (disease_name, scientific_name, crop_type, description, symptoms, causes, prevention, severity, ai_model_class)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id`,
        [
          disease.disease_name,
          disease.scientific_name,
          disease.crop_type,
          disease.description,
          disease.symptoms,
          disease.causes,
          disease.prevention,
          disease.severity,
          disease.ai_model_class
        ]
      );

      diseaseIdMap[disease.disease_name] = result.rows[0].id;
      console.log(`✓ Inserted disease: ${disease.disease_name} (ID: ${result.rows[0].id})`);
    }

    // Insert treatments
    let treatmentCount = 0;
    for (const diseaseWithTreatments of treatmentRecommendations) {
      const diseaseId = diseaseIdMap[diseaseWithTreatments.disease_ref];

      if (!diseaseId) {
        console.error(`✗ Disease not found: ${diseaseWithTreatments.disease_ref}`);
        continue;
      }

      for (const treatment of diseaseWithTreatments.treatments) {
        await client.query(
          `INSERT INTO treatment_recommendations
          (disease_id, treatment_type, treatment_name, active_ingredient, dosage,
           application_method, timing, frequency, precautions, effectiveness_rating,
           cost_estimate, availability, notes)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`,
          [
            diseaseId,
            treatment.treatment_type,
            treatment.treatment_name,
            treatment.active_ingredient,
            treatment.dosage,
            treatment.application_method,
            treatment.timing,
            treatment.frequency,
            treatment.precautions,
            treatment.effectiveness_rating,
            treatment.cost_estimate,
            treatment.availability,
            treatment.notes
          ]
        );
        treatmentCount++;
      }
      console.log(`✓ Inserted ${diseaseWithTreatments.treatments.length} treatments for ${diseaseWithTreatments.disease_ref}`);
    }

    await client.query('COMMIT');

    console.log('\n=== Seeding Complete ===');
    console.log(`Total diseases inserted: ${cropDiseases.length}`);
    console.log(`Total treatments inserted: ${treatmentCount}`);
    console.log('Database seeded successfully!');

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error seeding database:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Run if executed directly
if (require.main === module) {
  seedTreatmentDatabase()
    .then(() => {
      console.log('Seed process completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Seed process failed:', error);
      process.exit(1);
    });
}

module.exports = { seedTreatmentDatabase, cropDiseases, treatmentRecommendations };

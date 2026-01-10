"""
Comprehensive Disease Database for Kheti Sahayak
Contains disease information for 20+ crops commonly grown in India
"""

from typing import Dict, List, Any

# Comprehensive crop disease database with treatments in English and Hindi
CROP_DISEASES: Dict[str, Dict[str, Dict[str, Any]]] = {
    # ===== CEREALS =====
    "rice": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Maintain proper water management", "Use balanced fertilizers", "Practice crop rotation"],
            "severity": "none"
        },
        "rice_blast": {
            "name": "Rice Blast",
            "hindi_name": "धान का झुलसा",
            "description": "Fungal disease caused by Magnaporthe oryzae affecting leaves, nodes, and panicles.",
            "hindi_description": "मैग्नापोर्थे ओराइज़े कवक द्वारा होने वाला रोग जो पत्तियों, गांठों और बालियों को प्रभावित करता है।",
            "symptoms": [
                "Diamond-shaped lesions on leaves",
                "Gray-green lesions with brown margins",
                "Neck rot and panicle blast",
                "White or gray centers in lesions"
            ],
            "causes": [
                "Fungal pathogen Magnaporthe oryzae",
                "High nitrogen fertilization",
                "Continuous wet conditions",
                "Susceptible varieties"
            ],
            "treatments": [
                {"type": "chemical", "name": "Tricyclazole 75% WP", "dosage": "0.6 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Carbendazim 50% WP", "dosage": "1 g/liter water", "application": "Foliar spray"},
                {"type": "biological", "name": "Pseudomonas fluorescens", "dosage": "10 g/liter water", "application": "Seed treatment and spray"},
                {"type": "organic", "name": "Neem oil", "dosage": "3-5 ml/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Use resistant varieties (Pusa Basmati 1121, IR-64)",
                "Balanced nitrogen fertilization",
                "Proper water management",
                "Remove and destroy infected plant debris",
                "Avoid late planting"
            ],
            "severity": "high"
        },
        "bacterial_leaf_blight": {
            "name": "Bacterial Leaf Blight",
            "hindi_name": "जीवाणु पत्ती अंगमारी",
            "description": "Bacterial disease caused by Xanthomonas oryzae pv. oryzae.",
            "hindi_description": "ज़ैंथोमोनास ओराइज़े द्वारा होने वाला जीवाणु रोग।",
            "symptoms": [
                "Water-soaked lesions on leaf tips",
                "Yellow to white lesions along veins",
                "Leaves dry and wither",
                "Bacterial ooze on infected leaves"
            ],
            "causes": [
                "Xanthomonas oryzae bacteria",
                "Wounds from insects or mechanical damage",
                "High nitrogen and humidity",
                "Contaminated seeds"
            ],
            "treatments": [
                {"type": "chemical", "name": "Streptocycline", "dosage": "0.5 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Copper oxychloride", "dosage": "3 g/liter water", "application": "Foliar spray"},
                {"type": "biological", "name": "Bacillus subtilis", "dosage": "5 g/liter water", "application": "Seed treatment"}
            ],
            "prevention": [
                "Use certified disease-free seeds",
                "Grow resistant varieties",
                "Avoid excess nitrogen",
                "Drain fields periodically",
                "Control insect vectors"
            ],
            "severity": "high"
        },
        "brown_spot": {
            "name": "Brown Spot",
            "hindi_name": "भूरा धब्बा",
            "description": "Fungal disease caused by Bipolaris oryzae.",
            "hindi_description": "बाइपोलारिस ओराइज़े कवक द्वारा होने वाला रोग।",
            "symptoms": [
                "Oval brown spots on leaves",
                "Spots with gray centers",
                "Grain discoloration",
                "Seedling blight"
            ],
            "causes": [
                "Bipolaris oryzae fungus",
                "Nutrient deficiency (potassium, silicon)",
                "Poor soil health",
                "Drought stress"
            ],
            "treatments": [
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Propiconazole 25% EC", "dosage": "1 ml/liter water", "application": "Foliar spray"},
                {"type": "organic", "name": "Trichoderma viride", "dosage": "4 g/kg seed", "application": "Seed treatment"}
            ],
            "prevention": [
                "Balanced fertilization with potassium",
                "Proper water management",
                "Use disease-free seeds",
                "Apply silicon fertilizers"
            ],
            "severity": "medium"
        },
        "tungro": {
            "name": "Tungro",
            "hindi_name": "टुंग्रो",
            "description": "Viral disease transmitted by green leafhoppers.",
            "hindi_description": "हरे फुदके द्वारा फैलने वाला विषाणु रोग।",
            "symptoms": [
                "Yellow-orange leaf discoloration",
                "Stunted plant growth",
                "Reduced tillering",
                "Delayed flowering"
            ],
            "causes": [
                "Rice tungro bacilliform virus (RTBV)",
                "Rice tungro spherical virus (RTSV)",
                "Green leafhopper vectors"
            ],
            "treatments": [
                {"type": "chemical", "name": "Imidacloprid 17.8% SL", "dosage": "0.3 ml/liter water", "application": "Spray for vector control"},
                {"type": "chemical", "name": "Thiamethoxam 25% WG", "dosage": "0.2 g/liter water", "application": "Spray for vector control"}
            ],
            "prevention": [
                "Use resistant varieties",
                "Synchronize planting",
                "Remove infected plants",
                "Control leafhopper population",
                "Maintain field hygiene"
            ],
            "severity": "high"
        },
        "hispa": {
            "name": "Rice Hispa",
            "hindi_name": "हिस्पा",
            "description": "Insect pest damage caused by rice hispa beetle.",
            "hindi_description": "धान के हिस्पा कीट द्वारा होने वाला नुकसान।",
            "symptoms": [
                "White parallel streaks on leaves",
                "Scraping of upper leaf surface",
                "Tunneling by larvae",
                "Leaves turn white and dry"
            ],
            "causes": [
                "Dicladispa armigera beetle",
                "High nitrogen application",
                "Continuous rice cropping"
            ],
            "treatments": [
                {"type": "chemical", "name": "Chlorpyrifos 20% EC", "dosage": "2.5 ml/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Quinalphos 25% EC", "dosage": "2 ml/liter water", "application": "Foliar spray"},
                {"type": "biological", "name": "Neem-based insecticide", "dosage": "5 ml/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Avoid excessive nitrogen",
                "Clipping of leaf tips",
                "Remove grassy weeds",
                "Use light traps"
            ],
            "severity": "medium"
        },
        "sheath_blight": {
            "name": "Sheath Blight",
            "hindi_name": "शीथ ब्लाइट",
            "description": "Fungal disease caused by Rhizoctonia solani.",
            "hindi_description": "राइज़ोक्टोनिया सोलानी कवक द्वारा होने वाला रोग।",
            "symptoms": [
                "Oval greenish-gray lesions on sheath",
                "Lesions with irregular margins",
                "Lodging of plants",
                "Infected grains"
            ],
            "causes": [
                "Rhizoctonia solani fungus",
                "High plant density",
                "Excess nitrogen",
                "Warm humid conditions"
            ],
            "treatments": [
                {"type": "chemical", "name": "Hexaconazole 5% EC", "dosage": "2 ml/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Validamycin 3% L", "dosage": "2 ml/liter water", "application": "Foliar spray"},
                {"type": "biological", "name": "Trichoderma harzianum", "dosage": "4 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Optimal plant spacing",
                "Balanced fertilization",
                "Drain excess water",
                "Remove crop residues"
            ],
            "severity": "medium"
        }
    },
    
    "wheat": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Use certified seeds", "Practice crop rotation", "Maintain field hygiene"],
            "severity": "none"
        },
        "rust": {
            "name": "Wheat Rust",
            "hindi_name": "गेहूं का गेरुआ",
            "description": "Fungal disease causing orange-brown pustules on leaves and stems.",
            "hindi_description": "पत्तियों और तनों पर नारंगी-भूरे रंग के छाले पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Orange-brown pustules on leaves",
                "Yellow rust stripes",
                "Stem rust on stems",
                "Shriveled grains"
            ],
            "causes": [
                "Puccinia species fungi",
                "Cool wet weather",
                "Susceptible varieties",
                "Late sowing"
            ],
            "treatments": [
                {"type": "chemical", "name": "Propiconazole 25% EC", "dosage": "1 ml/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Tebuconazole 25.9% EC", "dosage": "1 ml/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Grow resistant varieties",
                "Timely sowing",
                "Balanced fertilization",
                "Remove volunteer plants"
            ],
            "severity": "high"
        },
        "powdery_mildew": {
            "name": "Powdery Mildew",
            "hindi_name": "चूर्णिल आसिता",
            "description": "Fungal disease causing white powdery coating on leaves.",
            "hindi_description": "पत्तियों पर सफेद पाउडर जैसी परत बनाने वाला कवक रोग।",
            "symptoms": [
                "White powdery patches on leaves",
                "Yellowing of leaves",
                "Premature leaf death",
                "Reduced grain quality"
            ],
            "causes": [
                "Blumeria graminis fungus",
                "Moderate temperatures",
                "High humidity",
                "Dense planting"
            ],
            "treatments": [
                {"type": "chemical", "name": "Sulfur 80% WP", "dosage": "3 g/liter water", "application": "Dusting"},
                {"type": "chemical", "name": "Hexaconazole 5% EC", "dosage": "1 ml/liter water", "application": "Foliar spray"},
                {"type": "organic", "name": "Neem oil", "dosage": "5 ml/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Resistant varieties",
                "Proper spacing",
                "Avoid excess nitrogen",
                "Early sowing"
            ],
            "severity": "medium"
        },
        "loose_smut": {
            "name": "Loose Smut",
            "hindi_name": "खुला कंड",
            "description": "Seed-borne fungal disease replacing grains with black spores.",
            "hindi_description": "बीज जनित कवक रोग जो दानों को काले बीजाणुओं से बदल देता है।",
            "symptoms": [
                "Black powdery mass in place of grains",
                "Infected heads emerge early",
                "Spores disperse in wind"
            ],
            "causes": [
                "Ustilago tritici fungus",
                "Infected seed",
                "Warm humid conditions"
            ],
            "treatments": [
                {"type": "chemical", "name": "Carboxin 37.5% + Thiram 37.5% DS", "dosage": "2.5 g/kg seed", "application": "Seed treatment"},
                {"type": "chemical", "name": "Tebuconazole 2% DS", "dosage": "1.5 g/kg seed", "application": "Seed treatment"}
            ],
            "prevention": [
                "Use certified disease-free seeds",
                "Hot water seed treatment (52°C for 10 min)",
                "Seed treatment before sowing"
            ],
            "severity": "medium"
        },
        "karnal_bunt": {
            "name": "Karnal Bunt",
            "hindi_name": "करनाल बंट",
            "description": "Fungal disease partially converting grains to black powder.",
            "hindi_description": "कवक रोग जो दानों को आंशिक रूप से काले पाउडर में बदल देता है।",
            "symptoms": [
                "Partial grain conversion to black powder",
                "Fishy smell in infected grains",
                "Grain discoloration"
            ],
            "causes": [
                "Tilletia indica fungus",
                "Cool temperatures during flowering",
                "High humidity"
            ],
            "treatments": [
                {"type": "chemical", "name": "Propiconazole 25% EC", "dosage": "0.1% spray", "application": "At boot stage"},
                {"type": "chemical", "name": "Thiram 75% WP", "dosage": "2.5 g/kg seed", "application": "Seed treatment"}
            ],
            "prevention": [
                "Use certified seeds",
                "Early sowing",
                "Avoid late irrigation",
                "Deep plowing"
            ],
            "severity": "medium"
        }
    },
    
    "maize": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Crop rotation", "Proper drainage", "Balanced nutrition"],
            "severity": "none"
        },
        "northern_leaf_blight": {
            "name": "Northern Leaf Blight",
            "hindi_name": "उत्तरी पत्ती झुलसा",
            "description": "Fungal disease causing long cigar-shaped lesions.",
            "hindi_description": "लंबे सिगार के आकार के घाव पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Long gray-green lesions",
                "Lesions 1-6 inches long",
                "Lesions turn tan with age",
                "Severe defoliation"
            ],
            "causes": [
                "Exserohilum turcicum fungus",
                "Moderate temperatures",
                "Wet conditions",
                "Susceptible hybrids"
            ],
            "treatments": [
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Propiconazole 25% EC", "dosage": "1 ml/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Plant resistant hybrids",
                "Crop rotation with non-hosts",
                "Residue management",
                "Balanced fertilization"
            ],
            "severity": "medium"
        },
        "maize_rust": {
            "name": "Common Rust",
            "hindi_name": "सामान्य गेरुआ",
            "description": "Fungal disease causing reddish-brown pustules.",
            "hindi_description": "लाल-भूरे रंग के छाले पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Circular to elongated rust pustules",
                "Pustules on both leaf surfaces",
                "Reddish-brown spore masses",
                "Premature leaf death"
            ],
            "causes": [
                "Puccinia sorghi fungus",
                "Cool humid weather",
                "Heavy dew"
            ],
            "treatments": [
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Trifloxystrobin 25% + Tebuconazole 50% WG", "dosage": "0.4 g/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Plant resistant varieties",
                "Early planting",
                "Avoid late-season planting"
            ],
            "severity": "medium"
        },
        "fall_armyworm": {
            "name": "Fall Armyworm",
            "hindi_name": "फॉल आर्मीवर्म",
            "description": "Invasive insect pest causing severe damage to maize.",
            "hindi_description": "मक्का को गंभीर नुकसान पहुंचाने वाला आक्रामक कीट।",
            "symptoms": [
                "Ragged feeding damage on leaves",
                "Presence of larvae in whorl",
                "Sawdust-like frass",
                "Damaged tassels and ears"
            ],
            "causes": [
                "Spodoptera frugiperda moth",
                "Migration from other regions",
                "Continuous maize cultivation"
            ],
            "treatments": [
                {"type": "chemical", "name": "Emamectin benzoate 5% SG", "dosage": "0.4 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Chlorantraniliprole 18.5% SC", "dosage": "0.4 ml/liter water", "application": "Foliar spray"},
                {"type": "biological", "name": "Bacillus thuringiensis", "dosage": "2 g/liter water", "application": "Early spray"},
                {"type": "organic", "name": "Neem oil", "dosage": "5 ml/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Early planting",
                "Pheromone traps for monitoring",
                "Crop diversification",
                "Release of natural enemies"
            ],
            "severity": "high"
        }
    },
    
    # ===== VEGETABLES =====
    "tomato": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Proper staking", "Adequate spacing", "Drip irrigation"],
            "severity": "none"
        },
        "early_blight": {
            "name": "Early Blight",
            "hindi_name": "अगेती झुलसा",
            "description": "Fungal disease causing target-like spots on leaves.",
            "hindi_description": "पत्तियों पर निशाने जैसे धब्बे पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Dark concentric ring spots on leaves",
                "Spots start on lower leaves",
                "Yellowing around spots",
                "Fruit rot at stem end"
            ],
            "causes": [
                "Alternaria solani fungus",
                "Warm humid conditions",
                "Overhead irrigation",
                "Poor air circulation"
            ],
            "treatments": [
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Foliar spray every 7-10 days"},
                {"type": "chemical", "name": "Chlorothalonil 75% WP", "dosage": "2 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Azoxystrobin 23% SC", "dosage": "1 ml/liter water", "application": "Foliar spray"},
                {"type": "organic", "name": "Copper hydroxide", "dosage": "2 g/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Crop rotation (3-4 years)",
                "Remove infected plant debris",
                "Adequate plant spacing",
                "Avoid overhead irrigation",
                "Mulching"
            ],
            "severity": "medium"
        },
        "late_blight": {
            "name": "Late Blight",
            "hindi_name": "पछेती झुलसा",
            "description": "Devastating fungal disease causing rapid plant death.",
            "hindi_description": "पौधों को तेजी से मारने वाला विनाशकारी कवक रोग।",
            "symptoms": [
                "Water-soaked lesions on leaves",
                "White mold on leaf undersides",
                "Rapid browning and death",
                "Firm brown fruit rot"
            ],
            "causes": [
                "Phytophthora infestans oomycete",
                "Cool wet weather",
                "High humidity",
                "Infected transplants"
            ],
            "treatments": [
                {"type": "chemical", "name": "Metalaxyl 8% + Mancozeb 64% WP", "dosage": "2.5 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Cymoxanil 8% + Mancozeb 64% WP", "dosage": "2 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Dimethomorph 50% WP", "dosage": "1 g/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Plant resistant varieties",
                "Use disease-free transplants",
                "Destroy crop debris",
                "Avoid overhead irrigation",
                "Proper spacing for air circulation"
            ],
            "severity": "high"
        },
        "bacterial_wilt": {
            "name": "Bacterial Wilt",
            "hindi_name": "जीवाणु म्लानि",
            "description": "Soil-borne bacterial disease causing sudden wilting.",
            "hindi_description": "अचानक मुरझाने का कारण बनने वाला मृदा जनित जीवाणु रोग।",
            "symptoms": [
                "Sudden wilting without yellowing",
                "Bacterial ooze when stem cut",
                "Brown discoloration of vascular tissue",
                "Rapid plant death"
            ],
            "causes": [
                "Ralstonia solanacearum bacteria",
                "Warm wet conditions",
                "Contaminated soil/water",
                "Infected seedlings"
            ],
            "treatments": [
                {"type": "biological", "name": "Pseudomonas fluorescens", "dosage": "10 g/liter water", "application": "Soil drench"},
                {"type": "biological", "name": "Bacillus subtilis", "dosage": "5 g/liter water", "application": "Soil application"},
                {"type": "chemical", "name": "Streptocycline", "dosage": "0.5 g/liter water", "application": "Soil drench"}
            ],
            "prevention": [
                "Use resistant rootstocks",
                "Crop rotation (4-5 years)",
                "Soil solarization",
                "Avoid waterlogging",
                "Use disease-free seedlings"
            ],
            "severity": "high"
        },
        "leaf_curl": {
            "name": "Tomato Leaf Curl",
            "hindi_name": "पत्ती मोड़क",
            "description": "Viral disease causing severe leaf curling and stunting.",
            "hindi_description": "गंभीर पत्ती मुड़ने और बौनेपन का कारण बनने वाला विषाणु रोग।",
            "symptoms": [
                "Upward curling of leaves",
                "Yellowing of leaf margins",
                "Stunted plant growth",
                "Reduced fruit production"
            ],
            "causes": [
                "Tomato leaf curl virus (ToLCV)",
                "Whitefly (Bemisia tabaci) vector",
                "Infected transplants"
            ],
            "treatments": [
                {"type": "chemical", "name": "Imidacloprid 17.8% SL", "dosage": "0.3 ml/liter water", "application": "Spray for whitefly control"},
                {"type": "chemical", "name": "Acetamiprid 20% SP", "dosage": "0.2 g/liter water", "application": "Spray for whitefly control"},
                {"type": "organic", "name": "Yellow sticky traps", "dosage": "25-30 per hectare", "application": "Install in field"}
            ],
            "prevention": [
                "Use resistant varieties",
                "Control whitefly population",
                "Remove infected plants early",
                "Use reflective mulches",
                "Avoid planting near infected fields"
            ],
            "severity": "high"
        },
        "septoria_leaf_spot": {
            "name": "Septoria Leaf Spot",
            "hindi_name": "सेप्टोरिया पत्ती धब्बा",
            "description": "Fungal disease causing numerous small spots on leaves.",
            "hindi_description": "पत्तियों पर कई छोटे धब्बे पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Small circular spots with dark borders",
                "Gray centers in spots",
                "Tiny black dots in spots",
                "Lower leaves affected first"
            ],
            "causes": [
                "Septoria lycopersici fungus",
                "Warm wet weather",
                "Splashing water",
                "Infected crop debris"
            ],
            "treatments": [
                {"type": "chemical", "name": "Chlorothalonil 75% WP", "dosage": "2 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Foliar spray"},
                {"type": "organic", "name": "Copper fungicide", "dosage": "2 g/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Remove lower infected leaves",
                "Avoid overhead irrigation",
                "Mulching to prevent splashing",
                "Crop rotation"
            ],
            "severity": "medium"
        }
    },
    
    "potato": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Use certified seed tubers", "Proper hilling", "Adequate drainage"],
            "severity": "none"
        },
        "late_blight": {
            "name": "Late Blight",
            "hindi_name": "पछेती झुलसा",
            "description": "Destructive disease caused by Phytophthora infestans.",
            "hindi_description": "फाइटोफ्थोरा इन्फेस्टन्स द्वारा होने वाला विनाशकारी रोग।",
            "symptoms": [
                "Water-soaked lesions on leaves",
                "White fuzzy growth on undersides",
                "Dark brown lesions on tubers",
                "Rapid plant collapse"
            ],
            "causes": [
                "Phytophthora infestans oomycete",
                "Cool humid conditions",
                "Infected seed tubers"
            ],
            "treatments": [
                {"type": "chemical", "name": "Metalaxyl 8% + Mancozeb 64% WP", "dosage": "2.5 g/liter water", "application": "Foliar spray every 7 days"},
                {"type": "chemical", "name": "Cymoxanil 8% + Mancozeb 64% WP", "dosage": "2 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Fenamidone 10% + Mancozeb 50% WG", "dosage": "3 g/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Use certified disease-free seed",
                "Plant resistant varieties",
                "Destroy volunteer plants",
                "Proper hilling",
                "Avoid overhead irrigation"
            ],
            "severity": "high"
        },
        "early_blight": {
            "name": "Early Blight",
            "hindi_name": "अगेती झुलसा",
            "description": "Fungal disease causing concentric ring lesions.",
            "hindi_description": "संकेंद्रित वलय घाव पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Brown spots with concentric rings",
                "Yellowing around lesions",
                "Lower leaves affected first",
                "Shallow lesions on tubers"
            ],
            "causes": [
                "Alternaria solani fungus",
                "Warm weather",
                "Stressed plants",
                "Poor nutrition"
            ],
            "treatments": [
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Azoxystrobin 23% SC", "dosage": "1 ml/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Balanced fertilization",
                "Adequate irrigation",
                "Crop rotation",
                "Remove infected debris"
            ],
            "severity": "medium"
        },
        "black_scurf": {
            "name": "Black Scurf",
            "hindi_name": "काला पपड़ी",
            "description": "Fungal disease causing black masses on tubers.",
            "hindi_description": "कंदों पर काले पिंड पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Black sclerotia on tuber surface",
                "Cankers on stems and stolons",
                "Aerial tubers formation",
                "Weak emergence"
            ],
            "causes": [
                "Rhizoctonia solani fungus",
                "Cold wet soil",
                "Deep planting"
            ],
            "treatments": [
                {"type": "chemical", "name": "Pencycuron 22.9% SC", "dosage": "1.5 ml/kg seed", "application": "Seed tuber treatment"},
                {"type": "biological", "name": "Trichoderma viride", "dosage": "4 g/kg seed", "application": "Seed treatment"}
            ],
            "prevention": [
                "Use clean seed tubers",
                "Avoid deep planting",
                "Plant in warm soil",
                "Crop rotation"
            ],
            "severity": "medium"
        }
    },
    
    "onion": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Use disease-free sets", "Proper curing", "Adequate drainage"],
            "severity": "none"
        },
        "purple_blotch": {
            "name": "Purple Blotch",
            "hindi_name": "बैंगनी धब्बा",
            "description": "Fungal disease causing purple lesions on leaves.",
            "hindi_description": "पत्तियों पर बैंगनी घाव पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Small white sunken spots initially",
                "Spots enlarge with purple centers",
                "Concentric rings in lesions",
                "Leaf girdling and death"
            ],
            "causes": [
                "Alternaria porri fungus",
                "Warm humid conditions",
                "Heavy dews",
                "Thrips damage"
            ],
            "treatments": [
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Foliar spray every 10-15 days"},
                {"type": "chemical", "name": "Chlorothalonil 75% WP", "dosage": "2 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Hexaconazole 5% EC", "dosage": "1 ml/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Avoid overhead irrigation",
                "Control thrips population",
                "Proper plant spacing",
                "Crop rotation"
            ],
            "severity": "medium"
        },
        "thrips_damage": {
            "name": "Thrips Damage",
            "hindi_name": "थ्रिप्स क्षति",
            "description": "Insect pest causing silvery streaks on leaves.",
            "hindi_description": "पत्तियों पर चांदी जैसी धारियां पैदा करने वाला कीट।",
            "symptoms": [
                "Silvery white streaks on leaves",
                "Leaf tips curl and dry",
                "Stunted plant growth",
                "Small bulb size"
            ],
            "causes": [
                "Thrips tabaci insects",
                "Hot dry weather",
                "Continuous onion cropping"
            ],
            "treatments": [
                {"type": "chemical", "name": "Fipronil 5% SC", "dosage": "1.5 ml/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Spinosad 45% SC", "dosage": "0.3 ml/liter water", "application": "Foliar spray"},
                {"type": "organic", "name": "Neem oil", "dosage": "5 ml/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Early planting",
                "Blue sticky traps",
                "Avoid water stress",
                "Inter-cropping with coriander"
            ],
            "severity": "medium"
        },
        "basal_rot": {
            "name": "Basal Rot",
            "hindi_name": "तल सड़न",
            "description": "Fungal disease causing bulb rot from base.",
            "hindi_description": "आधार से प्याज सड़न पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Yellowing and wilting of leaves",
                "Rotting of bulb base",
                "White mycelium on roots",
                "Soft watery decay"
            ],
            "causes": [
                "Fusarium oxysporum fungus",
                "Warm soil temperature",
                "Infected sets",
                "Waterlogged conditions"
            ],
            "treatments": [
                {"type": "chemical", "name": "Carbendazim 50% WP", "dosage": "2 g/liter water", "application": "Seed set treatment"},
                {"type": "biological", "name": "Trichoderma viride", "dosage": "4 g/kg sets", "application": "Set treatment"}
            ],
            "prevention": [
                "Use disease-free sets",
                "Crop rotation",
                "Proper drainage",
                "Avoid injury to bulbs"
            ],
            "severity": "high"
        }
    },
    
    "chilli": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Good drainage", "Proper spacing", "Balanced nutrition"],
            "severity": "none"
        },
        "anthracnose": {
            "name": "Anthracnose",
            "hindi_name": "एंथ्राक्नोज",
            "description": "Fungal disease causing fruit rot and die-back.",
            "hindi_description": "फल सड़न और शाखा मृत्यु पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Sunken spots on fruits",
                "Orange-pink spore masses",
                "Fruit rot and mummification",
                "Die-back of branches"
            ],
            "causes": [
                "Colletotrichum species fungi",
                "Warm humid conditions",
                "Splashing water",
                "Infected seeds"
            ],
            "treatments": [
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Carbendazim 50% WP", "dosage": "1 g/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Azoxystrobin 23% SC", "dosage": "1 ml/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Use disease-free seeds",
                "Seed treatment before sowing",
                "Avoid overhead irrigation",
                "Remove infected fruits"
            ],
            "severity": "high"
        },
        "leaf_curl": {
            "name": "Chilli Leaf Curl",
            "hindi_name": "पत्ती मोड़क",
            "description": "Viral disease causing leaf curling and deformation.",
            "hindi_description": "पत्ती मुड़ने और विकृति पैदा करने वाला विषाणु रोग।",
            "symptoms": [
                "Upward curling of leaves",
                "Puckering and crinkling",
                "Stunted growth",
                "Reduced fruit set"
            ],
            "causes": [
                "Chilli leaf curl virus",
                "Whitefly transmission",
                "Thrips transmission"
            ],
            "treatments": [
                {"type": "chemical", "name": "Imidacloprid 17.8% SL", "dosage": "0.3 ml/liter water", "application": "Spray for vector control"},
                {"type": "chemical", "name": "Diafenthiuron 50% WP", "dosage": "1 g/liter water", "application": "Spray for whitefly"}
            ],
            "prevention": [
                "Grow resistant varieties",
                "Control vector population",
                "Remove infected plants",
                "Use yellow sticky traps"
            ],
            "severity": "high"
        },
        "powdery_mildew": {
            "name": "Powdery Mildew",
            "hindi_name": "चूर्णिल आसिता",
            "description": "Fungal disease causing white powdery coating.",
            "hindi_description": "सफेद पाउडर जैसी परत बनाने वाला कवक रोग।",
            "symptoms": [
                "White powdery spots on leaves",
                "Yellowing of leaves",
                "Premature leaf drop",
                "Poor fruit quality"
            ],
            "causes": [
                "Leveillula taurica fungus",
                "Dry warm days",
                "Cool nights"
            ],
            "treatments": [
                {"type": "chemical", "name": "Sulfur 80% WP", "dosage": "2.5 g/liter water", "application": "Dusting or spray"},
                {"type": "chemical", "name": "Hexaconazole 5% EC", "dosage": "1 ml/liter water", "application": "Foliar spray"},
                {"type": "organic", "name": "Neem oil", "dosage": "5 ml/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Avoid water stress",
                "Proper plant spacing",
                "Remove infected leaves"
            ],
            "severity": "medium"
        }
    },
    
    "brinjal": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Proper staking", "Good drainage", "Crop rotation"],
            "severity": "none"
        },
        "shoot_borer": {
            "name": "Shoot and Fruit Borer",
            "hindi_name": "तना और फल छेदक",
            "description": "Major insect pest boring into shoots and fruits.",
            "hindi_description": "तनों और फलों में छेद करने वाला प्रमुख कीट।",
            "symptoms": [
                "Wilting of young shoots",
                "Bore holes in fruits",
                "Frass on fruits",
                "Reduced marketable yield"
            ],
            "causes": [
                "Leucinodes orbonalis moth",
                "Continuous brinjal cropping",
                "Warm humid conditions"
            ],
            "treatments": [
                {"type": "chemical", "name": "Spinosad 45% SC", "dosage": "0.3 ml/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Chlorantraniliprole 18.5% SC", "dosage": "0.4 ml/liter water", "application": "Foliar spray"},
                {"type": "biological", "name": "Bacillus thuringiensis", "dosage": "2 g/liter water", "application": "Weekly spray"},
                {"type": "organic", "name": "Neem seed kernel extract", "dosage": "50 g/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Pheromone traps",
                "Remove infected shoots",
                "Destroy crop residues",
                "Use resistant varieties"
            ],
            "severity": "high"
        },
        "little_leaf": {
            "name": "Little Leaf",
            "hindi_name": "छोटी पत्ती",
            "description": "Phytoplasma disease causing leaf reduction.",
            "hindi_description": "पत्तियों के छोटे होने का कारण बनने वाला फाइटोप्लाज्मा रोग।",
            "symptoms": [
                "Reduction in leaf size",
                "Excessive branching",
                "Leaf yellowing",
                "No fruit production"
            ],
            "causes": [
                "Phytoplasma organism",
                "Leafhopper transmission"
            ],
            "treatments": [
                {"type": "chemical", "name": "Dimethoate 30% EC", "dosage": "2 ml/liter water", "application": "Spray for vector control"},
                {"type": "antibiotic", "name": "Tetracycline", "dosage": "500 ppm", "application": "Root dip of seedlings"}
            ],
            "prevention": [
                "Use healthy seedlings",
                "Remove infected plants",
                "Control leafhopper population",
                "Avoid planting near infected fields"
            ],
            "severity": "high"
        },
        "bacterial_wilt": {
            "name": "Bacterial Wilt",
            "hindi_name": "जीवाणु म्लानि",
            "description": "Soil-borne bacterial disease causing wilting.",
            "hindi_description": "मुरझाने का कारण बनने वाला मृदा जनित जीवाणु रोग।",
            "symptoms": [
                "Sudden wilting of plants",
                "No yellowing before wilt",
                "Brown vascular discoloration",
                "Bacterial ooze test positive"
            ],
            "causes": [
                "Ralstonia solanacearum bacteria",
                "Warm wet conditions",
                "Contaminated soil"
            ],
            "treatments": [
                {"type": "biological", "name": "Pseudomonas fluorescens", "dosage": "10 g/liter water", "application": "Soil drench"},
                {"type": "biological", "name": "Bacillus subtilis", "dosage": "5 g/liter water", "application": "Root dip and soil drench"}
            ],
            "prevention": [
                "Resistant varieties or rootstocks",
                "Soil solarization",
                "Crop rotation (5-6 years)",
                "Raise beds for drainage"
            ],
            "severity": "high"
        }
    },
    
    "cabbage": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Crop rotation", "Clean transplants", "Proper drainage"],
            "severity": "none"
        },
        "black_rot": {
            "name": "Black Rot",
            "hindi_name": "काला सड़न",
            "description": "Bacterial disease causing V-shaped lesions.",
            "hindi_description": "V-आकार के घाव पैदा करने वाला जीवाणु रोग।",
            "symptoms": [
                "Yellow V-shaped lesions from leaf margins",
                "Blackening of veins",
                "Wilting and drying of leaves",
                "Foul odor in severe cases"
            ],
            "causes": [
                "Xanthomonas campestris bacteria",
                "Warm humid weather",
                "Contaminated seeds",
                "Splashing water"
            ],
            "treatments": [
                {"type": "chemical", "name": "Streptocycline", "dosage": "0.5 g/liter water", "application": "Spray every 10 days"},
                {"type": "chemical", "name": "Copper oxychloride", "dosage": "3 g/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Hot water seed treatment (50°C, 25 min)",
                "Use certified seed",
                "Crop rotation (2-3 years)",
                "Remove infected plants"
            ],
            "severity": "high"
        },
        "diamondback_moth": {
            "name": "Diamondback Moth",
            "hindi_name": "डायमंडबैक मॉथ",
            "description": "Major insect pest causing leaf damage.",
            "hindi_description": "पत्तियों को नुकसान पहुंचाने वाला प्रमुख कीट।",
            "symptoms": [
                "Small holes in leaves",
                "Window-pane damage",
                "Larvae on undersides",
                "Reduced head formation"
            ],
            "causes": [
                "Plutella xylostella moth",
                "Continuous crucifer cultivation",
                "Insecticide resistance"
            ],
            "treatments": [
                {"type": "biological", "name": "Bacillus thuringiensis", "dosage": "2 g/liter water", "application": "Weekly spray"},
                {"type": "chemical", "name": "Spinosad 45% SC", "dosage": "0.3 ml/liter water", "application": "Foliar spray"},
                {"type": "chemical", "name": "Emamectin benzoate 5% SG", "dosage": "0.4 g/liter water", "application": "Foliar spray"}
            ],
            "prevention": [
                "Pheromone traps",
                "Intercropping with tomato",
                "Destruction of crop residues",
                "Crop rotation"
            ],
            "severity": "medium"
        }
    },
    
    "cauliflower": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Use disease-free transplants", "Proper blanching", "Balanced nutrition"],
            "severity": "none"
        },
        "black_rot": {
            "name": "Black Rot",
            "hindi_name": "काला सड़न",
            "description": "Bacterial disease affecting leaves and curds.",
            "hindi_description": "पत्तियों और फूल को प्रभावित करने वाला जीवाणु रोग।",
            "symptoms": [
                "V-shaped yellow lesions",
                "Blackening of veins",
                "Curd discoloration",
                "Foul smell"
            ],
            "causes": [
                "Xanthomonas campestris bacteria",
                "Infected seeds",
                "Warm wet weather"
            ],
            "treatments": [
                {"type": "chemical", "name": "Streptocycline", "dosage": "0.5 g/liter water", "application": "Spray"},
                {"type": "chemical", "name": "Copper hydroxide", "dosage": "2 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Hot water seed treatment",
                "Crop rotation",
                "Remove infected plants",
                "Avoid overhead irrigation"
            ],
            "severity": "high"
        },
        "curd_rot": {
            "name": "Curd Rot",
            "hindi_name": "फूल सड़न",
            "description": "Bacterial/fungal disease causing curd rotting.",
            "hindi_description": "फूल सड़ने का कारण बनने वाला जीवाणु/कवक रोग।",
            "symptoms": [
                "Water-soaked spots on curd",
                "Soft rot of curd tissue",
                "Brown discoloration",
                "Bad odor"
            ],
            "causes": [
                "Erwinia carotovora bacteria",
                "High humidity",
                "Mechanical injury"
            ],
            "treatments": [
                {"type": "chemical", "name": "Streptocycline", "dosage": "0.5 g/liter water", "application": "Spray at curd formation"},
                {"type": "chemical", "name": "Copper fungicides", "dosage": "2 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Avoid injury during handling",
                "Proper drainage",
                "Timely harvesting",
                "Balanced fertilization"
            ],
            "severity": "high"
        }
    },
    
    "okra": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Proper spacing", "Good drainage", "Seed treatment"],
            "severity": "none"
        },
        "yellow_vein_mosaic": {
            "name": "Yellow Vein Mosaic",
            "hindi_name": "पीला शिरा मोज़ेक",
            "description": "Viral disease causing yellow vein patterns.",
            "hindi_description": "पीले शिरा पैटर्न पैदा करने वाला विषाणु रोग।",
            "symptoms": [
                "Yellow vein network on leaves",
                "Chlorosis of entire leaf",
                "Stunted growth",
                "Reduced fruit size"
            ],
            "causes": [
                "Bhendi yellow vein mosaic virus",
                "Whitefly transmission"
            ],
            "treatments": [
                {"type": "chemical", "name": "Imidacloprid 17.8% SL", "dosage": "0.3 ml/liter water", "application": "Spray for whitefly"},
                {"type": "chemical", "name": "Acetamiprid 20% SP", "dosage": "0.2 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Grow resistant varieties",
                "Control whitefly",
                "Remove infected plants",
                "Avoid continuous cropping"
            ],
            "severity": "high"
        },
        "shoot_borer": {
            "name": "Shoot and Fruit Borer",
            "hindi_name": "तना और फल छेदक",
            "description": "Insect pest boring into shoots and fruits.",
            "hindi_description": "तनों और फलों में छेद करने वाला कीट।",
            "symptoms": [
                "Wilting of shoots",
                "Bore holes in fruits",
                "Frass near holes",
                "Distorted fruits"
            ],
            "causes": [
                "Earias vittella and E. insulana moths"
            ],
            "treatments": [
                {"type": "chemical", "name": "Spinosad 45% SC", "dosage": "0.3 ml/liter water", "application": "Spray"},
                {"type": "biological", "name": "Bacillus thuringiensis", "dosage": "2 g/liter water", "application": "Weekly spray"},
                {"type": "organic", "name": "Neem oil", "dosage": "5 ml/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Collection and destruction of infested shoots",
                "Pheromone traps",
                "Intercropping",
                "Timely harvesting"
            ],
            "severity": "high"
        }
    },
    
    "cucumber": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Trellis support", "Drip irrigation", "Mulching"],
            "severity": "none"
        },
        "downy_mildew": {
            "name": "Downy Mildew",
            "hindi_name": "मृदुल आसिता",
            "description": "Fungal disease causing angular leaf spots.",
            "hindi_description": "कोणीय पत्ती धब्बे पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Angular yellow spots on upper surface",
                "Purple-gray mold on lower surface",
                "Rapid leaf death",
                "Reduced yield"
            ],
            "causes": [
                "Pseudoperonospora cubensis oomycete",
                "Cool humid conditions",
                "Dew on leaves"
            ],
            "treatments": [
                {"type": "chemical", "name": "Metalaxyl 8% + Mancozeb 64% WP", "dosage": "2.5 g/liter water", "application": "Spray every 7 days"},
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Preventive spray"}
            ],
            "prevention": [
                "Resistant varieties",
                "Good air circulation",
                "Avoid overhead irrigation",
                "Morning watering"
            ],
            "severity": "medium"
        },
        "powdery_mildew": {
            "name": "Powdery Mildew",
            "hindi_name": "चूर्णिल आसिता",
            "description": "Fungal disease causing white powdery coating.",
            "hindi_description": "सफेद पाउडर जैसी परत बनाने वाला कवक रोग।",
            "symptoms": [
                "White powdery spots on leaves",
                "Circular to irregular patches",
                "Yellowing of leaves",
                "Reduced fruit quality"
            ],
            "causes": [
                "Erysiphe cichoracearum fungus",
                "Moderate temperatures",
                "Dry conditions"
            ],
            "treatments": [
                {"type": "chemical", "name": "Sulfur 80% WP", "dosage": "2.5 g/liter water", "application": "Dusting/spray"},
                {"type": "chemical", "name": "Hexaconazole 5% EC", "dosage": "1 ml/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Resistant varieties",
                "Adequate plant spacing",
                "Remove infected leaves"
            ],
            "severity": "medium"
        }
    },
    
    # ===== CASH CROPS =====
    "cotton": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Use certified seeds", "Balanced fertilization", "IPM practices"],
            "severity": "none"
        },
        "bollworm": {
            "name": "Bollworm",
            "hindi_name": "बॉलवर्म",
            "description": "Major insect pest damaging cotton bolls.",
            "hindi_description": "कपास की बॉल को नुकसान पहुंचाने वाला प्रमुख कीट।",
            "symptoms": [
                "Bore holes in bolls",
                "Frass and webbing",
                "Damaged lint",
                "Premature boll opening"
            ],
            "causes": [
                "Helicoverpa armigera (American)",
                "Pectinophora gossypiella (Pink)",
                "Earias species (Spotted)"
            ],
            "treatments": [
                {"type": "chemical", "name": "Emamectin benzoate 5% SG", "dosage": "0.4 g/liter water", "application": "Spray at 15-day intervals"},
                {"type": "chemical", "name": "Chlorantraniliprole 18.5% SC", "dosage": "0.3 ml/liter water", "application": "Spray"},
                {"type": "biological", "name": "Bacillus thuringiensis", "dosage": "2 g/liter water", "application": "Early stage spray"},
                {"type": "organic", "name": "Neem seed kernel extract", "dosage": "50 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Plant Bt cotton varieties",
                "Pheromone traps",
                "Timely sowing",
                "Destroy crop residues"
            ],
            "severity": "high"
        },
        "bacterial_blight": {
            "name": "Bacterial Blight",
            "hindi_name": "जीवाणु अंगमारी",
            "description": "Bacterial disease causing angular leaf spots.",
            "hindi_description": "कोणीय पत्ती धब्बे पैदा करने वाला जीवाणु रोग।",
            "symptoms": [
                "Angular water-soaked spots",
                "Spots become brown",
                "Boll rot",
                "Black arm on stems"
            ],
            "causes": [
                "Xanthomonas citri bacteria",
                "Warm wet weather",
                "Infected seeds"
            ],
            "treatments": [
                {"type": "chemical", "name": "Streptocycline", "dosage": "0.5 g/liter water", "application": "Spray"},
                {"type": "chemical", "name": "Copper oxychloride", "dosage": "3 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Acid-delinted seeds",
                "Seed treatment",
                "Crop rotation",
                "Use resistant varieties"
            ],
            "severity": "medium"
        },
        "leaf_curl": {
            "name": "Cotton Leaf Curl",
            "hindi_name": "पत्ती मोड़क",
            "description": "Viral disease causing severe leaf curling.",
            "hindi_description": "गंभीर पत्ती मुड़ने का कारण बनने वाला विषाणु रोग।",
            "symptoms": [
                "Upward curling of leaves",
                "Thickening of veins",
                "Enations on undersides",
                "Stunted plants"
            ],
            "causes": [
                "Cotton leaf curl virus",
                "Whitefly transmission"
            ],
            "treatments": [
                {"type": "chemical", "name": "Imidacloprid 17.8% SL", "dosage": "0.3 ml/liter water", "application": "Spray for whitefly"},
                {"type": "chemical", "name": "Diafenthiuron 50% WP", "dosage": "1 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Grow resistant varieties",
                "Control whitefly early",
                "Remove infected plants",
                "Avoid late sowing"
            ],
            "severity": "high"
        }
    },
    
    "sugarcane": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Use disease-free setts", "Proper drainage", "Balanced nutrition"],
            "severity": "none"
        },
        "red_rot": {
            "name": "Red Rot",
            "hindi_name": "लाल सड़न",
            "description": "Fungal disease causing internal red discoloration.",
            "hindi_description": "आंतरिक लाल मलिनकिरण पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Yellowing and drying of leaves",
                "Red internal stalk color",
                "White patches in red tissue",
                "Alcohol smell"
            ],
            "causes": [
                "Colletotrichum falcatum fungus",
                "Infected seed cane",
                "Waterlogged conditions"
            ],
            "treatments": [
                {"type": "chemical", "name": "Carbendazim 50% WP", "dosage": "1 g/liter water", "application": "Sett treatment"},
                {"type": "biological", "name": "Trichoderma viride", "dosage": "4 g/liter water", "application": "Sett treatment"}
            ],
            "prevention": [
                "Use disease-free setts",
                "Resistant varieties",
                "Hot water treatment (50°C, 2 hrs)",
                "Proper drainage"
            ],
            "severity": "high"
        },
        "smut": {
            "name": "Smut",
            "hindi_name": "कंड",
            "description": "Fungal disease causing whip-like structures.",
            "hindi_description": "चाबुक जैसी संरचनाएं पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Long black whip from growing point",
                "Thin tillers",
                "Stunted growth",
                "Grass-like appearance"
            ],
            "causes": [
                "Sporisorium scitamineum fungus",
                "Infected setts",
                "Airborne spores"
            ],
            "treatments": [
                {"type": "chemical", "name": "Propiconazole 25% EC", "dosage": "0.1%", "application": "Sett dip treatment"}
            ],
            "prevention": [
                "Use smut-free setts",
                "Hot water treatment",
                "Rogue out infected plants",
                "Crop rotation"
            ],
            "severity": "high"
        },
        "top_borer": {
            "name": "Top Borer",
            "hindi_name": "शिखर छेदक",
            "description": "Insect pest damaging growing point.",
            "hindi_description": "बढ़ती नोक को नुकसान पहुंचाने वाला कीट।",
            "symptoms": [
                "Dead heart symptom",
                "Shot holes in leaves",
                "Bore holes in stalk",
                "Bunchy top appearance"
            ],
            "causes": [
                "Scirpophaga excerptalis moth"
            ],
            "treatments": [
                {"type": "chemical", "name": "Chlorantraniliprole 0.4% GR", "dosage": "7.5 kg/acre", "application": "Whorl application"},
                {"type": "chemical", "name": "Fipronil 0.3% GR", "dosage": "15 kg/acre", "application": "Whorl application"}
            ],
            "prevention": [
                "Early planting",
                "Light trap for moths",
                "Release of Trichogramma",
                "Detrashing"
            ],
            "severity": "high"
        }
    },
    
    "groundnut": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Crop rotation", "Use certified seeds", "Proper drainage"],
            "severity": "none"
        },
        "tikka_disease": {
            "name": "Tikka Disease (Leaf Spot)",
            "hindi_name": "टिक्का रोग",
            "description": "Fungal disease causing circular leaf spots.",
            "hindi_description": "गोलाकार पत्ती धब्बे पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Circular dark spots on leaves",
                "Yellow halo around spots",
                "Premature defoliation",
                "Reduced pod yield"
            ],
            "causes": [
                "Cercospora arachidicola (early)",
                "Cercosporidium personatum (late)",
                "Humid conditions"
            ],
            "treatments": [
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Spray at 10-day intervals"},
                {"type": "chemical", "name": "Carbendazim 50% WP", "dosage": "1 g/liter water", "application": "Spray"},
                {"type": "chemical", "name": "Hexaconazole 5% EC", "dosage": "1 ml/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Crop rotation",
                "Early sowing",
                "Resistant varieties",
                "Remove crop debris"
            ],
            "severity": "medium"
        },
        "rust": {
            "name": "Groundnut Rust",
            "hindi_name": "गेरुआ",
            "description": "Fungal disease causing rust pustules.",
            "hindi_description": "गेरुआ छाले पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Orange-brown pustules on undersides",
                "Circular to irregular pustules",
                "Premature leaf fall",
                "Small shriveled pods"
            ],
            "causes": [
                "Puccinia arachidis fungus",
                "Warm humid weather"
            ],
            "treatments": [
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Spray"},
                {"type": "chemical", "name": "Triadimefon 25% WP", "dosage": "1 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Resistant varieties",
                "Early sowing",
                "Proper spacing"
            ],
            "severity": "medium"
        }
    },
    
    "soybean": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Seed treatment", "Proper drainage", "Crop rotation"],
            "severity": "none"
        },
        "rust": {
            "name": "Soybean Rust",
            "hindi_name": "गेरुआ",
            "description": "Fungal disease causing brown pustules.",
            "hindi_description": "भूरे छाले पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Tan to brown pustules on undersides",
                "Yellowing of leaves",
                "Premature defoliation",
                "Reduced pod fill"
            ],
            "causes": [
                "Phakopsora pachyrhizi fungus",
                "Warm humid conditions"
            ],
            "treatments": [
                {"type": "chemical", "name": "Propiconazole 25% EC", "dosage": "1 ml/liter water", "application": "Spray"},
                {"type": "chemical", "name": "Tebuconazole 25.9% EC", "dosage": "1 ml/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Early sowing",
                "Resistant varieties",
                "Avoid late planting"
            ],
            "severity": "high"
        },
        "yellow_mosaic": {
            "name": "Yellow Mosaic",
            "hindi_name": "पीला मोज़ेक",
            "description": "Viral disease causing yellow mottling.",
            "hindi_description": "पीली चित्तीदार पैदा करने वाला विषाणु रोग।",
            "symptoms": [
                "Yellow and green mottling",
                "Puckering of leaves",
                "Stunted growth",
                "Few pods"
            ],
            "causes": [
                "Mungbean yellow mosaic virus",
                "Whitefly transmission"
            ],
            "treatments": [
                {"type": "chemical", "name": "Imidacloprid 17.8% SL", "dosage": "0.3 ml/liter water", "application": "Spray for whitefly"}
            ],
            "prevention": [
                "Resistant varieties",
                "Control whitefly",
                "Remove infected plants",
                "Timely sowing"
            ],
            "severity": "high"
        }
    },
    
    # ===== FRUITS =====
    "mango": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Proper pruning", "Balanced nutrition", "Clean orchard floor"],
            "severity": "none"
        },
        "anthracnose": {
            "name": "Anthracnose",
            "hindi_name": "एंथ्राक्नोज",
            "description": "Fungal disease affecting flowers, fruits, and leaves.",
            "hindi_description": "फूलों, फलों और पत्तियों को प्रभावित करने वाला कवक रोग।",
            "symptoms": [
                "Black spots on flowers",
                "Flower and fruit drop",
                "Sunken spots on fruits",
                "Leaf tip blight"
            ],
            "causes": [
                "Colletotrichum gloeosporioides fungus",
                "Humid conditions",
                "Rain during flowering"
            ],
            "treatments": [
                {"type": "chemical", "name": "Carbendazim 50% WP", "dosage": "1 g/liter water", "application": "Spray at flowering"},
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Spray"},
                {"type": "chemical", "name": "Azoxystrobin 23% SC", "dosage": "1 ml/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Prune infected branches",
                "Orchard sanitation",
                "Pre-harvest sprays",
                "Hot water treatment of fruits"
            ],
            "severity": "high"
        },
        "powdery_mildew": {
            "name": "Powdery Mildew",
            "hindi_name": "चूर्णिल आसिता",
            "description": "Fungal disease affecting flowers and young fruits.",
            "hindi_description": "फूलों और छोटे फलों को प्रभावित करने वाला कवक रोग।",
            "symptoms": [
                "White powdery coating",
                "Flower and fruit drop",
                "Deformed fruits",
                "Reduced fruit set"
            ],
            "causes": [
                "Oidium mangiferae fungus",
                "Cool nights and dry days"
            ],
            "treatments": [
                {"type": "chemical", "name": "Sulfur 80% WP", "dosage": "2 g/liter water", "application": "Spray at flower emergence"},
                {"type": "chemical", "name": "Hexaconazole 5% EC", "dosage": "1 ml/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Spray before flowering",
                "Prune water shoots",
                "Good air circulation"
            ],
            "severity": "high"
        },
        "mango_hopper": {
            "name": "Mango Hopper",
            "hindi_name": "आम का फुदका",
            "description": "Insect pest affecting flowers and young fruits.",
            "hindi_description": "फूलों और छोटे फलों को प्रभावित करने वाला कीट।",
            "symptoms": [
                "Yellowing of leaves",
                "Sooty mold on honeydew",
                "Flower drying",
                "Reduced fruit set"
            ],
            "causes": [
                "Idioscopus species hoppers"
            ],
            "treatments": [
                {"type": "chemical", "name": "Imidacloprid 17.8% SL", "dosage": "0.3 ml/liter water", "application": "Spray at panicle emergence"},
                {"type": "organic", "name": "Neem oil", "dosage": "5 ml/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Orchard sanitation",
                "Light traps",
                "Smoke under trees"
            ],
            "severity": "medium"
        }
    },
    
    "banana": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Use disease-free suckers", "Proper drainage", "Balanced nutrition"],
            "severity": "none"
        },
        "panama_wilt": {
            "name": "Panama Wilt (Fusarium Wilt)",
            "hindi_name": "पनामा विल्ट",
            "description": "Devastating soil-borne fungal disease.",
            "hindi_description": "विनाशकारी मृदा जनित कवक रोग।",
            "symptoms": [
                "Yellowing of older leaves",
                "Pseudostem splitting",
                "Brown vascular discoloration",
                "Plant collapse"
            ],
            "causes": [
                "Fusarium oxysporum f.sp. cubense",
                "Infected planting material",
                "Contaminated soil"
            ],
            "treatments": [
                {"type": "biological", "name": "Trichoderma viride", "dosage": "50 g/plant", "application": "Soil application"},
                {"type": "biological", "name": "Pseudomonas fluorescens", "dosage": "25 g/plant", "application": "Soil application"}
            ],
            "prevention": [
                "Use disease-free suckers",
                "Resistant varieties (Grand Naine)",
                "Soil solarization",
                "Long crop rotation"
            ],
            "severity": "high"
        },
        "sigatoka": {
            "name": "Sigatoka Leaf Spot",
            "hindi_name": "सिगाटोका पत्ती धब्बा",
            "description": "Fungal disease causing leaf spots.",
            "hindi_description": "पत्ती धब्बे पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Parallel streaks on leaves",
                "Spots with gray center",
                "Leaf drying",
                "Small bunches"
            ],
            "causes": [
                "Mycosphaerella species fungi",
                "Humid conditions"
            ],
            "treatments": [
                {"type": "chemical", "name": "Propiconazole 25% EC", "dosage": "1 ml/liter water", "application": "Spray"},
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Remove infected leaves",
                "Proper spacing",
                "Adequate drainage"
            ],
            "severity": "medium"
        },
        "bunchy_top": {
            "name": "Bunchy Top",
            "hindi_name": "बंची टॉप",
            "description": "Viral disease causing stunted bunchy growth.",
            "hindi_description": "बौना गुच्छेदार विकास पैदा करने वाला विषाणु रोग।",
            "symptoms": [
                "Stunted plants",
                "Narrow upright leaves",
                "Dark green dots and dashes",
                "No fruit production"
            ],
            "causes": [
                "Banana bunchy top virus",
                "Aphid transmission"
            ],
            "treatments": [
                {"type": "chemical", "name": "Imidacloprid 17.8% SL", "dosage": "0.3 ml/liter water", "application": "Spray for aphid control"}
            ],
            "prevention": [
                "Use virus-free tissue culture plants",
                "Rogue infected plants",
                "Control aphids",
                "Quarantine measures"
            ],
            "severity": "high"
        }
    },
    
    "grapes": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Proper pruning", "Good air circulation", "Canopy management"],
            "severity": "none"
        },
        "downy_mildew": {
            "name": "Downy Mildew",
            "hindi_name": "मृदुल आसिता",
            "description": "Fungal disease affecting leaves and berries.",
            "hindi_description": "पत्तियों और जामुन को प्रभावित करने वाला कवक रोग।",
            "symptoms": [
                "Yellow oily spots on leaves",
                "White downy growth underneath",
                "Berry shriveling",
                "Shoot infection"
            ],
            "causes": [
                "Plasmopara viticola oomycete",
                "Cool wet weather",
                "Overhead irrigation"
            ],
            "treatments": [
                {"type": "chemical", "name": "Metalaxyl 8% + Mancozeb 64% WP", "dosage": "2.5 g/liter water", "application": "Spray every 10-14 days"},
                {"type": "chemical", "name": "Fosetyl-Al 80% WP", "dosage": "2 g/liter water", "application": "Spray"},
                {"type": "organic", "name": "Copper hydroxide", "dosage": "2 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Good air circulation",
                "Remove infected leaves",
                "Avoid overhead irrigation",
                "Proper pruning"
            ],
            "severity": "high"
        },
        "powdery_mildew": {
            "name": "Powdery Mildew",
            "hindi_name": "चूर्णिल आसिता",
            "description": "Fungal disease causing white coating.",
            "hindi_description": "सफेद परत बनाने वाला कवक रोग।",
            "symptoms": [
                "White powdery coating",
                "Distorted shoot growth",
                "Berry cracking",
                "Poor fruit quality"
            ],
            "causes": [
                "Uncinula necator fungus",
                "Warm dry conditions",
                "Shaded canopy"
            ],
            "treatments": [
                {"type": "chemical", "name": "Sulfur 80% WP", "dosage": "2 g/liter water", "application": "Spray"},
                {"type": "chemical", "name": "Hexaconazole 5% EC", "dosage": "1 ml/liter water", "application": "Spray"},
                {"type": "chemical", "name": "Myclobutanil 10% WP", "dosage": "0.6 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Canopy management",
                "Resistant varieties",
                "Avoid water stress"
            ],
            "severity": "medium"
        },
        "anthracnose": {
            "name": "Anthracnose",
            "hindi_name": "एंथ्राक्नोज",
            "description": "Fungal disease causing bird's eye spots.",
            "hindi_description": "पक्षी की आंख जैसे धब्बे पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Circular spots with gray center",
                "Reddish-brown margins",
                "Shoot lesions",
                "Berry spots"
            ],
            "causes": [
                "Elsinoe ampelina fungus",
                "Warm wet weather"
            ],
            "treatments": [
                {"type": "chemical", "name": "Carbendazim 50% WP", "dosage": "1 g/liter water", "application": "Spray"},
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Prune and burn infected parts",
                "Dormant spray with Bordeaux mixture",
                "Proper training"
            ],
            "severity": "medium"
        }
    },
    
    "apple": {
        "healthy": {
            "name": "Healthy",
            "hindi_name": "स्वस्थ",
            "description": "No disease detected. Plant appears healthy.",
            "hindi_description": "कोई रोग नहीं पाया गया। पौधा स्वस्थ दिखाई देता है।",
            "symptoms": [],
            "causes": [],
            "treatments": [],
            "prevention": ["Proper pruning", "Orchard sanitation", "Balanced nutrition"],
            "severity": "none"
        },
        "scab": {
            "name": "Apple Scab",
            "hindi_name": "सेब का स्कैब",
            "description": "Fungal disease causing scab lesions.",
            "hindi_description": "पपड़ी जैसे घाव पैदा करने वाला कवक रोग।",
            "symptoms": [
                "Olive-green spots on leaves",
                "Velvety dark spots on fruits",
                "Fruit cracking and deformity",
                "Early leaf fall"
            ],
            "causes": [
                "Venturia inaequalis fungus",
                "Cool wet spring weather"
            ],
            "treatments": [
                {"type": "chemical", "name": "Mancozeb 75% WP", "dosage": "2.5 g/liter water", "application": "Spray every 10-14 days"},
                {"type": "chemical", "name": "Myclobutanil 10% WP", "dosage": "0.6 g/liter water", "application": "Spray"},
                {"type": "chemical", "name": "Captan 50% WP", "dosage": "2 g/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Remove fallen leaves",
                "Resistant varieties",
                "Proper pruning for air circulation",
                "Pre-bloom sprays"
            ],
            "severity": "high"
        },
        "powdery_mildew": {
            "name": "Powdery Mildew",
            "hindi_name": "चूर्णिल आसिता",
            "description": "Fungal disease affecting shoots and fruits.",
            "hindi_description": "शाखाओं और फलों को प्रभावित करने वाला कवक रोग।",
            "symptoms": [
                "White powdery coating on leaves",
                "Stunted shoot growth",
                "Russeting on fruits",
                "Netted pattern on fruits"
            ],
            "causes": [
                "Podosphaera leucotricha fungus",
                "Warm days and cool nights"
            ],
            "treatments": [
                {"type": "chemical", "name": "Sulfur 80% WP", "dosage": "2 g/liter water", "application": "Spray"},
                {"type": "chemical", "name": "Hexaconazole 5% EC", "dosage": "1 ml/liter water", "application": "Spray"}
            ],
            "prevention": [
                "Remove infected shoots",
                "Proper pruning",
                "Balanced nitrogen"
            ],
            "severity": "medium"
        },
        "fire_blight": {
            "name": "Fire Blight",
            "hindi_name": "अग्नि झुलसा",
            "description": "Bacterial disease causing shoot death.",
            "hindi_description": "शाखा मृत्यु पैदा करने वाला जीवाणु रोग।",
            "symptoms": [
                "Shepherd's crook on shoots",
                "Blackened dried shoots",
                "Oozing cankers",
                "Scorched appearance"
            ],
            "causes": [
                "Erwinia amylovora bacteria",
                "Warm wet weather",
                "Insect wounds"
            ],
            "treatments": [
                {"type": "chemical", "name": "Streptocycline", "dosage": "0.5 g/liter water", "application": "Spray at bloom"},
                {"type": "chemical", "name": "Copper hydroxide", "dosage": "2 g/liter water", "application": "Dormant spray"}
            ],
            "prevention": [
                "Prune infected branches 12 inches below",
                "Sterilize pruning tools",
                "Avoid excess nitrogen",
                "Control insect vectors"
            ],
            "severity": "high"
        }
    }
}

# Supported crops list with Hindi names
SUPPORTED_CROPS = {
    "rice": {"name": "Rice", "hindi_name": "धान"},
    "wheat": {"name": "Wheat", "hindi_name": "गेहूं"},
    "maize": {"name": "Maize", "hindi_name": "मक्का"},
    "tomato": {"name": "Tomato", "hindi_name": "टमाटर"},
    "potato": {"name": "Potato", "hindi_name": "आलू"},
    "onion": {"name": "Onion", "hindi_name": "प्याज"},
    "chilli": {"name": "Chilli", "hindi_name": "मिर्च"},
    "brinjal": {"name": "Brinjal", "hindi_name": "बैंगन"},
    "cabbage": {"name": "Cabbage", "hindi_name": "पत्तागोभी"},
    "cauliflower": {"name": "Cauliflower", "hindi_name": "फूलगोभी"},
    "okra": {"name": "Okra", "hindi_name": "भिंडी"},
    "cucumber": {"name": "Cucumber", "hindi_name": "खीरा"},
    "cotton": {"name": "Cotton", "hindi_name": "कपास"},
    "sugarcane": {"name": "Sugarcane", "hindi_name": "गन्ना"},
    "groundnut": {"name": "Groundnut", "hindi_name": "मूंगफली"},
    "soybean": {"name": "Soybean", "hindi_name": "सोयाबीन"},
    "mango": {"name": "Mango", "hindi_name": "आम"},
    "banana": {"name": "Banana", "hindi_name": "केला"},
    "grapes": {"name": "Grapes", "hindi_name": "अंगूर"},
    "apple": {"name": "Apple", "hindi_name": "सेब"}
}


def get_crop_diseases(crop_type: str) -> Dict[str, Any]:
    """Get all diseases for a specific crop."""
    crop_type = crop_type.lower()
    if crop_type not in CROP_DISEASES:
        return {}
    return CROP_DISEASES[crop_type]


def get_disease_info(crop_type: str, disease_id: str) -> Dict[str, Any]:
    """Get detailed information about a specific disease."""
    crop_type = crop_type.lower()
    disease_id = disease_id.lower()
    
    if crop_type not in CROP_DISEASES:
        return {}
    
    crop_diseases = CROP_DISEASES[crop_type]
    
    if disease_id not in crop_diseases:
        return {}
    
    return crop_diseases[disease_id]


def get_all_disease_names(crop_type: str) -> List[str]:
    """Get list of all disease names for a crop (excluding healthy)."""
    crop_type = crop_type.lower()
    if crop_type not in CROP_DISEASES:
        return []
    
    return [
        disease_id 
        for disease_id in CROP_DISEASES[crop_type].keys()
        if disease_id != "healthy"
    ]


def get_disease_class_labels(crop_type: str) -> Dict[str, str]:
    """Get class labels mapping (id -> name) for a crop."""
    crop_type = crop_type.lower()
    if crop_type not in CROP_DISEASES:
        return {"0": "healthy", "1": "diseased"}
    
    diseases = list(CROP_DISEASES[crop_type].keys())
    return {str(i): disease for i, disease in enumerate(diseases)}


def get_similar_diseases(crop_type: str, disease_id: str, limit: int = 3) -> List[Dict[str, Any]]:
    """Get similar diseases based on symptoms and severity."""
    crop_type = crop_type.lower()
    disease_id = disease_id.lower()
    
    if crop_type not in CROP_DISEASES:
        return []
    
    current_disease = CROP_DISEASES[crop_type].get(disease_id)
    if not current_disease:
        return []
    
    similar = []
    current_severity = current_disease.get("severity", "medium")
    
    for did, dinfo in CROP_DISEASES[crop_type].items():
        if did == disease_id or did == "healthy":
            continue
        
        # Score based on severity match and symptom overlap
        score = 0
        if dinfo.get("severity") == current_severity:
            score += 2
        
        # Check for overlapping symptoms
        current_symptoms = set(current_disease.get("symptoms", []))
        other_symptoms = set(dinfo.get("symptoms", []))
        if current_symptoms and other_symptoms:
            overlap = len(current_symptoms.intersection(other_symptoms))
            score += overlap
        
        similar.append({
            "disease_id": did,
            "name": dinfo.get("name"),
            "hindi_name": dinfo.get("hindi_name"),
            "severity": dinfo.get("severity"),
            "score": score
        })
    
    # Sort by score and return top N
    similar.sort(key=lambda x: x["score"], reverse=True)
    return similar[:limit]

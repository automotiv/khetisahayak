require('dotenv').config();
const db = require('../db');

const indianAgriculturalSchemes = [
    {
        name: 'PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)',
        name_hi: 'प्रधानमंत्री किसान सम्मान निधि',
        description: 'Income support scheme providing Rs 6,000 per year to small and marginal farmer families with cultivable land holding.',
        benefits: 'Rs 6,000 per year in 3 equal installments of Rs 2,000 each, directly transferred to bank account via DBT.',
        eligibility: 'Small and marginal farmers with cultivable land up to 2 hectares. Must have Aadhaar-linked bank account. Not eligible for income taxpayers, government employees.',
        application_process: 'Register online at pmkisan.gov.in or through Common Service Center (CSC). eKYC mandatory.',
        documents_required: 'Aadhaar Card, Bank Account Details, Land Ownership Documents, Citizenship Proof',
        link: 'https://pmkisan.gov.in/',
        category: 'Central',
        scheme_type: 'subsidy',
        ministry: 'Ministry of Agriculture & Farmers Welfare',
        min_farm_size: 0,
        max_farm_size: 2.0,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['All']),
        min_income: 0,
        max_income: null,
        land_ownership_type: 'owner',
        benefit_amount_min: 6000,
        benefit_amount_max: 6000,
        benefit_type: 'fixed',
        helpline_number: '155261, 011-24300606',
        application_url: 'https://pmkisan.gov.in/',
        is_featured: true,
        priority: 100,
        eligibility_criteria: JSON.stringify({
            requires_bank_account: true,
            requires_aadhar: true,
            farmer_categories: ['marginal', 'small'],
            excludes_income_taxpayers: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Bank Passbook', mandatory: true },
            { name: 'Land Records (7/12 or equivalent)', mandatory: true },
            { name: 'Mobile Number', mandatory: true }
        ])
    },
    {
        name: 'PMFBY (Pradhan Mantri Fasal Bima Yojana)',
        name_hi: 'प्रधानमंत्री फसल बीमा योजना',
        description: 'Comprehensive crop insurance scheme providing financial support to farmers suffering crop loss due to natural calamities, pests, and diseases.',
        benefits: 'Insurance coverage with farmer premium: Kharif 2%, Rabi 1.5%, Commercial/Horticulture 5%. Full claim settlement based on yield loss assessment.',
        eligibility: 'All farmers growing notified crops in notified areas. Both loanee and non-loanee farmers eligible.',
        application_process: 'Self-registration at pmfby.gov.in, through banks, insurance companies, or CSCs. Use premium calculator before enrollment.',
        documents_required: 'Aadhaar Card, Land Records, Bank Details, Crop Sowing Details',
        link: 'https://pmfby.gov.in/',
        category: 'Central',
        scheme_type: 'insurance',
        ministry: 'Ministry of Agriculture & Farmers Welfare',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['Rice', 'Wheat', 'Cotton', 'Sugarcane', 'Maize', 'Soybean', 'Groundnut', 'Mustard', 'Pulses']),
        states: JSON.stringify(['All']),
        min_income: 0,
        max_income: null,
        land_ownership_type: 'Any',
        benefit_type: 'variable',
        helpline_number: '14447, 7065514447',
        application_url: 'https://pmfby.gov.in/',
        is_featured: true,
        priority: 95,
        eligibility_criteria: JSON.stringify({
            requires_bank_account: true,
            requires_aadhar: true,
            crop_type_required: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Bank Account', mandatory: true },
            { name: 'Land Records', mandatory: true },
            { name: 'Sowing Certificate', mandatory: true }
        ])
    },
    {
        name: 'Soil Health Card Scheme',
        name_hi: 'मृदा स्वास्थ्य कार्ड योजना',
        description: 'Provides soil health reports to farmers every 3 years with nutrient status and fertilizer recommendations for improved crop yield.',
        benefits: 'Free soil analysis report every 3 years including N-P-K levels, pH, organic carbon, micronutrients. Crop-wise fertilizer recommendations.',
        eligibility: 'All farmers across India. No landholding restrictions.',
        application_process: 'Contact nearest soil testing laboratory or register on Soil Health Card portal.',
        documents_required: 'Aadhaar Card, Land Details, Location Coordinates',
        link: 'https://www.soilhealth.dac.gov.in/',
        category: 'Central',
        scheme_type: 'subsidy',
        ministry: 'Ministry of Agriculture & Farmers Welfare',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['All']),
        land_ownership_type: 'Any',
        benefit_type: 'in_kind',
        helpline_number: '1800-180-1551',
        application_url: 'https://www.soilhealth.dac.gov.in/',
        is_featured: true,
        priority: 85,
        eligibility_criteria: JSON.stringify({
            universal_eligibility: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Land Details', mandatory: true }
        ])
    },
    {
        name: 'Kisan Credit Card (KCC)',
        name_hi: 'किसान क्रेडिट कार्ड',
        description: 'Credit facility for farmers to meet agricultural and allied activity needs at subsidized interest rates.',
        benefits: 'Credit limit up to Rs 3 lakh. Interest rate 7% with 2% subvention (effective 5%). Additional 3% for prompt repayment. RuPay debit card included.',
        eligibility: 'All farmers, sharecroppers, tenant farmers. SHGs, FPOs also eligible.',
        application_process: 'Apply at any bank branch (SBI, PNB, BOI, cooperative banks). Online application available at major banks.',
        documents_required: 'Aadhaar Card, PAN Card, Land Records, Bank Account, Passport Photos',
        link: 'https://www.nabard.org/',
        category: 'Central',
        scheme_type: 'loan',
        ministry: 'Ministry of Finance / NABARD',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['All']),
        land_ownership_type: 'Any',
        benefit_amount_min: 0,
        benefit_amount_max: 300000,
        benefit_type: 'variable',
        helpline_number: '1800-425-1556',
        is_featured: true,
        priority: 90,
        eligibility_criteria: JSON.stringify({
            requires_bank_account: true,
            requires_aadhar: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'PAN Card', mandatory: false },
            { name: 'Land Records', mandatory: true },
            { name: 'Passport Photos', mandatory: true }
        ])
    },
    {
        name: 'eNAM (National Agriculture Market)',
        name_hi: 'राष्ट्रीय कृषि बाजार',
        description: 'Pan-India electronic trading portal linking APMCs across states to create unified national market for agricultural commodities.',
        benefits: 'Access to 1,470+ mandis across India. Online bidding for fair price discovery. Direct DBT payments. Real-time price information for 100+ commodities.',
        eligibility: 'Farmers, Traders, FPOs, Commission agents with license.',
        application_process: 'Online registration at enam.gov.in or through nearest mandi. Training available at mandis.',
        documents_required: 'Aadhaar Card, PAN Card, Bank Details, Mobile Number',
        link: 'https://enam.gov.in/',
        category: 'Central',
        scheme_type: 'market_support',
        ministry: 'Ministry of Agriculture & Farmers Welfare / SFAC',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['All']),
        land_ownership_type: 'Any',
        benefit_type: 'in_kind',
        helpline_number: '1800-270-0224',
        application_url: 'https://enam.gov.in/',
        is_featured: true,
        priority: 80,
        eligibility_criteria: JSON.stringify({
            requires_bank_account: true,
            requires_aadhar: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Bank Account', mandatory: true },
            { name: 'Mobile Number', mandatory: true }
        ])
    },
    {
        name: 'PKVY (Paramparagat Krishi Vikas Yojana)',
        name_hi: 'परम्परागत कृषि विकास योजना',
        description: 'Promotes organic farming through cluster approach with PGS certification and market linkage support.',
        benefits: 'Financial assistance for 3-year conversion period. Free PGS-India organic certification. Training and capacity building. Market linkage support.',
        eligibility: 'Small and marginal farmers willing to adopt organic practices. Clusters of minimum 20 hectares.',
        application_process: 'Apply through State Agriculture Department. Form cluster with 20+ farmers.',
        documents_required: 'Aadhaar Card, Land Records, Bank Details',
        link: 'https://pgsindia-ncof.gov.in/',
        category: 'Central',
        scheme_type: 'subsidy',
        ministry: 'Ministry of Agriculture & Farmers Welfare',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['All']),
        land_ownership_type: 'Any',
        benefit_type: 'variable',
        priority: 75,
        eligibility_criteria: JSON.stringify({
            farmer_categories: ['marginal', 'small'],
            organic_commitment: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Land Records', mandatory: true },
            { name: 'Cluster Formation Document', mandatory: true }
        ])
    },
    {
        name: 'SMAM (Sub-Mission on Agricultural Mechanization)',
        name_hi: 'कृषि मशीनीकरण पर उप-मिशन',
        description: 'Promotes farm mechanization through subsidies on agricultural machinery and equipment, Custom Hiring Centers, and Farm Machinery Banks.',
        benefits: 'Subsidy 50-80% on farm machinery. Support for Custom Hiring Centres (CHCs) and Farm Machinery Banks. Hi-tech Hubs for advanced equipment.',
        eligibility: 'All farmers, SHGs, User Groups, Cooperative Societies, FPOs. Priority to women and SC/ST farmers.',
        application_process: 'Online application at agrimachinery.nic.in. Subsidy via DBT.',
        documents_required: 'Aadhaar Card, Land Records, Bank Details, Caste Certificate (if applicable)',
        link: 'https://agrimachinery.nic.in/',
        category: 'Central',
        scheme_type: 'subsidy',
        ministry: 'Ministry of Agriculture & Farmers Welfare',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['All']),
        land_ownership_type: 'Any',
        benefit_type: 'percentage',
        application_url: 'https://agrimachinery.nic.in/',
        is_featured: true,
        priority: 85,
        eligibility_criteria: JSON.stringify({
            requires_bank_account: true,
            requires_aadhar: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Land Records', mandatory: true },
            { name: 'Bank Account', mandatory: true },
            { name: 'Caste Certificate', mandatory: false }
        ])
    },
    {
        name: 'PM-KUSUM (Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan)',
        name_hi: 'प्रधानमंत्री किसान ऊर्जा सुरक्षा एवं उत्थान महाभियान',
        description: 'Promotes solar energy in agricultural sector through solar pumps and grid-connected solar power plants.',
        benefits: 'Up to 60% subsidy on solar pumps (3-10 HP). Additional income from selling surplus power to grid. Reduced electricity bills.',
        eligibility: 'All farmers with agricultural land. Priority for areas with erratic power supply.',
        application_process: 'Apply through State Nodal Agency or MNRE portal.',
        documents_required: 'Aadhaar Card, Land Records, Electricity Connection Details, Bank Account',
        link: 'https://mnre.gov.in/pm-kusum',
        category: 'Central',
        scheme_type: 'subsidy',
        ministry: 'Ministry of New and Renewable Energy',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['All']),
        land_ownership_type: 'owner',
        benefit_type: 'percentage',
        priority: 80,
        eligibility_criteria: JSON.stringify({
            requires_land_ownership: true,
            requires_bank_account: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Land Records', mandatory: true },
            { name: 'Electricity Bill', mandatory: false },
            { name: 'Bank Account', mandatory: true }
        ])
    },
    {
        name: 'Maharashtra Krishi Samruddhi Yojana',
        name_hi: 'महाराष्ट्र कृषि समृद्धि योजना',
        description: 'Maharashtra state scheme for comprehensive agricultural development including AI-powered farming, solar subsidies, and market support.',
        benefits: 'Rs 25,000 crore over 5 years. AI-powered agriculture support. Solar farming subsidies. Micro-irrigation support. Warehouse infrastructure.',
        eligibility: 'Farmers registered in Maharashtra.',
        application_process: 'Register on MahaDBT Farmer Portal. FCFS system.',
        documents_required: 'Aadhaar Card, 7/12 Extract, Bank Details',
        link: 'https://mahadbt.maharashtra.gov.in/',
        category: 'State',
        scheme_type: 'subsidy',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['Maharashtra']),
        land_ownership_type: 'Any',
        benefit_type: 'variable',
        application_url: 'https://mahadbt.maharashtra.gov.in/',
        priority: 70,
        eligibility_criteria: JSON.stringify({
            requires_state_residence: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: '7/12 Extract', mandatory: true },
            { name: 'Bank Account', mandatory: true }
        ])
    },
    {
        name: 'Punjab Green Tractor Scheme',
        name_hi: 'पंजाब हरित ट्रैक्टर योजना',
        description: 'Punjab state scheme providing subsidies on eco-friendly tractors for sustainable farming.',
        benefits: 'Up to Rs 10 lakh subsidy (50%) on 75 HP and 85 HP eco-friendly tractors.',
        eligibility: 'Registered farmers of Punjab.',
        application_process: 'Apply through Punjab Agriculture Department.',
        documents_required: 'Aadhaar Card, Land Records, Bank Details',
        link: 'https://agri.punjab.gov.in/',
        category: 'State',
        scheme_type: 'subsidy',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['Punjab']),
        land_ownership_type: 'Any',
        benefit_amount_max: 1000000,
        benefit_type: 'percentage',
        priority: 65,
        eligibility_criteria: JSON.stringify({
            requires_state_residence: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Land Records', mandatory: true },
            { name: 'Bank Account', mandatory: true }
        ])
    },
    {
        name: 'UP Krishi Yantra Subsidy Yojana',
        name_hi: 'उत्तर प्रदेश कृषि यंत्र अनुदान योजना',
        description: 'Uttar Pradesh scheme providing subsidies on agricultural machinery for marginal and small farmers.',
        benefits: 'Up to 50-80% subsidy on agricultural machinery including threshers, power tillers, laser levellers.',
        eligibility: 'Marginal, backward, or small class farmers of UP.',
        application_process: 'Online registration at upagriculture.com. Token-based pre-booking system.',
        documents_required: 'Aadhaar Card, Land Records, Bank Details, Caste Certificate',
        link: 'https://upagriculture.com/',
        category: 'State',
        scheme_type: 'subsidy',
        min_farm_size: 0,
        max_farm_size: 2.0,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['Uttar Pradesh']),
        land_ownership_type: 'Any',
        benefit_type: 'percentage',
        helpline_number: '7554935001',
        application_url: 'https://upagriculture.com/',
        priority: 65,
        eligibility_criteria: JSON.stringify({
            requires_state_residence: true,
            farmer_categories: ['marginal', 'small']
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Land Records', mandatory: true },
            { name: 'Caste Certificate', mandatory: false }
        ])
    },
    {
        name: 'Karnataka Krishi Bhagya Scheme',
        name_hi: 'कर्नाटक कृषि भाग्य योजना',
        description: 'Karnataka scheme supporting rainfed agriculture through farm ponds, micro-irrigation, and solar pumps.',
        benefits: 'Farm pond construction subsidies. Polyethylene enclosure support. Drip/sprinkler irrigation units. Solar pump support.',
        eligibility: 'Farmers in rainfed areas of Karnataka with land ownership.',
        application_process: 'Apply through Karnataka Agriculture Department.',
        documents_required: 'Passport Photo, Caste Certificate, ID Card, Income Certificate, Pahani Letter',
        link: 'https://raitamitra.karnataka.gov.in/',
        category: 'State',
        scheme_type: 'infrastructure',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['Karnataka']),
        land_ownership_type: 'owner',
        benefit_type: 'variable',
        priority: 65,
        eligibility_criteria: JSON.stringify({
            requires_state_residence: true,
            rainfed_area: true
        }),
        required_documents: JSON.stringify([
            { name: 'Pahani Letter', mandatory: true },
            { name: 'Caste Certificate', mandatory: false },
            { name: 'Income Certificate', mandatory: true }
        ])
    },
    {
        name: 'Karnataka Raitha Siri Scheme',
        name_hi: 'कर्नाटक रैता सिरी योजना',
        description: 'Karnataka scheme promoting millet cultivation with direct cash incentives.',
        benefits: 'Rs 10,000 per hectare for millet cultivation. Promotes drought-resistant crops.',
        eligibility: 'Farmers in Karnataka growing millets.',
        application_process: 'Apply through Karnataka Agriculture Department.',
        documents_required: 'Aadhaar Card, Land Records, Crop Details',
        link: 'https://raitamitra.karnataka.gov.in/',
        category: 'State',
        scheme_type: 'subsidy',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['Ragi', 'Jowar', 'Bajra', 'Foxtail Millet', 'Little Millet']),
        states: JSON.stringify(['Karnataka']),
        land_ownership_type: 'Any',
        benefit_amount_min: 10000,
        benefit_type: 'fixed',
        priority: 60,
        eligibility_criteria: JSON.stringify({
            requires_state_residence: true,
            millet_cultivation: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Land Records', mandatory: true }
        ])
    },
    {
        name: 'Madhya Pradesh Solar Pump Subsidy',
        name_hi: 'मध्य प्रदेश सोलर पंप अनुदान',
        description: 'MP scheme providing up to 90% subsidy on solar pumps for irrigation.',
        benefits: '90% subsidy on solar pumps. Upgrade from 3 HP to 5 HP or 5 HP to 7.5 HP solar pump. Free electricity for irrigation.',
        eligibility: 'Farmers in Madhya Pradesh with agricultural land.',
        application_process: 'Apply through MP Agriculture Department.',
        documents_required: 'Aadhaar Card, Land Records, Existing Pump Details',
        link: 'https://mpkrishi.gov.in/',
        category: 'State',
        scheme_type: 'subsidy',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['Madhya Pradesh']),
        land_ownership_type: 'owner',
        benefit_type: 'percentage',
        priority: 70,
        eligibility_criteria: JSON.stringify({
            requires_state_residence: true,
            requires_land_ownership: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Land Records', mandatory: true },
            { name: 'Existing Pump Details', mandatory: false }
        ])
    },
    {
        name: 'National Horticulture Mission (NHM)',
        name_hi: 'राष्ट्रीय बागवानी मिशन',
        description: 'Central scheme for holistic development of horticulture sector including fruits, vegetables, flowers, and spices.',
        benefits: '35-50% subsidy on orchard establishment, protected cultivation, and post-harvest infrastructure.',
        eligibility: 'All farmers engaged in horticulture.',
        application_process: 'Apply through State Horticulture Department.',
        documents_required: 'Aadhaar Card, Land Records, Bank Account',
        link: 'https://nhm.nic.in/',
        category: 'Central',
        scheme_type: 'subsidy',
        ministry: 'Ministry of Agriculture & Farmers Welfare',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['Mango', 'Banana', 'Citrus', 'Apple', 'Grapes', 'Vegetables', 'Flowers', 'Spices']),
        states: JSON.stringify(['All']),
        land_ownership_type: 'Any',
        benefit_type: 'percentage',
        priority: 75,
        eligibility_criteria: JSON.stringify({
            horticulture_focus: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Land Records', mandatory: true },
            { name: 'Bank Account', mandatory: true }
        ])
    },
    {
        name: 'Rashtriya Krishi Vikas Yojana (RKVY)',
        name_hi: 'राष्ट्रीय कृषि विकास योजना',
        description: 'Umbrella scheme for state-level agricultural development projects with flexible funding.',
        benefits: 'Funding for various agricultural projects at state level. Infrastructure development. Technology adoption support.',
        eligibility: 'Varies by state project. Generally all farmers eligible.',
        application_process: 'Apply through State Agriculture Department based on specific project.',
        documents_required: 'Aadhaar Card, Land Records, Project-specific documents',
        link: 'https://rkvy.nic.in/',
        category: 'Central',
        scheme_type: 'infrastructure',
        ministry: 'Ministry of Agriculture & Farmers Welfare',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['All']),
        land_ownership_type: 'Any',
        benefit_type: 'variable',
        priority: 70,
        eligibility_criteria: JSON.stringify({
            project_based: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Land Records', mandatory: true }
        ])
    },
    {
        name: 'Interest Subvention Scheme for Short-term Crop Loans',
        name_hi: 'अल्पकालिक फसल ऋण पर ब्याज छूट योजना',
        description: 'Provides interest subvention on short-term crop loans up to Rs 3 lakh at 4% effective interest rate.',
        benefits: '2% interest subvention by Government. Additional 3% for prompt repayment. Effective interest rate 4% for timely repayers.',
        eligibility: 'All farmers taking short-term crop loans up to Rs 3 lakh.',
        application_process: 'Available through all scheduled commercial banks, RRBs, and cooperative banks.',
        documents_required: 'KCC or Crop Loan Account, Aadhaar Card',
        link: 'https://www.nabard.org/',
        category: 'Central',
        scheme_type: 'loan',
        ministry: 'Ministry of Finance / RBI',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['All']),
        land_ownership_type: 'Any',
        benefit_amount_max: 300000,
        benefit_type: 'percentage',
        priority: 80,
        eligibility_criteria: JSON.stringify({
            requires_bank_loan: true,
            loan_limit: 300000
        }),
        required_documents: JSON.stringify([
            { name: 'KCC/Loan Account', mandatory: true },
            { name: 'Aadhaar Card', mandatory: true }
        ])
    },
    {
        name: 'Agriculture Infrastructure Fund (AIF)',
        name_hi: 'कृषि अवसंरचना कोष',
        description: 'Rs 1 lakh crore financing facility for post-harvest management and community farming assets.',
        benefits: '3% interest subvention on loans up to Rs 2 crore. Credit guarantee up to Rs 2 crore.',
        eligibility: 'Farmers, FPOs, PACS, Marketing Cooperatives, Startups, Agri-entrepreneurs.',
        application_process: 'Apply online through AIF portal via Primary Lending Institutions.',
        documents_required: 'Aadhaar Card, PAN Card, Business/Farm Documents, Project Report',
        link: 'https://agriinfra.dac.gov.in/',
        category: 'Central',
        scheme_type: 'infrastructure',
        ministry: 'Ministry of Agriculture & Farmers Welfare',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['All']),
        land_ownership_type: 'Any',
        benefit_amount_max: 20000000,
        benefit_type: 'percentage',
        application_url: 'https://agriinfra.dac.gov.in/',
        priority: 75,
        eligibility_criteria: JSON.stringify({
            project_based: true,
            requires_project_report: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'PAN Card', mandatory: true },
            { name: 'Project Report', mandatory: true }
        ])
    },
    {
        name: 'Micro Irrigation Fund (MIF)',
        name_hi: 'सूक्ष्म सिंचाई कोष',
        description: 'Rs 5,000 crore dedicated fund for promoting drip and sprinkler irrigation systems.',
        benefits: 'Subsidies for drip and sprinkler systems. State-wise support for micro-irrigation infrastructure.',
        eligibility: 'All farmers, especially in water-stressed areas.',
        application_process: 'Apply through State Agriculture/Horticulture Department.',
        documents_required: 'Aadhaar Card, Land Records, Water Source Details',
        link: 'https://pmksy.gov.in/',
        category: 'Central',
        scheme_type: 'infrastructure',
        ministry: 'Ministry of Agriculture & Farmers Welfare',
        min_farm_size: 0,
        max_farm_size: null,
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['All']),
        land_ownership_type: 'Any',
        benefit_type: 'percentage',
        priority: 70,
        eligibility_criteria: JSON.stringify({
            irrigation_focus: true
        }),
        required_documents: JSON.stringify([
            { name: 'Aadhaar Card', mandatory: true },
            { name: 'Land Records', mandatory: true },
            { name: 'Water Source Details', mandatory: true }
        ])
    }
];

async function seedSchemes() {
    const client = await db.pool.connect();
    
    try {
        console.log('Starting schemes seeding...');
        await client.query('BEGIN');

        await client.query('DELETE FROM scheme_notifications WHERE 1=1');
        await client.query('DELETE FROM scheme_applications WHERE 1=1');
        await client.query('DELETE FROM scheme_subscriptions WHERE 1=1');
        await client.query('DELETE FROM schemes WHERE 1=1');

        for (const scheme of indianAgriculturalSchemes) {
            await client.query(
                `INSERT INTO schemes (
                    name, name_hi, description, benefits, eligibility, application_process,
                    documents_required, link, category, scheme_type, ministry,
                    min_farm_size, max_farm_size, crops, states, districts,
                    min_income, max_income, land_ownership_type,
                    benefit_amount_min, benefit_amount_max, benefit_type,
                    helpline_number, application_url, is_featured, priority,
                    eligibility_criteria, required_documents, active
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29)`,
                [
                    scheme.name,
                    scheme.name_hi || null,
                    scheme.description,
                    scheme.benefits,
                    scheme.eligibility,
                    scheme.application_process || null,
                    scheme.documents_required || null,
                    scheme.link || null,
                    scheme.category,
                    scheme.scheme_type || 'subsidy',
                    scheme.ministry || null,
                    scheme.min_farm_size || null,
                    scheme.max_farm_size || null,
                    scheme.crops || null,
                    scheme.states || null,
                    scheme.districts || null,
                    scheme.min_income || null,
                    scheme.max_income || null,
                    scheme.land_ownership_type || null,
                    scheme.benefit_amount_min || null,
                    scheme.benefit_amount_max || null,
                    scheme.benefit_type || null,
                    scheme.helpline_number || null,
                    scheme.application_url || null,
                    scheme.is_featured || false,
                    scheme.priority || 50,
                    scheme.eligibility_criteria || null,
                    scheme.required_documents || null,
                    true
                ]
            );
            console.log(`Seeded: ${scheme.name}`);
        }

        await client.query('COMMIT');
        console.log(`Successfully seeded ${indianAgriculturalSchemes.length} schemes.`);
        
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error seeding schemes:', error);
        throw error;
    } finally {
        client.release();
    }
}

if (require.main === module) {
    seedSchemes()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
}

module.exports = { seedSchemes, indianAgriculturalSchemes };

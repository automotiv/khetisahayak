require('dotenv').config();
const db = require('../db');
console.log('DB_HOST:', process.env.DB_HOST);

const schemes = [
    {
        name: 'PM Kisan Samman Nidhi',
        description: 'Income support of Rs 6000 per year for small and marginal farmers.',
        benefits: 'Rs 6000 per year in 3 installments',
        eligibility: 'Landholding up to 2 hectares',
        category: 'Central',
        min_farm_size: 0,
        max_farm_size: 2.0, // hectares
        crops: JSON.stringify(['All']),
        states: JSON.stringify(['All']),
        min_income: 0,
        max_income: 1000000, // No specific income limit but for filtering
        land_ownership_type: 'Owner',
        deadline: '2025-12-31',
        benefits_matrix: JSON.stringify({
            financial: 'Rs 6000/year',
            insurance: 'No',
            subsidy: 'No'
        })
    },
    {
        name: 'Punjab Wheat Subsidy',
        description: 'Subsidy for wheat seeds for farmers in Punjab.',
        benefits: '50% subsidy on seeds',
        eligibility: 'Farmers in Punjab growing wheat',
        category: 'State',
        min_farm_size: 0,
        max_farm_size: 10.0,
        crops: JSON.stringify(['Wheat']),
        states: JSON.stringify(['Punjab']),
        districts: JSON.stringify(['Amritsar', 'Ludhiana']),
        min_income: 0,
        max_income: 500000,
        land_ownership_type: 'Owner',
        deadline: '2024-10-15',
        benefits_matrix: JSON.stringify({
            financial: 'No',
            insurance: 'No',
            subsidy: '50% on seeds'
        })
    },
    {
        name: 'Crop Insurance Scheme',
        description: 'Insurance against crop loss due to natural calamities.',
        benefits: 'Coverage up to Rs 50,000 per hectare',
        eligibility: 'All farmers',
        category: 'Insurance',
        min_farm_size: 0,
        max_farm_size: 100.0,
        crops: JSON.stringify(['Rice', 'Wheat', 'Cotton']),
        states: JSON.stringify(['All']),
        min_income: 0,
        max_income: 10000000,
        land_ownership_type: 'Any',
        deadline: '2024-07-31',
        benefits_matrix: JSON.stringify({
            financial: 'Claim based',
            insurance: 'Yes',
            subsidy: 'Premium subsidy'
        })
    }
];

async function seed() {
    try {
        console.log('Seeding schemes...');
        // Clear existing
        await db.query('DELETE FROM schemes');

        for (const scheme of schemes) {
            await db.query(
                `INSERT INTO schemes (
                    name, description, benefits, eligibility, category, 
                    min_farm_size, max_farm_size, crops, states, districts, 
                    min_income, max_income, land_ownership_type, deadline, benefits_matrix
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)`,
                [
                    scheme.name, scheme.description, scheme.benefits, scheme.eligibility, scheme.category,
                    scheme.min_farm_size, scheme.max_farm_size, scheme.crops, scheme.states, scheme.districts,
                    scheme.min_income, scheme.max_income, scheme.land_ownership_type, scheme.deadline, scheme.benefits_matrix
                ]
            );
        }
        console.log('Seeding completed successfully.');
        process.exit(0);
    } catch (error) {
        console.error('Error seeding schemes:', error);
        process.exit(1);
    }
}

seed();

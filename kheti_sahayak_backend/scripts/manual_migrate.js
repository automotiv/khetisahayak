require('dotenv').config();
const db = require('../db');

async function migrate() {
    try {
        console.log('Running manual migration...');

        // Drop table if exists to ensure clean state with new columns
        await db.query('DROP TABLE IF EXISTS schemes');

        const createTableQuery = `
            CREATE TABLE IF NOT EXISTS schemes (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                name_hi VARCHAR(255),
                description TEXT NOT NULL,
                benefits TEXT,
                eligibility TEXT,
                application_process TEXT,
                documents_required TEXT,
                link VARCHAR(255),
                category VARCHAR(100),
                min_farm_size FLOAT,
                max_farm_size FLOAT,
                crops TEXT,
                states TEXT,
                districts TEXT,
                min_income FLOAT,
                max_income FLOAT,
                land_ownership_type VARCHAR(100),
                deadline TIMESTAMP,
                benefits_matrix JSON,
                active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `;

        await db.query(createTableQuery);
        console.log('Migration completed successfully.');
        process.exit(0);
    } catch (error) {
        console.error('Error running migration:', error);
        process.exit(1);
    }
}

migrate();

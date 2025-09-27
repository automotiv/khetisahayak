/* eslint-disable camelcase */

const fs = require('fs');
const path = require('path');

exports.shorthands = undefined;

// Read the initial schema from the SQL file
let initialSchemaSql;
try {
  initialSchemaSql = fs.readFileSync(path.join(__dirname, '../init_db.sql'), 'utf8');
} catch (error) {
  // If init_db.sql doesn't exist, use hardcoded schema
  initialSchemaSql = `
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

    CREATE TABLE IF NOT EXISTS users (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      username VARCHAR(255) UNIQUE NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      role VARCHAR(50) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin', 'content-creator')),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS products (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      name VARCHAR(255) NOT NULL,
      description TEXT,
      price NUMERIC(10, 2) NOT NULL,
      category VARCHAR(255),
      image_url VARCHAR(255),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      seller_id UUID REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS diagnostics (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
      crop_type VARCHAR(255) NOT NULL,
      issue_description TEXT NOT NULL,
      diagnosis_result TEXT,
      recommendations TEXT,
      image_url VARCHAR(255),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS educational_content (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      title VARCHAR(255) NOT NULL,
      content TEXT NOT NULL,
      category VARCHAR(255),
      author_id UUID REFERENCES users(id) ON DELETE SET NULL,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  `;
}

exports.up = (pgm) => {
  // Use pgm.sql() to execute the raw SQL from our init_db.sql file
  pgm.sql(initialSchemaSql);
};

exports.down = (pgm) => {
  // Drop tables in reverse order of creation to respect foreign key constraints
  pgm.sql(`
    DROP TABLE IF EXISTS educational_content, diagnostics, products, users CASCADE;
  `);
};
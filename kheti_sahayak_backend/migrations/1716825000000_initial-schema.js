/* eslint-disable camelcase */

const fs = require('fs');
const path = require('path');

exports.shorthands = undefined;

// Read the initial schema from the SQL file
const initialSchemaSql = fs.readFileSync(path.join(__dirname, '../init_db.sql'), 'utf8');

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
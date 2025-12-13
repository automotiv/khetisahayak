const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;
const isExternalRender = connectionString && connectionString.includes('render.com');
const dbHost = process.env.DB_HOST || 'localhost';

// For local development, never use SSL
const isLocalHost = dbHost === 'localhost' || dbHost === '127.0.0.1';

const pool = new Pool(
  connectionString
    ? {
      connectionString,
      ssl: isExternalRender ? { rejectUnauthorized: false } : false,
    }
    : {
      user: process.env.DB_USER || 'pponali',
      host: dbHost,
      database: process.env.DB_NAME || 'kheti_sahayak',
      password: process.env.DB_PASSWORD,
      port: process.env.DB_PORT || 5432,
      ssl: isLocalHost ? false : { rejectUnauthorized: false },
    }
);

module.exports = {
  query: (text, params) => pool.query(text, params),
};
const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;
const isExternalRender = connectionString && connectionString.includes('render.com');

const host = process.env.DB_HOST || 'localhost';
const isLocal = host === 'localhost' || host === '127.0.0.1';

const pool = new Pool(
  connectionString
    ? {
      connectionString,
      ssl: isExternalRender ? { rejectUnauthorized: false } : false,
    }
    : {
      user: process.env.DB_USER,
      host: host,
      database: process.env.DB_NAME,
      password: process.env.DB_PASSWORD,
      port: process.env.DB_PORT,
      ssl: isLocal ? false : { rejectUnauthorized: false },
    }
);

module.exports = {
  query: (text, params) => pool.query(text, params),
};
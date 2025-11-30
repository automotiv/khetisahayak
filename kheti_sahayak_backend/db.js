const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;
const isExternalRender = connectionString && connectionString.includes('render.com');

const pool = new Pool(
  connectionString
    ? {
      connectionString,
      ssl: isExternalRender ? { rejectUnauthorized: false } : false,
    }
    : {
      user: process.env.DB_USER,
      host: process.env.DB_HOST,
      database: process.env.DB_NAME,
      password: process.env.DB_PASSWORD,
      port: process.env.DB_PORT,
      ssl: process.env.DB_HOST === 'localhost' ? false : { rejectUnauthorized: false },
    }
);

module.exports = {
  query: (text, params) => pool.query(text, params),
};
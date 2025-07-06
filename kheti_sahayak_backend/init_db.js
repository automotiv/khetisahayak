const { Pool } = require('pg');
require('dotenv').config({ path: './.env' });
const fs = require('fs');

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

const createTables = async () => {
  const initSql = fs.readFileSync('./init_db.sql', 'utf8');
  try {
    await pool.query(initSql);
    console.log('Tables created successfully!');
  } catch (err) {
    console.error('Error creating tables:', err);
  } finally {
    await pool.end();
  }
};

createTables();
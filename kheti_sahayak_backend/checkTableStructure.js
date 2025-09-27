const { Pool } = require('pg');
require('dotenv').config({ path: './.env' });

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

const checkTableStructure = async () => {
  try {
    // Get table info
    const res = await pool.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'users';
    `);
    
    console.log('Users table structure:');
    console.table(res.rows);
    
    // Check if users exist
    const users = await pool.query('SELECT * FROM users LIMIT 5');
    console.log('\nFirst 5 users:');
    console.table(users.rows);
    
  } catch (err) {
    console.error('Error checking table structure:', err);
  } finally {
    await pool.end();
  }
};

checkTableStructure();

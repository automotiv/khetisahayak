const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_URL && process.env.DATABASE_URL.includes('render.com')
        ? { rejectUnauthorized: false }
        : false
});

async function checkTable() {
    try {
        const res = await pool.query("SELECT to_regclass('public.products')");
        console.log('Table exists:', !!res.rows[0].to_regclass);
    } catch (err) {
        console.error('Error checking table:', err);
    } finally {
        await pool.end();
    }
}

checkTable();

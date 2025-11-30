const { Pool } = require('pg');

const connectionString = 'postgresql://khetisahayak:HmKhnspjGDAruyyB83cd89UProBhe59K@dpg-d4ludg0gjchc73aud3fg-a.singapore-postgres.render.com/khetisahayak';

const pool = new Pool({
    connectionString,
    ssl: {
        rejectUnauthorized: false,
    },
});

async function testConnection() {
    try {
        console.log('Testing connection to:', connectionString);
        const res = await pool.query('SELECT NOW()');
        console.log('Connection successful:', res.rows[0]);
        await pool.end();
    } catch (err) {
        console.error('Connection error:', err);
    }
}

testConnection();

const { Pool } = require('pg');

const connectionString = 'postgresql://khetisahayak:HmKhnspjGDAruyyB83cd89UProBhe59K@dpg-d4ludg0gjchc73aud3fg-a.singapore-postgres.render.com/khetisahayak';

const pool = new Pool({
    connectionString,
    ssl: {
        rejectUnauthorized: false,
    },
});

async function listTables() {
    try {
        const res = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
        console.log('Tables:', res.rows.map(r => r.table_name));
        await pool.end();
    } catch (err) {
        console.error('Error:', err);
    }
}

listTables();

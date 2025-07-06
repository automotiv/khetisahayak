const { Pool } = require('pg');
require('dotenv').config({ path: './.env' });
const bcrypt = require('bcryptjs');

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

const seedTestUsers = async () => {
  const password = 'test123';
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(password, salt);
  
  const testUsers = [
    {
      id: '11111111-1111-1111-1111-111111111111',
      username: 'testuser',
      email: 'test@example.com',
      password_hash: hashedPassword
    },
    {
      id: '22222222-2222-2222-2222-222222222222',
      username: 'testadmin',
      email: 'admin@example.com',
      password_hash: hashedPassword
    },
    {
      id: '33333333-3333-3333-3333-333333333333',
      username: 'testcreator',
      email: 'creator@example.com',
      password_hash: hashedPassword
    }
  ];

  try {
    // Clear existing test users by username to avoid unique constraint issues
    await pool.query(`
      DELETE FROM users 
      WHERE username IN ($1, $2, $3)
    `, [
      'testuser',
      'testadmin',
      'testcreator'
    ]);

    // Insert test users
    for (const user of testUsers) {
      await pool.query(
        `INSERT INTO users (id, username, email, password_hash, created_at)
         VALUES ($1, $2, $3, $4, NOW())
         ON CONFLICT (id) DO UPDATE
         SET username = EXCLUDED.username,
             email = EXCLUDED.email,
             password_hash = EXCLUDED.password_hash`,
        [user.id, user.username, user.email, user.password_hash]
      );
    }
    
    console.log('Test users seeded successfully!');
    console.log('You can now log in with:');
    console.log('1. Email: test@example.com, Password: test123 (User)');
    console.log('2. Email: admin@example.com, Password: test123 (Admin)');
    console.log('3. Email: creator@example.com, Password: test123 (Content Creator)');
  } catch (err) {
    console.error('Error seeding test users:', err);
  } finally {
    await pool.end();
  }
};

seedTestUsers();

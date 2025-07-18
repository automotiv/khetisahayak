const { Pool } = require('pg');
const bcrypt = require('bcrypt');

// Your test database connection string.
// It's best to use a separate test database to avoid interfering with development data.
const connectionString = process.env.TEST_DATABASE_URL || 'postgres://user:pass@localhost:5432/khetisahayak_test';

const pool = new Pool({ connectionString });

// The hashing cost. This should match your application's configuration.
const SALT_ROUNDS = 10;

/**
 * Creates a new user in the test database.
 * Assumes a 'users' table with 'email', 'password', and 'role' columns.
 * @param {object} userData - The user data { email, password, role }.
 * @returns {Promise<object>} The created user object with id, email, and role.
 */
async function createTestUser({ email, password, role }) {
  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
  const result = await pool.query(
    'INSERT INTO users(email, password, role) VALUES($1, $2, $3) RETURNING id, email, role',
    [email, hashedPassword, role]
  );
  return result.rows[0];
}

/**
 * Deletes a user from the test database by their ID.
 * @param {string|number} id - The ID of the user to delete.
 */
async function deleteUserById(id) {
  await pool.query('DELETE FROM users WHERE id = $1', [id]);
}

/**
 * Closes the database connection pool. Should be called after all tests are done.
 */
async function disconnect() {
  await pool.end();
}

module.exports = { createTestUser, deleteUserById, disconnect };
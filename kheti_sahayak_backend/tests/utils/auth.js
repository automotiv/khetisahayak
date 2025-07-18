const jwt = require('jsonwebtoken');

// It's crucial that this secret matches the one used by your application for token verification.
// Load it from environment variables to keep it secure and consistent.
// You might be using a library like 'dotenv' to load this from a .env file.
const JWT_SECRET = process.env.JWT_SECRET || 'your-default-super-secret-key-for-dev';

/**
 * Generates a valid JWT for testing purposes.
 * @param {object} payload - The payload to include in the token (e.g., { sub: 'user-id', role: 'admin' }).
 * @param {string} expiresIn - The token expiration time (e.g., '1h').
 * @returns {string} The generated JWT, prefixed with 'Bearer '.
 */
function generateTestToken(payload, expiresIn = '1h') {
  if (!JWT_SECRET || JWT_SECRET === 'your-default-super-secret-key-for-dev') {
    console.warn(
      'Warning: Using a default or missing JWT_SECRET for signing test tokens. ' +
      'Ensure the JWT_SECRET environment variable is set to the same value as your application.'
    );
  }

  const token = jwt.sign(payload, JWT_SECRET, { expiresIn });
  return `Bearer ${token}`;
}

module.exports = { generateTestToken };
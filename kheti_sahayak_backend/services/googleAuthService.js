const { OAuth2Client } = require('google-auth-library');
const db = require('../db');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

let googleClient = null;

const initGoogleClient = () => {
  if (!googleClient && process.env.GOOGLE_CLIENT_ID) {
    googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
  }
  return googleClient;
};

/**
 * @param {string} idToken - Google ID token from client
 * @returns {Promise<{googleId: string, email: string, emailVerified: boolean, name: string, firstName: string, lastName: string, picture: string, locale: string}>}
 */
const verifyGoogleToken = async (idToken) => {
  const client = initGoogleClient();
  
  if (!client) {
    throw new Error('Google OAuth is not configured. Set GOOGLE_CLIENT_ID in environment variables.');
  }
  
  try {
    const ticket = await client.verifyIdToken({
      idToken,
      audience: [
        process.env.GOOGLE_CLIENT_ID,
        process.env.GOOGLE_CLIENT_ID_IOS,
        process.env.GOOGLE_CLIENT_ID_ANDROID,
      ].filter(Boolean),
    });
    
    const payload = ticket.getPayload();
    
    return {
      googleId: payload.sub,
      email: payload.email,
      emailVerified: payload.email_verified,
      name: payload.name,
      firstName: payload.given_name,
      lastName: payload.family_name,
      picture: payload.picture,
      locale: payload.locale,
    };
  } catch (error) {
    console.error('[GoogleAuth] Token verification failed:', error.message);
    throw new Error('Invalid Google token');
  }
};

/**
 * @param {{googleId: string, email: string, emailVerified: boolean, firstName: string, lastName: string, picture: string}} googleProfile
 * @returns {Promise<{user: Object, token: string}>}
 */
const findOrCreateUser = async (googleProfile) => {
  const { googleId, email, emailVerified, firstName, lastName, picture } = googleProfile;
  
  let result = await db.query(
    'SELECT * FROM users WHERE google_id = $1',
    [googleId]
  );
  
  let user = result.rows[0];
  
  if (!user) {
    result = await db.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );
    
    user = result.rows[0];
    
    if (user) {
      result = await db.query(
        `UPDATE users 
         SET google_id = $1, 
             profile_image_url = COALESCE(profile_image_url, $2),
             email_verified = COALESCE(email_verified, $3),
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $4 
         RETURNING *`,
        [googleId, picture, emailVerified, user.id]
      );
      user = result.rows[0];
      console.log(`[GoogleAuth] Linked Google account to existing user: ${email}`);
    } else {
      const username = generateUsername(email, firstName, lastName);
      
      result = await db.query(
        `INSERT INTO users (
          username, 
          email, 
          password_hash,
          first_name, 
          last_name, 
          profile_image_url,
          google_id,
          email_verified,
          is_verified,
          auth_provider
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
        RETURNING *`,
        [
          username,
          email,
          null,
          firstName || '',
          lastName || '',
          picture,
          googleId,
          emailVerified || false,
          true,
          'google',
        ]
      );
      user = result.rows[0];
      console.log(`[GoogleAuth] Created new user via Google: ${email}`);
    }
  } else {
    result = await db.query(
      `UPDATE users 
       SET profile_image_url = COALESCE($1, profile_image_url),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2 
       RETURNING *`,
      [picture, user.id]
    );
    user = result.rows[0];
  }
  
  delete user.password_hash;
  
  const token = jwt.sign(
    { id: user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
  );
  
  const tokenHash = await bcrypt.hash(token, 10);
  await db.query(
    'INSERT INTO user_sessions (user_id, token_hash, expires_at, auth_provider) VALUES ($1, $2, $3, $4)',
    [user.id, tokenHash, new Date(Date.now() + 24 * 60 * 60 * 1000), 'google']
  );
  
  return { user, token };
};

const generateUsername = (email, firstName, lastName) => {
  if (firstName && lastName) {
    const baseUsername = `${firstName.toLowerCase()}_${lastName.toLowerCase()}`.replace(/[^a-z0-9_]/g, '');
    return `${baseUsername}_${Date.now().toString(36).slice(-4)}`;
  }
  
  const emailUsername = email.split('@')[0].replace(/[^a-z0-9_]/g, '');
  return `${emailUsername}_${Date.now().toString(36).slice(-4)}`;
};

/**
 * @param {string} userId
 * @returns {Promise<{message: string}>}
 */
const unlinkGoogleAccount = async (userId) => {
  const userResult = await db.query(
    'SELECT password_hash, google_id, facebook_id FROM users WHERE id = $1',
    [userId]
  );
  
  const user = userResult.rows[0];
  
  if (!user) {
    throw new Error('User not found');
  }
  
  if (!user.google_id) {
    throw new Error('Google account is not linked');
  }
  
  const hasPassword = user.password_hash !== null;
  const hasFacebook = user.facebook_id !== null;
  
  if (!hasPassword && !hasFacebook) {
    throw new Error('Cannot unlink Google account. Please set a password first or link another account.');
  }
  
  await db.query(
    'UPDATE users SET google_id = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = $1',
    [userId]
  );
  
  return { message: 'Google account unlinked successfully' };
};

const isGoogleAuthConfigured = () => {
  return !!process.env.GOOGLE_CLIENT_ID;
};

module.exports = {
  verifyGoogleToken,
  findOrCreateUser,
  unlinkGoogleAccount,
  isGoogleAuthConfigured,
  initGoogleClient,
};

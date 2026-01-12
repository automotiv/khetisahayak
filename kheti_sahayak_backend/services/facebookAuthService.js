const axios = require('axios');
const db = require('../db');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const FACEBOOK_GRAPH_API = 'https://graph.facebook.com/v18.0';

const verifyFacebookToken = async (accessToken) => {
  if (!process.env.FACEBOOK_APP_ID || !process.env.FACEBOOK_APP_SECRET) {
    throw new Error('Facebook OAuth is not configured. Set FACEBOOK_APP_ID and FACEBOOK_APP_SECRET in environment variables.');
  }
  
  try {
    const debugResponse = await axios.get(
      `${FACEBOOK_GRAPH_API}/debug_token`,
      {
        params: {
          input_token: accessToken,
          access_token: `${process.env.FACEBOOK_APP_ID}|${process.env.FACEBOOK_APP_SECRET}`,
        },
      }
    );
    
    const tokenData = debugResponse.data.data;
    
    if (!tokenData.is_valid) {
      throw new Error('Invalid Facebook token');
    }
    
    if (tokenData.app_id !== process.env.FACEBOOK_APP_ID) {
      throw new Error('Token was not issued for this application');
    }
    
    const userResponse = await axios.get(
      `${FACEBOOK_GRAPH_API}/me`,
      {
        params: {
          access_token: accessToken,
          fields: 'id,name,email,first_name,last_name,picture.type(large)',
        },
      }
    );
    
    const userData = userResponse.data;
    
    return {
      facebookId: userData.id,
      email: userData.email,
      name: userData.name,
      firstName: userData.first_name,
      lastName: userData.last_name,
      picture: userData.picture?.data?.url,
    };
  } catch (error) {
    console.error('[FacebookAuth] Token verification failed:', error.message);
    if (error.response?.data?.error) {
      throw new Error(error.response.data.error.message);
    }
    throw new Error('Invalid Facebook token');
  }
};

const findOrCreateUser = async (facebookProfile) => {
  const { facebookId, email, firstName, lastName, picture } = facebookProfile;
  
  let result = await db.query(
    'SELECT * FROM users WHERE facebook_id = $1',
    [facebookId]
  );
  
  let user = result.rows[0];
  
  if (!user && email) {
    result = await db.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );
    
    user = result.rows[0];
    
    if (user) {
      result = await db.query(
        `UPDATE users 
         SET facebook_id = $1, 
             profile_image_url = COALESCE(profile_image_url, $2),
             email_verified = true,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $3 
         RETURNING *`,
        [facebookId, picture, user.id]
      );
      user = result.rows[0];
      console.log(`[FacebookAuth] Linked Facebook account to existing user: ${email}`);
    }
  }
  
  if (!user) {
    const username = generateUsername(email, firstName, lastName, facebookId);
    
    result = await db.query(
      `INSERT INTO users (
        username, 
        email, 
        password_hash,
        first_name, 
        last_name, 
        profile_image_url,
        facebook_id,
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
        facebookId,
        !!email,
        true,
        'facebook',
      ]
    );
    user = result.rows[0];
    console.log(`[FacebookAuth] Created new user via Facebook: ${email || facebookId}`);
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
    [user.id, tokenHash, new Date(Date.now() + 24 * 60 * 60 * 1000), 'facebook']
  );
  
  return { user, token };
};

const generateUsername = (email, firstName, lastName, facebookId) => {
  if (firstName && lastName) {
    const baseUsername = `${firstName.toLowerCase()}_${lastName.toLowerCase()}`.replace(/[^a-z0-9_]/g, '');
    return `${baseUsername}_${Date.now().toString(36).slice(-4)}`;
  }
  
  if (email) {
    const emailUsername = email.split('@')[0].replace(/[^a-z0-9_]/g, '');
    return `${emailUsername}_${Date.now().toString(36).slice(-4)}`;
  }
  
  return `fb_${facebookId.slice(-8)}_${Date.now().toString(36).slice(-4)}`;
};

const unlinkFacebookAccount = async (userId) => {
  const userResult = await db.query(
    'SELECT password_hash, google_id, facebook_id FROM users WHERE id = $1',
    [userId]
  );
  
  const user = userResult.rows[0];
  
  if (!user) {
    throw new Error('User not found');
  }
  
  if (!user.facebook_id) {
    throw new Error('Facebook account is not linked');
  }
  
  const hasPassword = user.password_hash !== null;
  const hasGoogle = user.google_id !== null;
  
  if (!hasPassword && !hasGoogle) {
    throw new Error('Cannot unlink Facebook account. Please set a password first or link another account.');
  }
  
  await db.query(
    'UPDATE users SET facebook_id = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = $1',
    [userId]
  );
  
  return { message: 'Facebook account unlinked successfully' };
};

const isFacebookAuthConfigured = () => {
  return !!(process.env.FACEBOOK_APP_ID && process.env.FACEBOOK_APP_SECRET);
};

module.exports = {
  verifyFacebookToken,
  findOrCreateUser,
  unlinkFacebookAccount,
  isFacebookAuthConfigured,
};

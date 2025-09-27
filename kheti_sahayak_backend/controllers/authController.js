const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const asyncHandler = require('express-async-handler');
const { validationResult } = require('express-validator');
const { uploadFileToS3 } = require('../s3');

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
const registerUser = asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { username, email, password, first_name, last_name, phone, address, location_lat, location_lng } = req.body;
  const hashedPassword = await bcrypt.hash(password, 10);
  
  const result = await db.query(
    `INSERT INTO users (username, email, password_hash, first_name, last_name, phone, address, location_lat, location_lng) 
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
    [username, email, hashedPassword, first_name, last_name, phone, address, location_lat, location_lng]
  );
  
  const user = result.rows[0];
  delete user.password_hash;

  // Generate JWT token
  const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '24h' });

  res.status(201).json({ 
    message: 'User registered successfully', 
    user,
    token 
  });
});

// @desc    Authenticate user & get token
// @route   POST /api/auth/login
// @access  Public
const loginUser = asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { email, password } = req.body;
  const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
  const user = result.rows[0];

  if (user && (await bcrypt.compare(password, user.password_hash))) {
    const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '24h' });
    
    // Store session
    const tokenHash = await bcrypt.hash(token, 10);
    await db.query(
      'INSERT INTO user_sessions (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
      [user.id, tokenHash, new Date(Date.now() + 24 * 60 * 60 * 1000)] // 24 hours
    );

    delete user.password_hash;
    res.json({ 
      message: 'Login successful',
      user,
      token 
    });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

// @desc    Get current user profile
// @route   GET /api/auth/profile
// @access  Private
const getProfile = asyncHandler(async (req, res) => {
  const result = await db.query(
    'SELECT id, username, email, first_name, last_name, phone, address, location_lat, location_lng, role, profile_image_url, is_verified, created_at FROM users WHERE id = $1',
    [req.user.id]
  );
  
  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('User not found');
  }
  
  res.json(result.rows[0]);
});

// @desc    Update user profile
// @route   PUT /api/auth/profile
// @access  Private
const updateProfile = asyncHandler(async (req, res) => {
  const { first_name, last_name, phone, address, location_lat, location_lng } = req.body;
  
  const result = await db.query(
    `UPDATE users 
     SET first_name = COALESCE($1, first_name), 
         last_name = COALESCE($2, last_name), 
         phone = COALESCE($3, phone), 
         address = COALESCE($4, address), 
         location_lat = COALESCE($5, location_lat), 
         location_lng = COALESCE($6, location_lng),
         updated_at = CURRENT_TIMESTAMP
     WHERE id = $7 RETURNING *`,
    [first_name, last_name, phone, address, location_lat, location_lng, req.user.id]
  );
  
  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('User not found');
  }
  
  const user = result.rows[0];
  delete user.password_hash;
  
  res.json({ 
    message: 'Profile updated successfully',
    user 
  });
});

// @desc    Upload profile image
// @route   POST /api/auth/profile-image
// @access  Private
const uploadProfileImage = asyncHandler(async (req, res) => {
  if (!req.file) {
    res.status(400);
    throw new Error('No image file provided');
  }

  const file = req.file;
  const fileName = `profiles/${req.user.id}/${Date.now()}-${file.originalname}`;
  
  const imageUrl = await uploadFileToS3(file.buffer, fileName, file.mimetype);
  
  const result = await db.query(
    'UPDATE users SET profile_image_url = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING profile_image_url',
    [imageUrl, req.user.id]
  );
  
  res.json({ 
    message: 'Profile image uploaded successfully',
    profile_image_url: result.rows[0].profile_image_url 
  });
});

// @desc    Change password
// @route   PUT /api/auth/change-password
// @access  Private
const changePassword = asyncHandler(async (req, res) => {
  const { current_password, new_password } = req.body;
  
  if (!current_password || !new_password) {
    res.status(400);
    throw new Error('Current password and new password are required');
  }
  
  // Get current user with password
  const userResult = await db.query('SELECT password_hash FROM users WHERE id = $1', [req.user.id]);
  const user = userResult.rows[0];
  
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }
  
  // Verify current password
  const isCurrentPasswordValid = await bcrypt.compare(current_password, user.password_hash);
  if (!isCurrentPasswordValid) {
    res.status(400);
    throw new Error('Current password is incorrect');
  }
  
  // Hash new password
  const hashedNewPassword = await bcrypt.hash(new_password, 10);
  
  // Update password
  await db.query(
    'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
    [hashedNewPassword, req.user.id]
  );
  
  res.json({ message: 'Password changed successfully' });
});

// @desc    Logout user
// @route   POST /api/auth/logout
// @access  Private
const logoutUser = asyncHandler(async (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (token) {
    const tokenHash = await bcrypt.hash(token, 10);
    await db.query(
      'DELETE FROM user_sessions WHERE user_id = $1 AND token_hash = $2',
      [req.user.id, tokenHash]
    );
  }
  
  res.json({ message: 'Logged out successfully' });
});

// @desc    Get all users (Admin only)
// @route   GET /api/auth/users
// @access  Private/Admin
const getAllUsers = asyncHandler(async (req, res) => {
  const result = await db.query(
    'SELECT id, username, email, first_name, last_name, role, is_verified, created_at FROM users ORDER BY created_at DESC'
  );
  
  res.json(result.rows);
});

// @desc    Delete user (Admin only)
// @route   DELETE /api/auth/users/:id
// @access  Private/Admin
const deleteUser = asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  if (id === req.user.id) {
    res.status(400);
    throw new Error('Cannot delete your own account');
  }
  
  const result = await db.query('DELETE FROM users WHERE id = $1 RETURNING id', [id]);
  
  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('User not found');
  }
  
  res.json({ message: 'User deleted successfully' });
});

module.exports = {
  registerUser,
  loginUser,
  getProfile,
  updateProfile,
  uploadProfileImage,
  changePassword,
  logoutUser,
  getAllUsers,
  deleteUser,
};
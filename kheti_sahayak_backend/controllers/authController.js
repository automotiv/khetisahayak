const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const asyncHandler = require('express-async-handler');
const { validationResult } = require('express-validator');
const { uploadFileToS3 } = require('../s3');
const verificationService = require('../services/verificationService');
const emailService = require('../services/emailService');
const smsService = require('../services/smsService');
const googleAuthService = require('../services/googleAuthService');
const facebookAuthService = require('../services/facebookAuthService');

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
const registerUser = asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  let { username, email, password, first_name, last_name, phone, address, location_lat, location_lng } = req.body;

  // Split username into first_name and last_name if not provided
  if (!first_name || !last_name) {
    const nameParts = username.trim().split(' ');
    // Handle single word names (put empty string as last name or repeat first name? Let's use dot for last name if missing to satisfy DB constraints if any, or just empty)
    // Looking at the INSERT query, it expects values for first_name and last_name.

    first_name = first_name || nameParts[0];
    // Join the rest as last name, or use a placeholder if single name
    last_name = last_name || (nameParts.length > 1 ? nameParts.slice(1).join(' ') : '.');
  }
  const hashedPassword = await bcrypt.hash(password, 10);

  const result = await db.query(
    `INSERT INTO users (username, email, password_hash, first_name, last_name, phone, address, location_lat, location_lng) 
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
    [username, email, hashedPassword, first_name, last_name, phone, address, location_lat, location_lng]
  );

  const user = result.rows[0];
  delete user.password_hash;

  const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '24h' });

  // Send verification email (non-blocking)
  verificationService.sendVerificationEmail(user).catch(err => {
    console.error('[Auth] Failed to send verification email:', err.message);
  });

  // Send welcome email (non-blocking)
  emailService.sendWelcomeEmail(user).catch(err => {
    console.error('[Auth] Failed to send welcome email:', err.message);
  });

  res.status(201).json({
    message: 'User registered successfully. Please check your email to verify your account.',
    user,
    token,
    emailVerificationRequired: true
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

// @desc    Verify email with token
// @route   GET /api/auth/verify-email
// @access  Public
const verifyEmail = asyncHandler(async (req, res) => {
  const { token } = req.query;

  if (!token) {
    res.status(400);
    throw new Error('Verification token is required');
  }

  const result = await verificationService.verifyEmail(token);

  if (!result.success) {
    res.status(400);
    throw new Error(result.error);
  }

  res.json({
    message: 'Email verified successfully',
    user: result.user
  });
});

// @desc    Resend verification email
// @route   POST /api/auth/resend-verification
// @access  Private
const resendVerificationEmail = asyncHandler(async (req, res) => {
  const userResult = await db.query(
    'SELECT id, email, username, first_name, email_verified FROM users WHERE id = $1',
    [req.user.id]
  );

  if (userResult.rows.length === 0) {
    res.status(404);
    throw new Error('User not found');
  }

  const user = userResult.rows[0];

  if (user.email_verified) {
    res.status(400);
    throw new Error('Email is already verified');
  }

  await verificationService.sendVerificationEmail(user);

  res.json({ message: 'Verification email sent successfully' });
});

// @desc    Request password reset
// @route   POST /api/auth/forgot-password
// @access  Public
const forgotPassword = asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { email } = req.body;

  const result = await verificationService.createPasswordResetToken(email);

  // Always return success to prevent email enumeration
  res.json({
    message: 'If an account exists with this email, a password reset link has been sent'
  });
});

// @desc    Reset password with token
// @route   POST /api/auth/reset-password
// @access  Public
const resetPassword = asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { token, password } = req.body;

  if (!token) {
    res.status(400);
    throw new Error('Reset token is required');
  }

  const result = await verificationService.resetPassword(token, password);

  if (!result.success) {
    res.status(400);
    throw new Error(result.error);
  }

  res.json({ message: 'Password reset successfully' });
});

// @desc    Send OTP for phone verification
// @route   POST /api/auth/send-otp
// @access  Private
const sendOTP = asyncHandler(async (req, res) => {
  const { phone } = req.body;

  if (!phone) {
    res.status(400);
    throw new Error('Phone number is required');
  }

  const result = await verificationService.createOTP(phone, req.user.id, 'phone_verification');

  if (!result.success) {
    res.status(429);
    throw new Error(result.error);
  }

  try {
    await smsService.sendOTP(phone, result.otp);
  } catch (smsError) {
    console.error('[Auth] SMS send failed:', smsError.message);
  }

  res.json({ message: 'OTP sent successfully' });
});

// @desc    Verify OTP
// @route   POST /api/auth/verify-otp
// @access  Private
const verifyOTP = asyncHandler(async (req, res) => {
  const { phone, otp } = req.body;

  if (!phone || !otp) {
    res.status(400);
    throw new Error('Phone number and OTP are required');
  }

  const result = await verificationService.verifyOTP(phone, otp, 'phone_verification');

  if (!result.success) {
    res.status(400);
    throw new Error(result.error);
  }

  res.json({ message: 'Phone number verified successfully' });
});

const googleSignIn = asyncHandler(async (req, res) => {
  const { idToken } = req.body;

  if (!idToken) {
    res.status(400);
    throw new Error('Google ID token is required');
  }

  if (!googleAuthService.isGoogleAuthConfigured()) {
    res.status(503);
    throw new Error('Google Sign-In is not available');
  }

  const googleProfile = await googleAuthService.verifyGoogleToken(idToken);
  const { user, token } = await googleAuthService.findOrCreateUser(googleProfile);

  emailService.sendWelcomeEmail(user).catch(err => {
    console.error('[Auth] Failed to send welcome email:', err.message);
  });

  res.json({
    message: 'Google sign-in successful',
    user,
    token,
  });
});

const unlinkGoogle = asyncHandler(async (req, res) => {
  const result = await googleAuthService.unlinkGoogleAccount(req.user.id);
  res.json(result);
});

const facebookSignIn = asyncHandler(async (req, res) => {
  const { accessToken } = req.body;

  if (!accessToken) {
    res.status(400);
    throw new Error('Facebook access token is required');
  }

  if (!facebookAuthService.isFacebookAuthConfigured()) {
    res.status(503);
    throw new Error('Facebook Sign-In is not available');
  }

  const facebookProfile = await facebookAuthService.verifyFacebookToken(accessToken);
  const { user, token } = await facebookAuthService.findOrCreateUser(facebookProfile);

  emailService.sendWelcomeEmail(user).catch(err => {
    console.error('[Auth] Failed to send welcome email:', err.message);
  });

  res.json({
    message: 'Facebook sign-in successful',
    user,
    token,
  });
});

const unlinkFacebook = asyncHandler(async (req, res) => {
  const result = await facebookAuthService.unlinkFacebookAccount(req.user.id);
  res.json(result);
});

const getAuthProviders = asyncHandler(async (req, res) => {
  res.json({
    google: googleAuthService.isGoogleAuthConfigured(),
    facebook: facebookAuthService.isFacebookAuthConfigured(),
    email: true,
  });
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
  verifyEmail,
  resendVerificationEmail,
  forgotPassword,
  resetPassword,
  sendOTP,
  verifyOTP,
  googleSignIn,
  unlinkGoogle,
  facebookSignIn,
  unlinkFacebook,
  getAuthProviders,
};
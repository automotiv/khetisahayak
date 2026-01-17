const express = require('express');
const { body } = require('express-validator');
const multer = require('multer');
const {
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
} = require('../controllers/authController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { authRateLimiter, sensitiveRateLimiter } = require('../middleware/securityMiddleware');
const db = require('../db');

/**
 * @swagger
 * tags:
 *   name: Authentication
 *   description: User authentication and profile management
 */

const router = express.Router();

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  },
});

// Validation rules for registration
const registerValidationRules = [
  body('username', 'Username is required').not().isEmpty().trim().escape(),
  body('email', 'Please include a valid email')
    .isEmail()
    .normalizeEmail()
    .custom(async (email) => {
      const { rows } = await db.query('SELECT * FROM users WHERE email = $1', [email]);
      if (rows.length > 0) {
        return Promise.reject('E-mail already in use');
      }
    }),
  body('password', 'Password must be at least 6 characters long').isLength({ min: 6 }),
  body('first_name').optional().trim().escape(), // Made optional, handled in controller from username
  body('last_name').optional().trim().escape(),  // Made optional, handled in controller from username
  body('phone', 'Phone number must be valid').optional().isMobilePhone(),
  body('location_lat', 'Latitude must be a valid number').optional().isFloat({ min: -90, max: 90 }),
  body('location_lng', 'Longitude must be a valid number').optional().isFloat({ min: -180, max: 180 }),
];

// Validation rules for login
const loginValidationRules = [
  body('email', 'Please include a valid email').isEmail().normalizeEmail(),
  body('password', 'Password is required').exists(),
];

// Validation rules for profile update
const profileUpdateValidationRules = [
  body('first_name', 'First name cannot be empty').optional().not().isEmpty().trim().escape(),
  body('last_name', 'Last name cannot be empty').optional().not().isEmpty().trim().escape(),
  body('phone', 'Phone number must be valid').optional().isMobilePhone(),
  body('location_lat', 'Latitude must be a valid number').optional().isFloat({ min: -90, max: 90 }),
  body('location_lng', 'Longitude must be a valid number').optional().isFloat({ min: -180, max: 180 }),
];

// Validation rules for password change
const passwordChangeValidationRules = [
  body('current_password', 'Current password is required').exists(),
  body('new_password', 'New password must be at least 6 characters long').isLength({ min: 6 }),
];

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - email
 *               - password
 *               - first_name
 *               - last_name
 *             properties:
 *               username:
 *                 type: string
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *                 minLength: 6
 *               first_name:
 *                 type: string
 *               last_name:
 *                 type: string
 *               phone:
 *                 type: string
 *               location_lat:
 *                 type: number
 *               location_lng:
 *                 type: number
 *     responses:
 *       201:
 *         description: User registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *       400:
 *         description: Validation error
 *       409:
 *         description: Email already exists
 */
router.post('/register', authRateLimiter, registerValidationRules, registerUser);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 token:
 *                   type: string
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *       401:
 *         description: Invalid credentials
 */
router.post('/login', authRateLimiter, loginValidationRules, loginUser);

/**
 * @swagger
 * /api/auth/profile:
 *   get:
 *     summary: Get user profile
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User profile retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *       401:
 *         description: Not authorized
 */
router.get('/profile', protect, getProfile);

/**
 * @swagger
 * /api/auth/profile:
 *   put:
 *     summary: Update user profile
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               first_name:
 *                 type: string
 *               last_name:
 *                 type: string
 *               phone:
 *                 type: string
 *               location_lat:
 *                 type: number
 *               location_lng:
 *                 type: number
 *     responses:
 *       200:
 *         description: Profile updated successfully
 *       401:
 *         description: Not authorized
 */
router.put('/profile', protect, profileUpdateValidationRules, updateProfile);

/**
 * @swagger
 * /api/auth/profile-image:
 *   post:
 *     summary: Upload profile image
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               image:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: Image uploaded successfully
 *       401:
 *         description: Not authorized
 */
router.post('/profile-image', protect, upload.single('image'), uploadProfileImage);

/**
 * @swagger
 * /api/auth/change-password:
 *   put:
 *     summary: Change user password
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - current_password
 *               - new_password
 *             properties:
 *               current_password:
 *                 type: string
 *               new_password:
 *                 type: string
 *                 minLength: 6
 *     responses:
 *       200:
 *         description: Password changed successfully
 *       401:
 *         description: Not authorized or invalid current password
 */
router.put('/change-password', protect, passwordChangeValidationRules, changePassword);

/**
 * @swagger
 * /api/auth/logout:
 *   post:
 *     summary: Logout user
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Logout successful
 *       401:
 *         description: Not authorized
 */
router.post('/logout', protect, logoutUser);

/**
 * @swagger
 * /api/auth/verify-email:
 *   get:
 *     summary: Verify email address
 *     tags: [Authentication]
 *     parameters:
 *       - in: query
 *         name: token
 *         required: true
 *         schema:
 *           type: string
 *         description: Email verification token
 *     responses:
 *       200:
 *         description: Email verified successfully
 *       400:
 *         description: Invalid or expired token
 */
router.get('/verify-email', verifyEmail);

/**
 * @swagger
 * /api/auth/resend-verification:
 *   post:
 *     summary: Resend verification email
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Verification email sent
 *       400:
 *         description: Email already verified
 *       401:
 *         description: Not authorized
 */
router.post('/resend-verification', protect, resendVerificationEmail);

/**
 * @swagger
 * /api/auth/forgot-password:
 *   post:
 *     summary: Request password reset
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *     responses:
 *       200:
 *         description: Password reset email sent (if account exists)
 */
router.post('/forgot-password', sensitiveRateLimiter, [
  body('email', 'Please include a valid email').isEmail().normalizeEmail(),
], forgotPassword);

/**
 * @swagger
 * /api/auth/reset-password:
 *   post:
 *     summary: Reset password with token
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - token
 *               - password
 *             properties:
 *               token:
 *                 type: string
 *               password:
 *                 type: string
 *                 minLength: 6
 *     responses:
 *       200:
 *         description: Password reset successfully
 *       400:
 *         description: Invalid or expired token
 */
router.post('/reset-password', sensitiveRateLimiter, [
  body('token', 'Reset token is required').not().isEmpty(),
  body('password', 'Password must be at least 6 characters long').isLength({ min: 6 }),
], resetPassword);

/**
 * @swagger
 * /api/auth/send-otp:
 *   post:
 *     summary: Send OTP for phone verification
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phone
 *             properties:
 *               phone:
 *                 type: string
 *     responses:
 *       200:
 *         description: OTP sent successfully
 *       429:
 *         description: Too many OTP requests
 */
router.post('/send-otp', protect, sensitiveRateLimiter, [
  body('phone', 'Phone number is required').not().isEmpty().isMobilePhone(),
], sendOTP);

/**
 * @swagger
 * /api/auth/verify-otp:
 *   post:
 *     summary: Verify OTP
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phone
 *               - otp
 *             properties:
 *               phone:
 *                 type: string
 *               otp:
 *                 type: string
 *     responses:
 *       200:
 *         description: Phone verified successfully
 *       400:
 *         description: Invalid OTP
 */
router.post('/verify-otp', protect, [
  body('phone', 'Phone number is required').not().isEmpty(),
  body('otp', 'OTP is required').not().isEmpty().isLength({ min: 6, max: 6 }),
], verifyOTP);

router.get('/users', protect, authorize('admin'), getAllUsers);
router.delete('/users/:id', protect, authorize('admin'), deleteUser);

/**
 * @swagger
 * /api/auth/google:
 *   post:
 *     summary: Sign in with Google
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - idToken
 *             properties:
 *               idToken:
 *                 type: string
 *                 description: Google ID token from client
 *     responses:
 *       200:
 *         description: Google sign-in successful
 *       400:
 *         description: Invalid token
 *       503:
 *         description: Google Sign-In not configured
 */
router.post('/google', authRateLimiter, [
  body('idToken', 'Google ID token is required').not().isEmpty(),
], googleSignIn);

/**
 * @swagger
 * /api/auth/google/unlink:
 *   post:
 *     summary: Unlink Google account
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Google account unlinked
 *       400:
 *         description: Cannot unlink (no other auth method)
 */
router.post('/google/unlink', protect, unlinkGoogle);

/**
 * @swagger
 * /api/auth/facebook:
 *   post:
 *     summary: Sign in with Facebook
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - accessToken
 *             properties:
 *               accessToken:
 *                 type: string
 *                 description: Facebook access token from client
 *     responses:
 *       200:
 *         description: Facebook sign-in successful
 *       400:
 *         description: Invalid token
 *       503:
 *         description: Facebook Sign-In not configured
 */
router.post('/facebook', authRateLimiter, [
  body('accessToken', 'Facebook access token is required').not().isEmpty(),
], facebookSignIn);

/**
 * @swagger
 * /api/auth/facebook/unlink:
 *   post:
 *     summary: Unlink Facebook account
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Facebook account unlinked
 *       400:
 *         description: Cannot unlink (no other auth method)
 */
router.post('/facebook/unlink', protect, unlinkFacebook);

/**
 * @swagger
 * /api/auth/providers:
 *   get:
 *     summary: Get available authentication providers
 *     tags: [Authentication]
 *     responses:
 *       200:
 *         description: List of available auth providers
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 google:
 *                   type: boolean
 *                 facebook:
 *                   type: boolean
 *                 email:
 *                   type: boolean
 */
router.get('/providers', getAuthProviders);

module.exports = router;
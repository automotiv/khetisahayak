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
} = require('../controllers/authController');
const { protect, authorize } = require('../middleware/authMiddleware');
const db = require('../db');

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
  body('first_name', 'First name is required').not().isEmpty().trim().escape(),
  body('last_name', 'Last name is required').not().isEmpty().trim().escape(),
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

// Public routes
router.post('/register', registerValidationRules, registerUser);
router.post('/login', loginValidationRules, loginUser);

// Protected routes
router.get('/profile', protect, getProfile);
router.put('/profile', protect, profileUpdateValidationRules, updateProfile);
router.post('/profile-image', protect, upload.single('image'), uploadProfileImage);
router.put('/change-password', protect, passwordChangeValidationRules, changePassword);
router.post('/logout', protect, logoutUser);

// Admin routes
router.get('/users', protect, authorize('admin'), getAllUsers);
router.delete('/users/:id', protect, authorize('admin'), deleteUser);

module.exports = router;
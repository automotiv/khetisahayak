const express = require('express');
const { body } = require('express-validator');
const {
  registerUser,
  loginUser,
} = require('../controllers/authController');
const db = require('../db');

const router = express.Router();

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
];

// Validation rules for login
const loginValidationRules = [
  body('email', 'Please include a valid email').isEmail().normalizeEmail(),
  body('password', 'Password is required').exists(),
];

// Register User
router.post('/register', registerValidationRules, registerUser);

// Login User
router.post('/login', loginValidationRules, loginUser);

module.exports = router;
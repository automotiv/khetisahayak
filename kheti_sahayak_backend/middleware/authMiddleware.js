const jwt = require('jsonwebtoken');
const db = require('../db');

const protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Get token from header
      token = req.headers.authorization.split(' ')[1];

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Get user from the token's payload, excluding the password
      const result = await db.query('SELECT id, username, email, role FROM users WHERE id = $1', [decoded.id]);
      
      if (result.rows.length === 0) {
        return res.status(401).json({ error: 'Not authorized, user not found' });
      }

      req.user = result.rows[0];
      next();
    } catch (error) {
      console.error(error);
      res.status(401).json({ error: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    res.status(401).json({ error: 'Not authorized, no token' });
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      // We'll use our centralized error handler for a consistent response.
      const error = new Error('Forbidden: You do not have permission to perform this action');
      res.status(403);
      return next(error);
    }
    // If the user has the required role, continue to the next middleware/controller.
    next();
  };
};

module.exports = {
  protect,
  authorize,
};
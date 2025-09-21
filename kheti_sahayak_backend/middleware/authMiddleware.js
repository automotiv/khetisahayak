const jwt = require('jsonwebtoken');
const db = require('../db');

const protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Get token from header
      token = req.headers.authorization.split(' ')[1];

      // Verify token exists
      if (!token) {
        return res.status(401).json({ 
          error: 'Not authorized, no token provided',
          code: 'NO_TOKEN'
        });
      }

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Get user from the token's payload, excluding the password
      const result = await db.query('SELECT id, username, email, role FROM users WHERE id = $1', [decoded.id]);
      
      if (result.rows.length === 0) {
        return res.status(401).json({ 
          error: 'Not authorized, user not found',
          code: 'USER_NOT_FOUND'
        });
      }

      req.user = result.rows[0];
      next();
    } catch (error) {
      console.error('Auth middleware error:', error);
      
      if (error.name === 'JsonWebTokenError') {
        return res.status(401).json({ 
          error: 'Not authorized, invalid token',
          code: 'INVALID_TOKEN'
        });
      } else if (error.name === 'TokenExpiredError') {
        return res.status(401).json({ 
          error: 'Not authorized, token expired',
          code: 'TOKEN_EXPIRED'
        });
      }
      
      return res.status(401).json({ 
        error: 'Not authorized, token failed',
        code: 'TOKEN_FAILED'
      });
    }
  } else {
    return res.status(401).json({ 
      error: 'Not authorized, no token provided',
      code: 'NO_TOKEN'
    });
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
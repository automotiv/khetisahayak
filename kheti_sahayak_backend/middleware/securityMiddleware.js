const logger = require('../utils/logger');

const securityHeaders = (req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'geolocation=(self), camera=(self), microphone=()');
  
  res.setHeader(
    'Content-Security-Policy',
    [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https:",
      "font-src 'self' https:",
      "connect-src 'self' https:",
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'"
    ].join('; ')
  );
  
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  
  res.removeHeader('X-Powered-By');
  
  next();
};

const createCorsConfig = (options = {}) => {
  const defaultOrigins = [
    'http://localhost:3000',
    'http://localhost:5173',
    'http://localhost:8080'
  ];
  
  const productionOrigins = process.env.ALLOWED_ORIGINS 
    ? process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
    : [];
  
  const allowedOrigins = [...defaultOrigins, ...productionOrigins];
  
  return {
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes(origin) || process.env.NODE_ENV === 'development') {
        callback(null, true);
      } else {
        logger.warn('CORS blocked request from origin', { origin });
        callback(new Error('Not allowed by CORS'));
      }
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'Accept',
      'Origin',
      'X-Request-ID'
    ],
    exposedHeaders: ['X-Request-ID', 'X-RateLimit-Remaining'],
    credentials: true,
    maxAge: 86400,
    optionsSuccessStatus: 204,
    ...options
  };
};

const RATE_LIMIT_WINDOWS = {
  general: { windowMs: 60 * 1000, max: 100 },
  auth: { windowMs: 60 * 1000, max: 5 },
  upload: { windowMs: 60 * 1000, max: 10 },
  sensitive: { windowMs: 60 * 1000, max: 3 },
  search: { windowMs: 60 * 1000, max: 30 }
};

const rateLimitStore = new Map();

const cleanupRateLimitStore = () => {
  const now = Date.now();
  for (const [key, data] of rateLimitStore.entries()) {
    if (now - data.windowStart > data.windowMs) {
      rateLimitStore.delete(key);
    }
  }
};

setInterval(cleanupRateLimitStore, 60 * 1000);

const createRateLimiter = (type = 'general') => {
  const config = RATE_LIMIT_WINDOWS[type] || RATE_LIMIT_WINDOWS.general;
  
  return (req, res, next) => {
    const identifier = req.user?.id || req.ip || 'anonymous';
    const key = `${type}:${identifier}`;
    const now = Date.now();
    
    let limitData = rateLimitStore.get(key);
    
    if (!limitData || now - limitData.windowStart > config.windowMs) {
      limitData = {
        count: 1,
        windowStart: now,
        windowMs: config.windowMs
      };
      rateLimitStore.set(key, limitData);
    } else {
      limitData.count++;
    }
    
    const remaining = Math.max(0, config.max - limitData.count);
    const resetTime = Math.ceil((limitData.windowStart + config.windowMs - now) / 1000);
    
    res.setHeader('X-RateLimit-Limit', config.max);
    res.setHeader('X-RateLimit-Remaining', remaining);
    res.setHeader('X-RateLimit-Reset', resetTime);
    
    if (limitData.count > config.max) {
      logger.warn('Rate limit exceeded', {
        type,
        identifier,
        count: limitData.count,
        limit: config.max
      });
      
      return res.status(429).json({
        success: false,
        error: 'Too many requests',
        message: `Rate limit exceeded. Please try again in ${resetTime} seconds.`,
        retryAfter: resetTime
      });
    }
    
    next();
  };
};

const generalRateLimiter = createRateLimiter('general');
const authRateLimiter = createRateLimiter('auth');
const uploadRateLimiter = createRateLimiter('upload');
const sensitiveRateLimiter = createRateLimiter('sensitive');
const searchRateLimiter = createRateLimiter('search');

const requestIdMiddleware = (req, res, next) => {
  const requestId = req.headers['x-request-id'] || 
    `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  
  req.requestId = requestId;
  res.setHeader('X-Request-ID', requestId);
  
  next();
};

const requestSizeLimit = (maxSize = '10mb') => {
  const sizes = { kb: 1024, mb: 1024 * 1024, gb: 1024 * 1024 * 1024 };
  const match = String(maxSize).toLowerCase().match(/^(\d+)(kb|mb|gb)?$/);
  
  const limit = match 
    ? parseInt(match[1]) * (sizes[match[2]] || 1)
    : 10 * 1024 * 1024;
  
  return (req, res, next) => {
    let size = 0;
    
    req.on('data', chunk => {
      size += chunk.length;
      if (size > limit) {
        logger.warn('Request size limit exceeded', { size, limit, path: req.path });
        req.destroy();
        return res.status(413).json({
          success: false,
          error: 'Payload too large',
          message: `Request body exceeds the ${maxSize} limit`
        });
      }
    });
    
    next();
  };
};

const sanitizeHeaders = (req, res, next) => {
  const suspiciousHeaders = ['x-forwarded-host', 'x-original-url', 'x-rewrite-url'];
  
  for (const header of suspiciousHeaders) {
    if (req.headers[header]) {
      logger.warn('Suspicious header detected', { header, value: req.headers[header] });
    }
  }
  
  next();
};

const preventParameterPollution = (whitelist = []) => {
  return (req, res, next) => {
    const pollutionKeys = ['query', 'body', 'params'];
    
    for (const key of pollutionKeys) {
      if (req[key] && typeof req[key] === 'object') {
        for (const [param, value] of Object.entries(req[key])) {
          if (Array.isArray(value) && !whitelist.includes(param)) {
            req[key][param] = value[value.length - 1];
          }
        }
      }
    }
    
    next();
  };
};

const securityLogging = (req, res, next) => {
  const startTime = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const logData = {
      requestId: req.requestId,
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip,
      userAgent: req.headers['user-agent']?.substring(0, 100),
      userId: req.user?.id
    };
    
    if (res.statusCode >= 400) {
      logger.warn('Request completed with error', logData);
    } else if (duration > 5000) {
      logger.warn('Slow request detected', logData);
    }
  });
  
  next();
};

const applySecurityMiddleware = (app, options = {}) => {
  const cors = require('cors');
  
  app.use(requestIdMiddleware);
  app.use(sanitizeHeaders);
  app.use(securityHeaders);
  app.use(cors(createCorsConfig(options.cors)));
  app.use(preventParameterPollution(options.paramWhitelist || []));
  
  if (options.enableLogging !== false) {
    app.use(securityLogging);
  }
  
  logger.info('Security middleware applied');
};

module.exports = {
  securityHeaders,
  createCorsConfig,
  createRateLimiter,
  generalRateLimiter,
  authRateLimiter,
  uploadRateLimiter,
  sensitiveRateLimiter,
  searchRateLimiter,
  requestIdMiddleware,
  requestSizeLimit,
  sanitizeHeaders,
  preventParameterPollution,
  securityLogging,
  applySecurityMiddleware,
  RATE_LIMIT_WINDOWS
};

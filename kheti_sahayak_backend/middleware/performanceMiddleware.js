const logger = require('../utils/logger');

const SLOW_REQUEST_THRESHOLD_MS = 1000;

const responseTimeMiddleware = (req, res, next) => {
  const startTime = process.hrtime.bigint();
  const startMemory = process.memoryUsage().heapUsed;

  res.on('finish', () => {
    const endTime = process.hrtime.bigint();
    const durationMs = Number(endTime - startTime) / 1_000_000;
    const endMemory = process.memoryUsage().heapUsed;
    const memoryDelta = (endMemory - startMemory) / 1024 / 1024;

    // res.setHeader('X-Response-Time', `${durationMs.toFixed(2)}ms`); // Cannot set headers after response is finished

    const logData = {
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      duration: `${durationMs.toFixed(2)}ms`,
      memoryDelta: `${memoryDelta.toFixed(2)}MB`,
      requestId: req.requestId,
    };

    if (durationMs > SLOW_REQUEST_THRESHOLD_MS) {
      logger.warn(`[SLOW REQUEST] ${req.method} ${req.originalUrl} took ${durationMs.toFixed(2)}ms`, logData);
    }
  });

  next();
};

const cacheControlMiddleware = (options = {}) => {
  const defaultMaxAge = options.maxAge || 0;
  const cacheableRoutes = options.cacheableRoutes || [];

  return (req, res, next) => {
    if (req.method !== 'GET') {
      res.setHeader('Cache-Control', 'no-store');
      return next();
    }

    const matchedRoute = cacheableRoutes.find(route => req.originalUrl.includes(route.path));

    if (matchedRoute) {
      res.setHeader('Cache-Control', `public, max-age=${matchedRoute.maxAge || defaultMaxAge}`);
    } else {
      res.setHeader('Cache-Control', 'no-cache');
    }

    next();
  };
};

const compressionHints = (req, res, next) => {
  const acceptEncoding = req.headers['accept-encoding'] || '';

  if (acceptEncoding.includes('br')) {
    res.setHeader('X-Compression-Hint', 'brotli');
  } else if (acceptEncoding.includes('gzip')) {
    res.setHeader('X-Compression-Hint', 'gzip');
  }

  next();
};

const etagMiddleware = (req, res, next) => {
  const originalJson = res.json.bind(res);

  res.json = (data) => {
    if (req.method === 'GET' && data) {
      const crypto = require('crypto');
      const hash = crypto.createHash('md5').update(JSON.stringify(data)).digest('hex');
      const etag = `"${hash}"`;

      res.setHeader('ETag', etag);

      const ifNoneMatch = req.headers['if-none-match'];
      if (ifNoneMatch === etag) {
        return res.status(304).end();
      }
    }

    return originalJson(data);
  };

  next();
};

const defaultCacheableRoutes = [
  { path: '/api/educational-content', maxAge: 3600 },
  { path: '/api/schemes', maxAge: 3600 },
  { path: '/api/crop-recommendations', maxAge: 7200 },
  { path: '/api/app-config', maxAge: 300 },
  { path: '/api/health', maxAge: 60 },
];

module.exports = {
  responseTimeMiddleware,
  cacheControlMiddleware,
  compressionHints,
  etagMiddleware,
  defaultCacheableRoutes,
  SLOW_REQUEST_THRESHOLD_MS,
};

const mockWarn = jest.fn();
const mockInfo = jest.fn();

jest.mock('../../utils/logger', () => ({
  warn: mockWarn,
  info: mockInfo
}));

const securityMiddleware = require('../../middleware/securityMiddleware');

describe('Security Middleware', () => {
  let mockReq;
  let mockRes;
  let mockNext;

  beforeEach(() => {
    jest.clearAllMocks();
    mockReq = {
      ip: '127.0.0.1',
      path: '/api/test',
      method: 'GET',
      headers: {},
      on: jest.fn()
    };
    mockRes = {
      setHeader: jest.fn(),
      removeHeader: jest.fn(),
      on: jest.fn(),
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
      statusCode: 200
    };
    mockNext = jest.fn();
  });

  describe('securityHeaders', () => {
    it('should set X-Content-Type-Options header', () => {
      securityMiddleware.securityHeaders(mockReq, mockRes, mockNext);

      expect(mockRes.setHeader).toHaveBeenCalledWith('X-Content-Type-Options', 'nosniff');
    });

    it('should set X-Frame-Options header', () => {
      securityMiddleware.securityHeaders(mockReq, mockRes, mockNext);

      expect(mockRes.setHeader).toHaveBeenCalledWith('X-Frame-Options', 'DENY');
    });

    it('should set X-XSS-Protection header', () => {
      securityMiddleware.securityHeaders(mockReq, mockRes, mockNext);

      expect(mockRes.setHeader).toHaveBeenCalledWith('X-XSS-Protection', '1; mode=block');
    });

    it('should set Referrer-Policy header', () => {
      securityMiddleware.securityHeaders(mockReq, mockRes, mockNext);

      expect(mockRes.setHeader).toHaveBeenCalledWith('Referrer-Policy', 'strict-origin-when-cross-origin');
    });

    it('should set Content-Security-Policy header', () => {
      securityMiddleware.securityHeaders(mockReq, mockRes, mockNext);

      expect(mockRes.setHeader).toHaveBeenCalledWith(
        'Content-Security-Policy',
        expect.stringContaining("default-src 'self'")
      );
    });

    it('should set Strict-Transport-Security header', () => {
      securityMiddleware.securityHeaders(mockReq, mockRes, mockNext);

      expect(mockRes.setHeader).toHaveBeenCalledWith(
        'Strict-Transport-Security',
        'max-age=31536000; includeSubDomains'
      );
    });

    it('should set cache control headers', () => {
      securityMiddleware.securityHeaders(mockReq, mockRes, mockNext);

      expect(mockRes.setHeader).toHaveBeenCalledWith(
        'Cache-Control',
        'no-store, no-cache, must-revalidate, proxy-revalidate'
      );
      expect(mockRes.setHeader).toHaveBeenCalledWith('Pragma', 'no-cache');
      expect(mockRes.setHeader).toHaveBeenCalledWith('Expires', '0');
    });

    it('should remove X-Powered-By header', () => {
      securityMiddleware.securityHeaders(mockReq, mockRes, mockNext);

      expect(mockRes.removeHeader).toHaveBeenCalledWith('X-Powered-By');
    });

    it('should call next()', () => {
      securityMiddleware.securityHeaders(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('createCorsConfig', () => {
    it('should include default origins', () => {
      const config = securityMiddleware.createCorsConfig();

      expect(config.origin).toBeDefined();
      expect(config.methods).toContain('GET');
      expect(config.credentials).toBe(true);
    });

    it('should allow localhost origins in development', (done) => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'development';

      const config = securityMiddleware.createCorsConfig();
      config.origin('http://localhost:5000', (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe(true);
        process.env.NODE_ENV = originalEnv;
        done();
      });
    });

    it('should allow requests with no origin', (done) => {
      const config = securityMiddleware.createCorsConfig();
      config.origin(undefined, (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe(true);
        done();
      });
    });

    it('should block unknown origins in production', (done) => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';

      const config = securityMiddleware.createCorsConfig();
      config.origin('http://malicious-site.com', (err) => {
        expect(err).toBeDefined();
        expect(err.message).toBe('Not allowed by CORS');
        process.env.NODE_ENV = originalEnv;
        done();
      });
    });

    it('should include standard allowed headers', () => {
      const config = securityMiddleware.createCorsConfig();

      expect(config.allowedHeaders).toContain('Content-Type');
      expect(config.allowedHeaders).toContain('Authorization');
    });

    it('should expose custom headers', () => {
      const config = securityMiddleware.createCorsConfig();

      expect(config.exposedHeaders).toContain('X-Request-ID');
      expect(config.exposedHeaders).toContain('X-RateLimit-Remaining');
    });

    it('should merge custom options', () => {
      const config = securityMiddleware.createCorsConfig({ maxAge: 3600 });

      expect(config.maxAge).toBe(3600);
    });
  });

  describe('createRateLimiter', () => {
    it('should allow requests under limit', () => {
      const limiter = securityMiddleware.createRateLimiter('general');
      mockReq.ip = '192.168.1.100';

      limiter(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
      expect(mockRes.setHeader).toHaveBeenCalledWith('X-RateLimit-Limit', 100);
    });

    it('should set rate limit headers', () => {
      const limiter = securityMiddleware.createRateLimiter('general');
      mockReq.ip = '192.168.1.101';

      limiter(mockReq, mockRes, mockNext);

      expect(mockRes.setHeader).toHaveBeenCalledWith('X-RateLimit-Limit', expect.any(Number));
      expect(mockRes.setHeader).toHaveBeenCalledWith('X-RateLimit-Remaining', expect.any(Number));
      expect(mockRes.setHeader).toHaveBeenCalledWith('X-RateLimit-Reset', expect.any(Number));
    });

    it('should use user ID for identifier when available', () => {
      const limiter = securityMiddleware.createRateLimiter('auth');
      mockReq.user = { id: 'user-123' };

      limiter(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });

    it('should use different limits for auth type', () => {
      expect(securityMiddleware.RATE_LIMIT_WINDOWS.auth.max).toBe(5);
      expect(securityMiddleware.RATE_LIMIT_WINDOWS.general.max).toBe(100);
    });

    it('should use different limits for upload type', () => {
      expect(securityMiddleware.RATE_LIMIT_WINDOWS.upload.max).toBe(10);
    });

    it('should use different limits for sensitive type', () => {
      expect(securityMiddleware.RATE_LIMIT_WINDOWS.sensitive.max).toBe(3);
    });

    it('should use different limits for search type', () => {
      expect(securityMiddleware.RATE_LIMIT_WINDOWS.search.max).toBe(30);
    });

    it('should fall back to general for unknown type', () => {
      const limiter = securityMiddleware.createRateLimiter('unknown');
      mockReq.ip = '192.168.1.200';

      limiter(mockReq, mockRes, mockNext);

      expect(mockRes.setHeader).toHaveBeenCalledWith('X-RateLimit-Limit', 100);
    });
  });

  describe('Pre-built Rate Limiters', () => {
    it('should export generalRateLimiter', () => {
      expect(securityMiddleware.generalRateLimiter).toBeDefined();
      expect(typeof securityMiddleware.generalRateLimiter).toBe('function');
    });

    it('should export authRateLimiter', () => {
      expect(securityMiddleware.authRateLimiter).toBeDefined();
    });

    it('should export uploadRateLimiter', () => {
      expect(securityMiddleware.uploadRateLimiter).toBeDefined();
    });

    it('should export sensitiveRateLimiter', () => {
      expect(securityMiddleware.sensitiveRateLimiter).toBeDefined();
    });

    it('should export searchRateLimiter', () => {
      expect(securityMiddleware.searchRateLimiter).toBeDefined();
    });
  });

  describe('requestIdMiddleware', () => {
    it('should generate request ID when not provided', () => {
      securityMiddleware.requestIdMiddleware(mockReq, mockRes, mockNext);

      expect(mockReq.requestId).toBeDefined();
      expect(mockRes.setHeader).toHaveBeenCalledWith('X-Request-ID', mockReq.requestId);
    });

    it('should use provided request ID', () => {
      mockReq.headers['x-request-id'] = 'custom-request-id';

      securityMiddleware.requestIdMiddleware(mockReq, mockRes, mockNext);

      expect(mockReq.requestId).toBe('custom-request-id');
    });

    it('should call next()', () => {
      securityMiddleware.requestIdMiddleware(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('requestSizeLimit', () => {
    it('should parse size with mb suffix', () => {
      const limiter = securityMiddleware.requestSizeLimit('5mb');

      expect(typeof limiter).toBe('function');
    });

    it('should parse size with kb suffix', () => {
      const limiter = securityMiddleware.requestSizeLimit('500kb');

      expect(typeof limiter).toBe('function');
    });

    it('should use default 10mb when invalid size', () => {
      const limiter = securityMiddleware.requestSizeLimit('invalid');

      expect(typeof limiter).toBe('function');
    });

    it('should call next() for normal requests', () => {
      const limiter = securityMiddleware.requestSizeLimit('10mb');
      limiter(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('sanitizeHeaders', () => {
    it('should log suspicious x-forwarded-host header', () => {
      mockReq.headers['x-forwarded-host'] = 'malicious.com';

      securityMiddleware.sanitizeHeaders(mockReq, mockRes, mockNext);

      expect(mockWarn).toHaveBeenCalledWith('Suspicious header detected', expect.any(Object));
    });

    it('should log suspicious x-original-url header', () => {
      mockReq.headers['x-original-url'] = '/admin';

      securityMiddleware.sanitizeHeaders(mockReq, mockRes, mockNext);

      expect(mockWarn).toHaveBeenCalled();
    });

    it('should log suspicious x-rewrite-url header', () => {
      mockReq.headers['x-rewrite-url'] = '/api/sensitive';

      securityMiddleware.sanitizeHeaders(mockReq, mockRes, mockNext);

      expect(mockWarn).toHaveBeenCalled();
    });

    it('should call next() regardless', () => {
      mockReq.headers['x-forwarded-host'] = 'bad.com';

      securityMiddleware.sanitizeHeaders(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });

    it('should not log for normal headers', () => {
      mockReq.headers['content-type'] = 'application/json';

      securityMiddleware.sanitizeHeaders(mockReq, mockRes, mockNext);

      expect(mockWarn).not.toHaveBeenCalled();
    });
  });

  describe('preventParameterPollution', () => {
    it('should flatten array query params', () => {
      mockReq.query = { sort: ['name', 'date'] };

      const middleware = securityMiddleware.preventParameterPollution();
      middleware(mockReq, mockRes, mockNext);

      expect(mockReq.query.sort).toBe('date');
    });

    it('should allow whitelisted array params', () => {
      mockReq.query = { tags: ['tag1', 'tag2'] };

      const middleware = securityMiddleware.preventParameterPollution(['tags']);
      middleware(mockReq, mockRes, mockNext);

      expect(mockReq.query.tags).toEqual(['tag1', 'tag2']);
    });

    it('should handle body params', () => {
      mockReq.body = { ids: ['id1', 'id2'] };

      const middleware = securityMiddleware.preventParameterPollution();
      middleware(mockReq, mockRes, mockNext);

      expect(mockReq.body.ids).toBe('id2');
    });

    it('should handle params', () => {
      mockReq.params = { id: ['123', '456'] };

      const middleware = securityMiddleware.preventParameterPollution();
      middleware(mockReq, mockRes, mockNext);

      expect(mockReq.params.id).toBe('456');
    });

    it('should call next()', () => {
      const middleware = securityMiddleware.preventParameterPollution();
      middleware(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('securityLogging', () => {
    it('should log on response finish', () => {
      let finishCallback;
      mockRes.on = jest.fn((event, cb) => {
        if (event === 'finish') finishCallback = cb;
      });

      securityMiddleware.securityLogging(mockReq, mockRes, mockNext);
      mockRes.statusCode = 200;
      finishCallback();

      expect(mockNext).toHaveBeenCalled();
    });

    it('should warn on error status codes', () => {
      let finishCallback;
      mockRes.on = jest.fn((event, cb) => {
        if (event === 'finish') finishCallback = cb;
      });

      securityMiddleware.securityLogging(mockReq, mockRes, mockNext);
      mockRes.statusCode = 400;
      finishCallback();

      expect(mockWarn).toHaveBeenCalledWith('Request completed with error', expect.any(Object));
    });

    it('should call next()', () => {
      securityMiddleware.securityLogging(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('applySecurityMiddleware', () => {
    it('should apply all security middleware to app', () => {
      jest.mock('cors', () => jest.fn(() => jest.fn()));
      const mockApp = {
        use: jest.fn()
      };

      securityMiddleware.applySecurityMiddleware(mockApp);

      expect(mockApp.use).toHaveBeenCalled();
      expect(mockInfo).toHaveBeenCalledWith('Security middleware applied');
    });

    it('should apply with custom options', () => {
      jest.mock('cors', () => jest.fn(() => jest.fn()));
      const mockApp = {
        use: jest.fn()
      };

      securityMiddleware.applySecurityMiddleware(mockApp, { enableLogging: false });

      expect(mockApp.use).toHaveBeenCalled();
    });
  });
});

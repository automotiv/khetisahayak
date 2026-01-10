const logger = require('./logger');

const HTML_ESCAPE_MAP = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#x27;',
  '/': '&#x2F;',
  '`': '&#x60;',
  '=': '&#x3D;'
};

const SQL_DANGEROUS_PATTERNS = [
  /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE|EXEC|EXECUTE|UNION|INTO)\b)/gi,
  /(--|;|\/\*|\*\/)/g,
  /(\bOR\b|\bAND\b)\s*\d+\s*=\s*\d+/gi,
  /'\s*OR\s*'1'\s*=\s*'1/gi,
  /(\bOR\b|\bAND\b)\s*'[^']*'\s*=\s*'[^']*'/gi
];

const PATH_TRAVERSAL_PATTERNS = [
  /\.\.\//g,
  /\.\.\\/, 
  /%2e%2e%2f/gi,
  /%2e%2e\//gi,
  /\.\.%2f/gi,
  /%252e%252e%252f/gi
];

function escapeHtml(str) {
  if (typeof str !== 'string') return str;
  return str.replace(/[&<>"'`=/]/g, char => HTML_ESCAPE_MAP[char]);
}

function sanitizeInput(input) {
  if (input === null || input === undefined) return input;
  
  if (typeof input === 'string') {
    let sanitized = input.trim();
    sanitized = sanitized.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
    sanitized = escapeHtml(sanitized);
    return sanitized;
  }
  
  if (Array.isArray(input)) {
    return input.map(item => sanitizeInput(item));
  }
  
  if (typeof input === 'object') {
    const sanitized = {};
    for (const [key, value] of Object.entries(input)) {
      const sanitizedKey = sanitizeInput(key);
      sanitized[sanitizedKey] = sanitizeInput(value);
    }
    return sanitized;
  }
  
  return input;
}

function detectSqlInjection(input) {
  if (typeof input !== 'string') return false;
  return SQL_DANGEROUS_PATTERNS.some(pattern => pattern.test(input));
}

function sanitizeForSQL(input) {
  if (typeof input !== 'string') return input;
  
  if (detectSqlInjection(input)) {
    logger.warn('Potential SQL injection attempt detected', { input: input.substring(0, 100) });
  }
  
  let sanitized = input.replace(/'/g, "''");
  sanitized = sanitized.replace(/\\/g, '\\\\');
  sanitized = sanitized.replace(/\x00/g, '');
  
  return sanitized;
}

function sanitizePath(filePath) {
  if (typeof filePath !== 'string') return '';
  
  let sanitized = filePath;
  
  for (const pattern of PATH_TRAVERSAL_PATTERNS) {
    if (pattern.test(sanitized)) {
      logger.warn('Path traversal attempt detected', { path: filePath });
    }
    sanitized = sanitized.replace(pattern, '');
  }
  
  sanitized = sanitized.replace(/^[\/\\]+/, '');
  sanitized = sanitized.replace(/[<>:"|?*\x00-\x1F]/g, '');
  sanitized = sanitized.replace(/\.+/g, '.');
  
  const MAX_PATH_LENGTH = 255;
  if (sanitized.length > MAX_PATH_LENGTH) {
    sanitized = sanitized.substring(0, MAX_PATH_LENGTH);
  }
  
  return sanitized;
}

function sanitizeFilename(filename) {
  if (typeof filename !== 'string') return '';
  
  let sanitized = filename.replace(/[<>:"/\\|?*\x00-\x1F]/g, '');
  sanitized = sanitized.replace(/^\.+/, '');
  sanitized = sanitized.trim();
  
  const MAX_FILENAME_LENGTH = 200;
  if (sanitized.length > MAX_FILENAME_LENGTH) {
    const ext = sanitized.lastIndexOf('.');
    if (ext > 0) {
      const extension = sanitized.substring(ext);
      const name = sanitized.substring(0, MAX_FILENAME_LENGTH - extension.length);
      sanitized = name + extension;
    } else {
      sanitized = sanitized.substring(0, MAX_FILENAME_LENGTH);
    }
  }
  
  return sanitized;
}

function sanitizeUrl(url) {
  if (typeof url !== 'string') return '';
  
  let sanitized = url.trim();
  
  if (sanitized.toLowerCase().startsWith('javascript:') ||
      sanitized.toLowerCase().startsWith('data:') ||
      sanitized.toLowerCase().startsWith('vbscript:')) {
    logger.warn('Dangerous URL protocol detected', { url: sanitized.substring(0, 50) });
    return '';
  }
  
  sanitized = sanitized.replace(/[<>"'`]/g, char => HTML_ESCAPE_MAP[char]);
  
  return sanitized;
}

function sanitizeJson(jsonString) {
  if (typeof jsonString !== 'string') return jsonString;
  
  try {
    const parsed = JSON.parse(jsonString);
    return sanitizeInput(parsed);
  } catch {
    logger.warn('Invalid JSON provided for sanitization');
    return null;
  }
}

function sanitizeSearchQuery(query) {
  if (typeof query !== 'string') return '';
  
  let sanitized = query.trim();
  sanitized = sanitized.replace(/[%_\[\]^]/g, '\\$&');
  sanitized = sanitized.substring(0, 200);
  
  return sanitized;
}

function stripHtmlTags(input) {
  if (typeof input !== 'string') return input;
  return input.replace(/<[^>]*>/g, '');
}

function sanitizeForLog(input, maxLength = 500) {
  if (input === null || input === undefined) return String(input);
  
  let sanitized;
  if (typeof input === 'object') {
    sanitized = JSON.stringify(input);
  } else {
    sanitized = String(input);
  }
  
  sanitized = sanitized.replace(/[\r\n]/g, ' ');
  sanitized = sanitized.replace(/[\x00-\x1F\x7F]/g, '');
  
  if (sanitized.length > maxLength) {
    sanitized = sanitized.substring(0, maxLength) + '...[truncated]';
  }
  
  return sanitized;
}

const SENSITIVE_FIELD_PATTERNS = [
  /password/i, /passwd/i, /pwd/i,
  /secret/i, /token/i, /api_key/i, /apikey/i,
  /credit_card/i, /creditcard/i, /card_number/i,
  /cvv/i, /ssn/i, /social_security/i,
  /auth/i, /bearer/i, /session/i,
  /private_key/i, /privatekey/i
];

function maskSensitiveData(obj, depth = 0) {
  if (depth > 10) return obj;
  if (obj === null || obj === undefined) return obj;
  
  if (typeof obj === 'string') return obj;
  
  if (Array.isArray(obj)) {
    return obj.map(item => maskSensitiveData(item, depth + 1));
  }
  
  if (typeof obj === 'object') {
    const masked = {};
    for (const [key, value] of Object.entries(obj)) {
      const isSensitive = SENSITIVE_FIELD_PATTERNS.some(pattern => pattern.test(key));
      if (isSensitive && value) {
        masked[key] = '***MASKED***';
      } else if (typeof value === 'object') {
        masked[key] = maskSensitiveData(value, depth + 1);
      } else {
        masked[key] = value;
      }
    }
    return masked;
  }
  
  return obj;
}

function createSanitizationMiddleware(options = {}) {
  const { 
    sanitizeBody = true, 
    sanitizeQuery = true, 
    sanitizeParams = true,
    logSanitization = false 
  } = options;
  
  return (req, res, next) => {
    if (sanitizeBody && req.body) {
      req.body = sanitizeInput(req.body);
      if (logSanitization) {
        logger.debug('Sanitized request body', { path: req.path });
      }
    }
    
    if (sanitizeQuery && req.query) {
      for (const [key, value] of Object.entries(req.query)) {
        if (typeof value === 'string') {
          req.query[key] = sanitizeInput(value);
        }
      }
    }
    
    if (sanitizeParams && req.params) {
      for (const [key, value] of Object.entries(req.params)) {
        if (typeof value === 'string') {
          req.params[key] = value.trim();
        }
      }
    }
    
    next();
  };
}

module.exports = {
  escapeHtml,
  sanitizeInput,
  sanitizeForSQL,
  sanitizePath,
  sanitizeFilename,
  sanitizeUrl,
  sanitizeJson,
  sanitizeSearchQuery,
  stripHtmlTags,
  sanitizeForLog,
  maskSensitiveData,
  detectSqlInjection,
  createSanitizationMiddleware
};

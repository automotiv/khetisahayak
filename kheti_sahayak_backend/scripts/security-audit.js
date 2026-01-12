#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const CHECKS = {
  envSecrets: {
    name: 'Environment Secrets Check',
    run: () => {
      const envPath = path.join(__dirname, '..', '.env');
      const issues = [];

      if (!fs.existsSync(envPath)) {
        return { passed: true, message: 'No .env file found (using environment variables)' };
      }

      const envContent = fs.readFileSync(envPath, 'utf-8');
      const lines = envContent.split('\n');

      const weakSecrets = ['password', 'secret', 'test', 'demo', 'example', 'changeme', '123456'];

      lines.forEach((line, idx) => {
        if (line.startsWith('#') || !line.includes('=')) return;

        const [key, ...valueParts] = line.split('=');
        const value = valueParts.join('=').trim();

        if (key.toLowerCase().includes('secret') || key.toLowerCase().includes('password')) {
          if (value.length < 16) {
            issues.push(`Line ${idx + 1}: ${key} appears too short (< 16 chars)`);
          }
          if (weakSecrets.some(weak => value.toLowerCase().includes(weak))) {
            issues.push(`Line ${idx + 1}: ${key} contains weak pattern`);
          }
        }
      });

      return {
        passed: issues.length === 0,
        message: issues.length === 0 ? 'No weak secrets detected' : issues.join('\n'),
      };
    },
  },

  sqlInjection: {
    name: 'SQL Injection Pattern Check',
    run: () => {
      const issues = [];
      const dangerousPatterns = [
        /\$\{.*\}/g,
        /`SELECT.*\$\{/gi,
        /`INSERT.*\$\{/gi,
        /`UPDATE.*\$\{/gi,
        /`DELETE.*\$\{/gi,
        /query\s*\(\s*`[^`]*\$\{/g,
      ];

      const controllersDir = path.join(__dirname, '..', 'controllers');
      const servicesDir = path.join(__dirname, '..', 'services');

      [controllersDir, servicesDir].forEach(dir => {
        if (!fs.existsSync(dir)) return;

        fs.readdirSync(dir).forEach(file => {
          if (!file.endsWith('.js')) return;

          const content = fs.readFileSync(path.join(dir, file), 'utf-8');
          const lines = content.split('\n');

          lines.forEach((line, idx) => {
            dangerousPatterns.forEach(pattern => {
              if (pattern.test(line) && !line.includes('$1') && !line.includes('$2')) {
                issues.push(`${file}:${idx + 1} - Potential SQL injection: ${line.trim().substring(0, 80)}`);
              }
            });
          });
        });
      });

      return {
        passed: issues.length === 0,
        message: issues.length === 0 ? 'No SQL injection patterns detected' : issues.join('\n'),
      };
    },
  },

  xssVulnerabilities: {
    name: 'XSS Vulnerability Check',
    run: () => {
      const issues = [];
      const xssPatterns = [
        /innerHTML\s*=/g,
        /document\.write/g,
        /eval\s*\(/g,
        /new\s+Function\s*\(/g,
      ];

      const checkDir = (dir) => {
        if (!fs.existsSync(dir)) return;

        fs.readdirSync(dir).forEach(file => {
          if (!file.endsWith('.js')) return;

          const content = fs.readFileSync(path.join(dir, file), 'utf-8');
          const lines = content.split('\n');

          lines.forEach((line, idx) => {
            xssPatterns.forEach(pattern => {
              if (pattern.test(line)) {
                issues.push(`${file}:${idx + 1} - Potential XSS: ${line.trim().substring(0, 80)}`);
              }
            });
          });
        });
      };

      checkDir(path.join(__dirname, '..', 'controllers'));
      checkDir(path.join(__dirname, '..', 'routes'));

      return {
        passed: issues.length === 0,
        message: issues.length === 0 ? 'No XSS patterns detected' : issues.join('\n'),
      };
    },
  },

  hardcodedCredentials: {
    name: 'Hardcoded Credentials Check',
    run: () => {
      const issues = [];
      const credentialPatterns = [
        /password\s*[:=]\s*['"][^'"]{3,}['"]/gi,
        /api[_-]?key\s*[:=]\s*['"][^'"]{10,}['"]/gi,
        /secret\s*[:=]\s*['"][^'"]{10,}['"]/gi,
        /token\s*[:=]\s*['"][^'"]{20,}['"]/gi,
      ];

      const excludePatterns = [/process\.env/i, /\.env/i, /example/i, /placeholder/i];

      const checkDir = (dir) => {
        if (!fs.existsSync(dir)) return;

        fs.readdirSync(dir, { recursive: true }).forEach(file => {
          if (typeof file !== 'string' || !file.endsWith('.js')) return;

          const filePath = path.join(dir, file);
          if (!fs.statSync(filePath).isFile()) return;

          const content = fs.readFileSync(filePath, 'utf-8');
          const lines = content.split('\n');

          lines.forEach((line, idx) => {
            if (excludePatterns.some(p => p.test(line))) return;

            credentialPatterns.forEach(pattern => {
              if (pattern.test(line)) {
                issues.push(`${file}:${idx + 1} - Possible hardcoded credential`);
              }
            });
          });
        });
      };

      checkDir(path.join(__dirname, '..'));

      return {
        passed: issues.length === 0,
        message: issues.length === 0 ? 'No hardcoded credentials detected' : issues.join('\n'),
      };
    },
  },

  securityHeaders: {
    name: 'Security Headers Configuration',
    run: () => {
      const middlewarePath = path.join(__dirname, '..', 'middleware', 'securityMiddleware.js');

      if (!fs.existsSync(middlewarePath)) {
        return { passed: false, message: 'Security middleware not found' };
      }

      const content = fs.readFileSync(middlewarePath, 'utf-8');
      const requiredHeaders = [
        'X-Content-Type-Options',
        'X-Frame-Options',
        'X-XSS-Protection',
        'Strict-Transport-Security',
      ];

      const missing = requiredHeaders.filter(h => !content.includes(h));

      return {
        passed: missing.length === 0,
        message: missing.length === 0
          ? 'All required security headers configured'
          : `Missing headers: ${missing.join(', ')}`,
      };
    },
  },

  rateLimiting: {
    name: 'Rate Limiting Configuration',
    run: () => {
      const middlewarePath = path.join(__dirname, '..', 'middleware', 'securityMiddleware.js');

      if (!fs.existsSync(middlewarePath)) {
        return { passed: false, message: 'Security middleware not found' };
      }

      const content = fs.readFileSync(middlewarePath, 'utf-8');

      const hasRateLimiter = content.includes('rateLimit') || content.includes('RateLimiter');

      return {
        passed: hasRateLimiter,
        message: hasRateLimiter
          ? 'Rate limiting is configured'
          : 'Rate limiting not found - consider adding rate limiting middleware',
      };
    },
  },

  inputValidation: {
    name: 'Input Validation Check',
    run: () => {
      const routesDir = path.join(__dirname, '..', 'routes');

      if (!fs.existsSync(routesDir)) {
        return { passed: false, message: 'Routes directory not found' };
      }

      const routeFiles = fs.readdirSync(routesDir).filter(f => f.endsWith('.js'));
      const unvalidatedRoutes = [];

      routeFiles.forEach(file => {
        const content = fs.readFileSync(path.join(routesDir, file), 'utf-8');

        const postPutRoutes = content.match(/router\.(post|put)\s*\([^)]+\)/g) || [];

        postPutRoutes.forEach(route => {
          const hasValidation = content.includes('body(') || content.includes('validationResult');
          if (!hasValidation) {
            unvalidatedRoutes.push(`${file}: POST/PUT routes may lack validation`);
          }
        });
      });

      return {
        passed: unvalidatedRoutes.length === 0,
        message: unvalidatedRoutes.length === 0
          ? 'Input validation appears configured'
          : unvalidatedRoutes.join('\n'),
      };
    },
  },
};

const runAudit = () => {
  console.log('\n========================================');
  console.log('  KHETI SAHAYAK SECURITY AUDIT');
  console.log('========================================\n');

  let passed = 0;
  let failed = 0;
  const results = [];

  for (const [key, check] of Object.entries(CHECKS)) {
    try {
      const result = check.run();
      results.push({ name: check.name, ...result });

      const status = result.passed ? '\x1b[32mPASS\x1b[0m' : '\x1b[31mFAIL\x1b[0m';
      console.log(`[${status}] ${check.name}`);

      if (!result.passed) {
        console.log(`       ${result.message.split('\n').join('\n       ')}\n`);
        failed++;
      } else {
        console.log(`       ${result.message}\n`);
        passed++;
      }
    } catch (error) {
      console.log(`[\x1b[31mERROR\x1b[0m] ${check.name}`);
      console.log(`       ${error.message}\n`);
      failed++;
    }
  }

  console.log('========================================');
  console.log(`  Results: ${passed} passed, ${failed} failed`);
  console.log('========================================\n');

  process.exit(failed > 0 ? 1 : 0);
};

if (require.main === module) {
  runAudit();
}

module.exports = { runAudit, CHECKS };

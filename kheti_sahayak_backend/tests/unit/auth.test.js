const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

describe('Authentication Unit Tests', () => {
  describe('Password Hashing', () => {
    it('should hash password correctly', async () => {
      const password = 'Test@123';
      const hashedPassword = await bcrypt.hash(password, 10);
      
      expect(hashedPassword).toBeDefined();
      expect(hashedPassword).not.toBe(password);
      expect(hashedPassword.length).toBeGreaterThan(password.length);
    });

    it('should verify correct password', async () => {
      const password = 'Test@123';
      const hashedPassword = await bcrypt.hash(password, 10);
      
      const isMatch = await bcrypt.compare(password, hashedPassword);
      expect(isMatch).toBe(true);
    });

    it('should reject incorrect password', async () => {
      const password = 'Test@123';
      const wrongPassword = 'Wrong@123';
      const hashedPassword = await bcrypt.hash(password, 10);
      
      const isMatch = await bcrypt.compare(wrongPassword, hashedPassword);
      expect(isMatch).toBe(false);
    });
  });

  describe('JWT Token', () => {
    const secret = process.env.JWT_SECRET || 'test-secret';
    
    it('should generate valid JWT token', () => {
      const payload = { userId: 1, email: 'test@example.com' };
      const token = jwt.sign(payload, secret, { expiresIn: '1h' });
      
      expect(token).toBeDefined();
      expect(typeof token).toBe('string');
      expect(token.split('.').length).toBe(3); // JWT has 3 parts
    });

    it('should decode JWT token correctly', () => {
      const payload = { userId: 1, email: 'test@example.com' };
      const token = jwt.sign(payload, secret, { expiresIn: '1h' });
      
      const decoded = jwt.verify(token, secret);
      expect(decoded.userId).toBe(payload.userId);
      expect(decoded.email).toBe(payload.email);
    });

    it('should reject invalid JWT token', () => {
      const invalidToken = 'invalid.token.here';
      
      expect(() => {
        jwt.verify(invalidToken, secret);
      }).toThrow();
    });

    it('should reject expired JWT token', () => {
      const payload = { userId: 1, email: 'test@example.com' };
      const token = jwt.sign(payload, secret, { expiresIn: '0s' });
      
      // Wait a moment to ensure expiration
      return new Promise((resolve) => {
        setTimeout(() => {
          expect(() => {
            jwt.verify(token, secret);
          }).toThrow();
          resolve();
        }, 100);
      });
    });
  });

  describe('Input Validation', () => {
    it('should validate email format', () => {
      const validEmails = [
        'test@example.com',
        'user.name@domain.co.in',
        'user+tag@example.com',
      ];
      
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      
      validEmails.forEach(email => {
        expect(emailRegex.test(email)).toBe(true);
      });
    });

    it('should reject invalid email format', () => {
      const invalidEmails = [
        'notanemail',
        '@example.com',
        'user@',
        'user @example.com',
      ];
      
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      
      invalidEmails.forEach(email => {
        expect(emailRegex.test(email)).toBe(false);
      });
    });

    it('should validate password strength', () => {
      const weakPasswords = [
        '123',
        'abc',
        'test',
        '12345',
      ];

      const strongPasswords = [
        'Test@123',
        'MyP@ssw0rd',
        'Strong#Pass1',
        'SecurePass123',
      ];

      // Password should be at least 6 characters
      weakPasswords.forEach(password => {
        expect(password.length >= 6).toBe(false);
      });

      strongPasswords.forEach(password => {
        expect(password.length >= 6).toBe(true);
      });
    });
  });
});

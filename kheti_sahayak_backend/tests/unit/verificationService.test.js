const mockQuery = jest.fn();
const mockHash = jest.fn();
const mockCompare = jest.fn();

jest.mock('../../db', () => ({
  query: mockQuery
}));

jest.mock('bcryptjs', () => ({
  hash: mockHash,
  compare: mockCompare
}));

const mockSendEmail = jest.fn();
const mockSendPasswordResetEmail = jest.fn();

jest.mock('../../services/emailService', () => ({
  sendEmail: mockSendEmail,
  sendPasswordResetEmail: mockSendPasswordResetEmail
}));

const verificationService = require('../../services/verificationService');

describe('Verification Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Constants', () => {
    it('should export expiry constants', () => {
      expect(verificationService.VERIFICATION_TOKEN_EXPIRY).toBe(24 * 60 * 60 * 1000);
      expect(verificationService.PASSWORD_RESET_EXPIRY).toBe(60 * 60 * 1000);
      expect(verificationService.OTP_EXPIRY).toBe(10 * 60 * 1000);
      expect(verificationService.MAX_OTP_ATTEMPTS).toBe(3);
      expect(verificationService.OTP_RATE_LIMIT).toBe(5);
    });
  });

  describe('generateToken', () => {
    it('should generate unique tokens', () => {
      const token1 = verificationService.generateToken();
      const token2 = verificationService.generateToken();

      expect(token1).not.toBe(token2);
      expect(token1.length).toBe(64);
      expect(token2.length).toBe(64);
    });
  });

  describe('generateOTP', () => {
    it('should generate 6-digit OTP', () => {
      const otp = verificationService.generateOTP();

      expect(otp.length).toBe(6);
      expect(parseInt(otp)).toBeGreaterThanOrEqual(100000);
      expect(parseInt(otp)).toBeLessThanOrEqual(999999);
    });

    it('should generate different OTPs each time', () => {
      const otps = new Set();
      for (let i = 0; i < 100; i++) {
        otps.add(verificationService.generateOTP());
      }
      expect(otps.size).toBeGreaterThan(90);
    });
  });

  describe('createEmailVerificationToken', () => {
    it('should create and store verification token', async () => {
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });

      const token = await verificationService.createEmailVerificationToken('user-1');

      expect(token.length).toBe(64);
      expect(mockQuery).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE users'),
        expect.arrayContaining(['user-1'])
      );
    });
  });

  describe('verifyEmail', () => {
    it('should verify valid token and return user', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [{ id: 'user-1', email: 'test@example.com', username: 'testuser' }]
      });

      const result = await verificationService.verifyEmail('valid-token');

      expect(result.success).toBe(true);
      expect(result.user.id).toBe('user-1');
    });

    it('should return failure for invalid token', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await verificationService.verifyEmail('invalid-token');

      expect(result.success).toBe(false);
      expect(result.error).toBe('Invalid or expired verification token');
    });

    it('should return failure for expired token', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await verificationService.verifyEmail('expired-token');

      expect(result.success).toBe(false);
    });
  });

  describe('sendVerificationEmail', () => {
    it('should send verification email with token', async () => {
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });
      mockSendEmail.mockResolvedValueOnce({ success: true });

      const user = { id: 'user-1', email: 'test@example.com', first_name: 'Test' };
      const result = await verificationService.sendVerificationEmail(user);

      expect(mockSendEmail).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'test@example.com',
          subject: expect.stringContaining('Verify')
        })
      );
      expect(result.success).toBe(true);
    });

    it('should include verification URL in email', async () => {
      mockQuery.mockResolvedValueOnce({ rowCount: 1 });
      mockSendEmail.mockResolvedValueOnce({ success: true });

      const user = { id: 'user-1', email: 'test@example.com' };
      await verificationService.sendVerificationEmail(user);

      expect(mockSendEmail).toHaveBeenCalledWith(
        expect.objectContaining({
          html: expect.stringContaining('verify-email?token=')
        })
      );
    });
  });

  describe('createPasswordResetToken', () => {
    it('should create reset token for existing user', async () => {
      mockQuery
        .mockResolvedValueOnce({
          rows: [{ id: 'user-1', email: 'test@example.com', username: 'test', first_name: 'Test' }]
        })
        .mockResolvedValueOnce({ rowCount: 1 });
      mockSendPasswordResetEmail.mockResolvedValueOnce({ success: true });

      const result = await verificationService.createPasswordResetToken('test@example.com');

      expect(result.success).toBe(true);
      expect(mockSendPasswordResetEmail).toHaveBeenCalled();
    });

    it('should return failure for non-existent email', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await verificationService.createPasswordResetToken('unknown@example.com');

      expect(result.success).toBe(false);
      expect(result.error).toBe('No account found with this email');
    });
  });

  describe('resetPassword', () => {
    it('should reset password with valid token', async () => {
      mockQuery
        .mockResolvedValueOnce({ rows: [{ id: 'user-1' }] })
        .mockResolvedValueOnce({ rowCount: 1 });
      mockHash.mockResolvedValueOnce('hashed_password');

      const result = await verificationService.resetPassword('valid-token', 'NewPassword123');

      expect(result.success).toBe(true);
      expect(mockHash).toHaveBeenCalledWith('NewPassword123', 10);
    });

    it('should return failure for invalid token', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await verificationService.resetPassword('invalid-token', 'NewPassword123');

      expect(result.success).toBe(false);
      expect(result.error).toBe('Invalid or expired reset token');
    });

    it('should clear reset token after successful reset', async () => {
      mockQuery
        .mockResolvedValueOnce({ rows: [{ id: 'user-1' }] })
        .mockResolvedValueOnce({ rowCount: 1 });
      mockHash.mockResolvedValueOnce('hashed_password');

      await verificationService.resetPassword('valid-token', 'NewPassword123');

      expect(mockQuery).toHaveBeenNthCalledWith(
        2,
        expect.stringContaining('password_reset_token = NULL'),
        expect.any(Array)
      );
    });
  });

  describe('checkOTPRateLimit', () => {
    it('should return true when under rate limit', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [{ count: '3' }] });

      const result = await verificationService.checkOTPRateLimit('+919876543210');

      expect(result).toBe(true);
    });

    it('should return false when at rate limit', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [{ count: '5' }] });

      const result = await verificationService.checkOTPRateLimit('+919876543210');

      expect(result).toBe(false);
    });

    it('should return false when over rate limit', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [{ count: '10' }] });

      const result = await verificationService.checkOTPRateLimit('+919876543210');

      expect(result).toBe(false);
    });
  });

  describe('createOTP', () => {
    it('should create OTP when under rate limit', async () => {
      mockQuery
        .mockResolvedValueOnce({ rows: [{ count: '2' }] })
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ rowCount: 1 });
      mockHash.mockResolvedValueOnce('hashed_otp');

      const result = await verificationService.createOTP('+919876543210', 'user-1', 'phone_verification');

      expect(result.success).toBe(true);
      expect(result.otp.length).toBe(6);
    });

    it('should return failure when rate limit exceeded', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [{ count: '5' }] });

      const result = await verificationService.createOTP('+919876543210', 'user-1');

      expect(result.success).toBe(false);
      expect(result.error).toContain('Too many OTP requests');
    });

    it('should delete previous unverified OTPs', async () => {
      mockQuery
        .mockResolvedValueOnce({ rows: [{ count: '0' }] })
        .mockResolvedValueOnce({ rowCount: 2 })
        .mockResolvedValueOnce({ rowCount: 1 });
      mockHash.mockResolvedValueOnce('hashed_otp');

      await verificationService.createOTP('+919876543210', 'user-1');

      expect(mockQuery).toHaveBeenNthCalledWith(
        2,
        expect.stringContaining('DELETE FROM otp_verifications'),
        expect.any(Array)
      );
    });
  });

  describe('verifyOTP', () => {
    it('should verify correct OTP', async () => {
      mockQuery
        .mockResolvedValueOnce({
          rows: [{ id: 'otp-1', user_id: 'user-1', otp_hash: 'hash', attempts: 0 }]
        })
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ rowCount: 1 });
      mockCompare.mockResolvedValueOnce(true);

      const result = await verificationService.verifyOTP('+919876543210', '123456');

      expect(result.success).toBe(true);
      expect(result.userId).toBe('user-1');
    });

    it('should return failure when no valid OTP found', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [] });

      const result = await verificationService.verifyOTP('+919876543210', '123456');

      expect(result.success).toBe(false);
      expect(result.error).toContain('No valid OTP found');
    });

    it('should return failure when max attempts exceeded', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [{ id: 'otp-1', user_id: 'user-1', otp_hash: 'hash', attempts: 3 }]
      });

      const result = await verificationService.verifyOTP('+919876543210', '123456');

      expect(result.success).toBe(false);
      expect(result.error).toContain('Maximum attempts exceeded');
    });

    it('should increment attempts on wrong OTP', async () => {
      mockQuery
        .mockResolvedValueOnce({
          rows: [{ id: 'otp-1', user_id: 'user-1', otp_hash: 'hash', attempts: 1 }]
        })
        .mockResolvedValueOnce({ rowCount: 1 });
      mockCompare.mockResolvedValueOnce(false);

      const result = await verificationService.verifyOTP('+919876543210', 'wrong');

      expect(result.success).toBe(false);
      expect(result.error).toContain('Invalid OTP');
      expect(mockQuery).toHaveBeenNthCalledWith(
        2,
        expect.stringContaining('attempts = attempts + 1'),
        ['otp-1']
      );
    });

    it('should mark phone as verified for phone_verification purpose', async () => {
      mockQuery
        .mockResolvedValueOnce({
          rows: [{ id: 'otp-1', user_id: 'user-1', otp_hash: 'hash', attempts: 0 }]
        })
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ rowCount: 1 });
      mockCompare.mockResolvedValueOnce(true);

      await verificationService.verifyOTP('+919876543210', '123456', 'phone_verification');

      expect(mockQuery).toHaveBeenCalledWith(
        expect.stringContaining('phone_verified = true'),
        ['user-1']
      );
    });
  });
});

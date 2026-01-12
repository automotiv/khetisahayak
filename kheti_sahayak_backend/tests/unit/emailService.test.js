/**
 * Unit Tests for Email Service
 */

const mockSendMail = jest.fn();
const mockCreateTransport = jest.fn(() => ({
  sendMail: mockSendMail
}));

jest.mock('nodemailer', () => ({
  createTransport: mockCreateTransport
}));

const emailService = require('../../services/emailService');

describe('Email Service', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env = { ...originalEnv };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  describe('sendEmail', () => {
    it('should log email when SMTP not configured', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const result = await emailService.sendEmail({
        to: 'test@example.com',
        subject: 'Test Subject',
        html: '<p>Test content</p>'
      });

      expect(result.success).toBe(true);
      expect(result.mock).toBe(true);
      consoleSpy.mockRestore();
    });

    it('should send email when SMTP is configured', async () => {
      process.env.SMTP_USER = 'testuser';
      process.env.SMTP_PASS = 'testpass';
      mockSendMail.mockResolvedValueOnce({ messageId: 'msg-123' });

      const result = await emailService.sendEmail({
        to: 'test@example.com',
        subject: 'Test Subject',
        html: '<p>Test content</p>'
      });

      expect(result.success).toBe(true);
      expect(result.messageId).toBe('msg-123');
    });

    it('should handle email sending errors', async () => {
      process.env.SMTP_USER = 'testuser';
      process.env.SMTP_PASS = 'testpass';
      mockSendMail.mockRejectedValueOnce(new Error('SMTP connection failed'));
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

      const result = await emailService.sendEmail({
        to: 'test@example.com',
        subject: 'Test Subject',
        html: '<p>Test content</p>'
      });

      expect(result.success).toBe(false);
      expect(result.error).toBe('SMTP connection failed');
      consoleSpy.mockRestore();
    });

    it('should strip HTML for plain text when not provided', async () => {
      process.env.SMTP_USER = 'testuser';
      mockSendMail.mockResolvedValueOnce({ messageId: 'msg-123' });

      await emailService.sendEmail({
        to: 'test@example.com',
        subject: 'Test',
        html: '<p>Hello <strong>World</strong></p>'
      });

      expect(mockSendMail).toHaveBeenCalledWith(
        expect.objectContaining({
          text: expect.any(String)
        })
      );
    });
  });

  describe('sendOrderConfirmation', () => {
    const mockOrder = {
      id: '12345678-1234-1234-1234-123456789012',
      items: [
        { product_name: 'Seeds', quantity: 2, unit_price: 100, total_price: 200 },
        { product_name: 'Fertilizer', quantity: 1, unit_price: 500, total_price: 500 }
      ],
      total_amount: 700,
      shipping_address: '123 Farm Road, Village',
      payment_method: 'UPI',
      created_at: new Date()
    };

    const mockUser = {
      email: 'farmer@example.com',
      first_name: 'Rahul',
      username: 'rahul123'
    };

    it('should send order confirmation email', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const result = await emailService.sendOrderConfirmation(mockOrder, mockUser);

      expect(result.success).toBe(true);
      consoleSpy.mockRestore();
    });

    it('should include order details in email', async () => {
      process.env.SMTP_USER = 'testuser';
      mockSendMail.mockResolvedValueOnce({ messageId: 'msg-123' });

      await emailService.sendOrderConfirmation(mockOrder, mockUser);

      expect(mockSendMail).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'farmer@example.com',
          subject: expect.stringContaining('Order Confirmed')
        })
      );
    });

    it('should handle missing first_name gracefully', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const userWithoutName = { email: 'test@example.com', username: 'testuser' };
      const result = await emailService.sendOrderConfirmation(mockOrder, userWithoutName);

      expect(result.success).toBe(true);
      consoleSpy.mockRestore();
    });
  });

  describe('sendOrderStatusUpdate', () => {
    const mockOrder = {
      id: '12345678-1234-1234-1234-123456789012',
      created_at: new Date()
    };

    const mockUser = {
      email: 'farmer@example.com',
      first_name: 'Rahul'
    };

    it('should send confirmed status email', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const result = await emailService.sendOrderStatusUpdate(mockOrder, mockUser, 'confirmed');

      expect(result.success).toBe(true);
      consoleSpy.mockRestore();
    });

    it('should send shipped status email', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const result = await emailService.sendOrderStatusUpdate(mockOrder, mockUser, 'shipped');

      expect(result.success).toBe(true);
      consoleSpy.mockRestore();
    });

    it('should send delivered status email', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const result = await emailService.sendOrderStatusUpdate(mockOrder, mockUser, 'delivered');

      expect(result.success).toBe(true);
      consoleSpy.mockRestore();
    });

    it('should send cancelled status email', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const result = await emailService.sendOrderStatusUpdate(mockOrder, mockUser, 'cancelled');

      expect(result.success).toBe(true);
      consoleSpy.mockRestore();
    });

    it('should handle unknown status', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const result = await emailService.sendOrderStatusUpdate(mockOrder, mockUser, 'processing');

      expect(result.success).toBe(true);
      consoleSpy.mockRestore();
    });
  });

  describe('sendPaymentConfirmation', () => {
    const mockPayment = {
      id: 'pay_123',
      razorpay_payment_id: 'pay_rzp_123',
      amount: 70000,
      method: 'card'
    };

    const mockOrder = {
      id: '12345678-1234-1234-1234-123456789012'
    };

    const mockUser = {
      email: 'farmer@example.com',
      first_name: 'Rahul'
    };

    it('should send payment confirmation email', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const result = await emailService.sendPaymentConfirmation(mockPayment, mockOrder, mockUser);

      expect(result.success).toBe(true);
      consoleSpy.mockRestore();
    });

    it('should display amount in rupees', async () => {
      process.env.SMTP_USER = 'testuser';
      mockSendMail.mockResolvedValueOnce({ messageId: 'msg-123' });

      await emailService.sendPaymentConfirmation(mockPayment, mockOrder, mockUser);

      expect(mockSendMail).toHaveBeenCalledWith(
        expect.objectContaining({
          subject: expect.stringContaining('700.00')
        })
      );
    });

    it('should use fallback payment ID when razorpay_payment_id is missing', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const paymentWithoutRazorpay = { id: 'pay_123', amount: 50000, method: 'upi' };
      const result = await emailService.sendPaymentConfirmation(paymentWithoutRazorpay, mockOrder, mockUser);

      expect(result.success).toBe(true);
      consoleSpy.mockRestore();
    });
  });

  describe('sendWelcomeEmail', () => {
    it('should send welcome email to new user', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const mockUser = {
        email: 'newfarmer@example.com',
        first_name: 'Amit',
        username: 'amit_farmer'
      };

      const result = await emailService.sendWelcomeEmail(mockUser);

      expect(result.success).toBe(true);
      consoleSpy.mockRestore();
    });

    it('should include welcome offer in email', async () => {
      process.env.SMTP_USER = 'testuser';
      mockSendMail.mockResolvedValueOnce({ messageId: 'msg-123' });

      const mockUser = { email: 'test@example.com', first_name: 'Test' };
      await emailService.sendWelcomeEmail(mockUser);

      expect(mockSendMail).toHaveBeenCalledWith(
        expect.objectContaining({
          html: expect.stringContaining('WELCOME10')
        })
      );
    });

    it('should handle user without first_name', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const mockUser = { email: 'test@example.com', username: 'testuser' };
      const result = await emailService.sendWelcomeEmail(mockUser);

      expect(result.success).toBe(true);
      consoleSpy.mockRestore();
    });
  });

  describe('sendPasswordResetEmail', () => {
    it('should send password reset email', async () => {
      process.env.SMTP_USER = '';
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      const mockUser = {
        email: 'user@example.com',
        first_name: 'Test',
        username: 'testuser'
      };
      const resetToken = 'abc123resettoken';
      const resetUrl = 'http://localhost:3000/reset-password?token=abc123resettoken';

      const result = await emailService.sendPasswordResetEmail(mockUser, resetToken, resetUrl);

      expect(result.success).toBe(true);
      consoleSpy.mockRestore();
    });

    it('should include reset URL in email', async () => {
      process.env.SMTP_USER = 'testuser';
      mockSendMail.mockResolvedValueOnce({ messageId: 'msg-123' });

      const mockUser = { email: 'user@example.com', first_name: 'Test' };
      const resetUrl = 'http://localhost:3000/reset-password?token=xyz789';

      await emailService.sendPasswordResetEmail(mockUser, 'xyz789', resetUrl);

      expect(mockSendMail).toHaveBeenCalledWith(
        expect.objectContaining({
          html: expect.stringContaining(resetUrl)
        })
      );
    });

    it('should include expiry warning in email', async () => {
      process.env.SMTP_USER = 'testuser';
      mockSendMail.mockResolvedValueOnce({ messageId: 'msg-123' });

      const mockUser = { email: 'user@example.com' };
      await emailService.sendPasswordResetEmail(mockUser, 'token', 'http://reset.url');

      expect(mockSendMail).toHaveBeenCalledWith(
        expect.objectContaining({
          html: expect.stringContaining('1 hour')
        })
      );
    });
  });
});

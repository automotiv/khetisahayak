const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const db = require('../db');
const emailService = require('./emailService');

const VERIFICATION_TOKEN_EXPIRY = 24 * 60 * 60 * 1000; // 24 hours
const PASSWORD_RESET_EXPIRY = 60 * 60 * 1000; // 1 hour
const OTP_EXPIRY = 10 * 60 * 1000; // 10 minutes
const MAX_OTP_ATTEMPTS = 3;
const OTP_RATE_LIMIT = 5; // max OTPs per hour

const generateToken = () => crypto.randomBytes(32).toString('hex');

const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

const createEmailVerificationToken = async (userId) => {
  const token = generateToken();
  const expires = new Date(Date.now() + VERIFICATION_TOKEN_EXPIRY);
  
  await db.query(
    `UPDATE users 
     SET email_verification_token = $1, 
         email_verification_expires = $2 
     WHERE id = $3`,
    [token, expires, userId]
  );
  
  return token;
};

const verifyEmail = async (token) => {
  const result = await db.query(
    `UPDATE users 
     SET email_verified = true, 
         email_verification_token = NULL, 
         email_verification_expires = NULL 
     WHERE email_verification_token = $1 
       AND email_verification_expires > NOW() 
     RETURNING id, email, username`,
    [token]
  );
  
  if (result.rows.length === 0) {
    return { success: false, error: 'Invalid or expired verification token' };
  }
  
  return { success: true, user: result.rows[0] };
};

const sendVerificationEmail = async (user) => {
  const token = await createEmailVerificationToken(user.id);
  const verificationUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/verify-email?token=${token}`;
  
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Verify Your Email</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #4CAF50, #2E7D32); padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0;">🌾 Kheti Sahayak</h1>
      </div>
      
      <div style="background: #fff; padding: 30px; border: 1px solid #e0e0e0; border-top: none;">
        <h2 style="color: #2E7D32; margin-top: 0;">Verify Your Email Address</h2>
        
        <p>Hello ${user.first_name || user.username || 'there'},</p>
        
        <p>Thank you for registering with Kheti Sahayak! Please verify your email address to complete your registration.</p>
        
        <div style="text-align: center; margin: 30px 0;">
          <a href="${verificationUrl}" style="background: #4CAF50; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold; display: inline-block;">Verify Email</a>
        </div>
        
        <p style="color: #666; font-size: 14px;">Or copy and paste this link:</p>
        <p style="background: #f5f5f5; padding: 10px; border-radius: 4px; word-break: break-all; font-size: 12px;">${verificationUrl}</p>
        
        <div style="background: #FFF3E0; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="margin: 0;"><strong>⏰ This link expires in 24 hours</strong></p>
        </div>
        
        <p>If you didn't create an account, you can safely ignore this email.</p>
        
        <p style="margin-top: 30px;">
          Happy Farming! 🌱<br>
          <strong>The Kheti Sahayak Team</strong>
        </p>
      </div>
      
      <div style="background: #f5f5f5; padding: 20px; text-align: center; border-radius: 0 0 10px 10px; font-size: 12px; color: #666;">
        <p style="margin: 0;">© ${new Date().getFullYear()} Kheti Sahayak. All rights reserved.</p>
      </div>
    </body>
    </html>
  `;
  
  return emailService.sendEmail({
    to: user.email,
    subject: '✉️ Verify Your Email - Kheti Sahayak',
    html,
  });
};

const createPasswordResetToken = async (email) => {
  const userResult = await db.query('SELECT id, email, username, first_name FROM users WHERE email = $1', [email]);
  
  if (userResult.rows.length === 0) {
    return { success: false, error: 'No account found with this email' };
  }
  
  const user = userResult.rows[0];
  const token = generateToken();
  const expires = new Date(Date.now() + PASSWORD_RESET_EXPIRY);
  
  await db.query(
    `UPDATE users 
     SET password_reset_token = $1, 
         password_reset_expires = $2 
     WHERE id = $3`,
    [token, expires, user.id]
  );
  
  const resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?token=${token}`;
  
  await emailService.sendPasswordResetEmail(user, token, resetUrl);
  
  return { success: true };
};

const resetPassword = async (token, newPassword) => {
  const userResult = await db.query(
    `SELECT id FROM users 
     WHERE password_reset_token = $1 
       AND password_reset_expires > NOW()`,
    [token]
  );
  
  if (userResult.rows.length === 0) {
    return { success: false, error: 'Invalid or expired reset token' };
  }
  
  const userId = userResult.rows[0].id;
  const hashedPassword = await bcrypt.hash(newPassword, 10);
  
  await db.query(
    `UPDATE users 
     SET password_hash = $1, 
         password_reset_token = NULL, 
         password_reset_expires = NULL,
         updated_at = CURRENT_TIMESTAMP 
     WHERE id = $2`,
    [hashedPassword, userId]
  );
  
  return { success: true };
};

const checkOTPRateLimit = async (phone) => {
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
  
  const result = await db.query(
    `SELECT COUNT(*) FROM otp_verifications 
     WHERE phone = $1 AND created_at > $2`,
    [phone, oneHourAgo]
  );
  
  return parseInt(result.rows[0].count) < OTP_RATE_LIMIT;
};

const createOTP = async (phone, userId, purpose = 'phone_verification') => {
  const canSend = await checkOTPRateLimit(phone);
  if (!canSend) {
    return { success: false, error: 'Too many OTP requests. Please try again later.' };
  }
  
  const otp = generateOTP();
  const otpHash = await bcrypt.hash(otp, 10);
  const expires = new Date(Date.now() + OTP_EXPIRY);
  
  await db.query(
    `DELETE FROM otp_verifications 
     WHERE phone = $1 AND purpose = $2 AND verified_at IS NULL`,
    [phone, purpose]
  );
  
  await db.query(
    `INSERT INTO otp_verifications (user_id, phone, otp_hash, purpose, expires_at) 
     VALUES ($1, $2, $3, $4, $5)`,
    [userId, phone, otpHash, purpose, expires]
  );
  
  return { success: true, otp };
};

const verifyOTP = async (phone, otp, purpose = 'phone_verification') => {
  const result = await db.query(
    `SELECT * FROM otp_verifications 
     WHERE phone = $1 
       AND purpose = $2 
       AND verified_at IS NULL 
       AND expires_at > NOW() 
     ORDER BY created_at DESC 
     LIMIT 1`,
    [phone, purpose]
  );
  
  if (result.rows.length === 0) {
    return { success: false, error: 'No valid OTP found. Please request a new one.' };
  }
  
  const otpRecord = result.rows[0];
  
  if (otpRecord.attempts >= MAX_OTP_ATTEMPTS) {
    return { success: false, error: 'Maximum attempts exceeded. Please request a new OTP.' };
  }
  
  const isValid = await bcrypt.compare(otp, otpRecord.otp_hash);
  
  if (!isValid) {
    await db.query(
      'UPDATE otp_verifications SET attempts = attempts + 1 WHERE id = $1',
      [otpRecord.id]
    );
    return { success: false, error: 'Invalid OTP. Please try again.' };
  }
  
  await db.query(
    'UPDATE otp_verifications SET verified_at = NOW() WHERE id = $1',
    [otpRecord.id]
  );
  
  if (purpose === 'phone_verification' && otpRecord.user_id) {
    await db.query(
      'UPDATE users SET phone_verified = true WHERE id = $1',
      [otpRecord.user_id]
    );
  }
  
  return { success: true, userId: otpRecord.user_id };
};

module.exports = {
  generateToken,
  generateOTP,
  createEmailVerificationToken,
  verifyEmail,
  sendVerificationEmail,
  createPasswordResetToken,
  resetPassword,
  checkOTPRateLimit,
  createOTP,
  verifyOTP,
  VERIFICATION_TOKEN_EXPIRY,
  PASSWORD_RESET_EXPIRY,
  OTP_EXPIRY,
  MAX_OTP_ATTEMPTS,
  OTP_RATE_LIMIT,
};

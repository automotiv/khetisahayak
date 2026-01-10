/**
 * Email Service for Kheti Sahayak
 * 
 * Handles sending transactional emails for:
 * - Order confirmations
 * - Order status updates
 * - Payment confirmations
 * - Password reset
 * - Welcome emails
 * 
 * Supports multiple providers:
 * - SendGrid (primary)
 * - AWS SES (fallback)
 * - SMTP (development)
 */

const nodemailer = require('nodemailer');

// Email configuration
const EMAIL_CONFIG = {
  provider: process.env.EMAIL_PROVIDER || 'smtp', // 'sendgrid', 'ses', 'smtp'
  from: process.env.EMAIL_FROM || 'noreply@khetisahayak.com',
  fromName: process.env.EMAIL_FROM_NAME || 'Kheti Sahayak',
  
  // SMTP settings (for development)
  smtp: {
    host: process.env.SMTP_HOST || 'smtp.mailtrap.io',
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  },
  
  // SendGrid settings
  sendgrid: {
    apiKey: process.env.SENDGRID_API_KEY,
  },
  
  // AWS SES settings
  ses: {
    region: process.env.AWS_REGION || 'ap-south-1',
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
};

// Create transporter based on provider
let transporter = null;

/**
 * Initialize email transporter
 */
const initTransporter = () => {
  if (transporter) return transporter;
  
  const provider = EMAIL_CONFIG.provider;
  
  switch (provider) {
    case 'sendgrid':
      // SendGrid uses nodemailer-sendgrid transport
      transporter = nodemailer.createTransport({
        host: 'smtp.sendgrid.net',
        port: 587,
        auth: {
          user: 'apikey',
          pass: EMAIL_CONFIG.sendgrid.apiKey,
        },
      });
      break;
      
    case 'ses':
      // AWS SES transport
      const aws = require('@aws-sdk/client-ses');
      const { defaultProvider } = require('@aws-sdk/credential-provider-node');
      
      const ses = new aws.SES({
        region: EMAIL_CONFIG.ses.region,
        credentials: defaultProvider(),
      });
      
      transporter = nodemailer.createTransport({
        SES: { ses, aws },
      });
      break;
      
    case 'smtp':
    default:
      // Standard SMTP transport
      transporter = nodemailer.createTransport(EMAIL_CONFIG.smtp);
      break;
  }
  
  return transporter;
};

/**
 * Send email
 * @param {Object} options - Email options
 * @param {string} options.to - Recipient email
 * @param {string} options.subject - Email subject
 * @param {string} options.html - HTML content
 * @param {string} [options.text] - Plain text content
 * @returns {Promise<Object>} - Send result
 */
const sendEmail = async ({ to, subject, html, text }) => {
  try {
    // Check if email is configured
    if (!EMAIL_CONFIG.smtp.auth.user && EMAIL_CONFIG.provider === 'smtp') {
      console.log('[EmailService] Email not configured, logging instead:');
      console.log(`  To: ${to}`);
      console.log(`  Subject: ${subject}`);
      console.log(`  Content: ${text || html.substring(0, 200)}...`);
      return { success: true, mock: true, message: 'Email logged (not configured)' };
    }
    
    const transport = initTransporter();
    
    const mailOptions = {
      from: `"${EMAIL_CONFIG.fromName}" <${EMAIL_CONFIG.from}>`,
      to,
      subject,
      html,
      text: text || html.replace(/<[^>]*>/g, ''), // Strip HTML for plain text
    };
    
    const result = await transport.sendMail(mailOptions);
    
    console.log(`[EmailService] Email sent to ${to}: ${result.messageId}`);
    
    return {
      success: true,
      messageId: result.messageId,
    };
  } catch (error) {
    console.error('[EmailService] Error sending email:', error);
    return {
      success: false,
      error: error.message,
    };
  }
};

/**
 * Send order confirmation email
 * @param {Object} order - Order details
 * @param {Object} user - User details
 */
const sendOrderConfirmation = async (order, user) => {
  const itemsHtml = order.items.map(item => `
    <tr>
      <td style="padding: 10px; border-bottom: 1px solid #eee;">${item.product_name}</td>
      <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: center;">${item.quantity}</td>
      <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: right;">₹${item.unit_price.toFixed(2)}</td>
      <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: right;">₹${item.total_price.toFixed(2)}</td>
    </tr>
  `).join('');
  
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Order Confirmation</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #4CAF50, #2E7D32); padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0;">🌾 Kheti Sahayak</h1>
        <p style="color: #E8F5E9; margin: 5px 0 0 0;">Your Agricultural Partner</p>
      </div>
      
      <div style="background: #fff; padding: 30px; border: 1px solid #e0e0e0; border-top: none;">
        <h2 style="color: #2E7D32; margin-top: 0;">Order Confirmed! ✓</h2>
        
        <p>Dear ${user.first_name || user.username || 'Valued Customer'},</p>
        
        <p>Thank you for your order! We're excited to help you with your farming needs.</p>
        
        <div style="background: #F1F8E9; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="margin: 0;"><strong>Order ID:</strong> #${order.id.substring(0, 8).toUpperCase()}</p>
          <p style="margin: 5px 0 0 0;"><strong>Order Date:</strong> ${new Date(order.created_at).toLocaleDateString('en-IN', { 
            weekday: 'long', 
            year: 'numeric', 
            month: 'long', 
            day: 'numeric' 
          })}</p>
        </div>
        
        <h3 style="color: #2E7D32; border-bottom: 2px solid #4CAF50; padding-bottom: 10px;">Order Details</h3>
        
        <table style="width: 100%; border-collapse: collapse; margin: 15px 0;">
          <thead>
            <tr style="background: #E8F5E9;">
              <th style="padding: 10px; text-align: left;">Product</th>
              <th style="padding: 10px; text-align: center;">Qty</th>
              <th style="padding: 10px; text-align: right;">Price</th>
              <th style="padding: 10px; text-align: right;">Total</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml}
          </tbody>
          <tfoot>
            <tr style="background: #F1F8E9;">
              <td colspan="3" style="padding: 10px; text-align: right;"><strong>Order Total:</strong></td>
              <td style="padding: 10px; text-align: right;"><strong style="color: #2E7D32; font-size: 18px;">₹${order.total_amount.toFixed(2)}</strong></td>
            </tr>
          </tfoot>
        </table>
        
        <h3 style="color: #2E7D32;">Shipping Address</h3>
        <p style="background: #f5f5f5; padding: 15px; border-radius: 8px; white-space: pre-line;">${order.shipping_address}</p>
        
        <h3 style="color: #2E7D32;">Payment Method</h3>
        <p>${order.payment_method || 'Online Payment'}</p>
        
        <div style="background: #E3F2FD; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="margin: 0;"><strong>📦 What's Next?</strong></p>
          <ul style="margin: 10px 0 0 0; padding-left: 20px;">
            <li>We'll process your order within 24 hours</li>
            <li>You'll receive a shipping notification with tracking details</li>
            <li>Expected delivery: 3-5 business days</li>
          </ul>
        </div>
        
        <p>If you have any questions, feel free to contact our support team.</p>
        
        <p style="margin-top: 30px;">
          Happy Farming! 🌱<br>
          <strong>The Kheti Sahayak Team</strong>
        </p>
      </div>
      
      <div style="background: #f5f5f5; padding: 20px; text-align: center; border-radius: 0 0 10px 10px; font-size: 12px; color: #666;">
        <p style="margin: 0;">© ${new Date().getFullYear()} Kheti Sahayak. All rights reserved.</p>
        <p style="margin: 5px 0 0 0;">
          <a href="#" style="color: #4CAF50; text-decoration: none;">Unsubscribe</a> | 
          <a href="#" style="color: #4CAF50; text-decoration: none;">Privacy Policy</a> | 
          <a href="#" style="color: #4CAF50; text-decoration: none;">Contact Us</a>
        </p>
      </div>
    </body>
    </html>
  `;
  
  return sendEmail({
    to: user.email,
    subject: `Order Confirmed! #${order.id.substring(0, 8).toUpperCase()} - Kheti Sahayak`,
    html,
  });
};

/**
 * Send order status update email
 * @param {Object} order - Order details
 * @param {Object} user - User details
 * @param {string} newStatus - New order status
 */
const sendOrderStatusUpdate = async (order, user, newStatus) => {
  const statusMessages = {
    confirmed: {
      title: 'Order Confirmed',
      icon: '✅',
      message: 'Your order has been confirmed and is being prepared for shipping.',
      color: '#4CAF50',
    },
    shipped: {
      title: 'Order Shipped',
      icon: '🚚',
      message: 'Great news! Your order is on its way.',
      color: '#2196F3',
    },
    delivered: {
      title: 'Order Delivered',
      icon: '📦',
      message: 'Your order has been delivered. We hope you enjoy your purchase!',
      color: '#4CAF50',
    },
    cancelled: {
      title: 'Order Cancelled',
      icon: '❌',
      message: 'Your order has been cancelled. If you have any questions, please contact support.',
      color: '#F44336',
    },
  };
  
  const statusInfo = statusMessages[newStatus] || {
    title: 'Order Update',
    icon: '📋',
    message: `Your order status has been updated to: ${newStatus}`,
    color: '#FF9800',
  };
  
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${statusInfo.title}</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #4CAF50, #2E7D32); padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0;">🌾 Kheti Sahayak</h1>
      </div>
      
      <div style="background: #fff; padding: 30px; border: 1px solid #e0e0e0; border-top: none;">
        <div style="text-align: center; margin-bottom: 20px;">
          <span style="font-size: 48px;">${statusInfo.icon}</span>
          <h2 style="color: ${statusInfo.color}; margin: 10px 0;">${statusInfo.title}</h2>
        </div>
        
        <p>Dear ${user.first_name || user.username || 'Valued Customer'},</p>
        
        <p>${statusInfo.message}</p>
        
        <div style="background: #F1F8E9; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="margin: 0;"><strong>Order ID:</strong> #${order.id.substring(0, 8).toUpperCase()}</p>
          <p style="margin: 5px 0 0 0;"><strong>Status:</strong> <span style="color: ${statusInfo.color}; font-weight: bold;">${newStatus.toUpperCase()}</span></p>
        </div>
        
        ${newStatus === 'shipped' ? `
          <div style="background: #E3F2FD; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p style="margin: 0;"><strong>📍 Track Your Order</strong></p>
            <p style="margin: 10px 0 0 0;">You can track your shipment using the tracking number provided by our delivery partner.</p>
          </div>
        ` : ''}
        
        ${newStatus === 'delivered' ? `
          <div style="background: #FFF3E0; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p style="margin: 0;"><strong>⭐ Rate Your Experience</strong></p>
            <p style="margin: 10px 0 0 0;">We'd love to hear your feedback! Please rate your purchase in the app.</p>
          </div>
        ` : ''}
        
        <p style="margin-top: 30px;">
          Thank you for choosing Kheti Sahayak! 🌱<br>
          <strong>The Kheti Sahayak Team</strong>
        </p>
      </div>
      
      <div style="background: #f5f5f5; padding: 20px; text-align: center; border-radius: 0 0 10px 10px; font-size: 12px; color: #666;">
        <p style="margin: 0;">© ${new Date().getFullYear()} Kheti Sahayak. All rights reserved.</p>
      </div>
    </body>
    </html>
  `;
  
  return sendEmail({
    to: user.email,
    subject: `${statusInfo.icon} ${statusInfo.title} - Order #${order.id.substring(0, 8).toUpperCase()}`,
    html,
  });
};

/**
 * Send payment confirmation email
 * @param {Object} payment - Payment details
 * @param {Object} order - Order details
 * @param {Object} user - User details
 */
const sendPaymentConfirmation = async (payment, order, user) => {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Payment Confirmation</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #4CAF50, #2E7D32); padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0;">🌾 Kheti Sahayak</h1>
      </div>
      
      <div style="background: #fff; padding: 30px; border: 1px solid #e0e0e0; border-top: none;">
        <div style="text-align: center; margin-bottom: 20px;">
          <span style="font-size: 48px;">💳</span>
          <h2 style="color: #4CAF50; margin: 10px 0;">Payment Successful!</h2>
        </div>
        
        <p>Dear ${user.first_name || user.username || 'Valued Customer'},</p>
        
        <p>We've received your payment. Thank you for your purchase!</p>
        
        <div style="background: #E8F5E9; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center;">
          <p style="margin: 0; font-size: 14px; color: #666;">Amount Paid</p>
          <p style="margin: 5px 0 0 0; font-size: 32px; font-weight: bold; color: #2E7D32;">₹${(payment.amount / 100).toFixed(2)}</p>
        </div>
        
        <table style="width: 100%; margin: 20px 0;">
          <tr>
            <td style="padding: 8px 0; color: #666;">Payment ID:</td>
            <td style="padding: 8px 0; text-align: right;"><strong>${payment.razorpay_payment_id || payment.id}</strong></td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #666;">Order ID:</td>
            <td style="padding: 8px 0; text-align: right;"><strong>#${order.id.substring(0, 8).toUpperCase()}</strong></td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #666;">Date:</td>
            <td style="padding: 8px 0; text-align: right;"><strong>${new Date().toLocaleDateString('en-IN', { 
              year: 'numeric', 
              month: 'long', 
              day: 'numeric',
              hour: '2-digit',
              minute: '2-digit'
            })}</strong></td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #666;">Payment Method:</td>
            <td style="padding: 8px 0; text-align: right;"><strong>${payment.method || 'Online Payment'}</strong></td>
          </tr>
        </table>
        
        <div style="background: #FFF3E0; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="margin: 0;"><strong>📄 Need a Receipt?</strong></p>
          <p style="margin: 10px 0 0 0;">You can download your invoice from the order details page in the app.</p>
        </div>
        
        <p style="margin-top: 30px;">
          Thank you for your trust in us! 🌱<br>
          <strong>The Kheti Sahayak Team</strong>
        </p>
      </div>
      
      <div style="background: #f5f5f5; padding: 20px; text-align: center; border-radius: 0 0 10px 10px; font-size: 12px; color: #666;">
        <p style="margin: 0;">© ${new Date().getFullYear()} Kheti Sahayak. All rights reserved.</p>
      </div>
    </body>
    </html>
  `;
  
  return sendEmail({
    to: user.email,
    subject: `💳 Payment Received - ₹${(payment.amount / 100).toFixed(2)} - Kheti Sahayak`,
    html,
  });
};

/**
 * Send welcome email to new users
 * @param {Object} user - User details
 */
const sendWelcomeEmail = async (user) => {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Welcome to Kheti Sahayak</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #4CAF50, #2E7D32); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0; font-size: 28px;">🌾 Welcome to Kheti Sahayak!</h1>
        <p style="color: #E8F5E9; margin: 10px 0 0 0; font-size: 16px;">Your Agricultural Partner</p>
      </div>
      
      <div style="background: #fff; padding: 30px; border: 1px solid #e0e0e0; border-top: none;">
        <h2 style="color: #2E7D32; margin-top: 0;">Namaste, ${user.first_name || user.username || 'Farmer'}! 🙏</h2>
        
        <p>Welcome to the Kheti Sahayak family! We're thrilled to have you on board.</p>
        
        <p>Kheti Sahayak is your one-stop solution for all farming needs. Here's what you can do:</p>
        
        <div style="margin: 25px 0;">
          <div style="display: flex; align-items: center; margin: 15px 0; padding: 15px; background: #F1F8E9; border-radius: 8px;">
            <span style="font-size: 24px; margin-right: 15px;">🔬</span>
            <div>
              <strong style="color: #2E7D32;">AI Crop Diagnostics</strong>
              <p style="margin: 5px 0 0 0; font-size: 14px; color: #666;">Upload photos of your crops to detect diseases instantly</p>
            </div>
          </div>
          
          <div style="display: flex; align-items: center; margin: 15px 0; padding: 15px; background: #E3F2FD; border-radius: 8px;">
            <span style="font-size: 24px; margin-right: 15px;">🛒</span>
            <div>
              <strong style="color: #1976D2;">Marketplace</strong>
              <p style="margin: 5px 0 0 0; font-size: 14px; color: #666;">Buy quality seeds, fertilizers, and equipment</p>
            </div>
          </div>
          
          <div style="display: flex; align-items: center; margin: 15px 0; padding: 15px; background: #FFF3E0; border-radius: 8px;">
            <span style="font-size: 24px; margin-right: 15px;">🌤️</span>
            <div>
              <strong style="color: #F57C00;">Weather Forecasts</strong>
              <p style="margin: 5px 0 0 0; font-size: 14px; color: #666;">Get hyperlocal weather updates for your farm</p>
            </div>
          </div>
          
          <div style="display: flex; align-items: center; margin: 15px 0; padding: 15px; background: #F3E5F5; border-radius: 8px;">
            <span style="font-size: 24px; margin-right: 15px;">👨‍🌾</span>
            <div>
              <strong style="color: #7B1FA2;">Expert Consultation</strong>
              <p style="margin: 5px 0 0 0; font-size: 14px; color: #666;">Connect with agricultural experts for advice</p>
            </div>
          </div>
        </div>
        
        <div style="background: #E8F5E9; padding: 20px; border-radius: 8px; text-align: center; margin: 25px 0;">
          <p style="margin: 0; font-size: 16px;"><strong>🎁 Special Offer!</strong></p>
          <p style="margin: 10px 0 0 0;">Get <strong style="color: #2E7D32;">10% OFF</strong> on your first order!</p>
          <p style="margin: 10px 0 0 0; font-size: 14px; color: #666;">Use code: <strong style="background: #fff; padding: 5px 10px; border-radius: 4px;">WELCOME10</strong></p>
        </div>
        
        <p style="margin-top: 30px;">
          Happy Farming! 🌱<br>
          <strong>The Kheti Sahayak Team</strong>
        </p>
      </div>
      
      <div style="background: #f5f5f5; padding: 20px; text-align: center; border-radius: 0 0 10px 10px; font-size: 12px; color: #666;">
        <p style="margin: 0;">© ${new Date().getFullYear()} Kheti Sahayak. All rights reserved.</p>
        <p style="margin: 10px 0 0 0;">
          <a href="#" style="color: #4CAF50; text-decoration: none; margin: 0 10px;">Download App</a> | 
          <a href="#" style="color: #4CAF50; text-decoration: none; margin: 0 10px;">Help Center</a> | 
          <a href="#" style="color: #4CAF50; text-decoration: none; margin: 0 10px;">Contact Us</a>
        </p>
      </div>
    </body>
    </html>
  `;
  
  return sendEmail({
    to: user.email,
    subject: '🌾 Welcome to Kheti Sahayak - Your Agricultural Partner!',
    html,
  });
};

/**
 * Send password reset email
 * @param {Object} user - User details
 * @param {string} resetToken - Password reset token
 * @param {string} resetUrl - Password reset URL
 */
const sendPasswordResetEmail = async (user, resetToken, resetUrl) => {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Reset Your Password</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #4CAF50, #2E7D32); padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0;">🌾 Kheti Sahayak</h1>
      </div>
      
      <div style="background: #fff; padding: 30px; border: 1px solid #e0e0e0; border-top: none;">
        <h2 style="color: #2E7D32; margin-top: 0;">Reset Your Password 🔐</h2>
        
        <p>Dear ${user.first_name || user.username || 'User'},</p>
        
        <p>We received a request to reset your password. Click the button below to create a new password:</p>
        
        <div style="text-align: center; margin: 30px 0;">
          <a href="${resetUrl}" style="background: #4CAF50; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold; display: inline-block;">Reset Password</a>
        </div>
        
        <p style="color: #666; font-size: 14px;">Or copy and paste this link in your browser:</p>
        <p style="background: #f5f5f5; padding: 10px; border-radius: 4px; word-break: break-all; font-size: 12px;">${resetUrl}</p>
        
        <div style="background: #FFF3E0; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="margin: 0;"><strong>⚠️ Important:</strong></p>
          <ul style="margin: 10px 0 0 0; padding-left: 20px; font-size: 14px;">
            <li>This link will expire in 1 hour</li>
            <li>If you didn't request this, please ignore this email</li>
            <li>Your password won't change until you create a new one</li>
          </ul>
        </div>
        
        <p style="margin-top: 30px;">
          Stay safe! 🌱<br>
          <strong>The Kheti Sahayak Team</strong>
        </p>
      </div>
      
      <div style="background: #f5f5f5; padding: 20px; text-align: center; border-radius: 0 0 10px 10px; font-size: 12px; color: #666;">
        <p style="margin: 0;">© ${new Date().getFullYear()} Kheti Sahayak. All rights reserved.</p>
      </div>
    </body>
    </html>
  `;
  
  return sendEmail({
    to: user.email,
    subject: '🔐 Reset Your Password - Kheti Sahayak',
    html,
  });
};

module.exports = {
  sendEmail,
  sendOrderConfirmation,
  sendOrderStatusUpdate,
  sendPaymentConfirmation,
  sendWelcomeEmail,
  sendPasswordResetEmail,
};

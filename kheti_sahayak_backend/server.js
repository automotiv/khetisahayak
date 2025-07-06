const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const logger = require('./utils/logger');

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Import routes
const authRoutes = require('./routes/auth');
const weatherRoutes = require('./routes/weather');
const diagnosticsRoutes = require('./routes/diagnostics');
const marketplaceRoutes = require('./routes/marketplace');
const educationalContentRoutes = require('./routes/educationalContent');
const healthRoutes = require('./routes/health');
const orderRoutes = require('./routes/orders');
const notificationRoutes = require('./routes/notifications');
const { notFound, errorHandler } = require('./middleware/errorMiddleware');

// Middleware
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// HTTP request logger middleware
app.use((req, res, next) => {
  // Log an http message for each incoming request
  logger.http(`${req.method} ${req.url}`);
  next();
});

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/health', healthRoutes);
app.use('/api/weather', weatherRoutes);
app.use('/api/diagnostics', diagnosticsRoutes);
app.use('/api/marketplace', marketplaceRoutes);
app.use('/api/educational-content', educationalContentRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/notifications', notificationRoutes);

app.get('/', (req, res) => {
  res.json({
    message: 'Kheti Sahayak Backend API',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      auth: '/api/auth',
      health: '/api/health',
      weather: '/api/weather',
      diagnostics: '/api/diagnostics',
      marketplace: '/api/marketplace',
      educationalContent: '/api/educational-content',
      orders: '/api/orders',
      notifications: '/api/notifications'
    }
  });
});

// Error Handling Middleware
app.use(notFound);
app.use(errorHandler);

app.listen(port, () => {
  logger.info(`Server running on port ${port}`);
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
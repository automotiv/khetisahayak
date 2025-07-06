const express = require('express');
const dotenv = require('dotenv');
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
const { notFound, errorHandler } = require('./middleware/errorMiddleware');

app.use(express.json());

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

app.get('/', (req, res) => {
  res.send('Kheti Sahayak Backend is running!');
});

// Error Handling Middleware
app.use(notFound);
app.use(errorHandler);

app.listen(port, () => {
  logger.info(`Server running on port ${port}`);
});
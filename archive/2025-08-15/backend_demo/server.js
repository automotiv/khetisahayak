const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Kheti Sahayak Backend is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// API endpoints
app.get('/api/crops', (req, res) => {
  res.json({
    success: true,
    data: [
      { id: 1, name: 'Rice', season: 'Kharif', duration: '120-150 days' },
      { id: 2, name: 'Wheat', season: 'Rabi', duration: '120-130 days' },
      { id: 3, name: 'Maize', season: 'Kharif', duration: '90-120 days' },
      { id: 4, name: 'Cotton', season: 'Kharif', duration: '180-200 days' }
    ]
  });
});

app.get('/api/products', (req, res) => {
  res.json({
    success: true,
    data: [
      { 
        id: 1, 
        name: 'Organic Fertilizer', 
        category: 'Fertilizer', 
        price: 500, 
        unit: 'kg',
        description: 'High-quality organic fertilizer for better crop yield'
      },
      { 
        id: 2, 
        name: 'Pesticide Spray', 
        category: 'Pesticide', 
        price: 300, 
        unit: 'liter',
        description: 'Effective pesticide for crop protection'
      },
      { 
        id: 3, 
        name: 'Seeds - Hybrid Rice', 
        category: 'Seeds', 
        price: 200, 
        unit: 'kg',
        description: 'High yield hybrid rice seeds'
      }
    ]
  });
});

app.get('/api/weather', (req, res) => {
  res.json({
    success: true,
    data: {
      location: 'Delhi, India',
      temperature: 28,
      humidity: 65,
      rainfall: 0,
      weather: 'Partly Cloudy',
      forecast: [
        { day: 'Today', temp: 28, weather: 'Partly Cloudy' },
        { day: 'Tomorrow', temp: 30, weather: 'Sunny' },
        { day: 'Day After', temp: 26, weather: 'Rainy' }
      ]
    }
  });
});

// Catch all route
app.get('*', (req, res) => {
  res.json({ 
    message: 'Kheti Sahayak API', 
    version: '1.0.0',
    endpoints: [
      'GET /health - Health check',
      'GET /api/crops - Get crop information',
      'GET /api/products - Get marketplace products',
      'GET /api/weather - Get weather information'
    ]
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    success: false, 
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal Server Error'
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Kheti Sahayak Backend running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

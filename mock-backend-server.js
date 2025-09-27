#!/usr/bin/env node

/**
 * Mock Backend Server for Kheti Sahayak MVP Testing
 * Simulates Spring Boot API endpoints for comprehensive testing
 * Implements CodeRabbit testing standards for agricultural platform validation
 */

const express = require('express');
const cors = require('cors');
const multer = require('multer');
const jwt = require('jsonwebtoken');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 8080;
const JWT_SECRET = 'khetisahayak-agricultural-platform-jwt-secret-key-for-farmer-authentication';

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Mock data storage
const users = new Map();
const products = new Map();
const otpStorage = new Map();
let productIdCounter = 1;
let userIdCounter = 1;

// File upload configuration
const upload = multer({
    dest: 'uploads/',
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    },
    fileFilter: (req, file, cb) => {
        const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only JPEG and PNG images are allowed.'));
        }
    }
});

// Utility functions
function generateJWT(userId, userType) {
    return jwt.sign(
        { userId, userType, exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60) },
        JWT_SECRET
    );
}

function verifyJWT(token) {
    try {
        return jwt.verify(token, JWT_SECRET);
    } catch (error) {
        return null;
    }
}

function generateOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

// Authentication middleware
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    const decoded = verifyJWT(token);
    if (!decoded) {
        return res.status(403).json({ error: 'Invalid or expired token' });
    }

    req.user = decoded;
    next();
}

// Health Check Endpoint
app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'Kheti Sahayak API',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// Authentication Endpoints
app.post('/api/auth/register', (req, res) => {
    const { mobileNumber, fullName, primaryCrop, state, district, farmSize } = req.query;
    
    if (!mobileNumber || !fullName) {
        return res.status(400).json({ error: 'Mobile number and name are required' });
    }

    // Generate and store OTP
    const otp = generateOTP();
    otpStorage.set(mobileNumber, {
        otp,
        userData: { mobileNumber, fullName, primaryCrop, state, district, farmSize },
        expires: Date.now() + (5 * 60 * 1000) // 5 minutes
    });

    console.log(`📱 OTP for ${mobileNumber}: ${otp}`);

    res.json({
        message: 'OTP sent successfully',
        mobileNumber,
        otpExpiry: 5
    });
});

app.post('/api/auth/verify-otp', (req, res) => {
    const { mobileNumber, otp } = req.query;
    
    const otpData = otpStorage.get(mobileNumber);
    if (!otpData || otpData.expires < Date.now()) {
        return res.status(400).json({ error: 'OTP expired or invalid' });
    }

    if (otpData.otp !== otp && otp !== '123456') { // Allow test OTP
        return res.status(400).json({ error: 'Invalid OTP' });
    }

    // Create user
    const userId = userIdCounter++;
    const user = {
        id: userId,
        ...otpData.userData,
        userType: 'FARMER',
        isVerified: true,
        createdAt: new Date().toISOString()
    };

    users.set(userId, user);
    otpStorage.delete(mobileNumber);

    const token = generateJWT(userId, 'FARMER');

    res.json({
        message: 'Registration successful',
        token,
        user: {
            id: user.id,
            fullName: user.fullName,
            mobileNumber: user.mobileNumber,
            userType: user.userType
        }
    });
});

app.post('/api/auth/login', (req, res) => {
    const { mobileNumber } = req.query;
    
    // Find user by mobile number
    const user = Array.from(users.values()).find(u => u.mobileNumber === mobileNumber);
    if (!user) {
        return res.status(404).json({ error: 'User not found' });
    }

    // Generate and store OTP
    const otp = generateOTP();
    otpStorage.set(mobileNumber, {
        otp,
        userId: user.id,
        expires: Date.now() + (5 * 60 * 1000)
    });

    console.log(`📱 Login OTP for ${mobileNumber}: ${otp}`);

    res.json({
        message: 'Login OTP sent successfully',
        mobileNumber
    });
});

app.post('/api/auth/verify-login', (req, res) => {
    const { mobileNumber, otp } = req.query;
    
    const otpData = otpStorage.get(mobileNumber);
    if (!otpData || otpData.expires < Date.now()) {
        return res.status(400).json({ error: 'OTP expired or invalid' });
    }

    if (otpData.otp !== otp && otp !== '123456') { // Allow test OTP
        return res.status(400).json({ error: 'Invalid OTP' });
    }

    const user = users.get(otpData.userId);
    const token = generateJWT(user.id, user.userType);

    otpStorage.delete(mobileNumber);

    res.json({
        message: 'Login successful',
        token,
        user: {
            id: user.id,
            fullName: user.fullName,
            mobileNumber: user.mobileNumber,
            userType: user.userType
        }
    });
});

app.get('/api/auth/profile', authenticateToken, (req, res) => {
    const user = users.get(req.user.userId);
    if (!user) {
        return res.status(404).json({ error: 'User not found' });
    }

    res.json({
        user: {
            id: user.id,
            fullName: user.fullName,
            mobileNumber: user.mobileNumber,
            userType: user.userType,
            primaryCrop: user.primaryCrop,
            state: user.state,
            district: user.district,
            farmSize: user.farmSize
        }
    });
});

// Weather Endpoints
app.get('/api/weather', (req, res) => {
    const { lat, lon } = req.query;
    
    const weatherData = {
        latitude: parseFloat(lat),
        longitude: parseFloat(lon),
        timestamp: new Date().toISOString(),
        source: 'mock_data',
        temperature: 28.5,
        feelsLike: 31.2,
        humidity: 72,
        pressure: 1008.5,
        temperatureMin: 24.0,
        temperatureMax: 32.0,
        description: 'Partly cloudy with chance of rain',
        main: 'Clouds',
        windSpeed: 8.5,
        windDirection: 210,
        visibility: 8000,
        rainfall1h: 0.5,
        rainfall3h: 1.2,
        cloudCoverage: 65,
        agriculturalInsights: {
            cropSuitability: {
                rice: 'Excellent conditions for rice cultivation',
                sugarcane: 'Good conditions for sugarcane growth'
            },
            irrigationAdvice: [
                'Light to moderate rainfall - reduce irrigation'
            ],
            pestAlerts: [
                'High humidity may increase fungal disease risk'
            ],
            farmingActivities: [
                'Good weather for harvesting operations'
            ]
        }
    };

    res.json(weatherData);
});

app.get('/api/weather/forecast', (req, res) => {
    const { lat, lon } = req.query;
    
    const forecast = [];
    for (let i = 0; i < 5; i++) {
        const date = new Date();
        date.setDate(date.getDate() + i);
        
        forecast.push({
            date: date.toISOString(),
            temperature: 26 + (Math.random() * 8),
            humidity: 60 + (Math.random() * 30),
            description: i % 2 === 0 ? 'Sunny' : 'Partly cloudy',
            windSpeed: 5 + (Math.random() * 10)
        });
    }

    res.json({
        latitude: parseFloat(lat),
        longitude: parseFloat(lon),
        timestamp: new Date().toISOString(),
        source: 'mock_data',
        forecast,
        forecastDays: forecast.length,
        farmingRecommendations: {
            weeklyCalendar: [
                'Monday-Tuesday: Good for land preparation and sowing',
                'Wednesday-Thursday: Suitable for irrigation and fertilizer application'
            ],
            season: 'Kharif',
            seasonalAdvice: [
                'Monsoon season - focus on rice, cotton, sugarcane cultivation'
            ]
        }
    });
});

app.get('/api/weather/alerts', (req, res) => {
    const { lat, lon } = req.query;
    
    const alerts = [
        {
            type: 'HEAVY_RAINFALL',
            severity: 'MEDIUM',
            title: 'Heavy Rain Alert',
            message: 'Heavy rainfall expected. Prepare for waterlogging.',
            recommendations: [
                'Ensure proper field drainage',
                'Postpone harvesting operations'
            ]
        }
    ];

    res.json({
        alerts,
        alertCount: alerts.length,
        latitude: parseFloat(lat),
        longitude: parseFloat(lon),
        timestamp: new Date().toISOString()
    });
});

// ML/Diagnostics Endpoints
app.get('/api/diagnostics/model-info', (req, res) => {
    res.json({
        model_name: 'Kheti Sahayak Crop Disease Detection Model',
        version: '1.0.0',
        serviceStatus: 'healthy',
        supportedCrops: ['Rice', 'Wheat', 'Cotton', 'Sugarcane'],
        lastUpdated: new Date().toISOString(),
        accuracy: '95.2%'
    });
});

app.post('/api/diagnostics/upload', upload.single('image'), authenticateToken, (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'Image file is required' });
    }

    const { cropType, symptoms, latitude, longitude } = req.body;

    // Mock ML prediction
    const diseases = ['Leaf Spot', 'Blight', 'Rust', 'Healthy'];
    const randomDisease = diseases[Math.floor(Math.random() * diseases.length)];
    const confidence = 0.7 + Math.random() * 0.3;

    const diagnosis = {
        diagnosisId: Date.now().toString(),
        status: 'completed',
        cropType,
        symptoms,
        location: { latitude, longitude },
        imageUrl: `/uploads/${req.file.filename}`,
        diagnosis: {
            disease: randomDisease,
            confidence: Math.round(confidence * 100),
            severity: confidence > 0.8 ? 'high' : 'medium',
            recommendations: [
                'Apply appropriate fungicide',
                'Improve field drainage',
                'Monitor crop regularly'
            ]
        },
        mlPrediction: {
            predictions: [
                { disease: randomDisease, confidence }
            ]
        },
        expertReviewRecommended: confidence < 0.8,
        timestamp: new Date().toISOString()
    };

    res.json(diagnosis);
});

// Marketplace Endpoints
app.post('/api/marketplace/products', authenticateToken, (req, res) => {
    const {
        name, description, category, pricePerUnit, availableQuantity,
        qualityGrade, isOrganicCertified, variety, season
    } = req.body;

    const user = users.get(req.user.userId);
    const productId = productIdCounter++;

    const product = {
        id: productId,
        name,
        description,
        category,
        pricePerUnit,
        availableQuantity,
        qualityGrade,
        isOrganicCertified: isOrganicCertified || false,
        variety,
        season,
        seller: {
            id: user.id,
            name: user.fullName,
            location: `${user.district}, ${user.state}`
        },
        status: 'ACTIVE',
        createdAt: new Date().toISOString()
    };

    products.set(productId, product);

    res.json({
        message: 'Product listed successfully',
        productId,
        product
    });
});

app.get('/api/marketplace/products', (req, res) => {
    const {
        page = 0, size = 20, category, state, search,
        minPrice, maxPrice, organic, delivery
    } = req.query;

    let filteredProducts = Array.from(products.values());

    // Apply filters
    if (category) {
        filteredProducts = filteredProducts.filter(p => p.category === category);
    }
    if (search) {
        filteredProducts = filteredProducts.filter(p => 
            p.name.toLowerCase().includes(search.toLowerCase()) ||
            p.description.toLowerCase().includes(search.toLowerCase())
        );
    }
    if (organic === 'true') {
        filteredProducts = filteredProducts.filter(p => p.isOrganicCertified);
    }

    // Pagination
    const startIndex = page * size;
    const endIndex = startIndex + parseInt(size);
    const paginatedProducts = filteredProducts.slice(startIndex, endIndex);

    res.json({
        products: paginatedProducts,
        totalElements: filteredProducts.length,
        totalPages: Math.ceil(filteredProducts.length / size),
        currentPage: parseInt(page),
        pageSize: parseInt(size)
    });
});

app.get('/api/marketplace/products/:id', (req, res) => {
    const productId = parseInt(req.params.id);
    const product = products.get(productId);

    if (!product) {
        return res.status(404).json({ error: 'Product not found' });
    }

    res.json(product);
});

app.get('/api/marketplace/categories', (req, res) => {
    const categories = {
        CROPS: { name: 'Crops & Grains', productCount: 25 },
        VEGETABLES: { name: 'Vegetables', productCount: 18 },
        FRUITS: { name: 'Fruits', productCount: 12 },
        SEEDS: { name: 'Seeds & Seedlings', productCount: 30 },
        FERTILIZERS: { name: 'Fertilizers', productCount: 15 },
        TOOLS: { name: 'Farm Tools & Equipment', productCount: 8 }
    };

    res.json({ categories });
});

// Location-based product search
app.get('/api/marketplace/products/near', (req, res) => {
    const { latitude, longitude, radiusKm } = req.query;
    
    const nearbyProducts = [
        {
            id: 1,
            name: 'Local Fresh Tomatoes',
            category: 'VEGETABLES',
            price: 25.50,
            distance: 2.5,
            seller: { name: 'Local Farmer', location: 'Nearby Village' }
        },
        {
            id: 2,
            name: 'Organic Rice',
            category: 'CROPS', 
            price: 65.00,
            distance: 5.2,
            seller: { name: 'Organic Farm', location: 'Within Region' }
        }
    ];
    
    res.json({
        products: nearbyProducts,
        searchLocation: { latitude: parseFloat(latitude), longitude: parseFloat(longitude) },
        radiusKm: parseFloat(radiusKm),
        totalElements: nearbyProducts.length
    });
});

// Swagger/API Documentation
app.get('/api/swagger-ui', (req, res) => {
    res.json({
        message: 'Kheti Sahayak API Documentation',
        version: '1.0.0',
        endpoints: {
            authentication: [
                'POST /api/auth/register',
                'POST /api/auth/verify-otp',
                'POST /api/auth/login',
                'POST /api/auth/verify-login',
                'GET /api/auth/profile'
            ],
            weather: [
                'GET /api/weather',
                'GET /api/weather/forecast',
                'GET /api/weather/alerts'
            ],
            diagnostics: [
                'GET /api/diagnostics/model-info',
                'POST /api/diagnostics/upload'
            ],
            marketplace: [
                'POST /api/marketplace/products',
                'GET /api/marketplace/products',
                'GET /api/marketplace/products/:id',
                'GET /api/marketplace/categories'
            ]
        }
    });
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Error:', error.message);
    res.status(500).json({ 
        error: 'Internal server error',
        message: error.message,
        timestamp: new Date().toISOString()
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🌾 Kheti Sahayak Mock Backend Server running on port ${PORT}`);
    console.log(`🔗 API Base URL: http://localhost:${PORT}`);
    console.log(`📚 API Documentation: http://localhost:${PORT}/api/swagger-ui`);
    console.log(`💚 Health Check: http://localhost:${PORT}/api/health`);
    console.log('\n🚀 Ready for testing all MVP features!');
});

module.exports = app;

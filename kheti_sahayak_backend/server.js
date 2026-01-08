// Load environment variables FIRST before any other imports
const dotenv = require('dotenv');
dotenv.config();

const express = require('express');
const cors = require('cors');
// const swaggerUi = require('swagger-ui-express');
const logger = require('./utils/logger');
// const swaggerSpecs = require('./swagger');

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
const ingestionRoutes = require('./routes/ingestion');
const reviewsRoutes = require('./routes/reviews');
const cartRoutes = require('./routes/cart');
const paymentRoutes = require('./routes/payments');
const equipmentRoutes = require('./routes/equipment');
const technologyRoutes = require('./routes/technology');
const appConfigRoutes = require('./routes/app_config');
const expertRoutes = require('./routes/experts');
const communityRoutes = require('./routes/community');
const schemeRoutes = require('./routes/schemes');
const logbookRoutes = require('./routes/logbook');
const externalApiRoutes = require('./routes/external_apis');
const newsRoutes = require('./routes/news'); // Added news routes
const marketPriceRoutes = require('./routes/market_prices'); // Added market prices
const { notFound, errorHandler } = require('./middleware/errorMiddleware');

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// HTTP request logger middleware
app.use((req, res, next) => {
    // Log an http message for each incoming request
    logger.http(`${req.method} ${req.url}`);
    next();
});

// Swagger UI
// app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpecs, {
//   customCss: '.swagger-ui .topbar { display: none }',
//   customSiteTitle: 'Kheti Sahayak API Documentation'
// }));

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/health', healthRoutes);
app.use('/api/weather', weatherRoutes);
app.use('/api/diagnostics', diagnosticsRoutes);
app.use('/api/marketplace', marketplaceRoutes);
app.use('/api/educational-content', educationalContentRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/ingestion', ingestionRoutes);
app.use('/api/reviews', reviewsRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/equipment', equipmentRoutes);
app.use('/api/technology', technologyRoutes);
app.use('/api/app-config', appConfigRoutes);
app.use('/api/experts', expertRoutes);
app.use('/api/community', communityRoutes);
app.use('/api/schemes', schemeRoutes);
app.use('/api/logbook', logbookRoutes);
app.use('/api/news', newsRoutes); // Added news endpoint
app.use('/api/market-prices', marketPriceRoutes); // Added market prices endpoint
app.use('/api/external', externalApiRoutes);

app.get('/', (req, res) => {
    res.json({
        message: 'Kheti Sahayak Backend API',
        version: '1.0.0',
        status: 'running',
        documentation: '/api-docs',
        endpoints: {
            auth: '/api/auth',
            health: '/api/health',
            weather: '/api/weather',
            diagnostics: '/api/diagnostics',
            marketplace: '/api/marketplace',
            educationalContent: '/api/educational-content',
            orders: '/api/orders',
            notifications: '/api/notifications',
            reviews: '/api/reviews',
            cart: '/api/cart',
            payments: '/api/payments',
            equipment: '/api/equipment',
            technology: '/api/technology',
            external: '/api/external (agro-weather, soil-data, market-prices, news, crop-calendar, pest-alerts)'
        }
    });
});

// Error Handling Middleware
app.use(notFound);
app.use(errorHandler);

const runStartupTasks = async () => {
    if (process.env.NODE_ENV === 'production') {
        const { exec } = require('child_process');
        const db = require('./db');
        
        try {
            logger.info('Running database migrations...');
            await new Promise((resolve) => {
                exec('npm run migrate:up', { cwd: __dirname }, (error, stdout, stderr) => {
                    if (error) {
                        logger.error(`Migration error: ${error.message}`);
                    } else {
                        logger.info(`Migrations completed: ${stdout}`);
                    }
                    resolve();
                });
            });
        } catch (err) {
            logger.error(`Migration failed: ${err.message}`);
        }
        
        try {
            const result = await db.query('SELECT COUNT(*) FROM users');
            const userCount = parseInt(result.rows[0].count);
            
            if (userCount === 0) {
                logger.info('Database empty, running seed data...');
                const seedData = require('./seedData');
                await seedData();
                logger.info('Seed data completed successfully');
            } else {
                logger.info(`Database already has ${userCount} users, skipping seed`);
            }
        } catch (err) {
            logger.error(`Seed check/run failed: ${err.message}`);
        }
    }
};

runStartupTasks().then(() => {
    app.listen(port, () => {
        logger.info(`Server running on port ${port}`);
        logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
});

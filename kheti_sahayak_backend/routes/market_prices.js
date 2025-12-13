const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const redisClient = require('../redisClient');

const router = express.Router();

/**
 * @swagger
 * /api/market-prices:
 *   get:
 *     summary: Get mandi prices for commodities
 *     tags: [Marketplace]
 *     parameters:
 *       - in: query
 *         name: state
 *         schema:
 *           type: string
 *         description: State name (e.g., Maharashtra)
 *       - in: query
 *         name: commodity
 *         schema:
 *           type: string
 *         description: Commodity name (e.g., Onion)
 *     responses:
 *       200:
 *         description: List of market prices
 */
router.get('/', async (req, res) => {
    const { state = 'Maharashtra', commodity } = req.query;
    const cacheKey = `mandi:${state}:${commodity || 'all'}`;

    // 1. Try Cache
    try {
        const cachedData = await redisClient.get(cacheKey);
        if (cachedData) {
            console.log('Serving mandi prices from Redis cache');
            return res.json(JSON.parse(cachedData));
        }
    } catch (err) {
        console.error('Redis error:', err);
    }

    // 2. Fetch Data (Scraping Fallback since API key might be missing)
    // We will try to scrape a reliable source or use a free endpoint if found.
    // For robustness, we will create a mock generator that mimics real Indian mandi data
    // because relying on a specific HTML structure of a gov site is fragile for a demo.

    // Real implementation note: You would use data.gov.in API Key here.
    // URL: https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070?api-key=YOUR_KEY&format=json&limit=10

    try {
        // Generating realistic mock data for the demo
        // In production, replace this block with actual API call or scraper
        const commodities = commodity ? [commodity] : ['Tomato', 'Onion', 'Potato', 'Wheat', 'Rice', 'Soybean', 'Cotton'];
        const markets = ['Nashik', 'Pune', 'Mumbai', 'Nagpur', 'Aurangabad'];

        const realData = commodities.flatMap(comm => {
            return markets.map(mkt => {
                // Randomize price slightly around a base price
                const basePrice = getBasePrice(comm);
                const variance = Math.floor(Math.random() * (basePrice * 0.2)); // 20% variance
                const minPrice = basePrice - variance;
                const maxPrice = basePrice + variance;
                const modalPrice = Math.floor((minPrice + maxPrice) / 2);

                return {
                    id: `${mkt}-${comm}-${Date.now()}`,
                    state: state,
                    district: mkt, // Simplified
                    market: `${mkt} APMC`,
                    commodity: comm,
                    variety: 'Common',
                    min_price: minPrice,
                    max_price: maxPrice,
                    modal_price: modalPrice,
                    arrival_date: new Date().toISOString().split('T')[0]
                };
            });
        });

        const responseData = {
            success: true,
            source: 'Mandi Prices (Simulated for Demo)',
            updated_at: new Date().toISOString(),
            data: realData
        };

        // Cache for 12 hours
        await redisClient.setex(cacheKey, 43200, JSON.stringify(responseData));

        res.json(responseData);

    } catch (error) {
        console.error('Error fetching market prices:', error);
        res.status(500).json({ success: false, error: 'Failed to fetch market prices' });
    }
});

function getBasePrice(commodity) {
    const prices = {
        'Tomato': 2500, // per quintal
        'Onion': 1800,
        'Potato': 1500,
        'Wheat': 2200,
        'Rice': 3000,
        'Soybean': 4500,
        'Cotton': 6000
    };
    return prices[commodity] || 2000;
}

module.exports = router;

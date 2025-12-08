const express = require('express');
const Parser = require('rss-parser');
const redisClient = require('../redisClient');

const router = express.Router();
const parser = new Parser();

const RSS_FEEDS = [
    {
        name: 'Google News - Agriculture',
        url: 'https://news.google.com/rss/search?q=Agriculture+India&hl=en-IN&gl=IN&ceid=IN:en'
    },
    // Add more feeds here if needed
    // { name: 'Times of India', url: 'https://timesofindia.indiatimes.com/rssfeeds/4719161.cms' } 
];

/**
 * @swagger
 * /api/news:
 *   get:
 *     summary: Get latest agricultural news
 *     tags: [News]
 *     responses:
 *       200:
 *         description: List of news articles
 */
router.get('/', async (req, res) => {
    try {
        const cacheKey = 'news:agriculture';

        // Check Redis Cache (1 hour expiry)
        const cachedNews = await redisClient.get(cacheKey);
        if (cachedNews) {
            console.log('Serving news from Redis cache');
            return res.json(JSON.parse(cachedNews));
        }

        // Fetch and Parse
        // For now, just taking the first feed, but could aggregate
        const feed = await parser.parseURL(RSS_FEEDS[0].url);

        const articles = feed.items.slice(0, 15).map(item => ({
            id: item.guid || item.link,
            title: item.title,
            link: item.link,
            pubDate: item.pubDate,
            content: item.contentSnippet || item.content,
            source: item.source || 'Google News',
            imageUrl: null // RSS often doesn't have images easily extractable without scraping
        }));

        const result = {
            success: true,
            source: 'Aggregated Public Feeds',
            count: articles.length,
            data: articles
        };

        // Cache for 1 hour
        await redisClient.setex(cacheKey, 3600, JSON.stringify(result));

        res.json(result);

    } catch (error) {
        console.error('Error fetching news:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch news'
        });
    }
});

module.exports = router;

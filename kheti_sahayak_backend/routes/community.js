const express = require('express');
const router = express.Router();
const db = require('../db');

/**
 * @swagger
 * tags:
 *   name: Community
 *   description: Community forum endpoints
 */

/**
 * @swagger
 * /api/community/posts:
 *   get:
 *     summary: Get community posts
 *     tags: [Community]
 *     responses:
 *       200:
 *         description: List of community posts
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: integer
 *                       user_name:
 *                         type: string
 *                       content:
 *                         type: string
 *                       likes:
 *                         type: integer
 *                       comments_count:
 *                         type: integer
 *                       timestamp:
 *                         type: string
 *                         format: date-time
 */
router.get('/posts', async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM community_posts ORDER BY timestamp DESC');
        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Error fetching community posts:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching community posts'
        });
    }
});

/**
 * @swagger
 * /api/community/posts:
 *   post:
 *     summary: Create a new post
 *     tags: [Community]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - user_name
 *               - content
 *             properties:
 *               user_name:
 *                 type: string
 *               content:
 *                 type: string
 *               image_url:
 *                 type: string
 *     responses:
 *       201:
 *         description: Post created
 */
router.post('/posts', async (req, res) => {
    try {
        const { user_name, content, image_url } = req.body;

        if (!user_name || !content) {
            return res.status(400).json({
                success: false,
                message: 'User name and content are required'
            });
        }

        const result = await db.query(
            'INSERT INTO community_posts (user_name, content, image_url) VALUES ($1, $2, $3) RETURNING *',
            [user_name, content, image_url]
        );

        res.status(201).json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error creating post:', error);
        res.status(500).json({
            success: false,
            message: 'Server error creating post'
        });
    }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const db = require('../db');

/**
 * @swagger
 * tags:
 *   name: AppConfig
 *   description: Mobile app configuration endpoints
 */

/**
 * @swagger
 * /api/app-config/menu:
 *   get:
 *     summary: Get mobile app menu items
 *     tags: [AppConfig]
 *     responses:
 *       200:
 *         description: List of menu items
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 menu:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: integer
 *                       label:
 *                         type: string
 *                       icon_name:
 *                         type: string
 *                       route_id:
 *                         type: string
 *                       display_order:
 *                         type: integer
 */
router.get('/menu', async (req, res) => {
    try {
        const result = await db.query(
            'SELECT * FROM app_menu_items WHERE is_active = true ORDER BY display_order ASC'
        );

        res.json({
            success: true,
            menu: result.rows
        });
    } catch (error) {
        console.error('Error fetching menu items:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching menu items'
        });
    }
});

module.exports = router;

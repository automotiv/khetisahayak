const express = require('express');
const router = express.Router();
const db = require('../db');

/**
 * @swagger
 * tags:
 *   name: Schemes
 *   description: Government schemes information
 */

/**
 * @swagger
 * /api/schemes:
 *   get:
 *     summary: Get all government schemes
 *     tags: [Schemes]
 *     responses:
 *       200:
 *         description: List of schemes
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
 *                       name:
 *                         type: string
 *                       description:
 *                         type: string
 *                       benefits:
 *                         type: string
 *                       eligibility:
 *                         type: string
 */
router.get('/', async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM schemes WHERE active = true ORDER BY created_at DESC');
        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Error fetching schemes:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching schemes'
        });
    }
});

/**
 * @swagger
 * /api/schemes/{id}:
 *   get:
 *     summary: Get scheme details
 *     tags: [Schemes]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Scheme details
 *       404:
 *         description: Scheme not found
 */
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await db.query('SELECT * FROM schemes WHERE id = $1', [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Scheme not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error fetching scheme details:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching scheme details'
        });
    }
});

module.exports = router;

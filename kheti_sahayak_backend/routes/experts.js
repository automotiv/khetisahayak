const express = require('express');
const router = express.Router();
const db = require('../db');

/**
 * @swagger
 * tags:
 *   name: Experts
 *   description: Expert consultation endpoints
 */

/**
 * @swagger
 * /api/experts:
 *   get:
 *     summary: Get all experts
 *     tags: [Experts]
 *     responses:
 *       200:
 *         description: List of experts
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
 *                       specialization:
 *                         type: string
 *                       qualification:
 *                         type: string
 *                       experience_years:
 *                         type: integer
 *                       rating:
 *                         type: number
 *                       is_online:
 *                         type: boolean
 */
router.get('/', async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM experts ORDER BY is_online DESC, rating DESC');
        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Error fetching experts:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching experts'
        });
    }
});

/**
 * @swagger
 * /api/experts/{id}:
 *   get:
 *     summary: Get expert details
 *     tags: [Experts]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Expert details
 *       404:
 *         description: Expert not found
 */
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await db.query('SELECT * FROM experts WHERE id = $1', [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Expert not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error fetching expert details:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching expert details'
        });
    }
});

module.exports = router;

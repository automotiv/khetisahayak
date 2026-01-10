const express = require('express');
const router = express.Router();
const db = require('../db');
const { schemeQueryValidation, validateIdParam } = require('../middleware/validationMiddleware');

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
router.get('/', schemeQueryValidation, async (req, res) => {
    try {
        const {
            farm_size,
            crop,
            state,
            district,
            income,
            land_ownership
        } = req.query;

        let query = 'SELECT * FROM schemes WHERE active = true';
        const params = [];
        let paramIndex = 1;

        if (farm_size) {
            query += ` AND (min_farm_size IS NULL OR min_farm_size <= $${paramIndex}) AND (max_farm_size IS NULL OR max_farm_size >= $${paramIndex})`;
            params.push(parseFloat(farm_size));
            paramIndex++;
        }

        if (crop) {
            // Check if crop is in the crops JSON array or if crops is null (all crops)
            query += ` AND (crops IS NULL OR crops::jsonb ? $${paramIndex})`;
            params.push(crop);
            paramIndex++;
        }

        if (state) {
            query += ` AND (states IS NULL OR states::jsonb ? $${paramIndex})`;
            params.push(state);
            paramIndex++;
        }

        if (district) {
            query += ` AND (districts IS NULL OR districts::jsonb ? $${paramIndex})`;
            params.push(district);
            paramIndex++;
        }

        if (income) {
            query += ` AND (min_income IS NULL OR min_income <= $${paramIndex}) AND (max_income IS NULL OR max_income >= $${paramIndex})`;
            params.push(parseFloat(income));
            paramIndex++;
        }

        if (land_ownership) {
            query += ` AND (land_ownership_type IS NULL OR land_ownership_type = $${paramIndex})`;
            params.push(land_ownership);
            paramIndex++;
        }

        query += ' ORDER BY created_at DESC';

        const result = await db.query(query, params);
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
router.get('/:id', validateIdParam, async (req, res) => {
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

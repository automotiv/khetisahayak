const express = require('express');
const router = express.Router();
const db = require('../db');
const { protect } = require('../middleware/authMiddleware');
const { logbookEntryValidation, validateIdParam, validatePagination, handleValidationErrors } = require('../middleware/validationMiddleware');

/**
 * @swagger
 * tags:
 *   name: Logbook
 *   description: Digital farm logbook operations
 */

/**
 * @swagger
 * /api/logbook:
 *   get:
 *     summary: Get user's logbook entries
 *     tags: [Logbook]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of logbook entries
 */
router.get('/', protect, [...validatePagination, handleValidationErrors], async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const offset = (page - 1) * limit;
        
        const result = await db.query(
            'SELECT * FROM logbook WHERE user_id = $1 ORDER BY date DESC, created_at DESC LIMIT $2 OFFSET $3',
            [req.user.id, limit, offset]
        );
        res.json({
            success: true,
            data: result.rows,
            pagination: { page, limit }
        });
    } catch (error) {
        console.error('Error fetching logbook entries:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching logbook entries'
        });
    }
});

/**
 * @swagger
 * /api/logbook:
 *   post:
 *     summary: Create a new logbook entry
 *     tags: [Logbook]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - activity_type
 *               - date
 *             properties:
 *               activity_type:
 *                 type: string
 *               date:
 *                 type: string
 *                 format: date
 *               description:
 *                 type: string
 *               cost:
 *                 type: number
 *               income:
 *                 type: number
 *     responses:
 *       201:
 *         description: Entry created
 */
router.post('/', protect, logbookEntryValidation, async (req, res) => {
    try {
        const { activity_type, date, description, cost, income } = req.body;

        const result = await db.query(
            `INSERT INTO logbook (user_id, activity_type, date, description, cost, income)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
            [req.user.id, activity_type, date, description, cost || 0, income || 0]
        );

        res.status(201).json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error creating logbook entry:', error);
        res.status(500).json({
            success: false,
            message: 'Server error creating logbook entry'
        });
    }
});

/**
 * @swagger
 * /api/logbook/{id}:
 *   delete:
 *     summary: Delete a logbook entry
 *     tags: [Logbook]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Entry deleted
 *       404:
 *         description: Entry not found
 */
router.delete('/:id', protect, validateIdParam, async (req, res) => {
    try {
        const { id } = req.params;

        const result = await db.query(
            'DELETE FROM logbook WHERE id = $1 AND user_id = $2 RETURNING id',
            [id, req.user.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Entry not found or not authorized'
            });
        }

        res.json({
            success: true,
            message: 'Entry deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting logbook entry:', error);
        res.status(500).json({
            success: false,
            message: 'Server error deleting logbook entry'
        });
    }
});

module.exports = router;

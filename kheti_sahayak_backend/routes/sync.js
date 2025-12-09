const express = require('express');
const router = express.Router();
const db = require('../db');
const { protect } = require('../middleware/authMiddleware');

/**
 * @swagger
 * tags:
 *   name: Sync
 *   description: Synchronization operations
 */

/**
 * @swagger
 * /api/sync/logbook:
 *   post:
 *     summary: Synchronize logbook entries (bidirectional)
 *     tags: [Sync]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               last_sync_timestamp:
 *                 type: string
 *                 format: date-time
 *                 description: Timestamp of the last successful sync
 *               changes:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *                       format: uuid
 *                       description: Backend UUID (if known)
 *                     local_id:
 *                       type: integer
 *                       description: Temporary local ID
 *                     activity_type:
 *                       type: string
 *                     date:
 *                       type: string
 *                     description:
 *                       type: string
 *                     cost:
 *                       type: number
 *                     income:
 *                       type: number
 *                     deleted:
 *                       type: boolean
 *                     version:
 *                       type: integer
 *     responses:
 *       200:
 *         description: Sync successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 new_sync_timestamp:
 *                   type: string
 *                   format: date-time
 *                 server_changes:
 *                   type: array
 *                   items:
 *                     type: object
 *                 processed_changes:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       local_id:
 *                         type: integer
 *                       backend_id:
 *                         type: string
 *                       status:
 *                         type: string
 *                         enum: [synced, conflict, error]
 *                       error:
 *                         type: string
 */
router.post('/logbook', protect, async (req, res) => {
    const client = await db.pool.connect();
    try {
        await client.query('BEGIN');

        const { last_sync_timestamp, changes } = req.body;
        const userId = req.user.id;
        const currentTimestamp = new Date().toISOString();
        const processedChanges = [];

        // 1. Process client changes
        if (changes && changes.length > 0) {
            for (const change of changes) {
                try {
                    if (change.id) {
                        // Update existing record
                        // Conflict resolution: Server wins if server version > client version
                        // But for simplicity in this MVP, we'll use Last Write Wins (LWW) or just accept client update if it sends a change.
                        // Better: Check if record exists and compare versions.

                        const existing = await client.query(
                            'SELECT * FROM logbook WHERE id = $1 AND user_id = $2',
                            [change.id, userId]
                        );

                        if (existing.rows.length === 0) {
                            // Record not found on server (maybe deleted or invalid ID)
                            // Treat as new insert if we want, or error.
                            // If it has an ID, it implies it was once synced.
                            processedChanges.push({
                                local_id: change.local_id,
                                backend_id: change.id,
                                status: 'error',
                                error: 'Record not found'
                            });
                            continue;
                        }

                        const serverRecord = existing.rows[0];

                        // Simple conflict resolution: Accept client change, increment version
                        // In a real app, we'd check serverRecord.version vs change.version

                        await client.query(
                            `UPDATE logbook 
                             SET activity_type = $1, date = $2, description = $3, cost = $4, income = $5, 
                                 deleted = $6, version = version + 1, last_modified = NOW()
                             WHERE id = $7 AND user_id = $8`,
                            [
                                change.activity_type,
                                change.date,
                                change.description,
                                change.cost || 0,
                                change.income || 0,
                                change.deleted || false,
                                change.id,
                                userId
                            ]
                        );

                        processedChanges.push({
                            local_id: change.local_id,
                            backend_id: change.id,
                            status: 'synced',
                            version: serverRecord.version + 1
                        });

                    } else {
                        // Insert new record
                        const result = await client.query(
                            `INSERT INTO logbook (user_id, activity_type, date, description, cost, income, version, last_modified)
                             VALUES ($1, $2, $3, $4, $5, $6, 1, NOW())
                             RETURNING id, version`,
                            [
                                userId,
                                change.activity_type,
                                change.date,
                                change.description,
                                change.cost || 0,
                                change.income || 0
                            ]
                        );

                        processedChanges.push({
                            local_id: change.local_id,
                            backend_id: result.rows[0].id,
                            status: 'synced',
                            version: result.rows[0].version
                        });
                    }
                } catch (err) {
                    console.error('Error processing change:', err);
                    processedChanges.push({
                        local_id: change.local_id,
                        status: 'error',
                        error: err.message
                    });
                }
            }
        }

        // 2. Fetch server changes (Delta Sync)
        // Get records modified AFTER the last_sync_timestamp
        // AND exclude records that were just updated by this client (to avoid echoing back)
        // Ideally, we filter by last_modified > last_sync_timestamp.

        let serverChangesQuery = `
            SELECT * FROM logbook 
            WHERE user_id = $1 
        `;

        const queryParams = [userId];

        if (last_sync_timestamp) {
            serverChangesQuery += ` AND last_modified > $2`;
            queryParams.push(last_sync_timestamp);
        }

        const serverChangesResult = await client.query(serverChangesQuery, queryParams);

        // Filter out the changes we just made? 
        // The transaction is not committed yet, so they are visible inside transaction.
        // But `last_modified` will be NOW().
        // If `last_sync_timestamp` is old, we will fetch everything modified since then.
        // This includes what we just updated.
        // The client needs to know the new version of what it just updated anyway.
        // But `processedChanges` already gives the status of what was sent.
        // To save bandwidth, we might want to exclude IDs present in `changes`.

        let serverChanges = serverChangesResult.rows;

        if (changes && changes.length > 0) {
            const changedIds = new Set(changes.map(c => c.id).filter(id => id));
            // Also exclude newly inserted IDs? 
            // The client will update the newly inserted ones using `processedChanges` mapping.
            // So we can exclude them from `serverChanges` to avoid double processing.

            // Actually, for simplicity, let's send everything. The client can merge.
            // But to be efficient:
            serverChanges = serverChanges.filter(r => !changedIds.has(r.id));

            // Also filter out the newly created ones (we don't have their IDs in `changedIds` easily 
            // unless we track them from `processedChanges`).
            const newIds = new Set(processedChanges.filter(p => p.backend_id).map(p => p.backend_id));
            serverChanges = serverChanges.filter(r => !newIds.has(r.id));
        }

        await client.query('COMMIT');

        res.json({
            success: true,
            new_sync_timestamp: currentTimestamp,
            server_changes: serverChanges,
            processed_changes: processedChanges
        });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Sync error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error during sync'
        });
    } finally {
        client.release();
    }
});

module.exports = router;

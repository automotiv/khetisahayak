const db = require('../db');
const asyncHandler = require('express-async-handler');

// @desc    Get all educational content
// @route   GET /api/educational-content
// @access  Public
const getAllContent = asyncHandler(async (req, res) => {
  const result = await db.query('SELECT * FROM educational_content ORDER BY created_at DESC');
  res.json(result.rows);
});

// @desc    Get a single educational content by ID
// @route   GET /api/educational-content/:id
// @access  Public
const getContentById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const result = await db.query('SELECT * FROM educational_content WHERE id = $1', [id]);
  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Content not found');
  }
  res.json(result.rows[0]);
});

// @desc    Add new educational content
// @route   POST /api/educational-content
// @access  Private (Admin/Creator)
const addContent = asyncHandler(async (req, res) => {
  const { title, content, category } = req.body;
  if (!title || !content) {
    res.status(400);
    throw new Error('Title and content are required');
  }

  const result = await db.query(
    'INSERT INTO educational_content (title, content, category, author_id) VALUES ($1, $2, $3, $4) RETURNING *',
    [title, content, category, req.user.id]
  );
  res.status(201).json({ message: 'Educational content added successfully', content: result.rows[0] });
});

module.exports = {
  getAllContent,
  getContentById,
  addContent,
};
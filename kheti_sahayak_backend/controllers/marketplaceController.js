const db = require('../db');
const asyncHandler = require('express-async-handler');

// @desc    Get all products
// @route   GET /api/marketplace
// @access  Public
const getAllProducts = asyncHandler(async (req, res) => {
  const result = await db.query('SELECT * FROM products');
  res.json(result.rows);
});

// @desc    Add a new product
// @route   POST /api/marketplace
// @access  Private (to be protected)
const addProduct = asyncHandler(async (req, res) => {
  const { name, description, price, category, imageUrl } = req.body;
  if (!name || !price) {
    res.status(400);
    throw new Error('Product name and price are required');
  }

  const result = await db.query(
    'INSERT INTO products (name, description, price, category, image_url, seller_id) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
    [name, description, price, category, imageUrl, req.user.id]
  );
  res.status(201).json({ message: 'Product added successfully', product: result.rows[0] });
});

// @desc    Get a single product by ID
// @route   GET /api/marketplace/:id
// @access  Public
const getProductById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const result = await db.query('SELECT * FROM products WHERE id = $1', [id]);
  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Product not found');
  }
  res.json(result.rows[0]);
});

module.exports = {
  getAllProducts,
  addProduct,
  getProductById,
};
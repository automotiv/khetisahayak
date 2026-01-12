const db = require('../db');
const asyncHandler = require('express-async-handler');

const getWishlist = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const result = await db.query(
    `SELECT
      w.id,
      w.product_id,
      w.created_at,
      p.name as product_name,
      p.description as product_description,
      p.price,
      p.image_urls as product_images,
      p.stock_quantity,
      p.is_available,
      p.category,
      p.brand,
      p.is_organic
    FROM wishlists w
    JOIN products p ON w.product_id = p.id
    WHERE w.user_id = $1
    ORDER BY w.created_at DESC`,
    [userId]
  );

  res.json({
    success: true,
    data: {
      items: result.rows,
      count: result.rows.length,
    },
  });
});

const addToWishlist = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { productId } = req.params;

  const productResult = await db.query(
    'SELECT id, name FROM products WHERE id = $1',
    [productId]
  );

  if (productResult.rows.length === 0) {
    res.status(404);
    throw new Error('Product not found');
  }

  const existingItem = await db.query(
    'SELECT id FROM wishlists WHERE user_id = $1 AND product_id = $2',
    [userId, productId]
  );

  if (existingItem.rows.length > 0) {
    res.status(400);
    throw new Error('Product already in wishlist');
  }

  const result = await db.query(
    `INSERT INTO wishlists (user_id, product_id)
     VALUES ($1, $2)
     RETURNING *`,
    [userId, productId]
  );

  res.status(201).json({
    success: true,
    message: 'Product added to wishlist',
    data: result.rows[0],
  });
});

const removeFromWishlist = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { productId } = req.params;

  const result = await db.query(
    'DELETE FROM wishlists WHERE user_id = $1 AND product_id = $2 RETURNING *',
    [userId, productId]
  );

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Product not found in wishlist');
  }

  res.json({
    success: true,
    message: 'Product removed from wishlist',
  });
});

const isInWishlist = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { productId } = req.params;

  const result = await db.query(
    'SELECT id FROM wishlists WHERE user_id = $1 AND product_id = $2',
    [userId, productId]
  );

  res.json({
    success: true,
    data: {
      inWishlist: result.rows.length > 0,
    },
  });
});

const getWishlistProductIds = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const result = await db.query(
    'SELECT product_id FROM wishlists WHERE user_id = $1',
    [userId]
  );

  res.json({
    success: true,
    data: {
      productIds: result.rows.map(row => row.product_id),
    },
  });
});

module.exports = {
  getWishlist,
  addToWishlist,
  removeFromWishlist,
  isInWishlist,
  getWishlistProductIds,
};

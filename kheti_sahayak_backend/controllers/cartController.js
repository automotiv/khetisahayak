const db = require('../db');
const asyncHandler = require('express-async-handler');

/**
 * @desc    Get user's cart items
 * @route   GET /api/cart
 * @access  Private
 */
const getCartItems = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const result = await db.query(
    `SELECT
      ci.id,
      ci.product_id,
      ci.quantity,
      ci.unit_price,
      ci.quantity * ci.unit_price as total_price,
      ci.created_at,
      ci.updated_at,
      p.name as product_name,
      p.description as product_description,
      p.image_urls as product_images,
      p.stock_quantity,
      p.is_available,
      p.category,
      p.brand
    FROM cart_items ci
    JOIN products p ON ci.product_id = p.id
    WHERE ci.user_id = $1
    ORDER BY ci.created_at DESC`,
    [userId]
  );

  // Calculate cart summary
  const items = result.rows;
  const subtotal = items.reduce((sum, item) => sum + parseFloat(item.total_price), 0);
  const totalItems = items.reduce((sum, item) => sum + item.quantity, 0);

  res.json({
    success: true,
    data: {
      items,
      summary: {
        subtotal: subtotal.toFixed(2),
        totalItems,
        itemCount: items.length,
      },
    },
  });
});

/**
 * @desc    Add item to cart
 * @route   POST /api/cart
 * @access  Private
 */
const addToCart = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { product_id, quantity = 1 } = req.body;

  // Validate input
  if (!product_id) {
    res.status(400);
    throw new Error('Product ID is required');
  }

  if (quantity < 1) {
    res.status(400);
    throw new Error('Quantity must be at least 1');
  }

  // Check if product exists and is available
  const productResult = await db.query(
    'SELECT id, name, price, stock_quantity, is_available FROM products WHERE id = $1',
    [product_id]
  );

  if (productResult.rows.length === 0) {
    res.status(404);
    throw new Error('Product not found');
  }

  const product = productResult.rows[0];

  if (!product.is_available) {
    res.status(400);
    throw new Error('Product is not available');
  }

  if (product.stock_quantity < quantity) {
    res.status(400);
    throw new Error(`Only ${product.stock_quantity} items available in stock`);
  }

  // Check if item already exists in cart
  const existingItem = await db.query(
    'SELECT id, quantity FROM cart_items WHERE user_id = $1 AND product_id = $2',
    [userId, product_id]
  );

  let result;
  if (existingItem.rows.length > 0) {
    // Update existing item quantity
    const newQuantity = existingItem.rows[0].quantity + quantity;

    if (product.stock_quantity < newQuantity) {
      res.status(400);
      throw new Error(`Only ${product.stock_quantity} items available in stock`);
    }

    result = await db.query(
      `UPDATE cart_items
       SET quantity = $1, unit_price = $2
       WHERE user_id = $3 AND product_id = $4
       RETURNING *`,
      [newQuantity, product.price, userId, product_id]
    );
  } else {
    // Insert new item
    result = await db.query(
      `INSERT INTO cart_items (user_id, product_id, quantity, unit_price)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [userId, product_id, quantity, product.price]
    );
  }

  res.status(201).json({
    success: true,
    message: 'Item added to cart successfully',
    data: result.rows[0],
  });
});

/**
 * @desc    Update cart item quantity
 * @route   PUT /api/cart/:itemId
 * @access  Private
 */
const updateCartItem = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { itemId } = req.params;
  const { quantity } = req.body;

  if (!quantity || quantity < 1) {
    res.status(400);
    throw new Error('Valid quantity is required');
  }

  // Get cart item and product info
  const cartItemResult = await db.query(
    `SELECT ci.*, p.stock_quantity, p.price
     FROM cart_items ci
     JOIN products p ON ci.product_id = p.id
     WHERE ci.id = $1 AND ci.user_id = $2`,
    [itemId, userId]
  );

  if (cartItemResult.rows.length === 0) {
    res.status(404);
    throw new Error('Cart item not found');
  }

  const cartItem = cartItemResult.rows[0];

  if (cartItem.stock_quantity < quantity) {
    res.status(400);
    throw new Error(`Only ${cartItem.stock_quantity} items available in stock`);
  }

  // Update quantity and unit price
  const result = await db.query(
    `UPDATE cart_items
     SET quantity = $1, unit_price = $2
     WHERE id = $3 AND user_id = $4
     RETURNING *`,
    [quantity, cartItem.price, itemId, userId]
  );

  res.json({
    success: true,
    message: 'Cart item updated successfully',
    data: result.rows[0],
  });
});

/**
 * @desc    Remove item from cart
 * @route   DELETE /api/cart/:itemId
 * @access  Private
 */
const removeCartItem = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { itemId } = req.params;

  const result = await db.query(
    'DELETE FROM cart_items WHERE id = $1 AND user_id = $2 RETURNING *',
    [itemId, userId]
  );

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Cart item not found');
  }

  res.json({
    success: true,
    message: 'Item removed from cart successfully',
  });
});

/**
 * @desc    Clear entire cart
 * @route   DELETE /api/cart
 * @access  Private
 */
const clearCart = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  await db.query('DELETE FROM cart_items WHERE user_id = $1', [userId]);

  res.json({
    success: true,
    message: 'Cart cleared successfully',
  });
});

/**
 * @desc    Get cart summary (count and total)
 * @route   GET /api/cart/summary
 * @access  Private
 */
const getCartSummary = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const result = await db.query(
    `SELECT
      COUNT(*) as item_count,
      SUM(quantity) as total_items,
      SUM(quantity * unit_price) as subtotal
    FROM cart_items
    WHERE user_id = $1`,
    [userId]
  );

  const summary = result.rows[0];

  res.json({
    success: true,
    data: {
      itemCount: parseInt(summary.item_count) || 0,
      totalItems: parseInt(summary.total_items) || 0,
      subtotal: parseFloat(summary.subtotal) || 0,
    },
  });
});

module.exports = {
  getCartItems,
  addToCart,
  updateCartItem,
  removeCartItem,
  clearCart,
  getCartSummary,
};

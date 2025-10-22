const db = require('../db');
const asyncHandler = require('express-async-handler');

// @desc    Create a new order
// @route   POST /api/orders
// @access  Private
const createOrder = asyncHandler(async (req, res) => {
  const { items, shipping_address, payment_method } = req.body;

  if (!items || !Array.isArray(items) || items.length === 0) {
    res.status(400);
    throw new Error('Order must contain at least one item');
  }

  if (!shipping_address) {
    res.status(400);
    throw new Error('Shipping address is required');
  }

  // Start transaction
  const client = await db.pool.connect();
  
  try {
    await client.query('BEGIN');

    let totalAmount = 0;
    const orderItems = [];

    // Validate items and calculate total
    for (const item of items) {
      const { product_id, quantity } = item;
      
      if (!product_id || !quantity || quantity <= 0) {
        throw new Error('Invalid item data');
      }

      // Get product details
      const productResult = await client.query(
        'SELECT * FROM products WHERE id = $1 AND is_available = true',
        [product_id]
      );

      if (productResult.rows.length === 0) {
        throw new Error(`Product with ID ${product_id} not found or unavailable`);
      }

      const product = productResult.rows[0];

      if (product.stock_quantity < quantity) {
        throw new Error(`Insufficient stock for product: ${product.name}`);
      }

      const itemTotal = product.price * quantity;
      totalAmount += itemTotal;

      orderItems.push({
        product_id,
        quantity,
        unit_price: product.price,
        total_price: itemTotal,
        product_name: product.name
      });
    }

    // Create order
    const orderResult = await client.query(
      `INSERT INTO orders (user_id, total_amount, shipping_address, payment_method) 
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.user.id, totalAmount, shipping_address, payment_method]
    );

    const order = orderResult.rows[0];

    // Create order items and update stock
    for (const item of orderItems) {
      await client.query(
        `INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price) 
         VALUES ($1, $2, $3, $4, $5)`,
        [order.id, item.product_id, item.quantity, item.unit_price, item.total_price]
      );

      // Update product stock
      await client.query(
        'UPDATE products SET stock_quantity = stock_quantity - $1 WHERE id = $2',
        [item.quantity, item.product_id]
      );
    }

    await client.query('COMMIT');

    // Get complete order details
    const completeOrderResult = await db.query(
      `SELECT o.*, 
              json_agg(
                json_build_object(
                  'id', oi.id,
                  'product_id', oi.product_id,
                  'quantity', oi.quantity,
                  'unit_price', oi.unit_price,
                  'total_price', oi.total_price,
                  'product_name', p.name,
                  'product_image', p.image_urls[1]
                )
              ) as items
       FROM orders o
       LEFT JOIN order_items oi ON o.id = oi.order_id
       LEFT JOIN products p ON oi.product_id = p.id
       WHERE o.id = $1
       GROUP BY o.id`,
      [order.id]
    );

    res.status(201).json({
      message: 'Order created successfully',
      order: completeOrderResult.rows[0]
    });

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

// @desc    Get user's orders
// @route   GET /api/orders
// @access  Private
const getUserOrders = asyncHandler(async (req, res) => {
  const { page = 1, limit = 10, status } = req.query;

  let query = `
    SELECT o.*, 
           json_agg(
             json_build_object(
               'id', oi.id,
               'product_id', oi.product_id,
               'quantity', oi.quantity,
               'unit_price', oi.unit_price,
               'total_price', oi.total_price,
               'product_name', p.name,
               'product_image', p.image_urls[1]
             )
           ) as items
    FROM orders o
    LEFT JOIN order_items oi ON o.id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.id
    WHERE o.user_id = $1
  `;
  
  const queryParams = [req.user.id];
  let paramCount = 1;

  if (status) {
    paramCount++;
    query += ` AND o.status = $${paramCount}`;
    queryParams.push(status);
  }

  query += ` GROUP BY o.id ORDER BY o.created_at DESC`;

  // Add pagination
  const offset = (page - 1) * limit;
  paramCount++;
  query += ` LIMIT $${paramCount}`;
  queryParams.push(parseInt(limit));
  
  paramCount++;
  query += ` OFFSET $${paramCount}`;
  queryParams.push(offset);

  const result = await db.query(query, queryParams);

  // Get total count
  let countQuery = 'SELECT COUNT(*) FROM orders WHERE user_id = $1';
  const countParams = [req.user.id];

  if (status) {
    countQuery += ' AND status = $2';
    countParams.push(status);
  }

  const countResult = await db.query(countQuery, countParams);
  const totalCount = parseInt(countResult.rows[0].count);

  res.json({
    orders: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(totalCount / limit),
      total_items: totalCount,
      items_per_page: parseInt(limit)
    }
  });
});

// @desc    Get order by ID
// @route   GET /api/orders/:id
// @access  Private
const getOrderById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `SELECT o.*, 
            json_agg(
              json_build_object(
                'id', oi.id,
                'product_id', oi.product_id,
                'quantity', oi.quantity,
                'unit_price', oi.unit_price,
                'total_price', oi.total_price,
                'product_name', p.name,
                'product_description', p.description,
                'product_image', p.image_urls[1],
                'seller_name', u.username
              )
            ) as items
     FROM orders o
     LEFT JOIN order_items oi ON o.id = oi.order_id
     LEFT JOIN products p ON oi.product_id = p.id
     LEFT JOIN users u ON p.seller_id = u.id
     WHERE o.id = $1 AND o.user_id = $2
     GROUP BY o.id`,
    [id, req.user.id]
  );

  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Order not found');
  }

  res.json(result.rows[0]);
});

// @desc    Update order status (for sellers)
// @route   PUT /api/orders/:id/status
// @access  Private
const updateOrderStatus = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  if (!status || !['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'].includes(status)) {
    res.status(400);
    throw new Error('Valid status is required');
  }

  // Check if user is the seller of any product in this order
  const orderCheck = await db.query(
    `SELECT o.id FROM orders o
     JOIN order_items oi ON o.id = oi.order_id
     JOIN products p ON oi.product_id = p.id
     WHERE o.id = $1 AND p.seller_id = $2`,
    [id, req.user.id]
  );

  if (orderCheck.rows.length === 0) {
    res.status(403);
    throw new Error('You can only update orders containing your products');
  }

  const result = await db.query(
    'UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
    [status, id]
  );

  res.json({
    message: 'Order status updated successfully',
    order: result.rows[0]
  });
});

// @desc    Cancel order
// @route   PUT /api/orders/:id/cancel
// @access  Private
const cancelOrder = asyncHandler(async (req, res) => {
  const { id } = req.params;

  // Check if order belongs to user and can be cancelled
  const orderResult = await db.query(
    'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
    [id, req.user.id]
  );

  if (orderResult.rows.length === 0) {
    res.status(404);
    throw new Error('Order not found');
  }

  const order = orderResult.rows[0];

  if (order.status !== 'pending') {
    res.status(400);
    throw new Error('Only pending orders can be cancelled');
  }

  const client = await db.pool.connect();

  try {
    await client.query('BEGIN');

    // Update order status
    await client.query(
      'UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      ['cancelled', id]
    );

    // Restore product stock
    const orderItems = await client.query(
      'SELECT product_id, quantity FROM order_items WHERE order_id = $1',
      [id]
    );

    for (const item of orderItems.rows) {
      await client.query(
        'UPDATE products SET stock_quantity = stock_quantity + $1 WHERE id = $2',
        [item.quantity, item.product_id]
      );
    }

    await client.query('COMMIT');

    res.json({ message: 'Order cancelled successfully' });

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

// @desc    Get seller's orders
// @route   GET /api/orders/seller
// @access  Private
const getSellerOrders = asyncHandler(async (req, res) => {
  const { page = 1, limit = 10, status } = req.query;

  let query = `
    SELECT o.id, o.total_amount, o.status, o.payment_status, o.created_at, o.updated_at,
           u.username as buyer_name, u.first_name, u.last_name, u.phone as buyer_phone,
           json_agg(
             json_build_object(
               'product_id', p.id,
               'product_name', p.name,
               'quantity', oi.quantity,
               'unit_price', oi.unit_price,
               'total_price', oi.total_price
             )
           ) as items
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    JOIN users u ON o.user_id = u.id
    WHERE p.seller_id = $1
  `;
  
  const queryParams = [req.user.id];
  let paramCount = 1;

  if (status) {
    paramCount++;
    query += ` AND o.status = $${paramCount}`;
    queryParams.push(status);
  }

  query += ` GROUP BY o.id, u.username, u.first_name, u.last_name, u.phone ORDER BY o.created_at DESC`;

  // Add pagination
  const offset = (page - 1) * limit;
  paramCount++;
  query += ` LIMIT $${paramCount}`;
  queryParams.push(parseInt(limit));
  
  paramCount++;
  query += ` OFFSET $${paramCount}`;
  queryParams.push(offset);

  const result = await db.query(query, queryParams);

  res.json({
    orders: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(result.rows.length / limit),
      items_per_page: parseInt(limit)
    }
  });
});

// @desc    Create order from user's cart
// @route   POST /api/orders/from-cart
// @access  Private
const createOrderFromCart = asyncHandler(async (req, res) => {
  const { shipping_address, payment_method } = req.body;

  if (!shipping_address) {
    res.status(400);
    throw new Error('Shipping address is required');
  }

  // Start transaction
  const client = await db.pool.connect();

  try {
    await client.query('BEGIN');

    // Get cart items
    const cartResult = await client.query(
      `SELECT ci.*, p.name, p.price, p.stock_quantity, p.is_available
       FROM cart_items ci
       JOIN products p ON ci.product_id = p.id
       WHERE ci.user_id = $1`,
      [req.user.id]
    );

    if (cartResult.rows.length === 0) {
      throw new Error('Cart is empty');
    }

    let totalAmount = 0;
    const orderItems = [];

    // Validate items and calculate total
    for (const item of cartResult.rows) {
      if (!item.is_available) {
        throw new Error(`Product ${item.name} is no longer available`);
      }

      if (item.stock_quantity < item.quantity) {
        throw new Error(`Insufficient stock for ${item.name}. Available: ${item.stock_quantity}`);
      }

      const itemTotal = item.unit_price * item.quantity;
      totalAmount += itemTotal;

      orderItems.push({
        product_id: item.product_id,
        quantity: item.quantity,
        unit_price: item.unit_price,
        total_price: itemTotal,
        product_name: item.name
      });
    }

    // Create order
    const orderResult = await client.query(
      `INSERT INTO orders (user_id, total_amount, shipping_address, payment_method)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.user.id, totalAmount, shipping_address, payment_method]
    );

    const order = orderResult.rows[0];

    // Create order items and update stock
    for (const item of orderItems) {
      await client.query(
        `INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price)
         VALUES ($1, $2, $3, $4, $5)`,
        [order.id, item.product_id, item.quantity, item.unit_price, item.total_price]
      );

      // Update product stock
      await client.query(
        'UPDATE products SET stock_quantity = stock_quantity - $1 WHERE id = $2',
        [item.quantity, item.product_id]
      );
    }

    // Clear the cart
    await client.query('DELETE FROM cart_items WHERE user_id = $1', [req.user.id]);

    await client.query('COMMIT');

    // Get complete order details
    const completeOrderResult = await db.query(
      `SELECT o.*,
              json_agg(
                json_build_object(
                  'id', oi.id,
                  'product_id', oi.product_id,
                  'quantity', oi.quantity,
                  'unit_price', oi.unit_price,
                  'total_price', oi.total_price,
                  'product_name', p.name,
                  'product_image', p.image_urls
                )
              ) as items
       FROM orders o
       JOIN order_items oi ON o.id = oi.order_id
       JOIN products p ON oi.product_id = p.id
       WHERE o.id = $1
       GROUP BY o.id`,
      [order.id]
    );

    res.status(201).json({
      success: true,
      message: 'Order created successfully from cart',
      data: completeOrderResult.rows[0]
    });

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

module.exports = {
  createOrder,
  createOrderFromCart,
  getUserOrders,
  getOrderById,
  updateOrderStatus,
  cancelOrder,
  getSellerOrders,
}; 
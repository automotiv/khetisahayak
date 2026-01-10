const db = require('../db');
const asyncHandler = require('express-async-handler');

// @desc    Get seller dashboard summary stats
// @route   GET /api/sellers/dashboard
// @access  Private
const getSellerDashboard = asyncHandler(async (req, res) => {
  const sellerId = req.user.id;

  const totalOrdersResult = await db.query(
    `SELECT COUNT(DISTINCT o.id) as total_orders
     FROM orders o
     JOIN order_items oi ON o.id = oi.order_id
     JOIN products p ON oi.product_id = p.id
     WHERE p.seller_id = $1`,
    [sellerId]
  );

  const pendingOrdersResult = await db.query(
    `SELECT COUNT(DISTINCT o.id) as pending_orders
     FROM orders o
     JOIN order_items oi ON o.id = oi.order_id
     JOIN products p ON oi.product_id = p.id
     WHERE p.seller_id = $1 AND o.status = 'pending'`,
    [sellerId]
  );

  const revenueResult = await db.query(
    `SELECT COALESCE(SUM(oi.total_price), 0) as total_revenue
     FROM orders o
     JOIN order_items oi ON o.id = oi.order_id
     JOIN products p ON oi.product_id = p.id
     WHERE p.seller_id = $1 AND o.status = 'delivered'`,
    [sellerId]
  );

  const productsResult = await db.query(
    `SELECT COUNT(*) as total_products
     FROM products
     WHERE seller_id = $1`,
    [sellerId]
  );

  const lowStockResult = await db.query(
    `SELECT COUNT(*) as low_stock_count
     FROM products
     WHERE seller_id = $1 AND stock_quantity < 10 AND is_available = true`,
    [sellerId]
  );

  res.json({
    success: true,
    data: {
      total_orders: parseInt(totalOrdersResult.rows[0].total_orders) || 0,
      pending_orders: parseInt(pendingOrdersResult.rows[0].pending_orders) || 0,
      total_revenue: parseFloat(revenueResult.rows[0].total_revenue) || 0,
      total_products: parseInt(productsResult.rows[0].total_products) || 0,
      low_stock_count: parseInt(lowStockResult.rows[0].low_stock_count) || 0
    }
  });
});

// @desc    Get seller's orders with filters
// @route   GET /api/sellers/orders
// @access  Private
const getSellerOrders = asyncHandler(async (req, res) => {
  const { page = 1, limit = 10, status, start_date, end_date } = req.query;
  const sellerId = req.user.id;

  let query = `
    SELECT DISTINCT o.id, o.total_amount, o.status, o.payment_status, 
           o.shipping_address, o.payment_method, o.created_at, o.updated_at,
           u.username as buyer_name, u.first_name as buyer_first_name, 
           u.last_name as buyer_last_name, u.phone as buyer_phone, u.email as buyer_email,
           (
             SELECT json_agg(
               json_build_object(
                 'id', oi2.id,
                 'product_id', oi2.product_id,
                 'product_name', p2.name,
                 'product_image', p2.image_urls[1],
                 'quantity', oi2.quantity,
                 'unit_price', oi2.unit_price,
                 'total_price', oi2.total_price
               )
             )
             FROM order_items oi2
             JOIN products p2 ON oi2.product_id = p2.id
             WHERE oi2.order_id = o.id AND p2.seller_id = $1
           ) as items
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    JOIN users u ON o.user_id = u.id
    WHERE p.seller_id = $1
  `;

  const queryParams = [sellerId];
  let paramCount = 1;

  if (status && ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'].includes(status)) {
    paramCount++;
    query += ` AND o.status = $${paramCount}`;
    queryParams.push(status);
  }

  if (start_date) {
    paramCount++;
    query += ` AND o.created_at >= $${paramCount}`;
    queryParams.push(start_date);
  }

  if (end_date) {
    paramCount++;
    query += ` AND o.created_at <= $${paramCount}`;
    queryParams.push(end_date);
  }

  query += ` ORDER BY o.created_at DESC`;

  const offset = (parseInt(page) - 1) * parseInt(limit);
  paramCount++;
  query += ` LIMIT $${paramCount}`;
  queryParams.push(parseInt(limit));

  paramCount++;
  query += ` OFFSET $${paramCount}`;
  queryParams.push(offset);

  const result = await db.query(query, queryParams);

  let countQuery = `
    SELECT COUNT(DISTINCT o.id) as total
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE p.seller_id = $1
  `;
  const countParams = [sellerId];
  let countParamCount = 1;

  if (status && ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'].includes(status)) {
    countParamCount++;
    countQuery += ` AND o.status = $${countParamCount}`;
    countParams.push(status);
  }

  if (start_date) {
    countParamCount++;
    countQuery += ` AND o.created_at >= $${countParamCount}`;
    countParams.push(start_date);
  }

  if (end_date) {
    countParamCount++;
    countQuery += ` AND o.created_at <= $${countParamCount}`;
    countParams.push(end_date);
  }

  const countResult = await db.query(countQuery, countParams);
  const totalCount = parseInt(countResult.rows[0].total);

  res.json({
    success: true,
    data: {
      orders: result.rows,
      pagination: {
        current_page: parseInt(page),
        total_pages: Math.ceil(totalCount / parseInt(limit)),
        total_items: totalCount,
        items_per_page: parseInt(limit)
      }
    }
  });
});

// @desc    Get seller revenue analytics
// @route   GET /api/sellers/revenue
// @access  Private
const getSellerRevenue = asyncHandler(async (req, res) => {
  const { period = '30d' } = req.query;
  const sellerId = req.user.id;

  let interval;
  let groupBy;
  switch (period) {
    case '7d':
      interval = '7 days';
      groupBy = 'day';
      break;
    case '30d':
      interval = '30 days';
      groupBy = 'day';
      break;
    case '90d':
      interval = '90 days';
      groupBy = 'week';
      break;
    case '1y':
      interval = '365 days';
      groupBy = 'month';
      break;
    default:
      interval = '30 days';
      groupBy = 'day';
  }

  let revenueQuery;
  if (groupBy === 'day') {
    revenueQuery = `
      SELECT DATE(o.created_at) as date,
             COALESCE(SUM(oi.total_price), 0) as revenue,
             COUNT(DISTINCT o.id) as order_count
      FROM orders o
      JOIN order_items oi ON o.id = oi.order_id
      JOIN products p ON oi.product_id = p.id
      WHERE p.seller_id = $1 
        AND o.status IN ('delivered', 'shipped', 'confirmed')
        AND o.created_at >= CURRENT_DATE - INTERVAL '${interval}'
      GROUP BY DATE(o.created_at)
      ORDER BY date ASC
    `;
  } else if (groupBy === 'week') {
    revenueQuery = `
      SELECT DATE_TRUNC('week', o.created_at)::date as date,
             COALESCE(SUM(oi.total_price), 0) as revenue,
             COUNT(DISTINCT o.id) as order_count
      FROM orders o
      JOIN order_items oi ON o.id = oi.order_id
      JOIN products p ON oi.product_id = p.id
      WHERE p.seller_id = $1 
        AND o.status IN ('delivered', 'shipped', 'confirmed')
        AND o.created_at >= CURRENT_DATE - INTERVAL '${interval}'
      GROUP BY DATE_TRUNC('week', o.created_at)
      ORDER BY date ASC
    `;
  } else {
    revenueQuery = `
      SELECT DATE_TRUNC('month', o.created_at)::date as date,
             COALESCE(SUM(oi.total_price), 0) as revenue,
             COUNT(DISTINCT o.id) as order_count
      FROM orders o
      JOIN order_items oi ON o.id = oi.order_id
      JOIN products p ON oi.product_id = p.id
      WHERE p.seller_id = $1 
        AND o.status IN ('delivered', 'shipped', 'confirmed')
        AND o.created_at >= CURRENT_DATE - INTERVAL '${interval}'
      GROUP BY DATE_TRUNC('month', o.created_at)
      ORDER BY date ASC
    `;
  }

  const revenueResult = await db.query(revenueQuery, [sellerId]);

  const totalResult = await db.query(
    `SELECT COALESCE(SUM(oi.total_price), 0) as total_revenue,
            COUNT(DISTINCT o.id) as total_orders
     FROM orders o
     JOIN order_items oi ON o.id = oi.order_id
     JOIN products p ON oi.product_id = p.id
     WHERE p.seller_id = $1 
       AND o.status IN ('delivered', 'shipped', 'confirmed')
       AND o.created_at >= CURRENT_DATE - INTERVAL '${interval}'`,
    [sellerId]
  );

  res.json({
    success: true,
    data: {
      period,
      group_by: groupBy,
      total_revenue: parseFloat(totalResult.rows[0].total_revenue) || 0,
      total_orders: parseInt(totalResult.rows[0].total_orders) || 0,
      revenue_data: revenueResult.rows.map(row => ({
        date: row.date,
        revenue: parseFloat(row.revenue) || 0,
        order_count: parseInt(row.order_count) || 0
      }))
    }
  });
});

// @desc    Get seller detailed analytics
// @route   GET /api/sellers/analytics
// @access  Private
const getSellerAnalytics = asyncHandler(async (req, res) => {
  const sellerId = req.user.id;

  const topProductsResult = await db.query(
    `SELECT p.id, p.name, p.category, p.price,
            SUM(oi.quantity) as total_sold,
            SUM(oi.total_price) as total_revenue
     FROM products p
     JOIN order_items oi ON p.id = oi.product_id
     JOIN orders o ON oi.order_id = o.id
     WHERE p.seller_id = $1 AND o.status IN ('delivered', 'shipped', 'confirmed')
     GROUP BY p.id, p.name, p.category, p.price
     ORDER BY total_sold DESC
     LIMIT 10`,
    [sellerId]
  );

  const categoryRevenueResult = await db.query(
    `SELECT p.category,
            COALESCE(SUM(oi.total_price), 0) as revenue,
            COUNT(DISTINCT o.id) as order_count
     FROM products p
     JOIN order_items oi ON p.id = oi.product_id
     JOIN orders o ON oi.order_id = o.id
     WHERE p.seller_id = $1 AND o.status IN ('delivered', 'shipped', 'confirmed')
     GROUP BY p.category
     ORDER BY revenue DESC`,
    [sellerId]
  );

  const statusDistributionResult = await db.query(
    `SELECT o.status, COUNT(DISTINCT o.id) as count
     FROM orders o
     JOIN order_items oi ON o.id = oi.order_id
     JOIN products p ON oi.product_id = p.id
     WHERE p.seller_id = $1
     GROUP BY o.status`,
    [sellerId]
  );

  const avgOrderValueResult = await db.query(
    `SELECT AVG(order_total) as average_order_value
     FROM (
       SELECT o.id, SUM(oi.total_price) as order_total
       FROM orders o
       JOIN order_items oi ON o.id = oi.order_id
       JOIN products p ON oi.product_id = p.id
       WHERE p.seller_id = $1 AND o.status IN ('delivered', 'shipped', 'confirmed')
       GROUP BY o.id
     ) as order_totals`,
    [sellerId]
  );

  const repeatCustomerResult = await db.query(
    `SELECT 
       COUNT(DISTINCT o.user_id) as total_customers,
       COUNT(DISTINCT CASE WHEN customer_orders.order_count > 1 THEN customer_orders.user_id END) as repeat_customers
     FROM orders o
     JOIN order_items oi ON o.id = oi.order_id
     JOIN products p ON oi.product_id = p.id
     LEFT JOIN (
       SELECT o2.user_id, COUNT(DISTINCT o2.id) as order_count
       FROM orders o2
       JOIN order_items oi2 ON o2.id = oi2.order_id
       JOIN products p2 ON oi2.product_id = p2.id
       WHERE p2.seller_id = $1
       GROUP BY o2.user_id
     ) as customer_orders ON o.user_id = customer_orders.user_id
     WHERE p.seller_id = $1`,
    [sellerId]
  );

  const totalCustomers = parseInt(repeatCustomerResult.rows[0].total_customers) || 0;
  const repeatCustomers = parseInt(repeatCustomerResult.rows[0].repeat_customers) || 0;
  const repeatRate = totalCustomers > 0 ? ((repeatCustomers / totalCustomers) * 100).toFixed(2) : 0;

  res.json({
    success: true,
    data: {
      top_selling_products: topProductsResult.rows.map(row => ({
        id: row.id,
        name: row.name,
        category: row.category,
        price: parseFloat(row.price),
        total_sold: parseInt(row.total_sold),
        total_revenue: parseFloat(row.total_revenue)
      })),
      revenue_by_category: categoryRevenueResult.rows.map(row => ({
        category: row.category,
        revenue: parseFloat(row.revenue),
        order_count: parseInt(row.order_count)
      })),
      order_status_distribution: statusDistributionResult.rows.map(row => ({
        status: row.status,
        count: parseInt(row.count)
      })),
      average_order_value: parseFloat(avgOrderValueResult.rows[0].average_order_value) || 0,
      customer_metrics: {
        total_customers: totalCustomers,
        repeat_customers: repeatCustomers,
        repeat_rate: parseFloat(repeatRate)
      }
    }
  });
});

// @desc    Get seller's product inventory
// @route   GET /api/sellers/inventory
// @access  Private
const getSellerInventory = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, low_stock, sort_by = 'created_at', sort_order = 'DESC' } = req.query;
  const sellerId = req.user.id;

  let query = `
    SELECT p.id, p.name, p.category, p.subcategory, p.price, p.stock_quantity,
           p.unit, p.is_available, p.is_organic, p.image_urls, p.created_at, p.updated_at
    FROM products p
    WHERE p.seller_id = $1
  `;

  const queryParams = [sellerId];
  let paramCount = 1;

  if (low_stock === 'true') {
    query += ` AND p.stock_quantity < 10`;
  }

  const allowedSortFields = ['name', 'price', 'stock_quantity', 'created_at', 'updated_at'];
  const allowedSortOrders = ['ASC', 'DESC'];

  const sortField = allowedSortFields.includes(sort_by) ? sort_by : 'created_at';
  const sortDirection = allowedSortOrders.includes(sort_order.toUpperCase()) ? sort_order.toUpperCase() : 'DESC';

  query += ` ORDER BY p.${sortField} ${sortDirection}`;

  const offset = (parseInt(page) - 1) * parseInt(limit);
  paramCount++;
  query += ` LIMIT $${paramCount}`;
  queryParams.push(parseInt(limit));

  paramCount++;
  query += ` OFFSET $${paramCount}`;
  queryParams.push(offset);

  const result = await db.query(query, queryParams);

  let countQuery = `SELECT COUNT(*) as total FROM products WHERE seller_id = $1`;
  const countParams = [sellerId];

  if (low_stock === 'true') {
    countQuery += ` AND stock_quantity < 10`;
  }

  const countResult = await db.query(countQuery, countParams);
  const totalCount = parseInt(countResult.rows[0].total);

  res.json({
    success: true,
    data: {
      products: result.rows.map(row => ({
        id: row.id,
        name: row.name,
        category: row.category,
        subcategory: row.subcategory,
        price: parseFloat(row.price),
        stock_quantity: parseInt(row.stock_quantity),
        unit: row.unit,
        is_available: row.is_available,
        is_organic: row.is_organic,
        image_urls: row.image_urls,
        created_at: row.created_at,
        updated_at: row.updated_at
      })),
      pagination: {
        current_page: parseInt(page),
        total_pages: Math.ceil(totalCount / parseInt(limit)),
        total_items: totalCount,
        items_per_page: parseInt(limit)
      }
    }
  });
});

// @desc    Update product inventory (stock quantity)
// @route   PUT /api/sellers/inventory/:productId
// @access  Private
const updateInventory = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const { stock_quantity } = req.body;
  const sellerId = req.user.id;

  if (stock_quantity === undefined || stock_quantity === null) {
    res.status(400);
    throw new Error('Stock quantity is required');
  }

  const stockQty = parseInt(stock_quantity);
  if (isNaN(stockQty) || stockQty < 0) {
    res.status(400);
    throw new Error('Stock quantity must be a non-negative integer');
  }

  const productCheck = await db.query(
    `SELECT id, name, stock_quantity FROM products WHERE id = $1 AND seller_id = $2`,
    [productId, sellerId]
  );

  if (productCheck.rows.length === 0) {
    res.status(404);
    throw new Error('Product not found or you do not have permission to update it');
  }

  const result = await db.query(
    `UPDATE products 
     SET stock_quantity = $1, updated_at = CURRENT_TIMESTAMP 
     WHERE id = $2 AND seller_id = $3 
     RETURNING id, name, stock_quantity, is_available, updated_at`,
    [stockQty, productId, sellerId]
  );

  res.json({
    success: true,
    message: 'Inventory updated successfully',
    data: {
      id: result.rows[0].id,
      name: result.rows[0].name,
      stock_quantity: parseInt(result.rows[0].stock_quantity),
      is_available: result.rows[0].is_available,
      updated_at: result.rows[0].updated_at
    }
  });
});

module.exports = {
  getSellerDashboard,
  getSellerOrders,
  getSellerRevenue,
  getSellerAnalytics,
  getSellerInventory,
  updateInventory,
};

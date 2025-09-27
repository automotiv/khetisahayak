const db = require('../db');
const asyncHandler = require('express-async-handler');
const { uploadFileToS3 } = require('../s3');

// @desc    Get all products with filtering and pagination
// @route   GET /api/marketplace
// @access  Public
const getAllProducts = asyncHandler(async (req, res) => {
  const { 
    category, 
    subcategory, 
    min_price, 
    max_price, 
    is_organic, 
    search, 
    page = 1, 
    limit = 10,
    sort_by = 'created_at',
    sort_order = 'DESC'
  } = req.query;

  let query = `
    SELECT p.*, u.username as seller_name, u.first_name, u.last_name
    FROM products p
    LEFT JOIN users u ON p.seller_id = u.id
    WHERE p.is_available = true
  `;
  const queryParams = [];
  let paramCount = 0;

  // Add filters
  if (category) {
    paramCount++;
    query += ` AND p.category = $${paramCount}`;
    queryParams.push(category);
  }

  if (subcategory) {
    paramCount++;
    query += ` AND p.subcategory = $${paramCount}`;
    queryParams.push(subcategory);
  }

  if (min_price) {
    paramCount++;
    query += ` AND p.price >= $${paramCount}`;
    queryParams.push(min_price);
  }

  if (max_price) {
    paramCount++;
    query += ` AND p.price <= $${paramCount}`;
    queryParams.push(max_price);
  }

  if (is_organic === 'true') {
    paramCount++;
    query += ` AND p.is_organic = $${paramCount}`;
    queryParams.push(true);
  }

  if (search) {
    paramCount++;
    query += ` AND (p.name ILIKE $${paramCount} OR p.description ILIKE $${paramCount})`;
    queryParams.push(`%${search}%`);
  }

  // Add sorting
  const allowedSortFields = ['name', 'price', 'created_at', 'stock_quantity'];
  const allowedSortOrders = ['ASC', 'DESC'];
  
  if (allowedSortFields.includes(sort_by) && allowedSortOrders.includes(sort_order.toUpperCase())) {
    query += ` ORDER BY p.${sort_by} ${sort_order.toUpperCase()}`;
  } else {
    query += ' ORDER BY p.created_at DESC';
  }

  // Add pagination
  const offset = (page - 1) * limit;
  paramCount++;
  query += ` LIMIT $${paramCount}`;
  queryParams.push(parseInt(limit));
  
  paramCount++;
  query += ` OFFSET $${paramCount}`;
  queryParams.push(offset);

  const result = await db.query(query, queryParams);
  
  // Get total count for pagination
  let countQuery = 'SELECT COUNT(*) FROM products WHERE is_available = true';
  const countParams = [];
  paramCount = 0;

  if (category) {
    paramCount++;
    countQuery += ` AND category = $${paramCount}`;
    countParams.push(category);
  }

  if (subcategory) {
    paramCount++;
    countQuery += ` AND subcategory = $${paramCount}`;
    countParams.push(subcategory);
  }

  if (min_price) {
    paramCount++;
    countQuery += ` AND price >= $${paramCount}`;
    countParams.push(min_price);
  }

  if (max_price) {
    paramCount++;
    countQuery += ` AND price <= $${paramCount}`;
    countParams.push(max_price);
  }

  if (is_organic === 'true') {
    paramCount++;
    countQuery += ` AND is_organic = $${paramCount}`;
    countParams.push(true);
  }

  if (search) {
    paramCount++;
    countQuery += ` AND (name ILIKE $${paramCount} OR description ILIKE $${paramCount})`;
    countParams.push(`%${search}%`);
  }

  const countResult = await db.query(countQuery, countParams);
  const totalCount = parseInt(countResult.rows[0].count);

  res.json({
    products: result.rows,
    pagination: {
      current_page: parseInt(page),
      total_pages: Math.ceil(totalCount / limit),
      total_items: totalCount,
      items_per_page: parseInt(limit)
    }
  });
});

// @desc    Get a single product by ID
// @route   GET /api/marketplace/:id
// @access  Public
const getProductById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const result = await db.query(`
    SELECT p.*, u.username as seller_name, u.first_name, u.last_name, u.phone as seller_phone
    FROM products p
    LEFT JOIN users u ON p.seller_id = u.id
    WHERE p.id = $1
  `, [id]);
  
  if (result.rows.length === 0) {
    res.status(404);
    throw new Error('Product not found');
  }
  
  res.json(result.rows[0]);
});

// @desc    Add a new product
// @route   POST /api/marketplace
// @access  Private
const addProduct = asyncHandler(async (req, res) => {
  const { 
    name, 
    description, 
    price, 
    category, 
    subcategory,
    brand,
    stock_quantity,
    unit,
    specifications,
    is_organic
  } = req.body;

  if (!name || !price || !category) {
    res.status(400);
    throw new Error('Product name, price, and category are required');
  }

  const result = await db.query(
    `INSERT INTO products (
      name, description, price, category, subcategory, brand, 
      stock_quantity, unit, specifications, is_organic, seller_id
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *`,
    [
      name, description, price, category, subcategory, brand,
      stock_quantity || 0, unit || 'piece', specifications, is_organic || false, req.user.id
    ]
  );
  
  res.status(201).json({ 
    message: 'Product added successfully', 
    product: result.rows[0] 
  });
});

// @desc    Update a product
// @route   PUT /api/marketplace/:id
// @access  Private
const updateProduct = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { 
    name, 
    description, 
    price, 
    category, 
    subcategory,
    brand,
    stock_quantity,
    unit,
    specifications,
    is_organic,
    is_available
  } = req.body;

  // Check if product exists and belongs to user
  const existingProduct = await db.query(
    'SELECT * FROM products WHERE id = $1 AND seller_id = $2',
    [id, req.user.id]
  );

  if (existingProduct.rows.length === 0) {
    res.status(404);
    throw new Error('Product not found or you do not have permission to update it');
  }

  const result = await db.query(
    `UPDATE products SET 
      name = COALESCE($1, name),
      description = COALESCE($2, description),
      price = COALESCE($3, price),
      category = COALESCE($4, category),
      subcategory = COALESCE($5, subcategory),
      brand = COALESCE($6, brand),
      stock_quantity = COALESCE($7, stock_quantity),
      unit = COALESCE($8, unit),
      specifications = COALESCE($9, specifications),
      is_organic = COALESCE($10, is_organic),
      is_available = COALESCE($11, is_available),
      updated_at = CURRENT_TIMESTAMP
    WHERE id = $12 RETURNING *`,
    [
      name, description, price, category, subcategory, brand,
      stock_quantity, unit, specifications, is_organic, is_available, id
    ]
  );

  res.json({ 
    message: 'Product updated successfully', 
    product: result.rows[0] 
  });
});

// @desc    Delete a product
// @route   DELETE /api/marketplace/:id
// @access  Private
const deleteProduct = asyncHandler(async (req, res) => {
  const { id } = req.params;

  // Check if product exists and belongs to user
  const existingProduct = await db.query(
    'SELECT * FROM products WHERE id = $1 AND seller_id = $2',
    [id, req.user.id]
  );

  if (existingProduct.rows.length === 0) {
    res.status(404);
    throw new Error('Product not found or you do not have permission to delete it');
  }

  await db.query('DELETE FROM products WHERE id = $1', [id]);

  res.json({ message: 'Product deleted successfully' });
});

// @desc    Upload product images
// @route   POST /api/marketplace/:id/images
// @access  Private
const uploadProductImages = asyncHandler(async (req, res) => {
  const { id } = req.params;

  if (!req.files || req.files.length === 0) {
    res.status(400);
    throw new Error('No image files provided');
  }

  // Check if product exists and belongs to user
  const existingProduct = await db.query(
    'SELECT * FROM products WHERE id = $1 AND seller_id = $2',
    [id, req.user.id]
  );

  if (existingProduct.rows.length === 0) {
    res.status(404);
    throw new Error('Product not found or you do not have permission to update it');
  }

  const uploadedUrls = [];
  
  for (const file of req.files) {
    const fileName = `products/${id}/${Date.now()}-${file.originalname}`;
    const imageUrl = await uploadFileToS3(file.buffer, fileName, file.mimetype);
    uploadedUrls.push(imageUrl);
  }

  // Update product with new image URLs
  const currentImages = existingProduct.rows[0].image_urls || [];
  const updatedImages = [...currentImages, ...uploadedUrls];
  
  const result = await db.query(
    'UPDATE products SET image_urls = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING image_urls',
    [updatedImages, id]
  );

  res.json({ 
    message: 'Product images uploaded successfully',
    image_urls: result.rows[0].image_urls
  });
});

// @desc    Get seller's products
// @route   GET /api/marketplace/seller/products
// @access  Private
const getSellerProducts = asyncHandler(async (req, res) => {
  const result = await db.query(
    'SELECT * FROM products WHERE seller_id = $1 ORDER BY created_at DESC',
    [req.user.id]
  );

  res.json(result.rows);
});

// @desc    Get product categories
// @route   GET /api/marketplace/categories
// @access  Public
const getProductCategories = asyncHandler(async (req, res) => {
  const result = await db.query(`
    SELECT DISTINCT category, subcategory 
    FROM products 
    WHERE is_available = true 
    ORDER BY category, subcategory
  `);

  const categories = {};
  result.rows.forEach(row => {
    if (!categories[row.category]) {
      categories[row.category] = [];
    }
    if (row.subcategory && !categories[row.category].includes(row.subcategory)) {
      categories[row.category].push(row.subcategory);
    }
  });

  res.json(categories);
});

module.exports = {
  getAllProducts,
  getProductById,
  addProduct,
  updateProduct,
  deleteProduct,
  uploadProductImages,
  getSellerProducts,
  getProductCategories,
};
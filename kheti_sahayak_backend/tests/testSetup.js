const db = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Create test users with different roles
const createTestUsers = async () => {
  const password = 'test123';
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(password, salt);
  
  const testUsers = [
    {
      id: '11111111-1111-1111-1111-111111111111',
      username: 'testuser',
      email: 'test@example.com',
      password_hash: hashedPassword,
      role: 'user',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: '22222222-2222-2222-2222-222222222222',
      username: 'testadmin',
      email: 'admin@example.com',
      password_hash: hashedPassword,
      role: 'admin',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: '33333333-3333-3333-3333-333333333333',
      username: 'testcreator',
      email: 'creator@example.com',
      password_hash: hashedPassword,
      role: 'content-creator',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }
  ];

  // Add test users to the database
  db.__addTestData('users', testUsers);
  
  // Generate tokens for test users
  const tokens = {};
  testUsers.forEach(user => {
    tokens[user.role] = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET || 'test-secret',
      { expiresIn: '1h' }
    );
  });
  
  return { testUsers, tokens, testPassword: password };
};

// Create test products
const createTestProducts = async () => {
  const testProducts = [
    {
      id: '44444444-4444-4444-4444-444444444444',
      name: 'Test Product 1',
      description: 'Test Description 1',
      price: '10.50',
      category: 'seeds',
      image_url: 'http://example.com/image1.jpg',
      created_at: new Date().toISOString(),
      seller_id: '11111111-1111-1111-1111-111111111111'
    },
    {
      id: '55555555-5555-5555-5555-555555555555',
      name: 'Test Product 2',
      description: 'Test Description 2',
      price: '20.00',
      category: 'fertilizers',
      image_url: 'http://example.com/image2.jpg',
      created_at: new Date().toISOString(),
      seller_id: '22222222-2222-2222-2222-222222222222'
    }
  ];
  
  db.__addTestData('products', testProducts);
  return testProducts;
};

// Initialize test data
const initializeTestData = async () => {
  // Reset the database
  db.__reset();
  
  // Create test data
  const { testUsers, tokens } = await createTestUsers();
  const testProducts = await createTestProducts();
  
  return {
    testUsers,
    testProducts,
    tokens
  };
};

module.exports = {
  initializeTestData,
  createTestUsers,
  createTestProducts
};

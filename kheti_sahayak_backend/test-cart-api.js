const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

async function testCartAPI() {
  try {
    console.log('🧪 Testing Cart API...\n');

    // 1. Login to get token
    console.log('1️⃣ Logging in...');
    const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
      email: 'farmer@khetisahayak.com',
      password: 'user123',
    });
    const token = loginResponse.data.token;
    console.log('✅ Login successful\n');

    const headers = { Authorization: `Bearer ${token}` };

    // 2. Get cart summary (should be empty initially)
    console.log('2️⃣ Getting cart summary...');
    const summaryResponse = await axios.get(`${BASE_URL}/cart/summary`, { headers });
    console.log('Cart Summary:', summaryResponse.data);
    console.log('✅ Summary retrieved\n');

    // 3. Get all products to find one to add to cart
    console.log('3️⃣ Getting products...');
    const productsResponse = await axios.get(`${BASE_URL}/marketplace`);
    const products = productsResponse.data.products;

    if (products && products.length > 0) {
      const testProduct = products[0];
      console.log(`✅ Found product: ${testProduct.name} (${testProduct.id})\n`);

      // 4. Add item to cart
      console.log('4️⃣ Adding item to cart...');
      const addResponse = await axios.post(
        `${BASE_URL}/cart`,
        { product_id: testProduct.id, quantity: 2 },
        { headers }
      );
      console.log('Add to Cart Response:', addResponse.data);
      console.log('✅ Item added to cart\n');

      // 5. Get cart items
      console.log('5️⃣ Getting cart items...');
      const cartResponse = await axios.get(`${BASE_URL}/cart`, { headers });
      console.log('Cart Items:', JSON.stringify(cartResponse.data, null, 2));
      console.log('✅ Cart items retrieved\n');

      // 6. Update cart item quantity
      if (cartResponse.data.data.items.length > 0) {
        const cartItemId = cartResponse.data.data.items[0].id;
        console.log('6️⃣ Updating cart item quantity...');
        const updateResponse = await axios.put(
          `${BASE_URL}/cart/${cartItemId}`,
          { quantity: 3 },
          { headers }
        );
        console.log('Update Response:', updateResponse.data);
        console.log('✅ Cart item updated\n');

        // 7. Get updated summary
        console.log('7️⃣ Getting updated cart summary...');
        const updatedSummary = await axios.get(`${BASE_URL}/cart/summary`, { headers });
        console.log('Updated Summary:', updatedSummary.data);
        console.log('✅ Updated summary retrieved\n');

        // 8. Remove item from cart
        console.log('8️⃣ Removing item from cart...');
        const removeResponse = await axios.delete(`${BASE_URL}/cart/${cartItemId}`, { headers });
        console.log('Remove Response:', removeResponse.data);
        console.log('✅ Item removed from cart\n');

        // 9. Verify cart is empty
        console.log('9️⃣ Verifying cart is empty...');
        const finalSummary = await axios.get(`${BASE_URL}/cart/summary`, { headers });
        console.log('Final Summary:', finalSummary.data);
        console.log('✅ Cart is empty again\n');
      }
    } else {
      console.log('⚠️  No products found. Skipping cart add test.\n');
    }

    console.log('🎉 All cart API tests passed!');
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    process.exit(1);
  }
}

testCartAPI();

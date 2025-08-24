/**
 * Test script for ML service integration
 * 
 * This script tests the connection between the backend and ML service
 * Run with: node test-ml-integration.js
 */

const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');
const path = require('path');

// Configuration
const ML_API_URL = process.env.ML_API_URL || 'http://localhost:8000';
const TEST_IMAGE_PATH = process.argv[2] || './test-image.jpg';

async function testMLService() {
  console.log('Testing ML Service Integration');
  console.log('--------------------------');
  
  try {
    // Test 1: Check health endpoint
    console.log('\n1. Testing health endpoint...');
    const healthResponse = await axios.get(`${ML_API_URL}/health`);
    console.log('Health check response:', healthResponse.data);
    
    // Test 2: Get model info
    console.log('\n2. Testing model info endpoint...');
    const modelInfoResponse = await axios.get(`${ML_API_URL}/model-info`);
    console.log('Model info:', modelInfoResponse.data);
    
    // Test 3: Test prediction with an image
    if (fs.existsSync(TEST_IMAGE_PATH)) {
      console.log(`\n3. Testing prediction with image: ${TEST_IMAGE_PATH}`);
      
      const formData = new FormData();
      formData.append('file', fs.createReadStream(TEST_IMAGE_PATH));
      
      const predictionResponse = await axios.post(`${ML_API_URL}/predict`, formData, {
        headers: {
          ...formData.getHeaders(),
        },
      });
      
      console.log('Prediction result:', predictionResponse.data);
    } else {
      console.log(`\n3. Skipping prediction test - image not found at ${TEST_IMAGE_PATH}`);
      console.log('   Provide an image path as argument: node test-ml-integration.js ./path/to/image.jpg');
    }
    
    console.log('\nAll tests completed successfully!');
  } catch (error) {
    console.error('Error testing ML service:');
    if (error.response) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx
      console.error('Response data:', error.response.data);
      console.error('Response status:', error.response.status);
    } else if (error.request) {
      // The request was made but no response was received
      console.error('No response received. Is the ML service running?');
    } else {
      // Something happened in setting up the request that triggered an Error
      console.error('Error message:', error.message);
    }
  }
}

testMLService();
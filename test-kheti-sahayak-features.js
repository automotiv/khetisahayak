#!/usr/bin/env node

/**
 * Comprehensive Test Script for Kheti Sahayak MVP Features
 * Tests authentication, ML integration, and core agricultural features
 * Implements CodeRabbit testing standards for agricultural platform validation
 */

const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

// Configuration
const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:8080';
const TEST_IMAGE_PATH = './test-images/test-image.jpg';

class KhetiSahayakTester {
    constructor() {
        this.baseURL = API_BASE_URL;
        this.authToken = null;
        this.testResults = {};
    }

    async runAllTests() {
        console.log('🌾 Starting Kheti Sahayak MVP Feature Tests\n');
        
        try {
            // Test health check
            await this.testHealthCheck();
            
            // Test authentication flow
            await this.testAuthenticationFlow();
            
            // Test ML service integration
            await this.testMLIntegration();
            
            // Test weather service
            await this.testWeatherService();
            
            // Test crop diagnostics
            await this.testCropDiagnostics();
            
            // Print summary
            this.printTestSummary();
            
        } catch (error) {
            console.error('❌ Test suite failed:', error.message);
            process.exit(1);
        }
    }

    async testHealthCheck() {
        console.log('🔍 Testing Health Check...');
        
        try {
            const response = await axios.get(`${this.baseURL}/api/health`);
            
            if (response.status === 200) {
                console.log('✅ Health check passed');
                this.testResults.healthCheck = true;
            } else {
                throw new Error(`Health check failed with status ${response.status}`);
            }
        } catch (error) {
            console.log('❌ Health check failed:', error.message);
            this.testResults.healthCheck = false;
        }
        
        console.log('');
    }

    async testAuthenticationFlow() {
        console.log('🔐 Testing Authentication Flow...');
        
        try {
            // Test farmer registration
            const mobileNumber = '9876543210';
            const registrationData = {
                mobileNumber,
                fullName: 'Test Farmer',
                primaryCrop: 'Rice',
                state: 'Maharashtra',
                district: 'Nashik',
                farmSize: 2.5
            };
            
            console.log('  📱 Testing farmer registration...');
            const registerResponse = await axios.post(
                `${this.baseURL}/api/auth/register`,
                null,
                { params: registrationData }
            );
            
            if (registerResponse.status === 200) {
                console.log('  ✅ Registration OTP sent successfully');
            }
            
            // Simulate OTP verification (in test mode, any 6-digit OTP should work)
            console.log('  🔑 Testing OTP verification...');
            const verifyData = {
                mobileNumber,
                otp: '123456',  // Test OTP
                ...registrationData
            };
            
            try {
                const verifyResponse = await axios.post(
                    `${this.baseURL}/api/auth/verify-otp`,
                    null,
                    { params: verifyData }
                );
                
                if (verifyResponse.status === 200 && verifyResponse.data.token) {
                    this.authToken = verifyResponse.data.token;
                    console.log('  ✅ OTP verification successful, token received');
                    this.testResults.authentication = true;
                } else {
                    throw new Error('OTP verification failed');
                }
            } catch (error) {
                // Try login flow instead (user might already exist)
                console.log('  🔄 Trying login flow...');
                await this.testLoginFlow(mobileNumber);
            }
            
        } catch (error) {
            console.log('  ❌ Authentication flow failed:', error.message);
            this.testResults.authentication = false;
        }
        
        console.log('');
    }

    async testLoginFlow(mobileNumber) {
        try {
            // Send login OTP
            const loginResponse = await axios.post(
                `${this.baseURL}/api/auth/login`,
                null,
                { params: { mobileNumber } }
            );
            
            if (loginResponse.status === 200) {
                console.log('  📱 Login OTP sent successfully');
            }
            
            // Verify login OTP
            const verifyLoginResponse = await axios.post(
                `${this.baseURL}/api/auth/verify-login`,
                null,
                { params: { mobileNumber, otp: '123456' } }
            );
            
            if (verifyLoginResponse.status === 200 && verifyLoginResponse.data.token) {
                this.authToken = verifyLoginResponse.data.token;
                console.log('  ✅ Login successful, token received');
                this.testResults.authentication = true;
            }
        } catch (error) {
            console.log('  ❌ Login flow failed:', error.message);
            this.testResults.authentication = false;
        }
    }

    async testMLIntegration() {
        console.log('🤖 Testing ML Service Integration...');
        
        try {
            // Test model info endpoint
            console.log('  📊 Testing model information...');
            const modelInfoResponse = await axios.get(`${this.baseURL}/api/diagnostics/model-info`);
            
            if (modelInfoResponse.status === 200) {
                const modelInfo = modelInfoResponse.data;
                console.log(`  ✅ Model info retrieved: ${modelInfo.model_name || 'Unknown'}`);
                console.log(`  📡 Service status: ${modelInfo.serviceStatus || 'Unknown'}`);
                this.testResults.mlIntegration = true;
            } else {
                throw new Error('Model info request failed');
            }
            
        } catch (error) {
            console.log('  ❌ ML integration test failed:', error.message);
            this.testResults.mlIntegration = false;
        }
        
        console.log('');
    }

    async testWeatherService() {
        console.log('🌤️ Testing Weather Service...');
        
        try {
            // Test weather API with coordinates (Nashik, Maharashtra)
            const weatherResponse = await axios.get(`${this.baseURL}/api/weather`, {
                params: {
                    lat: 19.9975,
                    lon: 73.7898
                }
            });
            
            if (weatherResponse.status === 200) {
                console.log('  ✅ Weather data retrieved successfully');
                this.testResults.weatherService = true;
            } else {
                throw new Error('Weather service request failed');
            }
            
        } catch (error) {
            console.log('  ❌ Weather service test failed:', error.message);
            this.testResults.weatherService = false;
        }
        
        console.log('');
    }

    async testCropDiagnostics() {
        console.log('🔬 Testing Crop Diagnostics...');
        
        try {
            // Check if test image exists
            if (!fs.existsSync(TEST_IMAGE_PATH)) {
                console.log('  ⚠️ Test image not found, creating dummy image...');
                await this.createDummyTestImage();
            }
            
            // Test crop diagnostics with image upload
            console.log('  📸 Testing image upload and diagnosis...');
            
            const formData = new FormData();
            formData.append('image', fs.createReadStream(TEST_IMAGE_PATH));
            formData.append('cropType', 'Rice');
            formData.append('symptoms', 'Yellow spots on leaves');
            formData.append('latitude', '19.9975');
            formData.append('longitude', '73.7898');
            
            const headers = {
                ...formData.getHeaders(),
            };
            
            if (this.authToken) {
                headers.Authorization = `Bearer ${this.authToken}`;
            }
            
            const diagnosticsResponse = await axios.post(
                `${this.baseURL}/api/diagnostics/upload`,
                formData,
                { headers }
            );
            
            if (diagnosticsResponse.status === 200) {
                const diagnosis = diagnosticsResponse.data;
                console.log('  ✅ Crop diagnosis completed successfully');
                console.log(`  🎯 Status: ${diagnosis.status}`);
                
                if (diagnosis.diagnosis) {
                    console.log(`  📋 Diagnosis available: Yes`);
                }
                
                this.testResults.cropDiagnostics = true;
            } else {
                throw new Error('Crop diagnostics request failed');
            }
            
        } catch (error) {
            console.log('  ❌ Crop diagnostics test failed:', error.message);
            this.testResults.cropDiagnostics = false;
        }
        
        console.log('');
    }

    async createDummyTestImage() {
        // Create a simple test image (1x1 pixel PNG)
        const dummyPngData = Buffer.from([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
            0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
            0x54, 0x08, 0xD7, 0x63, 0xF8, 0x00, 0x00, 0x00,
            0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x37,
            0x6E, 0xF9, 0x24, 0x00, 0x00, 0x00, 0x00, 0x49,
            0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
        ]);
        
        // Ensure test-images directory exists
        const dir = path.dirname(TEST_IMAGE_PATH);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        
        fs.writeFileSync(TEST_IMAGE_PATH, dummyPngData);
    }

    printTestSummary() {
        console.log('📊 Test Summary:');
        console.log('================');
        
        const tests = [
            { name: 'Health Check', key: 'healthCheck' },
            { name: 'Authentication Flow', key: 'authentication' },
            { name: 'ML Integration', key: 'mlIntegration' },
            { name: 'Weather Service', key: 'weatherService' },
            { name: 'Crop Diagnostics', key: 'cropDiagnostics' }
        ];
        
        let passedCount = 0;
        
        tests.forEach(test => {
            const status = this.testResults[test.key] ? '✅ PASS' : '❌ FAIL';
            console.log(`${test.name}: ${status}`);
            if (this.testResults[test.key]) passedCount++;
        });
        
        console.log('================');
        console.log(`Total: ${passedCount}/${tests.length} tests passed`);
        
        if (passedCount === tests.length) {
            console.log('🎉 All tests passed! Kheti Sahayak MVP is ready.');
        } else {
            console.log('⚠️ Some tests failed. Please check the implementation.');
        }
    }
}

// Run tests if this script is executed directly
if (require.main === module) {
    const tester = new KhetiSahayakTester();
    tester.runAllTests().catch(error => {
        console.error('Test execution failed:', error);
        process.exit(1);
    });
}

module.exports = KhetiSahayakTester;

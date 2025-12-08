const axios = require('axios');

async function testMLService() {
    console.log('Testing ML Service directly...');
    try {
        const response = await axios.post('http://localhost:8000/recommend-crops', {
            nitrogen: 60,
            phosphorus: 40,
            potassium: 40,
            ph: 6.5,
            rainfall: 100,
            temperature: 25,
            humidity: 60,
            soil_type: 'Loam',
            season: 'Kharif'
        });
        console.log('ML Service Response:', JSON.stringify(response.data, null, 2));
    } catch (error) {
        console.error('ML Service Error:', error.message);
        if (error.response) {
            console.error('Data:', error.response.data);
        }
    }
}

testMLService();

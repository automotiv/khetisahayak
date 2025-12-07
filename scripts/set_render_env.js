const fs = require('fs');
const path = require('path');

// Try to load API key
let apiKey = process.env.RENDER_API_KEY;
if (!apiKey) {
    try {
        const envPath = path.join(__dirname, '../render_mcp/.env');
        if (fs.existsSync(envPath)) {
            const envContent = fs.readFileSync(envPath, 'utf8');
            const match = envContent.match(/RENDER_API_KEY=(.*)/);
            if (match) apiKey = match[1].trim();
        }
    } catch (e) { }
}

if (!apiKey) {
    console.error('❌ Error: RENDER_API_KEY not found.');
    process.exit(1);
}

const API_URL = 'https://api.render.com/v1';
const SERVICE_NAME = 'khetisahayak';
const INTERNAL_DB_URL = 'postgresql://khetisahayak:HmKhnspjGDAruyyB83cd89UProBhe59K@dpg-d4ludg0gjchc73aud3fg-a/khetisahayak';

async function setEnvVar() {
    try {
        // 1. Find Service ID
        const servicesRes = await fetch(`${API_URL}/services?limit=100`, {
            headers: { 'Authorization': `Bearer ${apiKey}` }
        });
        const services = await servicesRes.json();
        const service = services.find(s => s.service.name === SERVICE_NAME);

        if (!service) {
            console.error('❌ Service not found');
            process.exit(1);
        }

        const serviceId = service.service.id;
        console.log(`Service ID: ${serviceId}`);

        // 2. Set Environment Variable
        console.log(`Setting DATABASE_URL...`);
        const envRes = await fetch(`${API_URL}/services/${serviceId}/env-vars`, {
            method: 'PUT',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify([
                {
                    key: 'DATABASE_URL',
                    value: INTERNAL_DB_URL
                }
            ])
        });

        if (!envRes.ok) {
            const errText = await envRes.text();
            throw new Error(`Failed to set env var: ${envRes.statusText} - ${errText}`);
        }

        const result = await envRes.json();
        console.log('✅ DATABASE_URL set successfully!');
        console.log(JSON.stringify(result, null, 2));

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

setEnvVar();

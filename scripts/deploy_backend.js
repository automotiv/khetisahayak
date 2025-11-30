const fs = require('fs');
const path = require('path');

// Try to load API key from render_mcp/.env
let apiKey = process.env.RENDER_API_KEY;
if (!apiKey) {
    try {
        const envPath = path.join(__dirname, '../render_mcp/.env');
        if (fs.existsSync(envPath)) {
            const envContent = fs.readFileSync(envPath, 'utf8');
            const match = envContent.match(/RENDER_API_KEY=(.*)/);
            if (match) {
                apiKey = match[1].trim();
            }
        }
    } catch (e) {
        // Ignore error
    }
}

if (!apiKey) {
    console.error('❌ Error: RENDER_API_KEY not found. Please set it in environment or render_mcp/.env');
    process.exit(1);
}

const API_URL = 'https://api.render.com/v1';

async function deployBackend() {
    try {
        console.log('🔍 Finding backend service...');
        const servicesRes = await fetch(`${API_URL}/services?limit=100`, {
            headers: { 'Authorization': `Bearer ${apiKey}` }
        });

        if (!servicesRes.ok) throw new Error(`Failed to list services: ${servicesRes.statusText}`);

        const services = await servicesRes.json();
        const backendService = services.find(s => s.service.name === 'kheti_sahayak_backend'); // Adjust name if needed

        if (!backendService) {
            console.error('❌ Error: Service "kheti_sahayak_backend" not found.');
            process.exit(1);
        }

        const serviceId = backendService.service.id;
        console.log(`✅ Found service: ${backendService.service.name} (${serviceId})`);

        console.log('🚀 Triggering deploy...');
        const deployRes = await fetch(`${API_URL}/services/${serviceId}/deploys`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ clearCache: false })
        });

        if (!deployRes.ok) throw new Error(`Failed to trigger deploy: ${deployRes.statusText}`);

        const deploy = await deployRes.json();
        console.log(`✅ Deploy triggered successfully!`);
        console.log(`   Deploy ID: ${deploy.id}`);
        console.log(`   Status: ${deploy.status}`);
        console.log(`   URL: https://dashboard.render.com/web/${serviceId}/deploys/${deploy.id}`);

    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

deployBackend();

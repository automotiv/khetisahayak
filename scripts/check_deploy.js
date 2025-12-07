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

async function checkDeploy() {
    try {
        const servicesRes = await fetch(`${API_URL}/services?limit=100`, {
            headers: { 'Authorization': `Bearer ${apiKey}` }
        });
        const services = await servicesRes.json();
        const service = services.find(s => s.service.name === 'khetisahayak');

        if (!service) {
            console.error('❌ Service not found');
            process.exit(1);
        }

        const serviceId = service.service.id;
        console.log(`Service ID: ${serviceId}`);

        const deploysRes = await fetch(`${API_URL}/services/${serviceId}/deploys?limit=1`, {
            headers: { 'Authorization': `Bearer ${apiKey}` }
        });
        const deploys = await deploysRes.json();

        if (deploys.length > 0) {
            const deploy = deploys[0].deploy;
            console.log(`Latest Deploy:`);
            console.log(`  ID: ${deploy.id}`);
            console.log(`  Status: ${deploy.status}`);
            console.log(`  Commit: ${deploy.commit ? deploy.commit.message : 'N/A'}`);
            console.log(`  Created At: ${deploy.createdAt}`);
            console.log(`  Finished At: ${deploy.finishedAt}`);
        } else {
            console.log('No deploys found.');
        }

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

checkDeploy();

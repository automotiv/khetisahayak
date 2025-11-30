import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const API_KEY = process.env.RENDER_API_KEY;
const OWNER_ID = "tea-d4lu9bkhg0os73bgbsug"; // From previous steps

const apiClient = axios.create({
    baseURL: "https://api.render.com/v1",
    headers: {
        Authorization: `Bearer ${API_KEY}`,
        Accept: "application/json",
    },
});

async function createBackend() {
    try {
        console.log("Creating Backend Web Service...");

        const payload = {
            type: "web_service",
            name: "kheti-sahayak-backend",
            ownerId: OWNER_ID,
            repo: "https://github.com/automotiv/khetisahayak",
            branch: "main",
            rootDir: "kheti_sahayak_backend",
            serviceDetails: {
                buildCommand: "npm install",
                startCommand: "npm start",
                env: "node",
                plan: "free",
                region: "singapore",
                envVars: [
                    {
                        key: "NODE_ENV",
                        value: "production"
                    },
                    {
                        key: "DATABASE_URL",
                        value: "postgresql://khetisahayak:HmKhnspjGDAruyyB83cd89UProBhe59K@dpg-d4ludg0gjchc73aud3fg-a/khetisahayak"
                    },
                    {
                        key: "REDIS_URL",
                        value: "redis://red-d4lul163jp1c739jfvk0:6379"
                    }
                ]
            }
        };

        const response = await apiClient.post("/services", payload);
        console.log("Backend service created successfully!");
        console.log("Service ID:", response.data.id);
        console.log("URL:", response.data.serviceDetails?.url);
        console.log("Full Details:", JSON.stringify(response.data, null, 2));

    } catch (error) {
        console.error("Error:", error.response?.data || error.message);
    }
}

createBackend();

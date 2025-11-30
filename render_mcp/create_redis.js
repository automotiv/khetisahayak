import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const API_KEY = process.env.RENDER_API_KEY;

if (!API_KEY) {
    console.error("Error: RENDER_API_KEY environment variable is required");
    process.exit(1);
}

const apiClient = axios.create({
    baseURL: "https://api.render.com/v1",
    headers: {
        Authorization: `Bearer ${API_KEY}`,
        Accept: "application/json",
    },
});

async function createRedis() {
    try {
        // 1. Get Owner ID
        console.log("Fetching owners...");
        const ownersResponse = await apiClient.get("/owners");
        const owners = ownersResponse.data;
        console.log("Raw Owners Response:", JSON.stringify(owners, null, 2));

        // Handle pagination if necessary (Render API returns a list directly usually, but let's check)
        let ownerId;
        if (Array.isArray(owners)) {
            if (owners.length > 0) {
                ownerId = owners[0].owner.id;
            } else {
                console.error("No owners found in array.");
                return;
            }
        } else {
            console.error("Unexpected response format.");
            return;
        }

        console.log(`Using Owner ID: ${ownerId}`);

        // 2. Create Redis Service
        console.log("Creating Redis service...");
        const redisPayload = {
            name: "khetisahayak-redis",
            ownerId: ownerId,
            plan: "free", // Explicitly requesting free plan
            region: "singapore", // Matching the DB region
        };

        const createResponse = await apiClient.post("/redis", redisPayload);
        console.log("Redis service created successfully!");
        console.log("Service ID:", createResponse.data.id);
        console.log("Service Details:", JSON.stringify(createResponse.data, null, 2));

    } catch (error) {
        if (axios.isAxiosError(error)) {
            console.error("API Error:", error.response?.data || error.message);
        } else {
            console.error("Error:", error);
        }
    }
}

createRedis();

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

async function createBlueprint() {
    try {
        console.log("Creating Blueprint...");

        const payload = {
            title: "Kheti Sahayak",
            ownerId: OWNER_ID,
            repo: "https://github.com/automotiv/khetisahayak",
            branch: "main",
            autoSync: true
        };

        const response = await apiClient.post("/blueprints", payload);
        console.log("Blueprint created successfully!");
        console.log("Blueprint ID:", response.data.id);
        console.log("Full Details:", JSON.stringify(response.data, null, 2));

    } catch (error) {
        console.error("Error:", error.response?.data || error.message);
    }
}

createBlueprint();

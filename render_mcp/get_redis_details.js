import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const API_KEY = process.env.RENDER_API_KEY;
const REDIS_ID = "red-d4lul163jp1c739jfvk0";

const apiClient = axios.create({
    baseURL: "https://api.render.com/v1",
    headers: {
        Authorization: `Bearer ${API_KEY}`,
        Accept: "application/json",
    },
});

async function getRedisDetails() {
    try {
        console.log(`Listing Redis services...`);
        const response = await apiClient.get(`/redis`);
        console.log("Redis List:", JSON.stringify(response.data, null, 2));
    } catch (error) {
        console.error("Error:", error.response?.data || error.message);
    }
}

getRedisDetails();

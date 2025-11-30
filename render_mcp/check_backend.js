import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const API_KEY = process.env.RENDER_API_KEY;

const apiClient = axios.create({
    baseURL: "https://api.render.com/v1",
    headers: {
        Authorization: `Bearer ${API_KEY}`,
        Accept: "application/json",
    },
});

async function checkBackend() {
    try {
        console.log("Listing services...");
        const response = await apiClient.get("/services");
        console.log("Raw Services Response:", JSON.stringify(response.data, null, 2));
        const services = response.data;

        const backendService = services.find(s => s.service.name === 'kheti-sahayak-backend' || s.service.name === 'khetisahayak-backend');

        if (backendService) {
            console.log("Backend Service Found:");
            console.log(`Name: ${backendService.service.name}`);
            console.log(`ID: ${backendService.service.id}`);
            console.log(`Status: ${backendService.service.serviceDetails?.status || 'Unknown'}`); // Adjust based on actual API response structure
            console.log(`URL: ${backendService.service.serviceDetails?.url || 'Unknown'}`);

            // Log full details to understand structure
            console.log("Full Details:", JSON.stringify(backendService, null, 2));
        } else {
            console.log("Backend service 'kheti-sahayak-backend' not found.");
            console.log("Available services:", services.map(s => s.service.name).join(", "));
        }

    } catch (error) {
        console.error("Error:", error.response?.data || error.message);
    }
}

checkBackend();

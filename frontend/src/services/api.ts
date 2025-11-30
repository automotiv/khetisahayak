import axios from 'axios';


// Use environment variable or default to localhost
const API_URL = (import.meta as any).env.VITE_API_URL || 'http://localhost:3000/api';

const api = axios.create({
    baseURL: API_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

export const khetiApi = {
    // Weather
    getWeather: async (lat: number, lng: number) => {
        const response = await api.get(`/weather?lat=${lat}&lon=${lng}`);
        return response.data;
    },

    // Marketplace
    getProducts: async () => {
        const response = await api.get('/marketplace/products');
        return response.data;
    },

    // Diagnostics
    getDiagnosticsHistory: async () => {
        const response = await api.get('/diagnostics/history');
        return response.data;
    },

    // Educational Content
    getEducationalContent: async () => {
        const response = await api.get('/educational-content');
        return response.data;
    },

    // Experts
    getExperts: async () => {
        // Mocking this for now as backend might not have it fully ready or it's under a different route
        // If you have an experts route, replace this.
        return [];
    },

    // Forum
    getForumPosts: async () => {
        // Mocking for now
        return [];
    }
};

export default api;

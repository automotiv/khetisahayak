import axios from 'axios';

// Types for external API responses
export interface AgroWeatherData {
    success: boolean;
    location: {
        lat: number;
        lon: number;
        timezone: string;
        elevation?: number;
    };
    current: {
        temperature: number;
        humidity: number;
        precipitation: number;
        rain: number;
        weatherCode: number;
        windSpeed: number;
        soilTemperature?: number;
        soilMoisture?: number;
        timestamp: string;
    };
    daily: Array<{
        date: string;
        tempMax: number;
        tempMin: number;
        precipitationSum: number;
        precipitationProbability: number;
        sunrise: string;
        sunset: string;
        uvIndexMax: number;
        evapotranspiration: number;
    }>;
    agriculturalInsights: Array<{
        type: string;
        severity: 'high' | 'medium' | 'low';
        message: string;
        message_hi?: string;
    }>;
    source: string;
}

export interface SoilData {
    success: boolean;
    location: { lat: number; lon: number };
    soilProperties: {
        clay?: Record<string, { value: number; unit: string }>;
        sand?: Record<string, { value: number; unit: string }>;
        silt?: Record<string, { value: number; unit: string }>;
        ph?: Record<string, { value: number; unit: string }>;
        organicCarbon?: Record<string, { value: number; unit: string }>;
        soilType?: string;
        suitableCrops?: string[];
    };
    recommendations: string[];
    source: string;
    isMock?: boolean;
}

export interface MarketPriceData {
    success: boolean;
    timestamp?: string;
    currency?: string;
    unit?: string;
    prices: Array<{
        commodity: string;
        variety?: string;
        grade?: string;
        minPrice: number;
        maxPrice: number;
        modalPrice: number;
        market?: string;
        state?: string;
        district?: string;
        trend?: 'up' | 'down';
        changePercent?: number;
        lastUpdated?: string;
        arrivalDate?: string;
        priceUnit?: string;
        priceRange?: string;
    }>;
    marketTrends?: {
        topGainers: Array<any>;
        topLosers: Array<any>;
        advice: string;
    };
    source: string;
    cache?: {
        hit: boolean;
        key: string;
        ttl: number;
        ttlFormatted: string;
    };
}

export interface AgriNewsData {
    success: boolean;
    category: string;
    language: string;
    articles: Array<{
        title: string;
        description?: string;
        url?: string;
        image?: string;
        publishedAt?: string;
        source?: string;
    }>;
    relatedTopics: string[];
    source: string;
}

export interface CropCalendarData {
    success: boolean;
    location: {
        lat: number;
        lon: number;
        climateZone: string;
        currentSeason: string;
    };
    currentMonth: string;
    calendar: {
        season: string;
        climateZone: string;
        crops: Array<{
            name: string;
            sowingStart: string;
            sowingEnd: string;
            harvestStart: string;
            harvestEnd: string;
            status: 'Sowing Time' | 'Growing' | 'Harvest Time' | 'Off Season';
        }>;
    };
    recommendations: string[];
}

export interface PestAlertData {
    success: boolean;
    location: { lat: number; lon: number };
    currentConditions: {
        temperature: number;
        humidity: number;
        precipitation: number;
    };
    alerts: Array<{
        pest: string;
        risk: 'High' | 'Medium' | 'Low';
        message: string;
        message_hi?: string;
        affectedCrops: string[];
    }>;
    preventiveMeasures: string[];
    source: string;
}

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
    getWeather: async (lat: number, lon: number) => {
        const response = await api.get(`/weather/current?lat=${lat}&lon=${lon}`);
        return response.data;
    },

    getForecast: async (lat: number, lon: number, city?: string) => {
        const query = city ? `city=${city}` : `lat=${lat}&lon=${lon}`;
        const response = await api.get(`/weather/forecast?${query}`);
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
        const response = await api.get('/experts');
        return response.data;
    },

    // Forum / Community
    getForumPosts: async () => {
        const response = await api.get('/community');
        return response.data;
    },

    // News
    getNews: async () => {
        const response = await api.get('/news');
        return response.data;
    },

    // Market Prices (Mandi)
    getMarketPrices: async (state?: string, commodity?: string) => {
        const params = new URLSearchParams();
        if (state) params.append('state', state);
        if (commodity) params.append('commodity', commodity);

        const response = await api.get(`/market-prices?${params.toString()}`);
        return response.data;
    },

    // Notifications
    getNotifications: async () => {
        const response = await api.get('/notifications');
        return response.data;
    }
};

// ============================================================================
// External API Service - Free Public APIs Integration
// ============================================================================
export const externalApi = {
    /**
     * Get agricultural weather data (Open-Meteo API)
     * Includes: soil moisture, evapotranspiration, UV index, 7-day forecast
     */
    getAgroWeather: async (lat: number, lon: number): Promise<AgroWeatherData> => {
        const response = await api.get(`/external/agro-weather?lat=${lat}&lon=${lon}`);
        return response.data;
    },

    /**
     * Get soil composition data (SoilGrids API)
     * Includes: clay/sand/silt %, pH, organic carbon, nitrogen
     */
    getSoilData: async (lat: number, lon: number): Promise<SoilData> => {
        const response = await api.get(`/external/soil-data?lat=${lat}&lon=${lon}`);
        return response.data;
    },

    /**
     * Get commodity market prices
     * @param commodity - Filter by commodity (wheat, rice, etc.)
     * @param state - Filter by state
     */
    getMarketPrices: async (commodity?: string, state?: string): Promise<MarketPriceData> => {
        const params = new URLSearchParams();
        if (commodity) params.append('commodity', commodity);
        if (state) params.append('state', state);
        const response = await api.get(`/external/market-prices?${params.toString()}`);
        return response.data;
    },

    /**
     * Get agricultural news
     * @param category - crops, weather, policy, technology, markets
     * @param lang - Language code (en, hi)
     */
    getAgriNews: async (category?: string, lang: string = 'en'): Promise<AgriNewsData> => {
        const params = new URLSearchParams({ lang });
        if (category) params.append('category', category);
        const response = await api.get(`/external/news?${params.toString()}`);
        return response.data;
    },

    /**
     * Get crop calendar based on location and season
     * @param crop - Filter by specific crop
     */
    getCropCalendar: async (lat: number, lon: number, crop?: string): Promise<CropCalendarData> => {
        const params = new URLSearchParams({ lat: lat.toString(), lon: lon.toString() });
        if (crop) params.append('crop', crop);
        const response = await api.get(`/external/crop-calendar?${params.toString()}`);
        return response.data;
    },

    /**
     * Get pest and disease alerts based on weather conditions
     * @param crop - Filter alerts for specific crop
     */
    getPestAlerts: async (lat: number, lon: number, crop?: string): Promise<PestAlertData> => {
        const params = new URLSearchParams({ lat: lat.toString(), lon: lon.toString() });
        if (crop) params.append('crop', crop);
        const response = await api.get(`/external/pest-alerts?${params.toString()}`);
        return response.data;
    }
};

export default api;

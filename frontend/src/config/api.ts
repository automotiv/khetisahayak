/**
 * API Configuration for Kheti Sahayak Frontend
 * Updated to use Spring Boot backend as primary service
 */

// Environment-based API configuration
const getApiConfig = () => {
  const env = (import.meta as any).env?.MODE || 'development';
  
  switch (env) {
    case 'production':
      return {
        baseURL: (import.meta as any).env?.VITE_API_BASE_URL || 'https://api.khetisahayak.com',
        timeout: 30000,
        withCredentials: true,
      };
    case 'staging':
      return {
        baseURL: (import.meta as any).env?.VITE_API_BASE_URL || 'https://staging-api.khetisahayak.com',
        timeout: 30000,
        withCredentials: true,
      };
    case 'development':
    default:
      return {
        baseURL: (import.meta as any).env?.VITE_API_BASE_URL || 'http://localhost:8080',
        timeout: 15000,
        withCredentials: true,
      };
  }
};

export const API_CONFIG = getApiConfig();

// API Endpoints mapping to Spring Boot controllers
export const API_ENDPOINTS = {
  // Authentication endpoints
  AUTH: {
    LOGIN: '/api/auth/login',
    REGISTER: '/api/auth/register',
    LOGOUT: '/api/auth/logout',
    PROFILE: '/api/auth/profile',
    REFRESH: '/api/auth/refresh',
  },
  
  // Health check endpoints
  HEALTH: {
    CHECK: '/api/health',
    DETAILED: '/actuator/health',
  },
  
  // Weather service endpoints
  WEATHER: {
    CURRENT: '/api/weather',
    FORECAST: '/api/weather/forecast',
    ALERTS: '/api/weather/alerts',
  },
  
  // Crop diagnostics endpoints
  DIAGNOSTICS: {
    UPLOAD: '/api/diagnostics/upload',
    HISTORY: '/api/diagnostics',
    RECOMMENDATIONS: '/api/diagnostics/recommendations',
    EXPERT_REVIEW: '/api/diagnostics/{id}/expert-review',
    STATS: '/api/diagnostics/stats',
  },
  
  // Marketplace endpoints (to be implemented in Spring Boot)
  MARKETPLACE: {
    PRODUCTS: '/api/marketplace/products',
    CATEGORIES: '/api/marketplace/categories',
    SEARCH: '/api/marketplace/search',
    ORDERS: '/api/marketplace/orders',
  },
  
  // Educational content endpoints (to be implemented)
  EDUCATION: {
    CONTENT: '/api/education/content',
    CATEGORIES: '/api/education/categories',
    BOOKMARKS: '/api/education/bookmarks',
  },
  
  // Expert consultation endpoints (to be implemented)
  EXPERTS: {
    LIST: '/api/experts',
    BOOK: '/api/experts/book',
    SESSIONS: '/api/experts/sessions',
  },
  
  // Community forum endpoints (to be implemented)
  COMMUNITY: {
    POSTS: '/api/community/posts',
    TOPICS: '/api/community/topics',
    REPLIES: '/api/community/replies',
  },
  
  // Government schemes endpoints (to be implemented)
  SCHEMES: {
    LIST: '/api/schemes',
    APPLY: '/api/schemes/apply',
    STATUS: '/api/schemes/status',
  },
  
  // Notifications endpoints (to be implemented)
  NOTIFICATIONS: {
    LIST: '/api/notifications',
    MARK_READ: '/api/notifications/{id}/read',
    PREFERENCES: '/api/notifications/preferences',
  },
};

// API Response types for better type safety
export interface ApiResponse<T = any> {
  success: boolean;
  data: T;
  message?: string;
  errors?: string[];
  timestamp: string;
}

export interface PaginatedResponse<T = any> extends ApiResponse<T[]> {
  pagination: {
    page: number;
    size: number;
    total: number;
    totalPages: number;
  };
}

// Error response type
export interface ApiError {
  success: false;
  error: string;
  code: string;
  timestamp: string;
  details?: any;
}

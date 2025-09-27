/**
 * API Client for Kheti Sahayak Frontend
 * Configured to work with Spring Boot backend
 */

import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios';
import { API_CONFIG, ApiResponse, ApiError } from '../config/api';

class ApiClient {
  private client: AxiosInstance;
  private authToken: string | null = null;

  constructor() {
    this.client = axios.create({
      baseURL: API_CONFIG.baseURL,
      timeout: API_CONFIG.timeout,
      withCredentials: API_CONFIG.withCredentials,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    });

    this.setupInterceptors();
    this.loadAuthToken();
  }

  private setupInterceptors() {
    // Request interceptor to add auth token
    this.client.interceptors.request.use(
      (config) => {
        if (this.authToken) {
          config.headers.Authorization = `Bearer ${this.authToken}`;
        }
        
        // Add request timestamp for debugging
        config.metadata = { startTime: new Date() };
        
        console.log(`🚀 API Request: ${config.method?.toUpperCase()} ${config.url}`);
        return config;
      },
      (error) => {
        console.error('❌ Request interceptor error:', error);
        return Promise.reject(error);
      }
    );

    // Response interceptor for error handling
    this.client.interceptors.response.use(
      (response: AxiosResponse) => {
        const endTime = new Date();
        const duration = endTime.getTime() - response.config.metadata?.startTime?.getTime();
        
        console.log(`✅ API Response: ${response.config.method?.toUpperCase()} ${response.config.url} (${duration}ms)`);
        return response;
      },
      (error) => {
        const endTime = new Date();
        const duration = endTime.getTime() - error.config?.metadata?.startTime?.getTime();
        
        console.error(`❌ API Error: ${error.config?.method?.toUpperCase()} ${error.config?.url} (${duration}ms)`, error);
        
        // Handle specific error cases
        if (error.response?.status === 401) {
          this.handleAuthError();
        } else if (error.response?.status >= 500) {
          this.handleServerError(error);
        }
        
        return Promise.reject(this.formatError(error));
      }
    );
  }

  private loadAuthToken() {
    const token = localStorage.getItem('kheti_sahayak_token');
    if (token) {
      this.setAuthToken(token);
    }
  }

  public setAuthToken(token: string) {
    this.authToken = token;
    localStorage.setItem('kheti_sahayak_token', token);
  }

  public clearAuthToken() {
    this.authToken = null;
    localStorage.removeItem('kheti_sahayak_token');
  }

  private handleAuthError() {
    console.warn('🔒 Authentication error - clearing token');
    this.clearAuthToken();
    // Redirect to login page or dispatch auth error action
    window.location.href = '/login';
  }

  private handleServerError(error: any) {
    console.error('🚨 Server error:', error);
    // Could integrate with error reporting service here
  }

  private formatError(error: any): ApiError {
    if (error.response?.data) {
      // Spring Boot error response format
      return {
        success: false,
        error: error.response.data.error || error.response.data.message || 'Unknown error',
        code: error.response.data.code || `HTTP_${error.response.status}`,
        timestamp: error.response.data.timestamp || new Date().toISOString(),
        details: error.response.data.details,
      };
    } else if (error.request) {
      // Network error
      return {
        success: false,
        error: 'Network error - please check your connection',
        code: 'NETWORK_ERROR',
        timestamp: new Date().toISOString(),
      };
    } else {
      // Other error
      return {
        success: false,
        error: error.message || 'An unexpected error occurred',
        code: 'UNKNOWN_ERROR',
        timestamp: new Date().toISOString(),
      };
    }
  }

  // Generic HTTP methods
  public async get<T = any>(url: string, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
    const response = await this.client.get(url, config);
    return response.data;
  }

  public async post<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
    const response = await this.client.post(url, data, config);
    return response.data;
  }

  public async put<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
    const response = await this.client.put(url, data, config);
    return response.data;
  }

  public async patch<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
    const response = await this.client.patch(url, data, config);
    return response.data;
  }

  public async delete<T = any>(url: string, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
    const response = await this.client.delete(url, config);
    return response.data;
  }

  // File upload method for crop diagnostics
  public async uploadFile<T = any>(
    url: string, 
    file: File, 
    additionalData?: Record<string, any>,
    onUploadProgress?: (progressEvent: any) => void
  ): Promise<ApiResponse<T>> {
    const formData = new FormData();
    formData.append('image', file);
    
    if (additionalData) {
      Object.entries(additionalData).forEach(([key, value]) => {
        formData.append(key, value);
      });
    }

    const response = await this.client.post(url, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      onUploadProgress,
    });
    
    return response.data;
  }

  // Health check method
  public async healthCheck(): Promise<boolean> {
    try {
      const response = await this.get('/api/health');
      return response.success && response.data?.message === 'OK';
    } catch (error) {
      console.error('Health check failed:', error);
      return false;
    }
  }
}

// Create and export singleton instance
export const apiClient = new ApiClient();
export default apiClient;

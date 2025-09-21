/**
 * Weather Service for Kheti Sahayak
 * Integrates with Spring Boot Weather Controller
 */

import { apiClient } from './apiClient';
import { API_ENDPOINTS, ApiResponse } from '../config/api';

export interface WeatherData {
  current: {
    temperature: number;
    humidity: number;
    windSpeed: number;
    condition: string;
    description: string;
    icon: string;
  };
  forecast: WeatherForecast[];
  location: {
    name: string;
    latitude: number;
    longitude: number;
  };
  alerts?: WeatherAlert[];
}

export interface WeatherForecast {
  date: string;
  temperature: {
    min: number;
    max: number;
  };
  humidity: number;
  precipitation: number;
  windSpeed: number;
  condition: string;
  description: string;
  icon: string;
}

export interface WeatherAlert {
  id: string;
  type: 'warning' | 'watch' | 'advisory';
  severity: 'minor' | 'moderate' | 'severe' | 'extreme';
  title: string;
  description: string;
  startTime: string;
  endTime: string;
  areas: string[];
}

export class WeatherService {
  /**
   * Get current weather data for given coordinates
   */
  async getCurrentWeather(latitude: number, longitude: number): Promise<WeatherData> {
    try {
      const response: ApiResponse<WeatherData> = await apiClient.get(
        `${API_ENDPOINTS.WEATHER.CURRENT}?lat=${latitude}&lon=${longitude}`
      );
      
      if (response.success) {
        return response.data;
      } else {
        throw new Error(response.message || 'Failed to fetch weather data');
      }
    } catch (error) {
      console.error('Error fetching current weather:', error);
      throw error;
    }
  }

  /**
   * Get weather forecast for given coordinates
   */
  async getWeatherForecast(latitude: number, longitude: number, days: number = 7): Promise<WeatherForecast[]> {
    try {
      const response: ApiResponse<WeatherForecast[]> = await apiClient.get(
        `${API_ENDPOINTS.WEATHER.FORECAST}?lat=${latitude}&lon=${longitude}&days=${days}`
      );
      
      if (response.success) {
        return response.data;
      } else {
        throw new Error(response.message || 'Failed to fetch weather forecast');
      }
    } catch (error) {
      console.error('Error fetching weather forecast:', error);
      throw error;
    }
  }

  /**
   * Get weather alerts for given coordinates
   */
  async getWeatherAlerts(latitude: number, longitude: number): Promise<WeatherAlert[]> {
    try {
      const response: ApiResponse<WeatherAlert[]> = await apiClient.get(
        `${API_ENDPOINTS.WEATHER.ALERTS}?lat=${latitude}&lon=${longitude}`
      );
      
      if (response.success) {
        return response.data;
      } else {
        throw new Error(response.message || 'Failed to fetch weather alerts');
      }
    } catch (error) {
      console.error('Error fetching weather alerts:', error);
      throw error;
    }
  }

  /**
   * Get agricultural weather insights
   * This method combines current weather, forecast, and alerts to provide
   * farming-specific recommendations
   */
  async getAgriculturalWeatherInsights(
    latitude: number, 
    longitude: number, 
    cropType?: string
  ): Promise<{
    current: WeatherData['current'];
    forecast: WeatherForecast[];
    alerts: WeatherAlert[];
    recommendations: string[];
  }> {
    try {
      const [currentWeather, forecast, alerts] = await Promise.all([
        this.getCurrentWeather(latitude, longitude),
        this.getWeatherForecast(latitude, longitude, 5),
        this.getWeatherAlerts(latitude, longitude),
      ]);

      // Generate farming recommendations based on weather data
      const recommendations = this.generateFarmingRecommendations(
        currentWeather.current,
        forecast,
        alerts,
        cropType
      );

      return {
        current: currentWeather.current,
        forecast,
        alerts,
        recommendations,
      };
    } catch (error) {
      console.error('Error fetching agricultural weather insights:', error);
      throw error;
    }
  }

  /**
   * Generate farming recommendations based on weather data
   */
  private generateFarmingRecommendations(
    current: WeatherData['current'],
    forecast: WeatherForecast[],
    alerts: WeatherAlert[],
    cropType?: string
  ): string[] {
    const recommendations: string[] = [];

    // Temperature-based recommendations
    if (current.temperature > 35) {
      recommendations.push('High temperature detected. Increase irrigation frequency and provide shade for sensitive crops.');
    } else if (current.temperature < 10) {
      recommendations.push('Low temperature warning. Protect crops from frost and consider using row covers.');
    }

    // Humidity-based recommendations
    if (current.humidity > 80) {
      recommendations.push('High humidity levels may increase disease risk. Ensure proper ventilation and consider fungicide application.');
    } else if (current.humidity < 30) {
      recommendations.push('Low humidity detected. Increase irrigation and consider misting for sensitive plants.');
    }

    // Wind speed recommendations
    if (current.windSpeed > 20) {
      recommendations.push('Strong winds expected. Secure tall crops and avoid spraying pesticides.');
    }

    // Forecast-based recommendations
    const rainExpected = forecast.some(day => day.precipitation > 5);
    if (rainExpected) {
      recommendations.push('Rain expected in the coming days. Delay irrigation and plan harvesting activities accordingly.');
    }

    // Alert-based recommendations
    alerts.forEach(alert => {
      if (alert.severity === 'severe' || alert.severity === 'extreme') {
        recommendations.push(`Weather alert: ${alert.title}. Take immediate protective measures for crops.`);
      }
    });

    // Crop-specific recommendations
    if (cropType) {
      recommendations.push(...this.getCropSpecificRecommendations(current, forecast, cropType));
    }

    return recommendations;
  }

  /**
   * Get crop-specific weather recommendations
   */
  private getCropSpecificRecommendations(
    current: WeatherData['current'],
    forecast: WeatherForecast[],
    cropType: string
  ): string[] {
    const recommendations: string[] = [];
    const cropLower = cropType.toLowerCase();

    // Rice-specific recommendations
    if (cropLower.includes('rice') || cropLower.includes('paddy')) {
      if (current.temperature > 30 && current.humidity < 70) {
        recommendations.push('Rice crops need consistent water levels. Monitor field water depth closely.');
      }
    }

    // Wheat-specific recommendations
    if (cropLower.includes('wheat')) {
      if (current.temperature > 25) {
        recommendations.push('High temperatures can affect wheat grain filling. Consider early morning irrigation.');
      }
    }

    // Cotton-specific recommendations
    if (cropLower.includes('cotton')) {
      if (current.humidity > 85) {
        recommendations.push('High humidity increases cotton bollworm risk. Monitor for pest activity.');
      }
    }

    // Tomato-specific recommendations
    if (cropLower.includes('tomato')) {
      if (current.temperature > 32) {
        recommendations.push('High temperatures can cause tomato blossom end rot. Ensure consistent watering.');
      }
    }

    return recommendations;
  }
}

// Export singleton instance
export const weatherService = new WeatherService();
export default weatherService;

/**
 * Crop Diagnostics Service for Kheti Sahayak
 * Integrates with Spring Boot Diagnostics Controller
 */

import { apiClient } from './apiClient';
import { API_ENDPOINTS, ApiResponse } from '../config/api';

export interface DiagnosisRequest {
  image: File;
  cropType?: string;
  symptoms?: string;
  location?: {
    latitude: number;
    longitude: number;
  };
  farmingPractices?: {
    irrigationType: string;
    fertilizers: string[];
    pesticides: string[];
  };
}

export interface DiagnosisResult {
  id: string;
  imageUrl: string;
  cropType: string;
  diagnosis: string;
  confidence: number;
  severity: 'low' | 'medium' | 'high' | 'critical';
  detectedIssues: DetectedIssue[];
  recommendations: Recommendation[];
  uploadDate: string;
  status: 'processing' | 'completed' | 'expert_review' | 'failed';
  expertReview?: ExpertReview;
}

export interface DetectedIssue {
  type: 'disease' | 'pest' | 'nutrient_deficiency' | 'environmental';
  name: string;
  description: string;
  confidence: number;
  affectedArea: number; // percentage of affected area
  severity: 'low' | 'medium' | 'high' | 'critical';
}

export interface Recommendation {
  category: 'treatment' | 'prevention' | 'monitoring' | 'cultural_practice';
  title: string;
  description: string;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  timeline: string;
  cost?: {
    min: number;
    max: number;
    currency: string;
  };
  materials?: string[];
  steps?: string[];
}

export interface ExpertReview {
  expertId: string;
  expertName: string;
  qualification: string;
  reviewDate: string;
  diagnosis: string;
  confidence: number;
  recommendations: Recommendation[];
  notes: string;
  followUpRequired: boolean;
}

export interface DiagnosticStats {
  totalDiagnoses: number;
  accuracyRate: number;
  commonIssues: Array<{
    issue: string;
    count: number;
    percentage: number;
  }>;
  cropDistribution: Array<{
    crop: string;
    count: number;
    percentage: number;
  }>;
  severityDistribution: Array<{
    severity: string;
    count: number;
    percentage: number;
  }>;
}

export class DiagnosticsService {
  /**
   * Upload image for crop diagnosis
   */
  async uploadForDiagnosis(request: DiagnosisRequest): Promise<DiagnosisResult> {
    try {
      const additionalData: Record<string, any> = {};
      
      if (request.cropType) additionalData.cropType = request.cropType;
      if (request.symptoms) additionalData.symptoms = request.symptoms;
      if (request.location) {
        additionalData.latitude = request.location.latitude.toString();
        additionalData.longitude = request.location.longitude.toString();
      }
      if (request.farmingPractices) {
        additionalData.farmingPractices = JSON.stringify(request.farmingPractices);
      }

      const response: ApiResponse<DiagnosisResult> = await apiClient.uploadFile(
        API_ENDPOINTS.DIAGNOSTICS.UPLOAD,
        request.image,
        additionalData,
        (progressEvent) => {
          const percentCompleted = Math.round((progressEvent.loaded * 100) / progressEvent.total);
          console.log(`Upload progress: ${percentCompleted}%`);
        }
      );

      if (response.success) {
        return response.data;
      } else {
        throw new Error(response.message || 'Failed to upload image for diagnosis');
      }
    } catch (error) {
      console.error('Error uploading image for diagnosis:', error);
      throw error;
    }
  }

  /**
   * Get diagnosis history for the current user
   */
  async getDiagnosisHistory(page: number = 0, size: number = 20): Promise<{
    diagnoses: DiagnosisResult[];
    totalPages: number;
    totalElements: number;
  }> {
    try {
      const response: ApiResponse<{
        content: DiagnosisResult[];
        totalPages: number;
        totalElements: number;
      }> = await apiClient.get(
        `${API_ENDPOINTS.DIAGNOSTICS.HISTORY}?page=${page}&size=${size}`
      );

      if (response.success) {
        return {
          diagnoses: response.data.content,
          totalPages: response.data.totalPages,
          totalElements: response.data.totalElements,
        };
      } else {
        throw new Error(response.message || 'Failed to fetch diagnosis history');
      }
    } catch (error) {
      console.error('Error fetching diagnosis history:', error);
      throw error;
    }
  }

  /**
   * Get specific diagnosis by ID
   */
  async getDiagnosisById(id: string): Promise<DiagnosisResult> {
    try {
      const response: ApiResponse<DiagnosisResult> = await apiClient.get(
        `${API_ENDPOINTS.DIAGNOSTICS.HISTORY}/${id}`
      );

      if (response.success) {
        return response.data;
      } else {
        throw new Error(response.message || 'Failed to fetch diagnosis details');
      }
    } catch (error) {
      console.error('Error fetching diagnosis details:', error);
      throw error;
    }
  }

  /**
   * Request expert review for a diagnosis
   */
  async requestExpertReview(diagnosisId: string, additionalNotes?: string): Promise<void> {
    try {
      const endpoint = API_ENDPOINTS.DIAGNOSTICS.EXPERT_REVIEW.replace('{id}', diagnosisId);
      const response: ApiResponse<void> = await apiClient.post(endpoint, {
        additionalNotes,
      });

      if (!response.success) {
        throw new Error(response.message || 'Failed to request expert review');
      }
    } catch (error) {
      console.error('Error requesting expert review:', error);
      throw error;
    }
  }

  /**
   * Get crop-specific recommendations
   */
  async getCropRecommendations(
    cropType: string,
    location?: { latitude: number; longitude: number }
  ): Promise<Recommendation[]> {
    try {
      let url = `${API_ENDPOINTS.DIAGNOSTICS.RECOMMENDATIONS}?cropType=${encodeURIComponent(cropType)}`;
      
      if (location) {
        url += `&latitude=${location.latitude}&longitude=${location.longitude}`;
      }

      const response: ApiResponse<Recommendation[]> = await apiClient.get(url);

      if (response.success) {
        return response.data;
      } else {
        throw new Error(response.message || 'Failed to fetch crop recommendations');
      }
    } catch (error) {
      console.error('Error fetching crop recommendations:', error);
      throw error;
    }
  }

  /**
   * Get diagnostic statistics for the user
   */
  async getDiagnosticStats(): Promise<DiagnosticStats> {
    try {
      const response: ApiResponse<DiagnosticStats> = await apiClient.get(
        API_ENDPOINTS.DIAGNOSTICS.STATS
      );

      if (response.success) {
        return response.data;
      } else {
        throw new Error(response.message || 'Failed to fetch diagnostic statistics');
      }
    } catch (error) {
      console.error('Error fetching diagnostic statistics:', error);
      throw error;
    }
  }

  /**
   * Validate image before upload
   */
  validateImage(file: File): { valid: boolean; error?: string } {
    // Check file size (max 10MB)
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
      return { valid: false, error: 'Image size must be less than 10MB' };
    }

    // Check file type
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
      return { valid: false, error: 'Only JPEG, PNG, and WebP images are allowed' };
    }

    return { valid: true };
  }

  /**
   * Get supported crop types
   */
  getSupportedCropTypes(): string[] {
    return [
      'Rice',
      'Wheat',
      'Cotton',
      'Sugarcane',
      'Tomato',
      'Potato',
      'Onion',
      'Maize',
      'Soybean',
      'Groundnut',
      'Sunflower',
      'Chili',
      'Brinjal',
      'Okra',
      'Cabbage',
      'Cauliflower',
      'Carrot',
      'Beans',
      'Peas',
      'Cucumber',
    ];
  }

  /**
   * Get common symptoms for crop selection
   */
  getCommonSymptoms(): string[] {
    return [
      'Yellowing leaves',
      'Brown spots on leaves',
      'Wilting',
      'Stunted growth',
      'Leaf curl',
      'White powdery coating',
      'Black spots',
      'Holes in leaves',
      'Root rot',
      'Fruit rot',
      'Discoloration',
      'Pest infestation',
    ];
  }
}

// Export singleton instance
export const diagnosticsService = new DiagnosticsService();
export default diagnosticsService;

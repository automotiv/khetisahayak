const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');
const config = require('../config');

/**
 * Service to interact with the ML inference API
 */
class MLService {
  constructor() {
    this.apiUrl = process.env.ML_API_URL || 'http://localhost:8000';
  }

  /**
   * Get health status of the ML API
   * @returns {Promise<Object>} Health status
   */
  async getHealth() {
    try {
      const response = await axios.get(`${this.apiUrl}/health`);
      return response.data;
    } catch (error) {
      console.error('Error checking ML API health:', error.message);
      throw new Error('ML service health check failed');
    }
  }

  /**
   * Get model information
   * @returns {Promise<Object>} Model information
   */
  async getModelInfo() {
    try {
      const response = await axios.get(`${this.apiUrl}/model-info`);
      return response.data;
    } catch (error) {
      console.error('Error getting model info:', error.message);
      throw new Error('Failed to retrieve model information');
    }
  }

  /**
   * Analyze image using ML model
   * @param {Buffer} imageBuffer - Image buffer
   * @param {String} cropType - Type of crop
   * @param {String} issueDescription - Description of the issue
   * @returns {Promise<Object>} Analysis results
   */
  async analyzeImage(imageBuffer, cropType, issueDescription) {
    try {
      const formData = new FormData();
      formData.append('image', imageBuffer, {
        filename: 'image.jpg',
        contentType: 'image/jpeg',
      });
      formData.append('crop_type', cropType);
      formData.append('issue_description', issueDescription);

      const response = await axios.post(`${this.apiUrl}/predict`, formData, {
        headers: {
          ...formData.getHeaders(),
        },
      });

      const result = response.data;

      // The ML service already returns the complete response format
      // {disease, confidence, severity, symptoms, treatment_steps, recommendations}
      return {
        disease: result.disease,
        confidence: result.confidence,
        recommendations: result.recommendations,
        severity: result.severity,
        symptoms: result.symptoms,
        treatment_steps: result.treatment_steps
      };
    } catch (error) {
      console.error('Error analyzing image with ML service:', error.message);
      throw new Error('Failed to analyze image with ML service');
    }
  }

  /**
   * Calculate severity based on confidence score
   * @param {Number} confidence - Confidence score
   * @returns {String} Severity level
   */
  calculateSeverity(confidence) {
    if (confidence > 0.85) return 'high';
    if (confidence > 0.7) return 'moderate';
    return 'low';
  }

  /**
   * Get recommendations based on disease and crop type
   * @param {String} disease - Disease name
   * @param {String} cropType - Type of crop
   * @returns {String} Recommendations
   */
  getRecommendations(disease, cropType) {
    // This would ideally come from a database or knowledge base
    // For now, we'll return a generic recommendation
    return `For ${disease} in ${cropType}, we recommend implementing appropriate cultural, chemical, or biological control measures. Consult with a local agricultural extension for specific treatments available in your region.`;
  }

  /**
   * Get symptoms based on disease and crop type
   * @param {String} disease - Disease name
   * @param {String} cropType - Type of crop
   * @returns {Array} List of symptoms
   */
  getSymptoms(disease, cropType) {
    // This would ideally come from a database or knowledge base
    return ['Leaf discoloration', 'Stunted growth', 'Visible lesions or spots'];
  }

  /**
   * Get treatment steps based on disease and crop type
   * @param {String} disease - Disease name
   * @param {String} cropType - Type of crop
   * @returns {Array} List of treatment steps
   */
  getTreatmentSteps(disease, cropType) {
    // This would ideally come from a database or knowledge base
    return [
      'Remove and destroy infected plant parts',
      'Apply appropriate fungicide or pesticide',
      'Improve plant spacing for better air circulation',
      'Implement crop rotation next season'
    ];
  }
}

module.exports = new MLService();
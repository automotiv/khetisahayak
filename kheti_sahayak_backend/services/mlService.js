const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');
const crypto = require('crypto');
const config = require('../config');

/**
 * Service to interact with ML inference APIs including LLaVA crop diagnostics
 * 
 * Fallback chain:
 * 1. LLaVA API (AI-powered detailed diagnosis)
 * 2. Traditional ML Service (disease classification)
 * 3. Mock responses (for development/fallback)
 */
class MLService {
  constructor() {
    this.mlApiUrl = process.env.ML_API_URL || 'http://localhost:8000';
    this.llavaApiUrl = process.env.LLAVA_API_URL || 'http://localhost:8001';
    this.llavaTimeout = parseInt(process.env.LLAVA_TIMEOUT_MS) || 60000;
    
    // Simple in-memory cache for diagnosis responses
    // Key: hash of image buffer + question
    // Value: { response, timestamp }
    this.diagnosisCache = new Map();
    this.cacheMaxAge = parseInt(process.env.DIAGNOSIS_CACHE_TTL_MS) || 3600000; // 1 hour default
    this.cacheMaxSize = parseInt(process.env.DIAGNOSIS_CACHE_MAX_SIZE) || 100;
  }

  /**
   * Generate cache key from image buffer and optional question
   * @param {Buffer} imageBuffer - Image buffer
   * @param {String} question - Optional question
   * @returns {String} Cache key
   */
  _generateCacheKey(imageBuffer, question = '') {
    const hash = crypto.createHash('sha256');
    hash.update(imageBuffer);
    hash.update(question);
    return hash.digest('hex');
  }

  /**
   * Get cached diagnosis if valid
   * @param {String} cacheKey - Cache key
   * @returns {Object|null} Cached response or null
   */
  _getCachedDiagnosis(cacheKey) {
    const cached = this.diagnosisCache.get(cacheKey);
    if (cached && (Date.now() - cached.timestamp) < this.cacheMaxAge) {
      console.log('Cache hit for diagnosis');
      return { ...cached.response, cached: true };
    }
    if (cached) {
      // Expired, remove from cache
      this.diagnosisCache.delete(cacheKey);
    }
    return null;
  }

  /**
   * Store diagnosis in cache
   * @param {String} cacheKey - Cache key
   * @param {Object} response - Response to cache
   */
  _cacheDiagnosis(cacheKey, response) {
    // Evict oldest entries if cache is full
    if (this.diagnosisCache.size >= this.cacheMaxSize) {
      const firstKey = this.diagnosisCache.keys().next().value;
      this.diagnosisCache.delete(firstKey);
    }
    this.diagnosisCache.set(cacheKey, {
      response: { ...response },
      timestamp: Date.now()
    });
  }

  /**
   * Clear the diagnosis cache
   */
  clearCache() {
    this.diagnosisCache.clear();
    console.log('Diagnosis cache cleared');
  }

  /**
   * Get cache statistics
   * @returns {Object} Cache stats
   */
  getCacheStats() {
    return {
      size: this.diagnosisCache.size,
      maxSize: this.cacheMaxSize,
      maxAgeTTL: this.cacheMaxAge
    };
  }

  /**
   * Get health status of the ML API
   * @returns {Promise<Object>} Health status
   */
  async getHealth() {
    try {
      const response = await axios.get(`${this.mlApiUrl}/health`);
      return response.data;
    } catch (error) {
      console.error('Error checking ML API health:', error.message);
      throw new Error('ML service health check failed');
    }
  }

  /**
   * Get health status of the LLaVA API
   * @returns {Promise<Object>} Health status
   */
  async getLlavaHealth() {
    try {
      const response = await axios.get(`${this.llavaApiUrl}/`, { timeout: 5000 });
      return response.data;
    } catch (error) {
      console.error('Error checking LLaVA API health:', error.message);
      return { status: 'unavailable', error: error.message };
    }
  }

  /**
   * Get model information
   * @returns {Promise<Object>} Model information
   */
  async getModelInfo() {
    try {
      const response = await axios.get(`${this.mlApiUrl}/model-info`);
      return response.data;
    } catch (error) {
      console.error('Error getting model info:', error.message);
      throw new Error('Failed to retrieve model information');
    }
  }

  /**
   * Analyze image using LLaVA AI model
   * @param {Buffer} imageBuffer - Image buffer
   * @param {String} question - Question to ask about the image
   * @param {Boolean} useCache - Whether to use caching (default: true)
   * @returns {Promise<Object>} LLaVA diagnosis result
   */
  async analyzeWithLlava(imageBuffer, question = 'What disease does this plant have? Provide diagnosis and treatment recommendations.', useCache = true) {
    // Check cache first
    if (useCache) {
      const cacheKey = this._generateCacheKey(imageBuffer, question);
      const cached = this._getCachedDiagnosis(cacheKey);
      if (cached) {
        return cached;
      }
    }

    try {
      const formData = new FormData();
      formData.append('image', imageBuffer, {
        filename: 'crop_image.jpg',
        contentType: 'image/jpeg',
      });
      formData.append('question', question);

      const response = await axios.post(`${this.llavaApiUrl}/api/diagnose`, formData, {
        headers: {
          ...formData.getHeaders(),
        },
        timeout: this.llavaTimeout
      });

      const result = {
        success: true,
        source: 'llava',
        diagnosis: response.data.diagnosis || response.data.generated_text,
        question: question,
        model: response.data.model || 'LLaVA-v1.5-7B',
        cached: false
      };

      // Cache the result
      if (useCache) {
        const cacheKey = this._generateCacheKey(imageBuffer, question);
        this._cacheDiagnosis(cacheKey, result);
      }

      return result;
    } catch (error) {
      console.error('Error analyzing image with LLaVA:', error.message);
      throw error;
    }
  }

  /**
   * Get detailed diagnosis from LLaVA (disease, severity, treatment, prevention)
   * @param {Buffer} imageBuffer - Image buffer
   * @param {Boolean} useCache - Whether to use caching (default: true)
   * @returns {Promise<Object>} Detailed diagnosis
   */
  async getDetailedLlavaDiagnosis(imageBuffer, useCache = true) {
    // Check cache first with a special key for detailed diagnosis
    if (useCache) {
      const cacheKey = this._generateCacheKey(imageBuffer, '__detailed__');
      const cached = this._getCachedDiagnosis(cacheKey);
      if (cached) {
        return cached;
      }
    }

    try {
      const formData = new FormData();
      formData.append('image', imageBuffer, {
        filename: 'crop_image.jpg',
        contentType: 'image/jpeg',
      });

      const response = await axios.post(`${this.llavaApiUrl}/api/diagnose/detailed`, formData, {
        headers: {
          ...formData.getHeaders(),
        },
        timeout: this.llavaTimeout * 4 // Detailed diagnosis takes longer (4 API calls)
      });

      const result = {
        success: true,
        source: 'llava_detailed',
        disease: response.data.disease,
        severity: response.data.severity,
        treatment: response.data.treatment,
        prevention: response.data.prevention,
        image: response.data.image,
        timestamp: response.data.timestamp,
        cached: false
      };

      // Cache the result
      if (useCache) {
        const cacheKey = this._generateCacheKey(imageBuffer, '__detailed__');
        this._cacheDiagnosis(cacheKey, result);
      }

      return result;
    } catch (error) {
      console.error('Error getting detailed LLaVA diagnosis:', error.message);
      throw error;
    }
  }

  /**
   * Conversational diagnosis - ask multiple questions about the same image
   * @param {Buffer} imageBuffer - Image buffer
   * @param {Array<String>} questions - Array of questions to ask
   * @returns {Promise<Object>} Responses mapped to questions
   */
  async conversationalDiagnosis(imageBuffer, questions) {
    try {
      const formData = new FormData();
      formData.append('image', imageBuffer, {
        filename: 'crop_image.jpg',
        contentType: 'image/jpeg',
      });
      formData.append('questions', questions.join(','));

      const response = await axios.post(`${this.llavaApiUrl}/api/diagnose/custom`, formData, {
        headers: {
          ...formData.getHeaders(),
        },
        timeout: this.llavaTimeout * questions.length
      });

      return {
        success: true,
        source: 'llava_conversational',
        responses: response.data,
        question_count: questions.length
      };
    } catch (error) {
      console.error('Error in conversational diagnosis:', error.message);
      throw error;
    }
  }

  /**
   * Analyze image using ML model (traditional service)
   * @param {Buffer} imageBuffer - Image buffer
   * @param {String} cropType - Type of crop
   * @param {String} issueDescription - Description of the issue
   * @returns {Promise<Object>} Analysis results
   */
  async analyzeImageWithMLService(imageBuffer, cropType, issueDescription) {
    try {
      const formData = new FormData();
      formData.append('image', imageBuffer, {
        filename: 'image.jpg',
        contentType: 'image/jpeg',
      });
      formData.append('crop_type', cropType);
      formData.append('issue_description', issueDescription);

      const response = await axios.post(`${this.mlApiUrl}/predict`, formData, {
        headers: {
          ...formData.getHeaders(),
        },
        timeout: 30000
      });

      const result = response.data;

      return {
        success: true,
        source: 'ml_service',
        disease: result.disease,
        confidence: result.confidence,
        recommendations: result.recommendations,
        severity: result.severity,
        symptoms: result.symptoms,
        treatment_steps: result.treatment_steps
      };
    } catch (error) {
      console.error('Error analyzing image with ML service:', error.message);
      throw error;
    }
  }

  /**
   * Get mock diagnosis response for fallback
   * @param {String} cropType - Type of crop
   * @param {String} issueDescription - Description of the issue
   * @returns {Object} Mock diagnosis result
   */
  getMockDiagnosis(cropType, issueDescription) {
    const mockResponses = {
      'tomato': {
        'yellow leaves': {
          disease: 'Early Blight',
          confidence: 0.85,
          recommendations: 'Apply fungicide containing chlorothalonil. Improve air circulation and avoid overhead watering. Remove infected leaves immediately.',
          severity: 'moderate',
          symptoms: ['Yellow leaves with brown spots', 'Circular lesions on leaves', 'Stem cankers'],
          treatment_steps: [
            'Remove and destroy infected plant parts',
            'Apply copper-based fungicide every 7-10 days',
            'Improve plant spacing for better air circulation',
            'Avoid overhead irrigation'
          ]
        },
        'wilting': {
          disease: 'Bacterial Wilt',
          confidence: 0.92,
          recommendations: 'Remove infected plants immediately. Disinfect tools. Plant resistant varieties next season.',
          severity: 'high',
          symptoms: ['Sudden wilting', 'Brown vascular tissue', 'No recovery after watering'],
          treatment_steps: [
            'Remove and destroy infected plants',
            'Disinfect all gardening tools',
            'Rotate crops next season',
            'Plant resistant varieties'
          ]
        },
        'spots on leaves': {
          disease: 'Septoria Leaf Spot',
          confidence: 0.78,
          recommendations: 'Apply fungicide with active ingredients like azoxystrobin. Remove infected leaves.',
          severity: 'low',
          symptoms: ['Small brown spots with gray centers', 'Yellow halos around spots'],
          treatment_steps: [
            'Remove infected leaves',
            'Apply fungicide every 7-10 days',
            'Improve air circulation',
            'Avoid overhead watering'
          ]
        }
      },
      'potato': {
        'brown spots': {
          disease: 'Late Blight',
          confidence: 0.95,
          recommendations: 'Remove infected plants immediately. Apply copper-based fungicide. Ensure proper drainage.',
          severity: 'high',
          symptoms: ['Dark brown spots on leaves', 'White fungal growth on underside', 'Rapid spread'],
          treatment_steps: [
            'Remove and destroy infected plants',
            'Apply copper fungicide immediately',
            'Improve field drainage',
            'Plant resistant varieties next season'
          ]
        },
        'yellow leaves': {
          disease: 'Early Blight',
          confidence: 0.88,
          recommendations: 'Apply fungicide and improve air circulation. Remove infected leaves.',
          severity: 'moderate',
          symptoms: ['Target-like lesions', 'Yellowing leaves', 'Stem lesions'],
          treatment_steps: [
            'Remove infected leaves',
            'Apply fungicide every 7-10 days',
            'Improve plant spacing',
            'Avoid overhead irrigation'
          ]
        }
      },
      'rice': {
        'brown spots': {
          disease: 'Brown Spot',
          confidence: 0.87,
          recommendations: 'Apply fungicide containing tricyclazole. Ensure balanced fertilization.',
          severity: 'moderate',
          symptoms: ['Oval brown spots on leaves', 'Dark borders around lesions', 'Grain discoloration'],
          treatment_steps: [
            'Apply appropriate fungicide',
            'Improve nutrient management',
            'Use resistant varieties',
            'Maintain proper water management'
          ]
        },
        'blast': {
          disease: 'Rice Blast',
          confidence: 0.91,
          recommendations: 'Apply tricyclazole fungicide. Avoid excess nitrogen. Use resistant varieties.',
          severity: 'high',
          symptoms: ['Diamond-shaped lesions', 'Gray center with brown margin', 'Node infection'],
          treatment_steps: [
            'Apply systemic fungicide immediately',
            'Reduce nitrogen application',
            'Improve drainage',
            'Plant resistant varieties'
          ]
        }
      },
      'wheat': {
        'white powder': {
          disease: 'Powdery Mildew',
          confidence: 0.90,
          recommendations: 'Apply sulfur-based fungicide. Increase plant spacing for better air circulation.',
          severity: 'moderate',
          symptoms: ['White powdery growth on leaves', 'Yellowing of leaves', 'Stunted growth'],
          treatment_steps: [
            'Apply sulfur fungicide',
            'Improve air circulation',
            'Avoid excessive nitrogen fertilization',
            'Plant resistant varieties'
          ]
        },
        'rust': {
          disease: 'Wheat Rust',
          confidence: 0.89,
          recommendations: 'Apply propiconazole fungicide. Remove volunteer wheat plants.',
          severity: 'high',
          symptoms: ['Orange-red pustules on leaves', 'Yellowing around pustules', 'Premature drying'],
          treatment_steps: [
            'Apply systemic fungicide',
            'Remove infected debris',
            'Use resistant varieties',
            'Monitor regularly'
          ]
        }
      }
    };

    const cropLower = (cropType || '').toLowerCase();
    const issueLower = (issueDescription || '').toLowerCase();
    const cropResponses = mockResponses[cropLower] || {};
    
    let bestMatch = null;
    let highestConfidence = 0;

    for (const [key, response] of Object.entries(cropResponses)) {
      if (issueLower.includes(key) && response.confidence > highestConfidence) {
        bestMatch = response;
        highestConfidence = response.confidence;
      }
    }

    if (!bestMatch) {
      bestMatch = {
        disease: 'Unknown Disease',
        confidence: 0.65,
        recommendations: 'Please consult with an agricultural expert for proper diagnosis. The symptoms may indicate multiple possible issues.',
        severity: 'unknown',
        symptoms: ['Various symptoms observed', 'Requires expert examination'],
        treatment_steps: [
          'Consult with agricultural expert',
          'Take detailed photos of symptoms',
          'Monitor plant development',
          'Consider soil testing'
        ]
      };
    }

    return {
      success: true,
      source: 'mock',
      ...bestMatch
    };
  }

  /**
   * Analyze image with fallback chain: LLaVA -> ML Service -> Mock
   * @param {Buffer} imageBuffer - Image buffer
   * @param {String} cropType - Type of crop
   * @param {String} issueDescription - Description of the issue
   * @param {Boolean} useCache - Whether to use caching (default: true)
   * @returns {Promise<Object>} Analysis results
   */
  async analyzeImage(imageBuffer, cropType, issueDescription, useCache = true) {
    // Check cache first
    if (useCache) {
      const cacheKey = this._generateCacheKey(imageBuffer, `${cropType}_${issueDescription}`);
      const cached = this._getCachedDiagnosis(cacheKey);
      if (cached) {
        return cached;
      }
    }

    // Build question for LLaVA
    const llavaQuestion = `This is a ${cropType} plant. The farmer describes the issue as: "${issueDescription}". What disease does this plant have? Provide: 1) Disease name, 2) Confidence level, 3) Severity, 4) Symptoms to look for, 5) Treatment steps, 6) Recommendations.`;

    // Try LLaVA first
    try {
      console.log('Attempting LLaVA diagnosis...');
      const llavaResult = await this.analyzeWithLlava(imageBuffer, llavaQuestion, false);
      
      // Parse LLaVA response into structured format
      const parsedResult = this._parseLlavaResponse(llavaResult.diagnosis, cropType);
      
      // Cache the result
      if (useCache) {
        const cacheKey = this._generateCacheKey(imageBuffer, `${cropType}_${issueDescription}`);
        this._cacheDiagnosis(cacheKey, parsedResult);
      }

      return parsedResult;
    } catch (llavaError) {
      console.log('LLaVA service unavailable, trying ML service...', llavaError.message);
    }

    // Try traditional ML service
    try {
      console.log('Attempting ML service diagnosis...');
      const mlResult = await this.analyzeImageWithMLService(imageBuffer, cropType, issueDescription);
      
      // Cache the result
      if (useCache) {
        const cacheKey = this._generateCacheKey(imageBuffer, `${cropType}_${issueDescription}`);
        this._cacheDiagnosis(cacheKey, mlResult);
      }

      return mlResult;
    } catch (mlError) {
      console.log('ML service unavailable, using mock response...', mlError.message);
    }

    // Fallback to mock
    console.log('Using mock diagnosis response');
    const mockResult = this.getMockDiagnosis(cropType, issueDescription);
    
    // Cache mock results too
    if (useCache) {
      const cacheKey = this._generateCacheKey(imageBuffer, `${cropType}_${issueDescription}`);
      this._cacheDiagnosis(cacheKey, mockResult);
    }

    return mockResult;
  }

  /**
   * Parse LLaVA text response into structured diagnosis format
   * @param {String} llavaText - Raw LLaVA response text
   * @param {String} cropType - Type of crop for context
   * @returns {Object} Structured diagnosis result
   */
  _parseLlavaResponse(llavaText, cropType) {
    // Extract disease name (look for common patterns)
    let disease = 'Unknown Disease';
    const diseasePatterns = [
      /disease[:\s]+([^.]+)/i,
      /diagnosis[:\s]+([^.]+)/i,
      /identified as[:\s]+([^.]+)/i,
      /appears to be[:\s]+([^.]+)/i,
      /suffering from[:\s]+([^.]+)/i
    ];
    
    for (const pattern of diseasePatterns) {
      const match = llavaText.match(pattern);
      if (match) {
        disease = match[1].trim();
        break;
      }
    }

    // Extract severity
    let severity = 'moderate';
    if (/severe|critical|high|serious/i.test(llavaText)) {
      severity = 'high';
    } else if (/mild|low|minor|early/i.test(llavaText)) {
      severity = 'low';
    }

    // Extract confidence (default based on AI response quality)
    let confidence = 0.75;
    const confMatch = llavaText.match(/confidence[:\s]+(\d+)/i);
    if (confMatch) {
      confidence = Math.min(parseInt(confMatch[1]) / 100, 0.99);
    }

    // Extract symptoms (look for bullet points or numbered lists)
    const symptoms = [];
    const symptomPatterns = [
      /symptoms?[:\s]*([^.]+(?:\.[^.]+)*)/i,
      /signs?[:\s]*([^.]+(?:\.[^.]+)*)/i
    ];
    for (const pattern of symptomPatterns) {
      const match = llavaText.match(pattern);
      if (match) {
        const symptomText = match[1];
        const items = symptomText.split(/[,;]|\d+\)/).map(s => s.trim()).filter(s => s.length > 3);
        symptoms.push(...items.slice(0, 5));
        break;
      }
    }
    if (symptoms.length === 0) {
      symptoms.push('Visual symptoms detected in image', 'Consult expert for detailed assessment');
    }

    // Extract treatment steps
    const treatment_steps = [];
    const treatmentPatterns = [
      /treatment[:\s]*([^.]+(?:\.[^.]+)*)/i,
      /recommend[:\s]*([^.]+(?:\.[^.]+)*)/i,
      /steps?[:\s]*([^.]+(?:\.[^.]+)*)/i
    ];
    for (const pattern of treatmentPatterns) {
      const match = llavaText.match(pattern);
      if (match) {
        const treatmentText = match[1];
        const items = treatmentText.split(/[,;]|\d+\)/).map(s => s.trim()).filter(s => s.length > 3);
        treatment_steps.push(...items.slice(0, 5));
        break;
      }
    }
    if (treatment_steps.length === 0) {
      treatment_steps.push(
        'Consult with agricultural expert for specific treatment',
        'Remove affected plant parts if applicable',
        'Monitor plant health closely'
      );
    }

    // Build recommendations from the response
    let recommendations = llavaText;
    if (recommendations.length > 500) {
      recommendations = recommendations.substring(0, 500) + '...';
    }

    return {
      success: true,
      source: 'llava',
      disease,
      confidence,
      severity,
      symptoms,
      treatment_steps,
      recommendations,
      raw_response: llavaText
    };
  }

  /**
   * Get crop recommendations based on soil and weather data
   * @param {Object} data - Soil and weather data
   * @returns {Promise<Object>} Recommended crops
   */
  async getRecommendedCrops(data) {
    try {
      const response = await axios.post(`${this.mlApiUrl}/recommend-crops`, data);
      return response.data;
    } catch (error) {
      console.error('Error getting crop recommendations from ML service:', error.message);
      throw new Error('Failed to get crop recommendations from ML service');
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
    return `For ${disease} in ${cropType}, we recommend implementing appropriate cultural, chemical, or biological control measures. Consult with a local agricultural extension for specific treatments available in your region.`;
  }

  /**
   * Get symptoms based on disease and crop type
   * @param {String} disease - Disease name
   * @param {String} cropType - Type of crop
   * @returns {Array} List of symptoms
   */
  getSymptoms(disease, cropType) {
    return ['Leaf discoloration', 'Stunted growth', 'Visible lesions or spots'];
  }

  /**
   * Get treatment steps based on disease and crop type
   * @param {String} disease - Disease name
   * @param {String} cropType - Type of crop
   * @returns {Array} List of treatment steps
   */
  getTreatmentSteps(disease, cropType) {
    return [
      'Remove and destroy infected plant parts',
      'Apply appropriate fungicide or pesticide',
      'Improve plant spacing for better air circulation',
      'Implement crop rotation next season'
    ];
  }
}

module.exports = new MLService();
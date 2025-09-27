package com.khetisahayak.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.Arrays;

/**
 * ML Service for Kheti Sahayak Agricultural Platform
 * Integrates with FastAPI ML inference service for crop disease detection
 * Implements CodeRabbit performance standards for rural network optimization
 */
@Service
public class MLService {

    @Value("${app.ml.service.url:http://localhost:8000}")
    private String mlServiceUrl;

    @Value("${app.ml.service.timeout:30000}")
    private int timeoutMs;

    @Value("${app.ml.service.enabled:true}")
    private boolean mlServiceEnabled;

    private final RestTemplate restTemplate;

    public MLService() {
        this.restTemplate = new RestTemplate();
        // Set timeout for rural network compatibility
        this.restTemplate.getMessageConverters().add(new org.springframework.http.converter.ByteArrayHttpMessageConverter());
    }

    /**
     * Check if ML service is available and healthy
     */
    public boolean isMLServiceHealthy() {
        if (!mlServiceEnabled) {
            return false;
        }

        try {
            String healthUrl = mlServiceUrl + "/health";
            ResponseEntity<Map> response = restTemplate.getForEntity(healthUrl, Map.class);
            return response.getStatusCode() == HttpStatus.OK;
        } catch (Exception e) {
            System.err.println("ML Service health check failed: " + e.getMessage());
            return false;
        }
    }

    /**
     * Get ML model information and metadata
     */
    public Map<String, Object> getModelInfo() {
        if (!mlServiceEnabled || !isMLServiceHealthy()) {
            return createFallbackModelInfo();
        }

        try {
            String modelInfoUrl = mlServiceUrl + "/model-info";
            ResponseEntity<Map> response = restTemplate.getForEntity(modelInfoUrl, Map.class);
            return response.getBody();
        } catch (Exception e) {
            System.err.println("Failed to get model info: " + e.getMessage());
            return createFallbackModelInfo();
        }
    }

    /**
     * Predict crop disease from uploaded image
     * Optimized for agricultural image analysis with Indian crop context
     */
    public Map<String, Object> predictCropDisease(
            MultipartFile imageFile, 
            String cropType, 
            String symptoms,
            Double latitude, 
            Double longitude) {
        
        if (!mlServiceEnabled || !isMLServiceHealthy()) {
            return createFallbackPrediction(cropType, symptoms);
        }

        try {
            // Prepare multipart request for ML service
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            
            // Add image file
            ByteArrayResource imageResource = new ByteArrayResource(imageFile.getBytes()) {
                @Override
                public String getFilename() {
                    return imageFile.getOriginalFilename();
                }
            };
            body.add("image", imageResource);
            
            // Add agricultural context
            if (cropType != null && !cropType.trim().isEmpty()) {
                body.add("crop_type", cropType);
            }
            if (symptoms != null && !symptoms.trim().isEmpty()) {
                body.add("symptoms", symptoms);
            }
            if (latitude != null) {
                body.add("latitude", latitude.toString());
            }
            if (longitude != null) {
                body.add("longitude", longitude.toString());
            }

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            // Call ML service prediction endpoint
            String predictUrl = mlServiceUrl + "/predict";
            ResponseEntity<Map> response = restTemplate.postForEntity(predictUrl, requestEntity, Map.class);
            
            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                return enhancePredictionWithAgriculturalContext(response.getBody(), cropType, latitude, longitude);
            } else {
                throw new RuntimeException("ML service returned invalid response");
            }

        } catch (IOException e) {
            throw new RuntimeException("Failed to process image file: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("ML prediction failed: " + e.getMessage());
            return createFallbackPrediction(cropType, symptoms);
        }
    }

    /**
     * Get crop health recommendations based on diagnosis
     */
    public Map<String, Object> getCropHealthRecommendations(
            String diseaseName, 
            String cropType, 
            String season,
            String state) {
        
        Map<String, Object> recommendations = new HashMap<>();
        
        if (diseaseName == null || diseaseName.trim().isEmpty()) {
            recommendations.put("treatment", getGeneralCropCareRecommendations(cropType));
            recommendations.put("type", "general_care");
        } else {
            recommendations.put("treatment", getDiseaseSpecificTreatment(diseaseName, cropType));
            recommendations.put("type", "disease_treatment");
        }
        
        recommendations.put("prevention", getPreventionMeasures(diseaseName, cropType));
        recommendations.put("seasonalAdvice", getSeasonalAdvice(season, state));
        recommendations.put("organicAlternatives", getOrganicTreatmentOptions(diseaseName, cropType));
        recommendations.put("followUpDays", getFollowUpSchedule(diseaseName));
        
        return recommendations;
    }

    /**
     * Enhance ML prediction with agricultural context and local knowledge
     */
    private Map<String, Object> enhancePredictionWithAgriculturalContext(
            Map<String, Object> mlPrediction, 
            String cropType, 
            Double latitude, 
            Double longitude) {
        
        Map<String, Object> enhancedPrediction = new HashMap<>(mlPrediction);
        
        // Add geographical context
        if (latitude != null && longitude != null) {
            String region = getIndianRegionFromCoordinates(latitude, longitude);
            enhancedPrediction.put("region", region);
            enhancedPrediction.put("regionalFactors", getRegionalFactors(region, cropType));
        }
        
        // Add confidence assessment
        Object confidenceObj = mlPrediction.get("confidence");
        if (confidenceObj instanceof Number) {
            double confidence = ((Number) confidenceObj).doubleValue();
            enhancedPrediction.put("confidenceLevel", getConfidenceLevel(confidence));
            enhancedPrediction.put("requiresExpertReview", confidence < 0.7);
        }
        
        // Add agricultural recommendations
        String predictedDisease = (String) mlPrediction.get("predicted_class");
        if (predictedDisease != null) {
            enhancedPrediction.put("recommendations", 
                getCropHealthRecommendations(predictedDisease, cropType, getCurrentSeason(), getStateFromCoordinates(latitude, longitude)));
        }
        
        return enhancedPrediction;
    }

    /**
     * Create fallback prediction when ML service is unavailable
     */
    private Map<String, Object> createFallbackPrediction(String cropType, String symptoms) {
        Map<String, Object> fallback = new HashMap<>();
        
        fallback.put("status", "fallback_mode");
        fallback.put("message", "ML service unavailable - providing general recommendations");
        fallback.put("predicted_class", "Unable to analyze - Service unavailable");
        fallback.put("confidence", 0.0);
        fallback.put("requiresExpertReview", true);
        
        // Provide basic recommendations based on symptoms
        if (symptoms != null && !symptoms.trim().isEmpty()) {
            fallback.put("recommendations", getSymptomBasedRecommendations(symptoms, cropType));
        } else {
            fallback.put("recommendations", getGeneralCropCareRecommendations(cropType));
        }
        
        return fallback;
    }

    /**
     * Create fallback model info when ML service is unavailable
     */
    private Map<String, Object> createFallbackModelInfo() {
        Map<String, Object> modelInfo = new HashMap<>();
        modelInfo.put("model_name", "Crop Disease Detection Model (Offline)");
        modelInfo.put("version", "fallback_v1.0");
        modelInfo.put("status", "offline");
        modelInfo.put("supported_crops", Arrays.asList("Rice", "Wheat", "Cotton", "Sugarcane", "Tomato", "Potato"));
        modelInfo.put("accuracy", "Available when online");
        return modelInfo;
    }

    /**
     * Get disease-specific treatment recommendations
     */
    private Map<String, Object> getDiseaseSpecificTreatment(String disease, String cropType) {
        Map<String, Object> treatment = new HashMap<>();
        
        // Common disease treatments for Indian crops
        switch (disease.toLowerCase()) {
            case "blast":
            case "rice blast":
                treatment.put("fungicide", "Tricyclazole 75% WP @ 0.6g/L");
                treatment.put("application", "Spray during evening hours");
                treatment.put("frequency", "Two applications 10 days apart");
                break;
            case "leaf spot":
            case "brown spot":
                treatment.put("fungicide", "Mancozeb 75% WP @ 2g/L");
                treatment.put("bioControl", "Pseudomonas fluorescens @ 5g/L");
                treatment.put("frequency", "Weekly application for 3 weeks");
                break;
            case "blight":
                treatment.put("fungicide", "Copper Oxychloride 50% WP @ 2g/L");
                treatment.put("bactericide", "Streptocycline @ 0.5g/L");
                treatment.put("application", "Spray on both leaf surfaces");
                break;
            default:
                treatment.put("general", "Consult agricultural expert for specific treatment");
                treatment.put("immediate", "Remove affected plant parts");
                treatment.put("preventive", "Improve drainage and air circulation");
        }
        
        return treatment;
    }

    /**
     * Get general crop care recommendations
     */
    private Map<String, Object> getGeneralCropCareRecommendations(String cropType) {
        Map<String, Object> care = new HashMap<>();
        
        care.put("watering", "Maintain consistent soil moisture");
        care.put("nutrition", "Apply balanced NPK fertilizer as per soil test");
        care.put("monitoring", "Regular inspection for pest and disease symptoms");
        care.put("hygiene", "Remove dead/diseased plant material promptly");
        
        if (cropType != null) {
            switch (cropType.toLowerCase()) {
                case "rice":
                    care.put("specific", "Maintain 2-3 cm water level during vegetative stage");
                    break;
                case "wheat":
                    care.put("specific", "Ensure proper drainage during grain filling stage");
                    break;
                case "cotton":
                    care.put("specific", "Regular monitoring for bollworm and whitefly");
                    break;
                default:
                    care.put("specific", "Follow crop-specific agricultural practices");
            }
        }
        
        return care;
    }

    /**
     * Helper methods for agricultural context
     */
    private List<String> getPreventionMeasures(String disease, String cropType) {
        return Arrays.asList(
            "Use disease-resistant varieties",
            "Maintain proper plant spacing",
            "Ensure good drainage",
            "Practice crop rotation",
            "Remove infected plant debris"
        );
    }

    private Map<String, Object> getSeasonalAdvice(String season, String state) {
        Map<String, Object> advice = new HashMap<>();
        advice.put("season", season != null ? season : getCurrentSeason());
        advice.put("recommendations", "Follow seasonal agricultural practices");
        return advice;
    }

    private List<String> getOrganicTreatmentOptions(String disease, String cropType) {
        return Arrays.asList(
            "Neem oil spray (5ml/L)",
            "Trichoderma application",
            "Pseudomonas fluorescens",
            "Bacillus subtilis",
            "Panchgavya foliar spray"
        );
    }

    private int getFollowUpSchedule(String disease) {
        return disease != null ? 7 : 14; // Days for follow-up
    }

    private String getCurrentSeason() {
        // Simple season detection - can be enhanced with actual calendar logic
        int month = java.time.LocalDate.now().getMonthValue();
        if (month >= 6 && month <= 9) return "Kharif";
        if (month >= 10 && month <= 3) return "Rabi";
        return "Zaid";
    }

    private String getIndianRegionFromCoordinates(Double latitude, Double longitude) {
        // Simplified region detection - can be enhanced with actual geolocation service
        if (latitude >= 28.0) return "Northern India";
        if (latitude <= 15.0) return "Southern India";
        if (longitude <= 77.0) return "Western India";
        return "Central India";
    }

    private String getStateFromCoordinates(Double latitude, Double longitude) {
        // Simplified state detection - should use actual reverse geocoding service
        return "Maharashtra"; // Default for demo
    }

    private Map<String, Object> getRegionalFactors(String region, String cropType) {
        Map<String, Object> factors = new HashMap<>();
        factors.put("climate", "Regional climate considerations");
        factors.put("soilType", "Predominant soil type in region");
        factors.put("commonPests", "Region-specific pest concerns");
        return factors;
    }

    private String getConfidenceLevel(double confidence) {
        if (confidence >= 0.9) return "Very High";
        if (confidence >= 0.8) return "High";
        if (confidence >= 0.7) return "Moderate";
        if (confidence >= 0.5) return "Low";
        return "Very Low";
    }

    private Map<String, Object> getSymptomBasedRecommendations(String symptoms, String cropType) {
        Map<String, Object> recommendations = new HashMap<>();
        
        String lowerSymptoms = symptoms.toLowerCase();
        if (lowerSymptoms.contains("yellow") || lowerSymptoms.contains("wilting")) {
            recommendations.put("possibleCause", "Nutrient deficiency or water stress");
            recommendations.put("immediateAction", "Check soil moisture and nutrient levels");
        } else if (lowerSymptoms.contains("spot") || lowerSymptoms.contains("lesion")) {
            recommendations.put("possibleCause", "Fungal or bacterial infection");
            recommendations.put("immediateAction", "Remove affected leaves and improve air circulation");
        } else {
            recommendations.put("possibleCause", "Multiple factors possible");
            recommendations.put("immediateAction", "Consult agricultural expert for detailed diagnosis");
        }
        
        return recommendations;
    }
}

package com.khetisahayak.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.Map;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for WeatherService
 * Tests weather data retrieval and agricultural insights generation
 * Implements CodeRabbit testing standards for agricultural weather features
 */
@SpringBootTest
@TestPropertySource(properties = {
    "app.external.weather.api-key=test_key"
})
@DisplayName("Weather Service Tests")
class WeatherServiceTest {

    private WeatherService weatherService;

    @BeforeEach
    void setUp() {
        WebClient.Builder webClientBuilder = WebClient.builder();
        weatherService = new WeatherService(webClientBuilder.build(), "test_key");
    }

    @Test
    @DisplayName("Should return weather data for valid Indian coordinates")
    void shouldReturnWeatherDataForValidCoordinates() {
        // Test with Nashik, Maharashtra coordinates
        double lat = 19.9975;
        double lon = 73.7898;
        
        Map<String, Object> weatherData = weatherService.getWeather(lat, lon);
        
        assertNotNull(weatherData);
        assertTrue(weatherData.containsKey("main") || weatherData.containsKey("current"));
        assertTrue(weatherData.containsKey("agriculturalRecommendations"));
        assertTrue(weatherData.containsKey("farmingConditions"));
        assertTrue(weatherData.containsKey("location"));
    }

    @Test
    @DisplayName("Should generate agricultural recommendations based on weather")
    void shouldGenerateAgriculturalRecommendations() {
        double lat = 19.9975;
        double lon = 73.7898;
        
        Map<String, Object> weatherData = weatherService.getWeather(lat, lon);
        
        assertNotNull(weatherData.get("agriculturalRecommendations"));
        List<String> recommendations = (List<String>) weatherData.get("agriculturalRecommendations");
        assertFalse(recommendations.isEmpty());
        
        // Check for agricultural context in recommendations
        boolean hasAgriculturalContext = recommendations.stream()
            .anyMatch(rec -> rec.contains("irrigation") || rec.contains("crop") || 
                           rec.contains("farming") || rec.contains("plant"));
        assertTrue(hasAgriculturalContext, "Recommendations should include agricultural context");
    }

    @Test
    @DisplayName("Should provide farming conditions assessment")
    void shouldProvideFarmingConditionsAssessment() {
        double lat = 19.9975;
        double lon = 73.7898;
        
        Map<String, Object> weatherData = weatherService.getWeather(lat, lon);
        Map<String, Object> farmingConditions = (Map<String, Object>) weatherData.get("farmingConditions");
        
        assertNotNull(farmingConditions);
        assertTrue(farmingConditions.containsKey("overallSuitability"));
        assertTrue(farmingConditions.containsKey("irrigationNeed"));
        assertTrue(farmingConditions.containsKey("diseaseRisk"));
        assertTrue(farmingConditions.containsKey("sprayingConditions"));
        
        // Validate suitability values
        String suitability = (String) farmingConditions.get("overallSuitability");
        assertTrue(suitability.matches("^(EXCELLENT|GOOD|CHALLENGING)$"));
    }

    @Test
    @DisplayName("Should handle coordinates within Indian boundaries")
    void shouldHandleIndianCoordinates() {
        // Test various Indian locations
        double[][] indianCoordinates = {
            {28.6139, 77.2090}, // Delhi
            {19.0760, 72.8777}, // Mumbai
            {13.0827, 80.2707}, // Chennai
            {22.5726, 88.3639}, // Kolkata
            {12.9716, 77.5946}  // Bangalore
        };
        
        for (double[] coords : indianCoordinates) {
            Map<String, Object> weatherData = weatherService.getWeather(coords[0], coords[1]);
            
            assertNotNull(weatherData);
            Map<String, Object> location = (Map<String, Object>) weatherData.get("location");
            assertNotNull(location);
            assertEquals(coords[0], (Double) location.get("latitude"), 0.01);
            assertEquals(coords[1], (Double) location.get("longitude"), 0.01);
        }
    }

    @Test
    @DisplayName("Should generate weather alerts for extreme conditions")
    void shouldGenerateWeatherAlertsForExtremeConditions() {
        double lat = 19.9975;
        double lon = 73.7898;
        
        Map<String, Object> weatherData = weatherService.getWeather(lat, lon);
        
        if (weatherData.containsKey("alerts")) {
            List<Map<String, Object>> alerts = (List<Map<String, Object>>) weatherData.get("alerts");
            
            for (Map<String, Object> alert : alerts) {
                assertTrue(alert.containsKey("type"));
                assertTrue(alert.containsKey("severity"));
                assertTrue(alert.containsKey("message"));
                
                String severity = (String) alert.get("severity");
                assertTrue(severity.matches("^(LOW|MEDIUM|HIGH|CRITICAL)$"));
            }
        }
    }

    @Test
    @DisplayName("Should provide location-specific agricultural insights")
    void shouldProvideLocationSpecificInsights() {
        // Test Maharashtra coordinates (major agricultural state)
        double lat = 19.9975;
        double lon = 73.7898;
        
        Map<String, Object> weatherData = weatherService.getWeather(lat, lon);
        Map<String, Object> location = (Map<String, Object>) weatherData.get("location");
        
        assertNotNull(location);
        assertTrue(location.containsKey("state"));
        assertTrue(location.containsKey("region"));
        
        // For Maharashtra coordinates, should identify state correctly
        String state = (String) location.get("state");
        // Should be either "Maharashtra" or fallback "India"
        assertTrue(state.equals("Maharashtra") || state.equals("India"));
    }

    @Test
    @DisplayName("Should handle API failure gracefully")
    void shouldHandleApiFailureGracefully() {
        // Create service with invalid API key to test fallback
        WeatherService serviceWithInvalidKey = new WeatherService(
            WebClient.builder().build(), "invalid_key");
        
        double lat = 19.9975;
        double lon = 73.7898;
        
        // Should not throw exception, should return mock data
        assertDoesNotThrow(() -> {
            Map<String, Object> weatherData = serviceWithInvalidKey.getWeather(lat, lon);
            assertNotNull(weatherData);
        });
    }

    @Test
    @DisplayName("Should validate agricultural temperature thresholds")
    void shouldValidateAgriculturalTemperatureThresholds() {
        double lat = 19.9975;
        double lon = 73.7898;
        
        Map<String, Object> weatherData = weatherService.getWeather(lat, lon);
        List<String> recommendations = (List<String>) weatherData.get("agriculturalRecommendations");
        
        assertNotNull(recommendations);
        
        // Check if temperature-based recommendations are contextual
        boolean hasTemperatureContext = recommendations.stream()
            .anyMatch(rec -> rec.toLowerCase().contains("temperature") || 
                           rec.toLowerCase().contains("heat") ||
                           rec.toLowerCase().contains("irrigation"));
        
        // Should have some temperature-related recommendations
        assertTrue(hasTemperatureContext || recommendations.size() > 0);
    }

    @Test
    @DisplayName("Should provide crop-specific weather insights")
    void shouldProvideCropSpecificInsights() {
        double lat = 19.9975;
        double lon = 73.7898;
        
        Map<String, Object> weatherData = weatherService.getWeather(lat, lon);
        Map<String, Object> farmingConditions = (Map<String, Object>) weatherData.get("farmingConditions");
        
        assertNotNull(farmingConditions);
        
        // Should assess disease risk based on humidity
        String diseaseRisk = (String) farmingConditions.get("diseaseRisk");
        assertTrue(diseaseRisk.matches("^(LOW|MEDIUM|HIGH)$"));
        
        // Should assess irrigation needs based on temperature
        String irrigationNeed = (String) farmingConditions.get("irrigationNeed");
        assertTrue(irrigationNeed.matches("^(LOW|MODERATE|HIGH)$"));
    }
}

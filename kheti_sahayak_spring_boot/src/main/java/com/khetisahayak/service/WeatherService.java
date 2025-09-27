package com.khetisahayak.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

import java.util.Map;

@Service
public class WeatherService {

    private final WebClient webClient;
    private final String apiKey;

    public WeatherService(WebClient webClient,
                          @Value("${app.external.weather.api-key:${WEATHER_API_KEY:}}") String apiKey) {
        this.webClient = webClient;
        this.apiKey = apiKey;
    }

    /**
     * Get weather data with agricultural insights for Indian farmers
     * Provides farming-specific recommendations based on weather conditions
     */
    public Map<String, Object> getWeather(double lat, double lon) {
        Map<String, Object> weatherData;
        
        if (apiKey == null || apiKey.isBlank()) {
            // Fallback to mock data for development
            weatherData = generateMockWeatherData(lat, lon);
        } else {
            try {
                weatherData = fetchWeatherFromApi(lat, lon);
            } catch (Exception ex) {
                // Fallback to mock data if API fails
                weatherData = generateMockWeatherData(lat, lon);
            }
        }
        
        // Add agricultural context to weather data
        enhanceWithAgriculturalContext(weatherData, lat, lon);
        
        return weatherData;
    }

    /**
     * Get 5-day weather forecast with agricultural recommendations
     */
    public Map<String, Object> getWeatherForecast(double lat, double lon) {
        Map<String, Object> forecastData;
        if (apiKey == null || apiKey.isBlank()) {
            // Mock forecast data for development
            forecastData = new java.util.HashMap<>();
            forecastData.put("forecast", java.util.List.of(
                java.util.Map.of("day", 1, "temp", 30, "condition", "Clouds"),
                java.util.Map.of("day", 2, "temp", 29, "condition", "Rain"),
                java.util.Map.of("day", 3, "temp", 31, "condition", "Clear")
            ));
        } else {
            // For simplicity, reuse current weather and annotate as forecast
            forecastData = getWeather(lat, lon);
            forecastData.put("note", "Forecast endpoint using simplified data in MVP");
        }
        enhanceWithAgriculturalContext(forecastData, lat, lon);
        return forecastData;
    }

    /**
     * Get weather alerts for agricultural activities
     */
    public Map<String, Object> getWeatherAlerts(double lat, double lon) {
        Map<String, Object> alertsData = new java.util.HashMap<>();
        java.util.List<Map<String, Object>> alerts = new java.util.ArrayList<>();
        alerts.add(java.util.Map.of(
            "type", "WIND",
            "severity", "MEDIUM",
            "message", "Gusty winds expected. Avoid spraying.")
        );
        alertsData.put("alerts", alerts);
        alertsData.put("latitude", lat);
        alertsData.put("longitude", lon);
        return alertsData;
    }

    /**
     * Fetch weather data from OpenWeatherMap API
     */
    private Map<String, Object> fetchWeatherFromApi(double lat, double lon) {
        String url = "https://api.openweathermap.org/data/2.5/weather";

        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path(url)
                        .queryParam("lat", lat)
                        .queryParam("lon", lon)
                        .queryParam("appid", apiKey)
                        .queryParam("units", "metric")
                        .build())
                .retrieve()
                .onStatus(org.springframework.http.HttpStatusCode::isError, resp -> resp.bodyToMono(String.class).flatMap(body ->
                        Mono.error(new ResponseStatusException(resp.statusCode(),
                                "Failed to fetch weather data: " + body))))
                .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                .block();
    }

    /**
     * Generate mock weather data for development and testing
     */
    private Map<String, Object> generateMockWeatherData(double lat, double lon) {
        Map<String, Object> weatherData = new java.util.HashMap<>();
        
        // Mock current weather
        Map<String, Object> main = new java.util.HashMap<>();
        main.put("temp", 28.5 + (Math.random() * 10 - 5));
        main.put("humidity", 65 + (Math.random() * 20 - 10));
        main.put("pressure", 1013.25);
        
        Map<String, Object> wind = new java.util.HashMap<>();
        wind.put("speed", 12.3 + (Math.random() * 8 - 4));
        wind.put("deg", Math.random() * 360);
        
        java.util.List<Map<String, Object>> weather = new java.util.ArrayList<>();
        Map<String, Object> weatherCondition = new java.util.HashMap<>();
        weatherCondition.put("main", "Clouds");
        weatherCondition.put("description", "Partly cloudy");
        weatherCondition.put("icon", "02d");
        weather.add(weatherCondition);
        
        weatherData.put("main", main);
        weatherData.put("wind", wind);
        weatherData.put("weather", weather);
        
        return weatherData;
    }

    /**
     * Enhance weather data with agricultural context and recommendations
     */
    private void enhanceWithAgriculturalContext(Map<String, Object> weatherData, double lat, double lon) {
        // Extract weather values
        Map<String, Object> main = (Map<String, Object>) weatherData.get("main");
        Map<String, Object> wind = (Map<String, Object>) weatherData.get("wind");
        
        double temperature = ((Number) main.get("temp")).doubleValue();
        double humidity = ((Number) main.get("humidity")).doubleValue();
        double windSpeed = wind != null ? ((Number) wind.get("speed")).doubleValue() : 0.0;
        
        // Add agricultural insights
        java.util.List<String> recommendations = new java.util.ArrayList<>();
        java.util.List<Map<String, Object>> alerts = new java.util.ArrayList<>();
        
        // Temperature recommendations
        if (temperature > 35) {
            recommendations.add("High temperature alert: Increase irrigation frequency");
            recommendations.add("Provide shade for sensitive crops during peak hours");
            
            Map<String, Object> alert = new java.util.HashMap<>();
            alert.put("type", "HEAT_STRESS");
            alert.put("severity", "HIGH");
            alert.put("message", "Extreme heat may damage crops");
            alerts.add(alert);
        }
        
        // Humidity recommendations
        if (humidity > 80) {
            recommendations.add("High humidity: Monitor for fungal diseases");
            recommendations.add("Ensure proper ventilation around plants");
        }
        
        // Wind recommendations
        if (windSpeed > 20) {
            recommendations.add("Strong winds: Secure tall crops and avoid spraying");
        }
        
        // Add location context
        Map<String, Object> location = new java.util.HashMap<>();
        location.put("latitude", lat);
        location.put("longitude", lon);
        location.put("region", getRegionName(lat, lon));
        location.put("state", getStateName(lat, lon));
        
        // Add agricultural enhancements to weather data
        weatherData.put("agriculturalRecommendations", recommendations);
        weatherData.put("alerts", alerts);
        weatherData.put("location", location);
        weatherData.put("farmingConditions", getFarmingConditions(temperature, humidity, windSpeed));
    }

    /**
     * Get farming conditions assessment
     */
    private Map<String, Object> getFarmingConditions(double temperature, double humidity, double windSpeed) {
        Map<String, Object> conditions = new java.util.HashMap<>();
        
        // Overall farming suitability
        String suitability;
        if (temperature >= 20 && temperature <= 30 && humidity >= 50 && humidity <= 70) {
            suitability = "EXCELLENT";
        } else if (temperature >= 15 && temperature <= 35 && humidity >= 40 && humidity <= 80) {
            suitability = "GOOD";
        } else {
            suitability = "CHALLENGING";
        }
        
        conditions.put("overallSuitability", suitability);
        conditions.put("irrigationNeed", temperature > 30 ? "HIGH" : "MODERATE");
        conditions.put("diseaseRisk", humidity > 75 ? "HIGH" : "LOW");
        conditions.put("sprayingConditions", windSpeed < 15 ? "SUITABLE" : "NOT_SUITABLE");
        
        return conditions;
    }

    private String getRegionName(double lat, double lon) {
        // Simplified region mapping for Indian agriculture
        if (lat >= 19.0 && lat <= 20.5 && lon >= 73.0 && lon <= 75.0) {
            return "Western Maharashtra";
        }
        return "Agricultural Region";
    }

    private String getStateName(double lat, double lon) {
        // Simplified state mapping
        if (lat >= 19.0 && lat <= 20.5 && lon >= 73.0 && lon <= 75.0) {
            return "Maharashtra";
        }
        return "India";
    }
}

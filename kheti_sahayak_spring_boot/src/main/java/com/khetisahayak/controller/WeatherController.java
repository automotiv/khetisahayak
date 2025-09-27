package com.khetisahayak.controller;

import com.khetisahayak.service.WeatherService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.HashMap;

@Tag(name = "Weather", description = "Weather forecast operations")
@RestController
@RequestMapping("/api/weather")
public class WeatherController {

    private final WeatherService weatherService;

    public WeatherController(WeatherService weatherService) {
        this.weatherService = weatherService;
    }

    @Operation(summary = "Get current weather with agricultural insights", 
               description = "Get current weather data enhanced with agricultural recommendations and crop suitability")
    @GetMapping
    public ResponseEntity<Map<String, Object>> getWeather(
            @Parameter(description = "Latitude", required = true) @RequestParam double lat,
            @Parameter(description = "Longitude", required = true) @RequestParam double lon) {
        try {
            Map<String, Object> weatherData = weatherService.getWeather(lat, lon);
            return ResponseEntity.ok(weatherData);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to fetch weather data: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.status(500).body(errorResponse);
        }
    }

    @Operation(summary = "Get weather forecast", 
               description = "Get 5-day weather forecast with agricultural planning recommendations")
    @GetMapping("/forecast")
    public ResponseEntity<Map<String, Object>> getWeatherForecast(
            @Parameter(description = "Latitude", required = true) @RequestParam double lat,
            @Parameter(description = "Longitude", required = true) @RequestParam double lon) {
        try {
            Map<String, Object> forecastData = weatherService.getWeatherForecast(lat, lon);
            return ResponseEntity.ok(forecastData);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to fetch forecast data: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.status(500).body(errorResponse);
        }
    }

    @Operation(summary = "Get weather alerts", 
               description = "Get weather alerts and warnings relevant to agricultural activities")
    @GetMapping("/alerts")
    public ResponseEntity<Map<String, Object>> getWeatherAlerts(
            @Parameter(description = "Latitude", required = true) @RequestParam double lat,
            @Parameter(description = "Longitude", required = true) @RequestParam double lon) {
        try {
            Map<String, Object> alertsData = weatherService.getWeatherAlerts(lat, lon);
            return ResponseEntity.ok(alertsData);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to fetch weather alerts: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.status(500).body(errorResponse);
        }
    }
}

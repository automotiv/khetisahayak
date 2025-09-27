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

@Tag(name = "Weather", description = "Weather forecast operations")
@RestController
@RequestMapping("/api/weather")
public class WeatherController {

    private final WeatherService weatherService;

    public WeatherController(WeatherService weatherService) {
        this.weatherService = weatherService;
    }

    @Operation(summary = "Get weather forecast", description = "Get weather forecast for a given latitude and longitude")
    @GetMapping
    public ResponseEntity<Map<String, Object>> getWeather(
            @Parameter(description = "Latitude", required = true) @RequestParam double lat,
            @Parameter(description = "Longitude", required = true) @RequestParam double lon) {
        Map<String, Object> weatherData = weatherService.getWeather(lat, lon);
        return ResponseEntity.ok(weatherData);
    }
}

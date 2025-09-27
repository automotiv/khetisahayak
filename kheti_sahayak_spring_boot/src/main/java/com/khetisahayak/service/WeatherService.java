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

    public Map<String, Object> getWeather(double lat, double lon) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "Server configuration error: Missing weather API key");
        }

        String url = "https://api.openweathermap.org/data/2.5/weather";

        try {
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
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to fetch weather data", ex);
        }
    }
}

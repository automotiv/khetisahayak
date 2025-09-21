package com.khetisahayak.controller;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
public class InfoController {

    @GetMapping(value = "/", produces = MediaType.APPLICATION_JSON_VALUE)
    public Map<String, Object> root() {
        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("message", "Kheti Sahayak Backend API");
        resp.put("version", "1.0.0");
        resp.put("status", "running");
        resp.put("documentation", "/api-docs");

        Map<String, String> endpoints = new LinkedHashMap<>();
        endpoints.put("auth", "/api/auth");
        endpoints.put("health", "/api/health");
        endpoints.put("weather", "/api/weather");
        endpoints.put("diagnostics", "/api/diagnostics");
        endpoints.put("marketplace", "/api/marketplace");
        endpoints.put("educationalContent", "/api/educational-content");
        endpoints.put("orders", "/api/orders");
        endpoints.put("notifications", "/api/notifications");
        resp.put("endpoints", endpoints);

        return resp;
    }
}

package com.khetisahayak.controller;

import com.khetisahayak.model.health.HealthResponse;
import com.khetisahayak.service.HealthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Health", description = "Health check endpoints")
@RestController
@RequestMapping("/api/health")
public class HealthController {

    private final HealthService healthService;

    public HealthController(HealthService healthService) {
        this.healthService = healthService;
    }

    @Operation(summary = "Health check", description = "Check application and dependent services (DB, Redis)")
    @GetMapping
    public ResponseEntity<HealthResponse> health() {
        HealthResponse response = healthService.getHealth();
        boolean ok = "OK".equalsIgnoreCase(response.getMessage());
        return new ResponseEntity<>(response, ok ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE);
    }
}

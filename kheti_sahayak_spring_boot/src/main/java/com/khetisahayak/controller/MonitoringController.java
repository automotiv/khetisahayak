package com.khetisahayak.controller;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Metrics;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Monitoring & Observability Controller
 * Implements Issue #256: QPS/Latency/Error telemetry and dashboards
 */
@Tag(name = "Monitoring", description = "Observability and monitoring APIs")
@RestController
@RequestMapping("/api/monitoring")
@CrossOrigin(origins = "*")
public class MonitoringController {

    private final MeterRegistry meterRegistry;

    @Autowired
    public MonitoringController(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }

    @Operation(summary = "Get application metrics summary")
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/metrics")
    public ResponseEntity<Map<String, Object>> getMetrics() {
        try {
            Map<String, Object> metrics = new HashMap<>();
            
            // Collect all metrics
            meterRegistry.getMeters().forEach(meter -> {
                String name = meter.getId().getName();
                Object value = meter.measure().iterator().hasNext() 
                    ? meter.measure().iterator().next().getValue() 
                    : 0;
                metrics.put(name, value);
            });
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", metrics);
            response.put("count", metrics.size());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch metrics");
            return ResponseEntity.internalServerError().body(errorResponse);
        }
    }

    @Operation(summary = "Get agricultural-specific metrics")
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/metrics/agricultural")
    public ResponseEntity<Map<String, Object>> getAgriculturalMetrics() {
        try {
            Map<String, Object> agricMetrics = new HashMap<>();
            
            // Filter agricultural metrics
            meterRegistry.getMeters().stream()
                .filter(meter -> meter.getId().getName().startsWith("agriculture."))
                .forEach(meter -> {
                    String name = meter.getId().getName();
                    Object value = meter.measure().iterator().hasNext() 
                        ? meter.measure().iterator().next().getValue() 
                        : 0;
                    agricMetrics.put(name, value);
                });
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", agricMetrics);
            response.put("count", agricMetrics.size());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch agricultural metrics");
            return ResponseEntity.internalServerError().body(errorResponse);
        }
    }

    @Operation(summary = "Get system health with detailed metrics")
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/health/detailed")
    public ResponseEntity<Map<String, Object>> getDetailedHealth() {
        try {
            Map<String, Object> health = new HashMap<>();
            
            // JVM metrics
            Map<String, Object> jvm = new HashMap<>();
            jvm.put("memory_used", Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory());
            jvm.put("memory_total", Runtime.getRuntime().totalMemory());
            jvm.put("memory_max", Runtime.getRuntime().maxMemory());
            jvm.put("processors", Runtime.getRuntime().availableProcessors());
            health.put("jvm", jvm);
            
            // Get HTTP metrics
            Map<String, Object> http = new HashMap<>();
            meterRegistry.getMeters().stream()
                .filter(meter -> meter.getId().getName().startsWith("http.server.requests"))
                .forEach(meter -> {
                    http.put(meter.getId().getName(), meter.measure().iterator().next().getValue());
                });
            health.put("http", http);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", health);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch detailed health");
            return ResponseEntity.internalServerError().body(errorResponse);
        }
    }
}


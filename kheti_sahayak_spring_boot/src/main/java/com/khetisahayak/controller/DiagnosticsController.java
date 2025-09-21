package com.khetisahayak.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.Map;
import java.util.HashMap;

/**
 * Crop Diagnostics Controller for Kheti Sahayak Agricultural Platform
 * Handles crop health analysis, image processing, and expert consultations
 * Implements CodeRabbit security standards for farmer data protection
 */
@Tag(name = "Diagnostics", description = "Crop diagnostics and expert review operations")
@RestController
@RequestMapping("/api/diagnostics")
@Validated
public class DiagnosticsController {

    /**
     * Get crop recommendations based on type and location
     * Provides agricultural insights for Indian farming conditions
     */
    @Operation(summary = "Get crop recommendations", 
               description = "Get agricultural recommendations for specific crop types and locations")
    @GetMapping("/recommendations")
    @PreAuthorize("hasRole('FARMER') or hasRole('EXPERT')")
    public ResponseEntity<Map<String, Object>> getCropRecommendations(
            @Parameter(description = "Crop type (e.g., Rice, Wheat, Cotton)")
            @RequestParam @Pattern(regexp = "^[a-zA-Z\\s]{2,50}$", message = "Invalid crop type") 
            String cropType,
            
            @Parameter(description = "Latitude for location-based recommendations")
            @RequestParam(required = false) 
            @DecimalMin(value = "-90.0", message = "Latitude must be between -90 and 90")
            @DecimalMax(value = "90.0", message = "Latitude must be between -90 and 90")
            Double latitude,
            
            @Parameter(description = "Longitude for location-based recommendations")
            @RequestParam(required = false)
            @DecimalMin(value = "-180.0", message = "Longitude must be between -180 and 180") 
            @DecimalMax(value = "180.0", message = "Longitude must be between -180 and 180")
            Double longitude) {
        
        Map<String, Object> response = new HashMap<>();
        response.put("cropType", cropType);
        response.put("recommendations", "Agricultural recommendations will be implemented");
        response.put("location", Map.of("latitude", latitude, "longitude", longitude));
        
        return ResponseEntity.ok(response);
    }

    /**
     * Get diagnostic statistics for farmer dashboard
     * Provides insights into crop health trends and patterns
     */
    @Operation(summary = "Get diagnostic statistics", 
               description = "Get statistical insights for crop diagnostics")
    @GetMapping("/stats")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<Map<String, Object>> getDiagnosticStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalDiagnoses", 0);
        stats.put("accuracyRate", 0.0);
        stats.put("commonIssues", new String[]{});
        
        return ResponseEntity.ok(stats);
    }

    /**
     * Upload crop image for AI-powered diagnosis
     * Implements comprehensive validation for agricultural image analysis
     * Optimized for rural network conditions with size and type restrictions
     */
    @Operation(summary = "Upload crop image for diagnosis", 
               description = "Upload crop image for AI-powered health analysis and treatment recommendations")
    @PostMapping("/upload")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<Map<String, Object>> uploadForDiagnosis(
            @Parameter(description = "Crop image file (JPEG, PNG, WebP only, max 5MB)")
            @RequestParam("image") MultipartFile image,
            
            @Parameter(description = "Type of crop being diagnosed")
            @RequestParam(value = "cropType", required = false)
            @Pattern(regexp = "^[a-zA-Z\\s]{2,50}$", message = "Crop type must be 2-50 alphabetic characters")
            String cropType,
            
            @Parameter(description = "Symptoms observed by farmer")
            @RequestParam(value = "symptoms", required = false)
            @Size(max = 500, message = "Symptoms description must be less than 500 characters")
            String symptoms,
            
            @Parameter(description = "Farm latitude for location-based analysis")
            @RequestParam(value = "latitude", required = false)
            @DecimalMin(value = "6.0", message = "Latitude must be within India (6.0 to 37.0)")
            @DecimalMax(value = "37.0", message = "Latitude must be within India (6.0 to 37.0)")
            Double latitude,
            
            @Parameter(description = "Farm longitude for location-based analysis")
            @RequestParam(value = "longitude", required = false)
            @DecimalMin(value = "68.0", message = "Longitude must be within India (68.0 to 97.0)")
            @DecimalMax(value = "97.0", message = "Longitude must be within India (68.0 to 97.0)")
            Double longitude) {
        
        // Validate image file for agricultural diagnosis
        if (image.isEmpty()) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", "Image file is required for crop diagnosis"));
        }
        
        // Check file size (max 5MB for rural network compatibility)
        if (image.getSize() > 5 * 1024 * 1024) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", "Image size must be less than 5MB for rural network compatibility"));
        }
        
        // Check file type for agricultural images
        String contentType = image.getContentType();
        if (contentType == null || 
            (!contentType.equals("image/jpeg") && 
             !contentType.equals("image/png") && 
             !contentType.equals("image/webp"))) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", "Only JPEG, PNG, and WebP images are supported for crop diagnosis"));
        }
        
        // Prepare response with agricultural context
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Crop image uploaded successfully for diagnosis");
        response.put("fileName", image.getOriginalFilename());
        response.put("fileSize", image.getSize());
        response.put("cropType", cropType);
        response.put("symptoms", symptoms);
        response.put("location", Map.of("latitude", latitude, "longitude", longitude));
        response.put("status", "processing");
        response.put("estimatedTime", "2-3 minutes");
        
        return ResponseEntity.ok(response);
    }

    /**
     * Get diagnostic history for authenticated farmer
     * Returns paginated list of previous crop diagnoses with agricultural insights
     */
    @Operation(summary = "Get diagnostic history", 
               description = "Retrieve paginated history of crop diagnoses for the authenticated farmer")
    @GetMapping
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<Map<String, Object>> getDiagnosticHistory(
            @Parameter(description = "Page number (0-based)")
            @RequestParam(defaultValue = "0") @Min(0) Integer page,
            
            @Parameter(description = "Page size (max 50)")
            @RequestParam(defaultValue = "20") @Min(1) @Max(50) Integer size) {
        
        Map<String, Object> response = new HashMap<>();
        response.put("content", new Object[]{});
        response.put("page", page);
        response.put("size", size);
        response.put("totalElements", 0);
        response.put("totalPages", 0);
        
        return ResponseEntity.ok(response);
    }

    /**
     * Get specific diagnostic details by ID
     * Provides detailed crop health analysis and treatment recommendations
     */
    @Operation(summary = "Get diagnostic by ID", 
               description = "Retrieve detailed information about a specific crop diagnosis")
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('FARMER') or hasRole('EXPERT')")
    public ResponseEntity<Map<String, Object>> getDiagnosticById(
            @Parameter(description = "Diagnostic ID")
            @PathVariable @Positive(message = "Diagnostic ID must be positive") Long id) {
        
        Map<String, Object> response = new HashMap<>();
        response.put("id", id);
        response.put("status", "Not found");
        
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }

    /**
     * Request expert review for crop diagnosis
     * Connects farmers with agricultural experts for complex cases
     */
    @Operation(summary = "Request expert review", 
               description = "Request agricultural expert review for complex crop diagnosis cases")
    @PostMapping("/{id}/expert-review")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<Map<String, Object>> requestExpertReview(
            @Parameter(description = "Diagnostic ID requiring expert review")
            @PathVariable @Positive(message = "Diagnostic ID must be positive") Long id,
            
            @Parameter(description = "Additional notes for expert")
            @RequestParam(value = "notes", required = false)
            @Size(max = 1000, message = "Notes must be less than 1000 characters")
            String notes) {
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Expert review requested successfully");
        response.put("diagnosticId", id);
        response.put("notes", notes);
        response.put("estimatedReviewTime", "24-48 hours");
        
        return ResponseEntity.ok(response);
    }

    /**
     * Submit expert review for crop diagnosis
     * Allows agricultural experts to provide professional recommendations
     */
    @Operation(summary = "Submit expert review", 
               description = "Submit professional agricultural expert review and recommendations")
    @PutMapping("/{id}/expert-review")
    @PreAuthorize("hasRole('EXPERT')")
    public ResponseEntity<Map<String, Object>> submitExpertReview(
            @Parameter(description = "Diagnostic ID being reviewed")
            @PathVariable @Positive(message = "Diagnostic ID must be positive") Long id,
            
            @Parameter(description = "Expert diagnosis and recommendations")
            @RequestBody @Valid Map<String, Object> reviewData) {
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Expert review submitted successfully");
        response.put("diagnosticId", id);
        response.put("reviewData", reviewData);
        
        return ResponseEntity.ok(response);
    }

    /**
     * Get diagnoses assigned to expert for review
     * Returns list of crop diagnoses requiring expert attention
     */
    @Operation(summary = "Get assigned diagnoses", 
               description = "Get list of crop diagnoses assigned to the authenticated expert")
    @GetMapping("/expert/assigned")
    @PreAuthorize("hasRole('EXPERT')")
    public ResponseEntity<Map<String, Object>> getExpertAssignedDiagnostics(
            @Parameter(description = "Page number (0-based)")
            @RequestParam(defaultValue = "0") @Min(0) Integer page,
            
            @Parameter(description = "Page size (max 50)")
            @RequestParam(defaultValue = "20") @Min(1) @Max(50) Integer size) {
        
        Map<String, Object> response = new HashMap<>();
        response.put("content", new Object[]{});
        response.put("page", page);
        response.put("size", size);
        response.put("totalElements", 0);
        response.put("totalPages", 0);
        
        return ResponseEntity.ok(response);
    }

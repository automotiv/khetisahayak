package com.khetisahayak.controller;

import com.khetisahayak.model.GovernmentScheme;
import com.khetisahayak.model.SchemeApplication;
import com.khetisahayak.service.SchemeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.Map;

@Tag(name = "Government Schemes", description = "Agricultural government schemes and subsidies APIs")
@RestController
@RequestMapping("/api/schemes")
@CrossOrigin(origins = "*")
public class SchemeController {

    private final SchemeService schemeService;

    @Autowired
    public SchemeController(SchemeService schemeService) {
        this.schemeService = schemeService;
    }

    private Long getAuthenticatedUserId() {
        return Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName());
    }

    @Operation(summary = "Get all schemes")
    @GetMapping
    public ResponseEntity<Map<String, Object>> getAllSchemes(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Page<GovernmentScheme> schemes = schemeService.getAllActiveSchemes(PageRequest.of(page, size));
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", schemes.getContent());
            response.put("currentPage", schemes.getNumber());
            response.put("totalItems", schemes.getTotalElements());
            response.put("totalPages", schemes.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch schemes");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get scheme by ID")
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getSchemeById(@PathVariable Long id) {
        return schemeService.getSchemeById(id)
            .map(scheme -> {
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("data", scheme);
                return ResponseEntity.ok(response);
            })
            .orElseGet(() -> {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("error", "Scheme not found");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
            });
    }

    @Operation(summary = "Search schemes")
    @GetMapping("/search")
    public ResponseEntity<Map<String, Object>> searchSchemes(
            @RequestParam String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Page<GovernmentScheme> schemes = schemeService.searchSchemes(q, PageRequest.of(page, size));
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", schemes.getContent());
            response.put("query", q);
            response.put("currentPage", schemes.getNumber());
            response.put("totalItems", schemes.getTotalElements());
            response.put("totalPages", schemes.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Search failed");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get farmer applications")
    @PreAuthorize("hasRole('FARMER')")
    @GetMapping("/applications")
    public ResponseEntity<Map<String, Object>> getFarmerApplications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Long farmerId = getAuthenticatedUserId();
            Page<SchemeApplication> applications = schemeService.getFarmerApplications(
                farmerId, PageRequest.of(page, size));
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", applications.getContent());
            response.put("currentPage", applications.getNumber());
            response.put("totalItems", applications.getTotalElements());
            response.put("totalPages", applications.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch applications");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Apply for scheme")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping("/applications")
    public ResponseEntity<Map<String, Object>> applyForScheme(@Valid @RequestBody SchemeApplication application) {
        try {
            Long farmerId = getAuthenticatedUserId();
            application.setFarmerId(farmerId);
            
            SchemeApplication created = schemeService.createApplication(application);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Application submitted successfully");
            response.put("data", created);
            response.put("applicationNumber", created.getApplicationNumber());
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to submit application");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get application status")
    @GetMapping("/applications/status/{applicationNumber}")
    public ResponseEntity<Map<String, Object>> getApplicationStatus(@PathVariable String applicationNumber) {
        return schemeService.getApplicationByNumber(applicationNumber)
            .map(application -> {
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("data", application);
                response.put("status", application.getStatus());
                return ResponseEntity.ok(response);
            })
            .orElseGet(() -> {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("error", "Application not found");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
            });
    }

    @Operation(summary = "Create scheme (Admin only)")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping
    public ResponseEntity<Map<String, Object>> createScheme(@Valid @RequestBody GovernmentScheme scheme) {
        try {
            GovernmentScheme created = schemeService.createScheme(scheme);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Scheme created successfully");
            response.put("data", created);
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to create scheme");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
}


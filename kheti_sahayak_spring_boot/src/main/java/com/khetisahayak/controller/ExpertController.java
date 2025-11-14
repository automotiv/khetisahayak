package com.khetisahayak.controller;

import com.khetisahayak.model.ExpertConsultation;
import com.khetisahayak.service.ExpertService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
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

/**
 * Expert Network Controller for Kheti Sahayak Agricultural Platform
 * Handles expert profiles, consultations, ratings, and availability
 * Implements CodeRabbit security standards for expert-farmer interactions
 */
@Tag(name = "Expert Network", description = "Agricultural expert consultation APIs")
@RestController
@RequestMapping("/api/experts")
@CrossOrigin(origins = "*")
public class ExpertController {

    private final ExpertService expertService;

    @Autowired
    public ExpertController(ExpertService expertService) {
        this.expertService = expertService;
    }

    private Long getAuthenticatedUserId() {
        return Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName());
    }

    @Operation(summary = "Get all available experts", description = "List all verified and active agricultural experts")
    @GetMapping
    public ResponseEntity<Map<String, Object>> getAllExperts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String state,
            @RequestParam(required = false) String category) {
        try {
            Page<Map<String, Object>> experts = expertService.getAllExperts(
                PageRequest.of(page, size), state, category);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", experts.getContent());
            response.put("currentPage", experts.getNumber());
            response.put("totalItems", experts.getTotalElements());
            response.put("totalPages", experts.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch experts");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get expert profile by ID", description = "Get detailed expert profile with ratings and statistics")
    @GetMapping("/{expertId}")
    public ResponseEntity<Map<String, Object>> getExpertProfile(@PathVariable Long expertId) {
        try {
            Map<String, Object> expertProfile = expertService.getExpertProfile(expertId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", expertProfile);
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch expert profile");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get expert ratings and reviews", description = "Get all ratings and feedback for an expert")
    @GetMapping("/{expertId}/ratings")
    public ResponseEntity<Map<String, Object>> getExpertRatings(
            @PathVariable Long expertId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Page<ExpertConsultation> ratings = expertService.getExpertRatings(
                expertId, PageRequest.of(page, size));
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", ratings.getContent());
            response.put("currentPage", ratings.getNumber());
            response.put("totalItems", ratings.getTotalElements());
            response.put("totalPages", ratings.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch expert ratings");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get farmer consultations")
    @PreAuthorize("hasRole('FARMER')")
    @GetMapping("/consultations")
    public ResponseEntity<Map<String, Object>> getFarmerConsultations(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Long farmerId = getAuthenticatedUserId();
            Page<ExpertConsultation> consultations = expertService.getFarmerConsultations(
                farmerId, PageRequest.of(page, size));
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", consultations.getContent());
            response.put("currentPage", consultations.getNumber());
            response.put("totalItems", consultations.getTotalElements());
            response.put("totalPages", consultations.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch consultations");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get expert consultations", description = "Get all consultations for an expert")
    @PreAuthorize("hasRole('EXPERT')")
    @GetMapping("/consultations/my-consultations")
    public ResponseEntity<Map<String, Object>> getExpertConsultations(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Long expertId = getAuthenticatedUserId();
            Page<ExpertConsultation> consultations = expertService.getExpertConsultations(
                expertId, PageRequest.of(page, size));
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", consultations.getContent());
            response.put("currentPage", consultations.getNumber());
            response.put("totalItems", consultations.getTotalElements());
            response.put("totalPages", consultations.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch consultations");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Book expert consultation")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping("/consultations")
    public ResponseEntity<Map<String, Object>> bookConsultation(@Valid @RequestBody ExpertConsultation consultation) {
        try {
            Long farmerId = getAuthenticatedUserId();
            consultation.setFarmerId(farmerId);
            
            ExpertConsultation created = expertService.createConsultation(consultation);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Consultation booked successfully");
            response.put("data", created);
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to book consultation");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Update consultation")
    @PreAuthorize("hasRole('EXPERT') or hasRole('FARMER')")
    @PutMapping("/consultations/{id}")
    public ResponseEntity<Map<String, Object>> updateConsultation(
            @PathVariable Long id,
            @Valid @RequestBody ExpertConsultation consultation) {
        try {
            ExpertConsultation updated = expertService.updateConsultation(id, consultation);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Consultation updated");
            response.put("data", updated);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        }
    }

    @Operation(summary = "Submit consultation rating", description = "Submit rating and feedback for a completed consultation")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping("/consultations/{id}/rating")
    public ResponseEntity<Map<String, Object>> submitRating(
            @PathVariable Long id,
            @RequestParam @Parameter(description = "Rating from 1 to 5") Integer rating,
            @RequestParam(required = false) String feedback) {
        try {
            Long farmerId = getAuthenticatedUserId();
            ExpertConsultation consultation = expertService.submitRating(id, farmerId, rating, feedback);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Rating submitted successfully");
            response.put("data", consultation);
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to submit rating");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get consultation by ID", description = "Get detailed consultation information")
    @PreAuthorize("hasRole('FARMER') or hasRole('EXPERT')")
    @GetMapping("/consultations/{id}")
    public ResponseEntity<Map<String, Object>> getConsultationById(@PathVariable Long id) {
        try {
            Long userId = getAuthenticatedUserId();
            ExpertConsultation consultation = expertService.getConsultationById(id)
                .orElseThrow(() -> new RuntimeException("Consultation not found"));
            
            // Verify user has access to this consultation
            if (!consultation.getFarmerId().equals(userId) && !consultation.getExpertId().equals(userId)) {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("error", "Not authorized to view this consultation");
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", consultation);
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch consultation");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
}


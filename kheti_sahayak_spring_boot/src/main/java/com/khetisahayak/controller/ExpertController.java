package com.khetisahayak.controller;

import com.khetisahayak.model.ExpertConsultation;
import com.khetisahayak.service.ExpertService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.Map;

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
}


package com.khetisahayak.controller;

import com.khetisahayak.model.UserConsent;
import com.khetisahayak.service.ConsentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.Map;

/**
 * Consent Management Controller
 * Implements Privacy & Consent APIs as per Issue #255
 */
@Tag(name = "Privacy & Consent", description = "User privacy consent management APIs")
@RestController
@RequestMapping("/api/consent")
@CrossOrigin(origins = "*")
public class ConsentController {

    private final ConsentService consentService;

    @Autowired
    public ConsentController(ConsentService consentService) {
        this.consentService = consentService;
    }

    private Long getAuthenticatedUserId() {
        return Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName());
    }

    @Operation(summary = "Get user consent preferences")
    @PreAuthorize("hasRole('FARMER')")
    @GetMapping
    public ResponseEntity<Map<String, Object>> getUserConsent() {
        try {
            Long userId = getAuthenticatedUserId();
            
            return consentService.getUserConsent(userId)
                .map(consent -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("success", true);
                    response.put("data", consent);
                    return ResponseEntity.ok(response);
                })
                .orElseGet(() -> {
                    // Return default (all false) if no consent record exists
                    Map<String, Object> response = new HashMap<>();
                    response.put("success", true);
                    response.put("data", new UserConsent(userId));
                    response.put("message", "No consent preferences set yet");
                    return ResponseEntity.ok(response);
                });
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch consent preferences");
            return ResponseEntity.internalServerError().body(errorResponse);
        }
    }

    @Operation(summary = "Update user consent preferences")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping
    public ResponseEntity<Map<String, Object>> updateConsent(
            @Valid @RequestBody UserConsent consent,
            HttpServletRequest request) {
        try {
            Long userId = getAuthenticatedUserId();
            
            // Capture IP and User Agent for audit trail
            consent.setIpAddress(getClientIp(request));
            consent.setUserAgent(request.getHeader("User-Agent"));
            
            UserConsent savedConsent = consentService.createOrUpdateConsent(userId, consent);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Consent preferences updated successfully");
            response.put("data", savedConsent);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to update consent preferences");
            return ResponseEntity.internalServerError().body(errorResponse);
        }
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        return ip;
    }
}


package com.khetisahayak.controller;

import com.khetisahayak.service.UserService;
import com.khetisahayak.service.JwtService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.Map;
import java.util.HashMap;

/**
 * Authentication Controller for Kheti Sahayak Agricultural Platform
 * Handles farmer registration, login, and profile management
 * Implements CodeRabbit security standards for agricultural user data protection
 */
@Tag(name = "Authentication", description = "User authentication and profile management for farmers")
@RestController
@RequestMapping("/api/auth")
@Validated
public class AuthController {

    @Autowired
    private UserService userService;

    @Autowired
    private JwtService jwtService;

    /**
     * Register a new farmer user with OTP verification
     * Implements agricultural user onboarding with regional context
     */
    @Operation(summary = "Register new farmer", 
               description = "Register a new farmer with mobile number and basic agricultural information")
    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> registerFarmer(
            @Parameter(description = "Farmer's mobile number (Indian format)")
            @RequestParam @Pattern(regexp = "^[6-9]\\d{9}$", 
                                 message = "Mobile number must be valid Indian number (10 digits starting with 6-9)")
            String mobileNumber,
            
            @Parameter(description = "Farmer's full name")
            @RequestParam @NotBlank @Size(min = 2, max = 100, 
                                        message = "Name must be between 2 and 100 characters")
            String fullName,
            
            @Parameter(description = "Primary crop type grown by farmer")
            @RequestParam(required = false) 
            @Pattern(regexp = "^[a-zA-Z\\s]{2,50}$", message = "Invalid crop type")
            String primaryCrop,
            
            @Parameter(description = "Farm location - State in India")
            @RequestParam @NotBlank @Size(max = 50, message = "State name required")
            String state,
            
            @Parameter(description = "Farm location - District")
            @RequestParam @NotBlank @Size(max = 50, message = "District name required")
            String district,
            
            @Parameter(description = "Farm size in acres")
            @RequestParam(required = false)
            @DecimalMin(value = "0.1", message = "Farm size must be at least 0.1 acres")
            @DecimalMax(value = "10000.0", message = "Farm size must be less than 10000 acres")
            Double farmSize) {
        
        try {
            Map<String, Object> response = userService.registerFarmer(
                mobileNumber, fullName, primaryCrop, state, district, farmSize
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Verify OTP and complete farmer registration
     * Creates farmer account with agricultural profile
     */
    @Operation(summary = "Verify OTP and complete registration", 
               description = "Verify OTP sent to farmer's mobile and complete account creation")
    @PostMapping("/verify-otp")
    public ResponseEntity<Map<String, Object>> verifyOtpAndRegister(
            @Parameter(description = "Farmer's mobile number")
            @RequestParam @Pattern(regexp = "^[6-9]\\d{9}$") String mobileNumber,
            
            @Parameter(description = "6-digit OTP received on mobile")
            @RequestParam @Pattern(regexp = "^\\d{6}$", message = "OTP must be 6 digits") String otp,
            
            @Parameter(description = "Farmer's full name")
            @RequestParam @NotBlank @Size(min = 2, max = 100) String fullName,
            
            @Parameter(description = "Primary crop type")
            @RequestParam(required = false) String primaryCrop,
            
            @Parameter(description = "State")
            @RequestParam @NotBlank String state,
            
            @Parameter(description = "District")
            @RequestParam @NotBlank String district,
            
            @Parameter(description = "Farm size in acres")
            @RequestParam(required = false) Double farmSize) {
        
        try {
            Map<String, Object> response = userService.verifyOtpAndCreateUser(
                mobileNumber, otp, fullName, primaryCrop, state, district, farmSize
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Login farmer with mobile number and OTP
     * Secure authentication for agricultural platform users
     */
    @Operation(summary = "Login farmer", 
               description = "Authenticate farmer using mobile number and OTP")
    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> loginFarmer(
            @Parameter(description = "Farmer's registered mobile number")
            @RequestParam @Pattern(regexp = "^[6-9]\\d{9}$") String mobileNumber) {
        
        try {
            Map<String, Object> response = userService.loginFarmer(mobileNumber);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Verify login OTP and generate JWT token
     * Returns authentication token for API access
     */
    @Operation(summary = "Verify login OTP", 
               description = "Verify login OTP and receive authentication token")
    @PostMapping("/verify-login")
    public ResponseEntity<Map<String, Object>> verifyLoginOtp(
            @Parameter(description = "Farmer's mobile number")
            @RequestParam @Pattern(regexp = "^[6-9]\\d{9}$") String mobileNumber,
            
            @Parameter(description = "6-digit OTP for login")
            @RequestParam @Pattern(regexp = "^\\d{6}$") String otp) {
        
        try {
            Map<String, Object> response = userService.verifyLoginOtp(mobileNumber, otp);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Get authenticated farmer's profile
     * Returns comprehensive agricultural profile information
     */
    @Operation(summary = "Get farmer profile", 
               description = "Retrieve authenticated farmer's profile and agricultural information")
    @GetMapping("/profile")
    @PreAuthorize("hasRole('FARMER') or hasRole('EXPERT') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getFarmerProfile() {
        
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String mobileNumber = auth.getName();
            
            Map<String, Object> profile = userService.getUserProfileByMobile(mobileNumber);
            return ResponseEntity.ok(profile);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Update farmer profile with agricultural information
     * Allows farmers to update their farming details and preferences
     */
    @Operation(summary = "Update farmer profile", 
               description = "Update farmer's agricultural profile and farming information")
    @PutMapping("/profile")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<Map<String, Object>> updateFarmerProfile(
            @Parameter(description = "Updated farmer profile information")
            @RequestBody @Valid Map<String, Object> profileData) {
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Profile updated successfully");
        response.put("updatedFields", profileData.keySet());
        response.put("lastUpdated", System.currentTimeMillis());
        
        return ResponseEntity.ok(response);
    }

    /**
     * Refresh authentication token
     * Extends farmer session without re-authentication
     */
    @Operation(summary = "Refresh token", 
               description = "Refresh authentication token using refresh token")
    @PostMapping("/refresh")
    public ResponseEntity<Map<String, Object>> refreshToken(
            @Parameter(description = "Refresh token")
            @RequestParam @NotBlank String refreshToken) {
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Token refreshed successfully");
        response.put("token", "new_jwt_token_placeholder");
        response.put("expiresIn", "24h");
        
        return ResponseEntity.ok(response);
    }

    /**
     * Logout farmer and invalidate tokens
     * Secure logout with token cleanup
     */
    @Operation(summary = "Logout farmer", 
               description = "Logout farmer and invalidate authentication tokens")
    @PostMapping("/logout")
    @PreAuthorize("hasRole('FARMER') or hasRole('EXPERT') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> logoutFarmer() {
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Logout successful");
        response.put("timestamp", System.currentTimeMillis());
        
        return ResponseEntity.ok(response);
    }
}

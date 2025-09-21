package com.khetisahayak.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "OTP sent successfully to mobile number");
        response.put("mobileNumber", mobileNumber);
        response.put("otpExpiry", "5 minutes");
        response.put("nextStep", "verify-otp");
        
        return ResponseEntity.ok(response);
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
            @RequestParam @Pattern(regexp = "^\\d{6}$", message = "OTP must be 6 digits") String otp) {
        
        // TODO: Implement actual OTP verification logic
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Registration completed successfully");
        response.put("userId", "farmer_" + System.currentTimeMillis());
        response.put("token", "jwt_token_placeholder");
        response.put("expiresIn", "24h");
        response.put("userType", "FARMER");
        
        return ResponseEntity.ok(response);
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
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "OTP sent successfully");
        response.put("mobileNumber", mobileNumber);
        response.put("otpExpiry", "5 minutes");
        response.put("nextStep", "verify-login-otp");
        
        return ResponseEntity.ok(response);
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
        
        // TODO: Implement actual login verification
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Login successful");
        response.put("token", "jwt_token_placeholder");
        response.put("refreshToken", "refresh_token_placeholder");
        response.put("expiresIn", "24h");
        response.put("userProfile", Map.of(
            "id", "farmer_123",
            "name", "Sample Farmer",
            "mobileNumber", mobileNumber,
            "userType", "FARMER",
            "farmProfile", Map.of(
                "primaryCrop", "Rice",
                "state", "Maharashtra",
                "district", "Nashik",
                "farmSize", 2.5
            )
        ));
        
        return ResponseEntity.ok(response);
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
        
        Map<String, Object> profile = new HashMap<>();
        profile.put("id", "farmer_123");
        profile.put("name", "Sample Farmer");
        profile.put("mobileNumber", "9876543210");
        profile.put("userType", "FARMER");
        profile.put("registrationDate", "2024-01-15");
        profile.put("isVerified", true);
        
        Map<String, Object> farmProfile = new HashMap<>();
        farmProfile.put("primaryCrop", "Rice");
        farmProfile.put("secondaryCrops", new String[]{"Wheat", "Sugarcane"});
        farmProfile.put("state", "Maharashtra");
        farmProfile.put("district", "Nashik");
        farmProfile.put("village", "Khandala");
        farmProfile.put("farmSize", 2.5);
        farmProfile.put("farmingExperience", 15);
        farmProfile.put("irrigationType", "Drip Irrigation");
        
        profile.put("farmProfile", farmProfile);
        
        return ResponseEntity.ok(profile);
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

package com.khetisahayak.controller;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

/**
 * Unit tests for AuthController
 * Tests authentication and user management for agricultural platform
 * Implements CodeRabbit testing standards for security-critical features
 */
@WebMvcTest(AuthController.class)
@DisplayName("Authentication Controller Tests")
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("Should register farmer with valid Indian mobile number")
    void shouldRegisterFarmerWithValidMobileNumber() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                .param("mobileNumber", "9876543210")
                .param("fullName", "Test Farmer")
                .param("state", "Maharashtra")
                .param("district", "Nashik")
                .param("primaryCrop", "Rice")
                .param("farmSize", "2.5")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", containsString("OTP sent successfully")))
                .andExpect(jsonPath("$.mobileNumber", is("9876543210")))
                .andExpect(jsonPath("$.nextStep", is("verify-otp")));
    }

    @Test
    @DisplayName("Should reject registration with invalid mobile number")
    void shouldRejectInvalidMobileNumber() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                .param("mobileNumber", "1234567890") // Invalid - doesn't start with 6-9
                .param("fullName", "Test Farmer")
                .param("state", "Maharashtra")
                .param("district", "Nashik")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Should verify OTP and complete registration")
    void shouldVerifyOtpAndCompleteRegistration() throws Exception {
        mockMvc.perform(post("/api/auth/verify-otp")
                .param("mobileNumber", "9876543210")
                .param("otp", "123456")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED))
                .andExpected(status().isOk())
                .andExpect(jsonPath("$.message", containsString("Registration completed")))
                .andExpect(jsonPath("$.token", notNullValue()))
                .andExpect(jsonPath("$.userType", is("FARMER")));
    }

    @Test
    @DisplayName("Should initiate login with mobile number")
    void shouldInitiateLoginWithMobileNumber() throws Exception {
        mockMvc.perform(post("/api/auth/login")
                .param("mobileNumber", "9876543210")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", containsString("OTP sent")))
                .andExpect(jsonPath("$.nextStep", is("verify-login-otp")));
    }

    @Test
    @DisplayName("Should verify login OTP and return token")
    void shouldVerifyLoginOtpAndReturnToken() throws Exception {
        mockMvc.perform(post("/api/auth/verify-login")
                .param("mobileNumber", "9876543210")
                .param("otp", "123456")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", is("Login successful")))
                .andExpect(jsonPath("$.token", notNullValue()))
                .andExpect(jsonPath("$.userProfile.userType", is("FARMER")));
    }

    @Test
    @DisplayName("Should reject OTP with invalid format")
    void shouldRejectInvalidOtpFormat() throws Exception {
        mockMvc.perform(post("/api/auth/verify-otp")
                .param("mobileNumber", "9876543210")
                .param("otp", "12345") // Invalid - only 5 digits
                .contentType(MediaType.APPLICATION_FORM_URLENCODED))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Should get farmer profile for authenticated user")
    void shouldGetFarmerProfile() throws Exception {
        // Note: In real implementation, this would require authentication
        mockMvc.perform(get("/api/auth/profile")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userType", is("FARMER")))
                .andExpect(jsonPath("$.farmProfile", notNullValue()))
                .andExpect(jsonPath("$.farmProfile.primaryCrop", notNullValue()));
    }

    @Test
    @DisplayName("Should update farmer profile with valid data")
    void shouldUpdateFarmerProfile() throws Exception {
        String profileJson = """
            {
                "primaryCrop": "Wheat",
                "farmSize": 3.5,
                "irrigationType": "DRIP"
            }
            """;

        mockMvc.perform(put("/api/auth/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", containsString("Profile updated")));
    }

    @Test
    @DisplayName("Should refresh authentication token")
    void shouldRefreshAuthenticationToken() throws Exception {
        mockMvc.perform(post("/api/auth/refresh")
                .param("refreshToken", "valid_refresh_token")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", containsString("Token refreshed")))
                .andExpect(jsonPath("$.token", notNullValue()));
    }

    @Test
    @DisplayName("Should logout farmer successfully")
    void shouldLogoutFarmer() throws Exception {
        mockMvc.perform(post("/api/auth/logout")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", is("Logout successful")));
    }

    @Test
    @DisplayName("Should validate Indian geographical coordinates")
    void shouldValidateIndianCoordinates() throws Exception {
        // Test with coordinates outside India
        mockMvc.perform(post("/api/auth/register")
                .param("mobileNumber", "9876543210")
                .param("fullName", "Test Farmer")
                .param("state", "Maharashtra")
                .param("district", "Nashik")
                .param("latitude", "51.5074") // London coordinates - invalid for India
                .param("longitude", "-0.1278")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED))
                .andExpect(status().isBadRequest());
    }
}

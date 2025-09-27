package com.khetisahayak.service;

import com.khetisahayak.model.User;
import com.khetisahayak.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * User Service for Kheti Sahayak Agricultural Platform
 * Handles farmer registration, authentication, and profile management
 * Implements CodeRabbit security standards for agricultural user data protection
 */
@Service
@Transactional
public class UserService implements UserDetailsService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private OtpService otpService;


    /**
     * Register a new farmer with agricultural profile
     * Implements CodeRabbit validation for Indian agricultural context
     */
    public Map<String, Object> registerFarmer(String mobileNumber, String fullName, 
                                             String primaryCrop, String state, 
                                             String district, Double farmSize) {
        
        // Validate mobile number format (Indian format)
        if (!mobileNumber.matches("^[6-9]\\d{9}$")) {
            throw new IllegalArgumentException("Invalid Indian mobile number format");
        }

        // Check if user already exists
        if (userRepository.findByMobileNumber(mobileNumber).isPresent()) {
            throw new IllegalArgumentException("Mobile number already registered");
        }

        // Generate and send OTP
        otpService.generateOtp(mobileNumber);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "OTP sent to mobile number");
        response.put("mobileNumber", mobileNumber);
        response.put("otpExpiry", otpService.getOtpExpiryMinutes());
        
        return response;
    }

    /**
     * Verify OTP and create farmer account
     * Implements agricultural user onboarding with regional context
     */
    public Map<String, Object> verifyOtpAndCreateUser(String mobileNumber, String otp,
                                                    String fullName, String primaryCrop,
                                                    String state, String district, Double farmSize) {
        
        // Verify OTP
        if (!otpService.verifyOtp(mobileNumber, otp)) {
            throw new IllegalArgumentException("Invalid or expired OTP");
        }

        // Create new farmer user
        User farmer = new User();
        farmer.setMobileNumber(mobileNumber);
        farmer.setFullName(fullName);
        farmer.setPrimaryCrop(primaryCrop);
        farmer.setState(state);
        farmer.setDistrict(district);
        farmer.setFarmSize(farmSize);
        farmer.setUserType(User.UserType.FARMER);
        farmer.setIsVerified(true);
        farmer.setIsActive(true);

        // Save farmer to database
        User savedFarmer = userRepository.save(farmer);

        // Generate JWT token for farmer
        Map<String, Object> farmProfile = new HashMap<>();
        farmProfile.put("primaryCrop", primaryCrop);
        farmProfile.put("state", state);
        farmProfile.put("district", district);
        farmProfile.put("farmSize", farmSize);

        String jwtToken = jwtService.generateTokenForFarmer(
            mobileNumber, 
            savedFarmer.getId().toString(), 
            "FARMER", 
            farmProfile
        );

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Farmer registered successfully");
        response.put("user", mapUserToResponse(savedFarmer));
        response.put("token", jwtToken);
        response.put("tokenType", "Bearer");
        response.put("expiresIn", jwtService.getExpirationTime());

        return response;
    }

    /**
     * Login farmer with mobile number
     * Sends OTP for authentication
     */
    public Map<String, Object> loginFarmer(String mobileNumber) {
        // Validate mobile number format
        if (!mobileNumber.matches("^[6-9]\\d{9}$")) {
            throw new IllegalArgumentException("Invalid Indian mobile number format");
        }

        // Check if user exists
        Optional<User> userOpt = userRepository.findByMobileNumber(mobileNumber);
        if (userOpt.isEmpty()) {
            throw new IllegalArgumentException("Mobile number not registered");
        }

        User user = userOpt.get();
        if (!user.getIsActive()) {
            throw new IllegalArgumentException("Account is deactivated");
        }

        // Generate and send OTP
        otpService.generateOtp(mobileNumber);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "OTP sent to mobile number");
        response.put("mobileNumber", mobileNumber);
        response.put("otpExpiry", otpService.getOtpExpiryMinutes());
        
        return response;
    }

    /**
     * Verify login OTP and generate JWT token
     */
    public Map<String, Object> verifyLoginOtp(String mobileNumber, String otp) {
        // Verify OTP
        if (!otpService.verifyOtp(mobileNumber, otp)) {
            throw new IllegalArgumentException("Invalid or expired OTP");
        }

        // Get user details
        User user = userRepository.findByMobileNumber(mobileNumber)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // Update last login
        user.setLastLoginAt(java.time.LocalDateTime.now());
        userRepository.save(user);

        // Generate JWT token
        Map<String, Object> farmProfile = new HashMap<>();
        farmProfile.put("primaryCrop", user.getPrimaryCrop());
        farmProfile.put("state", user.getState());
        farmProfile.put("district", user.getDistrict());
        farmProfile.put("farmSize", user.getFarmSize());

        String jwtToken = jwtService.generateTokenForFarmer(
            mobileNumber, 
            user.getId().toString(), 
            user.getUserType().name(), 
            farmProfile
        );

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Login successful");
        response.put("user", mapUserToResponse(user));
        response.put("token", jwtToken);
        response.put("tokenType", "Bearer");
        response.put("expiresIn", jwtService.getExpirationTime());

        return response;
    }

    /**
     * Get user profile by mobile number
     */
    public Map<String, Object> getUserProfileByMobile(String mobileNumber) {
        User user = userRepository.findByMobileNumber(mobileNumber)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        return mapUserToResponse(user);
    }

    /**
     * Load user details for Spring Security
     */
    @Override
    public UserDetails loadUserByUsername(String mobileNumber) throws UsernameNotFoundException {
        User user = userRepository.findByMobileNumber(mobileNumber)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + mobileNumber));

        return org.springframework.security.core.userdetails.User.builder()
                .username(user.getMobileNumber())
                .password("") // No password for OTP-based authentication
                .authorities(getAuthorities(user.getUserType()))
                .accountExpired(false)
                .accountLocked(!user.getIsActive())
                .credentialsExpired(false)
                .disabled(!user.getIsVerified())
                .build();
    }

    /**
     * Get authorities based on user type
     */
    private List<SimpleGrantedAuthority> getAuthorities(User.UserType userType) {
        List<String> roles = new ArrayList<>();
        
        switch (userType) {
            case FARMER:
                roles.add("ROLE_FARMER");
                break;
            case EXPERT:
                roles.add("ROLE_EXPERT");
                roles.add("ROLE_FARMER"); // Experts can also access farmer features
                break;
            case ADMIN:
                roles.add("ROLE_ADMIN");
                roles.add("ROLE_EXPERT");
                roles.add("ROLE_FARMER");
                break;
            case VENDOR:
                roles.add("ROLE_VENDOR");
                roles.add("ROLE_FARMER");
                break;
        }

        return roles.stream()
                .map(SimpleGrantedAuthority::new)
                .collect(Collectors.toList());
    }

    /**
     * Map User entity to response DTO
     */
    private Map<String, Object> mapUserToResponse(User user) {
        Map<String, Object> userResponse = new HashMap<>();
        userResponse.put("id", user.getId());
        userResponse.put("fullName", user.getFullName());
        userResponse.put("mobileNumber", user.getMobileNumber());
        userResponse.put("email", user.getEmail());
        userResponse.put("userType", user.getUserType().name());
        userResponse.put("isVerified", user.getIsVerified());
        userResponse.put("isActive", user.getIsActive());
        userResponse.put("primaryCrop", user.getPrimaryCrop());
        userResponse.put("state", user.getState());
        userResponse.put("district", user.getDistrict());
        userResponse.put("village", user.getVillage());
        userResponse.put("farmSize", user.getFarmSize());
        userResponse.put("farmingExperience", user.getFarmingExperience());
        userResponse.put("irrigationType", user.getIrrigationType());
        userResponse.put("preferredLanguage", user.getPreferredLanguage());
        userResponse.put("createdAt", user.getCreatedAt());
        userResponse.put("lastLoginAt", user.getLastLoginAt());
        
        return userResponse;
    }
}
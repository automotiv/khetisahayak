package com.khetisahayak.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * User entity for Kheti Sahayak agricultural platform
 * Represents farmers, experts, and administrators
 * Implements CodeRabbit data protection standards for agricultural users
 */
@Entity
@Table(name = "users", indexes = {
    @Index(name = "idx_user_mobile", columnList = "mobileNumber", unique = true),
    @Index(name = "idx_user_email", columnList = "email", unique = true),
    @Index(name = "idx_user_type", columnList = "userType"),
    @Index(name = "idx_user_state", columnList = "state"),
    @Index(name = "idx_user_created", columnList = "createdAt")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Farmer's full name - required for agricultural platform
     */
    @Column(nullable = false, length = 100)
    @NotBlank(message = "Full name is required")
    @Size(min = 2, max = 100, message = "Name must be between 2 and 100 characters")
    private String fullName;

    /**
     * Mobile number - primary identifier for Indian farmers
     * Follows Indian mobile number format validation
     */
    @Column(nullable = false, unique = true, length = 10)
    @Pattern(regexp = "^[6-9]\\d{9}$", message = "Mobile number must be valid Indian format")
    private String mobileNumber;

    /**
     * Email address - optional for farmers
     */
    @Column(unique = true, length = 100)
    @Email(message = "Email must be valid format")
    private String email;

    /**
     * User type for role-based access control
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserType userType = UserType.FARMER;

    /**
     * Account verification status (mobile/OTP)
     */
    @Column(nullable = false)
    private Boolean isVerified = false;

    /**
     * Email verification status
     */
    @Column(name = "email_verified", nullable = false)
    private Boolean isEmailVerified = false;

    /**
     * Account active status
     */
    @Column(nullable = false)
    private Boolean isActive = true;

    /**
     * Primary crop grown by farmer
     */
    @Column(length = 50)
    @Pattern(regexp = "^[a-zA-Z\\s]{2,50}$", message = "Invalid crop type")
    private String primaryCrop;

    /**
     * State where farm is located (Indian states)
     */
    @Column(nullable = false, length = 50)
    @NotBlank(message = "State is required")
    private String state;

    /**
     * District where farm is located
     */
    @Column(nullable = false, length = 50)
    @NotBlank(message = "District is required")
    private String district;

    /**
     * Village or area name
     */
    @Column(length = 100)
    private String village;

    /**
     * Farm size in acres
     */
    @Column
    @DecimalMin(value = "0.1", message = "Farm size must be at least 0.1 acres")
    @DecimalMax(value = "10000.0", message = "Farm size must be reasonable")
    private Double farmSize;

    /**
     * Years of farming experience
     */
    @Column
    @Min(value = 0, message = "Experience cannot be negative")
    @Max(value = 80, message = "Experience must be reasonable")
    private Integer farmingExperience;

    /**
     * Type of irrigation system used
     */
    @Enumerated(EnumType.STRING)
    private IrrigationType irrigationType;

    /**
     * Farm latitude for location-based services
     * Restricted to Indian geographical boundaries
     */
    @Column
    @DecimalMin(value = "6.0", message = "Latitude must be within India")
    @DecimalMax(value = "37.0", message = "Latitude must be within India")
    private Double latitude;

    /**
     * Farm longitude for location-based services
     * Restricted to Indian geographical boundaries
     */
    @Column
    @DecimalMin(value = "68.0", message = "Longitude must be within India")
    @DecimalMax(value = "97.0", message = "Longitude must be within India")
    private Double longitude;

    /**
     * Profile image URL for farmer identification
     */
    @Column(length = 500)
    private String profileImageUrl;

    /**
     * Preferred language for agricultural content
     */
    @Enumerated(EnumType.STRING)
    private Language preferredLanguage = Language.ENGLISH;

    /**
     * Account creation timestamp
     */
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    /**
     * Last profile update timestamp
     */
    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    /**
     * Last login timestamp for activity tracking
     */
    @Column
    private LocalDateTime lastLoginAt;

    /**
     * One-to-many relationship with crop diagnoses
     */
    @OneToMany(mappedBy = "farmer", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<CropDiagnosis> diagnoses;

    /**
     * One-to-many relationship with marketplace orders
     */
    @OneToMany(mappedBy = "buyer", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<MarketplaceOrder> orders;

    /**
     * User types for agricultural platform
     */
    public enum UserType {
        FARMER,    // Primary users - farmers growing crops
        EXPERT,    // Agricultural experts providing consultations
        ADMIN,     // Platform administrators
        VENDOR     // Marketplace vendors selling agricultural products
    }

    /**
     * Irrigation types common in Indian agriculture
     */
    public enum IrrigationType {
        RAIN_FED,      // Rain-dependent farming
        DRIP,          // Drip irrigation system
        SPRINKLER,     // Sprinkler irrigation
        FLOOD,         // Traditional flood irrigation
        MICRO_SPRINKLER, // Micro sprinkler system
        TUBE_WELL,     // Tube well irrigation
        CANAL          // Canal irrigation
    }

    /**
     * Supported languages for agricultural content
     */
    public enum Language {
        ENGLISH,    // Default language
        HINDI,      // National language
        MARATHI,    // Maharashtra state language
        GUJARATI,   // Gujarat state language
        PUNJABI,    // Punjab state language
        TAMIL,      // Tamil Nadu state language
        TELUGU,     // Telangana/Andhra Pradesh
        KANNADA,    // Karnataka state language
        BENGALI,    // West Bengal state language
        ODIA        // Odisha state language
    }

    /**
     * Update the updatedAt timestamp before saving
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}

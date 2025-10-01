package com.khetisahayak.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;

/**
 * User Consent Model for Kheti Sahayak
 * Implements Privacy & Consent management as per Issue #255
 * Tracks user consent for ML data usage, chatbot interactions, and data sharing
 */
@Entity
@Table(name = "user_consents")
public class UserConsent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull(message = "User ID is required")
    @Column(name = "user_id", nullable = false)
    private Long userId;

    // ML Data Usage Consent
    @Column(name = "ml_data_usage_consent")
    private Boolean mlDataUsageConsent = false;

    @Column(name = "ml_data_usage_consent_date")
    private LocalDateTime mlDataUsageConsentDate;

    // Chatbot Interaction Consent
    @Column(name = "chatbot_consent")
    private Boolean chatbotConsent = false;

    @Column(name = "chatbot_consent_date")
    private LocalDateTime chatbotConsentDate;

    // Location Data Sharing
    @Column(name = "location_sharing_consent")
    private Boolean locationSharingConsent = false;

    @Column(name = "location_sharing_consent_date")
    private LocalDateTime locationSharingConsentDate;

    // Crop Image Sharing for ML Training
    @Column(name = "image_sharing_ml_consent")
    private Boolean imageSharingMlConsent = false;

    @Column(name = "image_sharing_ml_consent_date")
    private LocalDateTime imageSharingMlConsentDate;

    // Marketing Communications
    @Column(name = "marketing_consent")
    private Boolean marketingConsent = false;

    @Column(name = "marketing_consent_date")
    private LocalDateTime marketingConsentDate;

    // Data Analytics
    @Column(name = "analytics_consent")
    private Boolean analyticsConsent = false;

    @Column(name = "analytics_consent_date")
    private LocalDateTime analyticsConsentDate;

    // Third-party Data Sharing
    @Column(name = "third_party_sharing_consent")
    private Boolean thirdPartySharingConsent = false;

    @Column(name = "third_party_sharing_consent_date")
    private LocalDateTime thirdPartySharingConsentDate;

    // Consent version (for tracking consent policy changes)
    @NotBlank
    @Column(name = "consent_version", nullable = false, length = 20)
    private String consentVersion = "1.0";

    // IP address when consent was given (for audit)
    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    // User agent when consent was given
    @Column(name = "user_agent", length = 500)
    private String userAgent;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Constructors
    public UserConsent() {
    }

    public UserConsent(Long userId) {
        this.userId = userId;
    }

    // Lifecycle callbacks
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    
    public Boolean getMlDataUsageConsent() { return mlDataUsageConsent; }
    public void setMlDataUsageConsent(Boolean mlDataUsageConsent) {
        this.mlDataUsageConsent = mlDataUsageConsent;
        if (mlDataUsageConsent) {
            this.mlDataUsageConsentDate = LocalDateTime.now();
        }
    }
    
    public LocalDateTime getMlDataUsageConsentDate() { return mlDataUsageConsentDate; }
    
    public Boolean getChatbotConsent() { return chatbotConsent; }
    public void setChatbotConsent(Boolean chatbotConsent) {
        this.chatbotConsent = chatbotConsent;
        if (chatbotConsent) {
            this.chatbotConsentDate = LocalDateTime.now();
        }
    }
    
    public LocalDateTime getChatbotConsentDate() { return chatbotConsentDate; }
    
    public Boolean getLocationSharingConsent() { return locationSharingConsent; }
    public void setLocationSharingConsent(Boolean locationSharingConsent) {
        this.locationSharingConsent = locationSharingConsent;
        if (locationSharingConsent) {
            this.locationSharingConsentDate = LocalDateTime.now();
        }
    }
    
    public Boolean getImageSharingMlConsent() { return imageSharingMlConsent; }
    public void setImageSharingMlConsent(Boolean imageSharingMlConsent) {
        this.imageSharingMlConsent = imageSharingMlConsent;
        if (imageSharingMlConsent) {
            this.imageSharingMlConsentDate = LocalDateTime.now();
        }
    }
    
    public Boolean getMarketingConsent() { return marketingConsent; }
    public void setMarketingConsent(Boolean marketingConsent) {
        this.marketingConsent = marketingConsent;
        if (marketingConsent) {
            this.marketingConsentDate = LocalDateTime.now();
        }
    }
    
    public Boolean getAnalyticsConsent() { return analyticsConsent; }
    public void setAnalyticsConsent(Boolean analyticsConsent) {
        this.analyticsConsent = analyticsConsent;
        if (analyticsConsent) {
            this.analyticsConsentDate = LocalDateTime.now();
        }
    }
    
    public Boolean getThirdPartySharingConsent() { return thirdPartySharingConsent; }
    public void setThirdPartySharingConsent(Boolean thirdPartySharingConsent) {
        this.thirdPartySharingConsent = thirdPartySharingConsent;
        if (thirdPartySharingConsent) {
            this.thirdPartySharingConsentDate = LocalDateTime.now();
        }
    }
    
    public String getConsentVersion() { return consentVersion; }
    public void setConsentVersion(String consentVersion) { this.consentVersion = consentVersion; }
    
    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }
    
    public String getUserAgent() { return userAgent; }
    public void setUserAgent(String userAgent) { this.userAgent = userAgent; }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }

    // Helper methods
    public boolean hasGivenMlConsent() {
        return Boolean.TRUE.equals(mlDataUsageConsent) && Boolean.TRUE.equals(imageSharingMlConsent);
    }

    public boolean canUseForTraining() {
        return hasGivenMlConsent();
    }

    public boolean canTrackLocation() {
        return Boolean.TRUE.equals(locationSharingConsent);
    }

    public boolean canSendMarketing() {
        return Boolean.TRUE.equals(marketingConsent);
    }
}


package com.khetisahayak.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Crop Diagnosis entity for Kheti Sahayak agricultural platform
 * Stores crop health analysis results and expert recommendations
 * Implements agricultural data standards for Indian farming context
 */
@Entity
@Table(name = "crop_diagnoses", indexes = {
    @Index(name = "idx_diagnosis_farmer", columnList = "farmer_id"),
    @Index(name = "idx_diagnosis_crop_type", columnList = "cropType"),
    @Index(name = "idx_diagnosis_status", columnList = "status"),
    @Index(name = "idx_diagnosis_created", columnList = "createdAt"),
    @Index(name = "idx_diagnosis_confidence", columnList = "confidence"),
    @Index(name = "idx_diagnosis_location", columnList = "latitude, longitude")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CropDiagnosis {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Farmer who submitted the diagnosis request
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "farmer_id", nullable = false)
    private User farmer;

    /**
     * Type of crop being diagnosed
     */
    @Column(nullable = false, length = 50)
    @NotBlank(message = "Crop type is required")
    @Pattern(regexp = "^[a-zA-Z\\s]{2,50}$", message = "Invalid crop type")
    private String cropType;

    /**
     * Original uploaded image URL
     */
    @Column(nullable = false, length = 500)
    @NotBlank(message = "Image URL is required")
    private String imageUrl;

    /**
     * Processed/compressed image URL for mobile optimization
     */
    @Column(length = 500)
    private String processedImageUrl;

    /**
     * AI diagnosis result
     */
    @Column(length = 200)
    private String diagnosis;

    /**
     * Confidence score of AI diagnosis (0.0 to 1.0)
     */
    @Column
    @DecimalMin(value = "0.0", message = "Confidence must be between 0 and 1")
    @DecimalMax(value = "1.0", message = "Confidence must be between 0 and 1")
    private Double confidence;

    /**
     * Severity level of detected issue
     */
    @Enumerated(EnumType.STRING)
    private Severity severity;

    /**
     * Current status of diagnosis
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DiagnosisStatus status = DiagnosisStatus.SUBMITTED;

    /**
     * Symptoms described by farmer
     */
    @Column(length = 1000)
    @Size(max = 1000, message = "Symptoms description too long")
    private String symptoms;

    /**
     * Farm latitude where image was taken
     */
    @Column
    @DecimalMin(value = "6.0", message = "Latitude must be within India")
    @DecimalMax(value = "37.0", message = "Latitude must be within India")
    private Double latitude;

    /**
     * Farm longitude where image was taken
     */
    @Column
    @DecimalMin(value = "68.0", message = "Longitude must be within India")
    @DecimalMax(value = "97.0", message = "Longitude must be within India")
    private Double longitude;

    /**
     * Weather conditions at time of diagnosis
     */
    @Column(length = 200)
    private String weatherConditions;

    /**
     * AI-generated treatment recommendations
     */
    @Column(length = 2000)
    private String aiRecommendations;

    /**
     * Expert who reviewed the diagnosis (if applicable)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "expert_id")
    private User expert;

    /**
     * Expert's professional review and recommendations
     */
    @Column(length = 2000)
    private String expertReview;

    /**
     * Expert's confidence in their diagnosis
     */
    @Column
    @DecimalMin(value = "0.0")
    @DecimalMax(value = "1.0")
    private Double expertConfidence;

    /**
     * Estimated cost of recommended treatment
     */
    @Column
    @DecimalMin(value = "0.0", message = "Treatment cost cannot be negative")
    private Double estimatedTreatmentCost;

    /**
     * Currency for treatment cost (INR for Indian farmers)
     */
    @Column(length = 3)
    private String currency = "INR";

    /**
     * Follow-up required flag
     */
    @Column(nullable = false)
    private Boolean followUpRequired = false;

    /**
     * Follow-up date if required
     */
    @Column
    private LocalDateTime followUpDate;

    /**
     * Diagnosis submission timestamp
     */
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    /**
     * Last update timestamp
     */
    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    /**
     * Expert review completion timestamp
     */
    @Column
    private LocalDateTime expertReviewedAt;

    /**
     * One-to-many relationship with treatment steps
     */
    @OneToMany(mappedBy = "diagnosis", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<TreatmentStep> treatmentSteps;

    /**
     * Severity levels for crop health issues
     */
    public enum Severity {
        LOW,        // Minor issues, preventive measures
        MEDIUM,     // Moderate issues, treatment recommended
        HIGH,       // Serious issues, immediate action required
        CRITICAL    // Severe issues, crop loss risk
    }

    /**
     * Status of diagnosis processing
     */
    public enum DiagnosisStatus {
        SUBMITTED,      // Image uploaded, waiting for AI analysis
        PROCESSING,     // AI analysis in progress
        AI_COMPLETED,   // AI analysis completed
        EXPERT_REVIEW,  // Under expert review
        COMPLETED,      // Diagnosis and recommendations provided
        FOLLOW_UP       // Follow-up diagnosis required
    }

    /**
     * Update the updatedAt timestamp before saving
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Set expert review completion timestamp
     */
    public void markExpertReviewed() {
        this.expertReviewedAt = LocalDateTime.now();
        this.status = DiagnosisStatus.COMPLETED;
    }

    /**
     * Check if diagnosis needs expert attention
     */
    public boolean needsExpertReview() {
        return this.confidence != null && this.confidence < 0.8 ||
               this.severity == Severity.HIGH || this.severity == Severity.CRITICAL;
    }

    /**
     * Get human-readable confidence percentage
     */
    public String getConfidencePercentage() {
        if (confidence == null) return "N/A";
        return String.format("%.1f%%", confidence * 100);
    }

    /**
     * Get location string for display
     */
    public String getLocationString() {
        if (latitude == null || longitude == null) return "Location not provided";
        return String.format("%.4f, %.4f", latitude, longitude);
    }
}

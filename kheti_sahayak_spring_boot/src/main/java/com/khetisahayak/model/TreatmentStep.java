package com.khetisahayak.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Treatment Step entity for Kheti Sahayak agricultural platform
 * Stores detailed treatment recommendations for crop health issues
 * Provides step-by-step guidance for Indian farmers
 */
@Entity
@Table(name = "treatment_steps", indexes = {
    @Index(name = "idx_treatment_diagnosis", columnList = "diagnosis_id"),
    @Index(name = "idx_treatment_priority", columnList = "priority"),
    @Index(name = "idx_treatment_category", columnList = "category"),
    @Index(name = "idx_treatment_cost", columnList = "estimatedCost")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TreatmentStep {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Associated crop diagnosis
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "diagnosis_id", nullable = false)
    private CropDiagnosis diagnosis;

    /**
     * Step number in treatment sequence
     */
    @Column(nullable = false)
    @Min(value = 1, message = "Step number must be positive")
    private Integer stepNumber;

    /**
     * Treatment step title
     */
    @Column(nullable = false, length = 200)
    @NotBlank(message = "Treatment title is required")
    @Size(min = 5, max = 200, message = "Title must be between 5 and 200 characters")
    private String title;

    /**
     * Detailed description of treatment step
     */
    @Column(nullable = false, length = 2000)
    @NotBlank(message = "Treatment description is required")
    @Size(min = 10, max = 2000, message = "Description must be between 10 and 2000 characters")
    private String description;

    /**
     * Category of treatment step
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TreatmentCategory category;

    /**
     * Priority level of this treatment step
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Priority priority;

    /**
     * Estimated time to complete this step
     */
    @Column(length = 50)
    private String estimatedTime;

    /**
     * Required materials or inputs
     */
    @Column(length = 1000)
    private String requiredMaterials;

    /**
     * Estimated cost of treatment in INR
     */
    @Column(precision = 8, scale = 2)
    @DecimalMin(value = "0.0", message = "Cost cannot be negative")
    private BigDecimal estimatedCost;

    /**
     * Currency for cost (INR for Indian farmers)
     */
    @Column(length = 3)
    private String currency = "INR";

    /**
     * Best time to apply treatment (e.g., "Early morning", "After sunset")
     */
    @Column(length = 100)
    private String bestTimeToApply;

    /**
     * Weather conditions required for treatment
     */
    @Column(length = 200)
    private String weatherRequirements;

    /**
     * Safety precautions for farmers
     */
    @Column(length = 1000)
    private String safetyPrecautions;

    /**
     * Expected results and timeline
     */
    @Column(length = 500)
    private String expectedResults;

    /**
     * Alternative treatment options
     */
    @Column(length = 1000)
    private String alternatives;

    /**
     * Organic treatment option flag
     */
    @Column(nullable = false)
    private Boolean isOrganic = false;

    /**
     * Suitable for small farmers flag
     */
    @Column(nullable = false)
    private Boolean suitableForSmallFarmers = true;

    /**
     * Step creation timestamp
     */
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    /**
     * Last update timestamp
     */
    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    /**
     * Treatment categories for agricultural interventions
     */
    public enum TreatmentCategory {
        CHEMICAL_TREATMENT,     // Chemical pesticides/fungicides
        ORGANIC_TREATMENT,      // Organic/natural treatments
        CULTURAL_PRACTICE,      // Farming practice changes
        IRRIGATION_MANAGEMENT,  // Water management
        FERTILIZER_APPLICATION, // Nutrient management
        PREVENTIVE_MEASURE,     // Prevention strategies
        MONITORING,             // Observation and tracking
        HARVESTING              // Harvest-related actions
    }

    /**
     * Priority levels for treatment steps
     */
    public enum Priority {
        URGENT,     // Immediate action required (within 24 hours)
        HIGH,       // Action needed within 2-3 days
        MEDIUM,     // Action needed within a week
        LOW         // Preventive or long-term measures
    }

    /**
     * Update the updatedAt timestamp before saving
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Get formatted cost with currency symbol
     */
    public String getFormattedCost() {
        if (estimatedCost == null) return "Cost not estimated";
        return String.format("₹%.2f", estimatedCost);
    }

    /**
     * Check if step is time-sensitive
     */
    public boolean isTimeSensitive() {
        return priority == Priority.URGENT || priority == Priority.HIGH;
    }

    /**
     * Check if step is suitable for organic farming
     */
    public boolean isOrganicFriendly() {
        return isOrganic || category == TreatmentCategory.ORGANIC_TREATMENT ||
               category == TreatmentCategory.CULTURAL_PRACTICE;
    }

    /**
     * Get priority display text
     */
    public String getPriorityText() {
        return switch (priority) {
            case URGENT -> "Immediate Action Required";
            case HIGH -> "Action Needed Soon";
            case MEDIUM -> "Moderate Priority";
            case LOW -> "When Convenient";
        };
    }

    /**
     * Get category display text
     */
    public String getCategoryText() {
        return switch (category) {
            case CHEMICAL_TREATMENT -> "Chemical Treatment";
            case ORGANIC_TREATMENT -> "Organic Treatment";
            case CULTURAL_PRACTICE -> "Farming Practice";
            case IRRIGATION_MANAGEMENT -> "Water Management";
            case FERTILIZER_APPLICATION -> "Fertilizer Application";
            case PREVENTIVE_MEASURE -> "Prevention";
            case MONITORING -> "Monitoring";
            case HARVESTING -> "Harvesting";
        };
    }
}

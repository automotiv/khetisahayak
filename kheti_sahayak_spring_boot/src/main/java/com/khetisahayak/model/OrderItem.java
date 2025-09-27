package com.khetisahayak.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Order Item entity for Kheti Sahayak marketplace
 * Represents individual agricultural products in an order
 * Optimized for Indian agricultural product specifications
 */
@Entity
@Table(name = "order_items", indexes = {
    @Index(name = "idx_item_order", columnList = "order_id"),
    @Index(name = "idx_item_product", columnList = "productName"),
    @Index(name = "idx_item_category", columnList = "productCategory"),
    @Index(name = "idx_item_total", columnList = "totalPrice")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Associated marketplace order
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private MarketplaceOrder order;

    /**
     * Agricultural product name
     */
    @Column(nullable = false, length = 200)
    @NotBlank(message = "Product name is required")
    @Size(min = 2, max = 200, message = "Product name must be between 2 and 200 characters")
    private String productName;

    /**
     * Product category for agricultural classification
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProductCategory productCategory;

    /**
     * Product variety or sub-type
     */
    @Column(length = 100)
    private String variety;

    /**
     * Quantity ordered
     */
    @Column(nullable = false)
    @NotNull(message = "Quantity is required")
    @DecimalMin(value = "0.01", message = "Quantity must be positive")
    private BigDecimal quantity;

    /**
     * Unit of measurement for agricultural products
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Unit unit;

    /**
     * Price per unit in INR
     */
    @Column(nullable = false, precision = 8, scale = 2)
    @NotNull(message = "Unit price is required")
    @DecimalMin(value = "0.01", message = "Unit price must be positive")
    private BigDecimal unitPrice;

    /**
     * Total price for this item (quantity × unitPrice)
     */
    @Column(nullable = false, precision = 10, scale = 2)
    @NotNull(message = "Total price is required")
    @DecimalMin(value = "0.01", message = "Total price must be positive")
    private BigDecimal totalPrice;

    /**
     * Currency (INR for Indian marketplace)
     */
    @Column(nullable = false, length = 3)
    private String currency = "INR";

    /**
     * Product quality grade
     */
    @Enumerated(EnumType.STRING)
    private QualityGrade qualityGrade;

    /**
     * Product origin (state/region)
     */
    @Column(length = 50)
    private String origin;

    /**
     * Harvest date for fresh produce
     */
    @Column
    private LocalDateTime harvestDate;

    /**
     * Expiry date for perishable products
     */
    @Column
    private LocalDateTime expiryDate;

    /**
     * Organic certification flag
     */
    @Column(nullable = false)
    private Boolean isOrganic = false;

    /**
     * Special handling instructions
     */
    @Column(length = 500)
    private String handlingInstructions;

    /**
     * Item creation timestamp
     */
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    /**
     * Agricultural product categories
     */
    public enum ProductCategory {
        SEEDS,              // Seeds and planting materials
        FERTILIZERS,        // Chemical and organic fertilizers
        PESTICIDES,         // Pest control products
        TOOLS,              // Farming tools and equipment
        FRESH_PRODUCE,      // Fresh fruits and vegetables
        GRAINS,             // Cereals and pulses
        IRRIGATION,         // Irrigation equipment
        MACHINERY,          // Agricultural machinery
        LIVESTOCK,          // Animals and poultry
        DAIRY,              // Dairy products
        ORGANIC_INPUTS      // Organic farming inputs
    }

    /**
     * Units of measurement for agricultural products
     */
    public enum Unit {
        KG,         // Kilograms
        QUINTAL,    // 100 kg (common in Indian agriculture)
        TON,        // 1000 kg
        LITER,      // Liters for liquids
        PIECE,      // Individual items
        PACKET,     // Packaged items
        BAG,        // Bags (usually 50kg)
        ACRE,       // Per acre (for services)
        SQUARE_METER, // Square meters
        BUNDLE      // Bundles (for fodder, etc.)
    }

    /**
     * Quality grades for agricultural products
     */
    public enum QualityGrade {
        PREMIUM,    // Highest quality, premium pricing
        GRADE_A,    // High quality, standard pricing
        GRADE_B,    // Good quality, moderate pricing
        GRADE_C,    // Basic quality, lower pricing
        UNGRADED    // Quality not assessed
    }

    /**
     * Calculate total price based on quantity and unit price
     */
    @PrePersist
    @PreUpdate
    public void calculateTotalPrice() {
        if (quantity != null && unitPrice != null) {
            this.totalPrice = quantity.multiply(unitPrice);
        }
    }

    /**
     * Check if product is perishable
     */
    public boolean isPerishable() {
        return productCategory == ProductCategory.FRESH_PRODUCE ||
               productCategory == ProductCategory.DAIRY;
    }

    /**
     * Get formatted unit price with currency
     */
    public String getFormattedUnitPrice() {
        return String.format("₹%.2f per %s", unitPrice, unit.toString().toLowerCase());
    }

    /**
     * Get formatted total price with currency
     */
    public String getFormattedTotalPrice() {
        return String.format("₹%.2f", totalPrice);
    }

    /**
     * Get quantity with unit display
     */
    public String getQuantityWithUnit() {
        return String.format("%.2f %s", quantity, unit.toString().toLowerCase());
    }

    /**
     * Check if item is eligible for organic premium
     */
    public boolean isOrganicPremium() {
        return isOrganic && (qualityGrade == QualityGrade.PREMIUM || 
                           qualityGrade == QualityGrade.GRADE_A);
    }
}

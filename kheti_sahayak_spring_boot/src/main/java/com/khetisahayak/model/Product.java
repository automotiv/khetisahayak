package com.khetisahayak.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Product entity for Kheti Sahayak agricultural marketplace
 * Represents agricultural products available for buying/selling
 * Implements CodeRabbit data modeling standards for agricultural commerce
 */
@Entity
@Table(name = "products", indexes = {
    @Index(name = "idx_product_seller", columnList = "seller_id"),
    @Index(name = "idx_product_category", columnList = "category"),
    @Index(name = "idx_product_status", columnList = "status"),
    @Index(name = "idx_product_location", columnList = "state, district"),
    @Index(name = "idx_product_created", columnList = "created_at"),
    @Index(name = "idx_product_price", columnList = "price_per_unit")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Seller (farmer or vendor) who listed the product
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "seller_id", nullable = false)
    private User seller;

    /**
     * Product name and description
     */
    @Column(nullable = false, length = 200)
    @NotBlank(message = "Product name is required")
    @Size(min = 3, max = 200, message = "Product name must be between 3 and 200 characters")
    private String name;

    @Column(columnDefinition = "TEXT")
    @Size(max = 2000, message = "Description must be less than 2000 characters")
    private String description;

    /**
     * Product category for agricultural products
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProductCategory category;

    /**
     * Product subcategory for detailed classification
     */
    @Column(length = 100)
    @Size(max = 100, message = "Subcategory must be less than 100 characters")
    private String subcategory;

    /**
     * Product pricing information
     */
    @Column(nullable = false, precision = 10, scale = 2)
    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.01", message = "Price must be greater than 0")
    private BigDecimal pricePerUnit;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UnitOfMeasurement unitOfMeasurement = UnitOfMeasurement.KG;

    /**
     * Stock and availability
     */
    @Column(nullable = false)
    @NotNull(message = "Quantity is required")
    @Min(value = 0, message = "Quantity cannot be negative")
    private Integer availableQuantity;

    @Column(nullable = false)
    @Min(value = 1, message = "Minimum order quantity must be at least 1")
    private Integer minimumOrderQuantity = 1;

    /**
     * Product quality and certification
     */
    @Enumerated(EnumType.STRING)
    private QualityGrade qualityGrade;

    @Column(nullable = false)
    private Boolean isOrganicCertified = false;

    @Column(length = 100)
    private String certificationBody;

    /**
     * Agricultural product specific details
     */
    @Column
    private LocalDate harvestDate;

    @Column
    private LocalDate expiryDate;

    @Column(length = 50)
    @Size(max = 50, message = "Variety name must be less than 50 characters")
    private String variety;

    @Column(length = 50)
    @Size(max = 50, message = "Season must be less than 50 characters")
    private String season;

    /**
     * Location information
     */
    @Column(nullable = false, length = 50)
    @NotBlank(message = "State is required")
    private String state;

    @Column(nullable = false, length = 50)
    @NotBlank(message = "District is required")
    private String district;

    @Column(length = 100)
    private String village;

    @Column(length = 6)
    @Pattern(regexp = "^[1-9][0-9]{5}$", message = "Invalid PIN code")
    private String pincode;

    /**
     * Product images
     */
    @ElementCollection
    @CollectionTable(name = "product_images", joinColumns = @JoinColumn(name = "product_id"))
    @Column(name = "image_url", length = 500)
    private List<String> imageUrls;

    /**
     * Product status and availability
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProductStatus status = ProductStatus.ACTIVE;

    @Column
    private Boolean isFeatured = false;

    @Column
    private Boolean isNegotiable = false;

    /**
     * Seller preferences
     */
    @Column
    private Boolean acceptsOnlinePayment = true;

    @Column
    private Boolean allowsHomeDelivery = false;

    @Column(precision = 8, scale = 2)
    private BigDecimal deliveryChargePerKm;

    @Column
    private Integer maxDeliveryDistanceKm;

    /**
     * Rating and reviews
     */
    @Column(precision = 3, scale = 2)
    @DecimalMin(value = "0.0")
    @DecimalMax(value = "5.0")
    private BigDecimal averageRating;

    @Column
    @Min(0)
    private Integer totalReviews = 0;

    @Column
    @Min(0)
    private Integer totalSales = 0;

    /**
     * Timestamps
     */
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column
    private LocalDateTime lastActiveAt;

    /**
     * Product categories for agricultural marketplace
     */
    public enum ProductCategory {
        CROPS("Crops & Grains"),
        VEGETABLES("Vegetables"),
        FRUITS("Fruits"),
        SPICES("Spices & Herbs"),
        PULSES("Pulses & Legumes"),
        DAIRY("Dairy Products"),
        POULTRY("Poultry & Eggs"),
        LIVESTOCK("Livestock"),
        SEEDS("Seeds & Seedlings"),
        FERTILIZERS("Fertilizers"),
        PESTICIDES("Pesticides & Chemicals"),
        TOOLS("Farm Tools & Equipment"),
        IRRIGATION("Irrigation Equipment"),
        ORGANIC_INPUTS("Organic Inputs"),
        PROCESSED_FOOD("Processed Food Products");

        private final String displayName;

        ProductCategory(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }

    /**
     * Units of measurement for agricultural products
     */
    public enum UnitOfMeasurement {
        KG("Kilogram"),
        QUINTAL("Quintal"),
        TON("Ton"),
        PIECE("Piece"),
        BOX("Box"),
        BAG("Bag"),
        LITER("Liter"),
        DOZEN("Dozen"),
        BUNDLE("Bundle"),
        PACKET("Packet");

        private final String displayName;

        UnitOfMeasurement(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }

    /**
     * Quality grades for agricultural products
     */
    public enum QualityGrade {
        PREMIUM("Premium Grade"),
        FIRST("First Grade"),
        SECOND("Second Grade"),
        STANDARD("Standard Grade"),
        EXPORT_QUALITY("Export Quality");

        private final String displayName;

        QualityGrade(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }

    /**
     * Product status for marketplace management
     */
    public enum ProductStatus {
        ACTIVE("Active"),
        INACTIVE("Inactive"),
        OUT_OF_STOCK("Out of Stock"),
        PENDING_APPROVAL("Pending Approval"),
        REJECTED("Rejected"),
        EXPIRED("Expired");

        private final String displayName;

        ProductStatus(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }

    /**
     * Update the updatedAt timestamp before saving
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Helper method to check if product is available for purchase
     */
    public boolean isAvailableForPurchase() {
        return status == ProductStatus.ACTIVE && 
               availableQuantity > 0 && 
               (expiryDate == null || expiryDate.isAfter(LocalDate.now()));
    }

    /**
     * Helper method to check if delivery is available
     */
    public boolean isDeliveryAvailable() {
        return allowsHomeDelivery && deliveryChargePerKm != null;
    }

    /**
     * Helper method to calculate delivery charge for distance
     */
    public BigDecimal calculateDeliveryCharge(double distanceKm) {
        if (!isDeliveryAvailable()) {
            return BigDecimal.ZERO;
        }
        
        if (maxDeliveryDistanceKm != null && distanceKm > maxDeliveryDistanceKm) {
            throw new IllegalArgumentException("Delivery not available for this distance");
        }
        
        return deliveryChargePerKm.multiply(BigDecimal.valueOf(distanceKm));
    }

    /**
     * Helper method to update stock after sale
     */
    public void updateStockAfterSale(int quantitySold) {
        if (quantitySold > availableQuantity) {
            throw new IllegalArgumentException("Cannot sell more than available quantity");
        }
        
        this.availableQuantity -= quantitySold;
        this.totalSales += quantitySold;
        
        if (this.availableQuantity == 0) {
            this.status = ProductStatus.OUT_OF_STOCK;
        }
    }
}

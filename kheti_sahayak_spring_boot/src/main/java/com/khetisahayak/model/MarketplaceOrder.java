package com.khetisahayak.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Marketplace Order entity for Kheti Sahayak agricultural platform
 * Handles agricultural product orders and transactions
 * Implements secure order management for farmer-to-farmer commerce
 */
@Entity
@Table(name = "marketplace_orders", indexes = {
    @Index(name = "idx_order_buyer", columnList = "buyer_id"),
    @Index(name = "idx_order_seller", columnList = "seller_id"),
    @Index(name = "idx_order_status", columnList = "orderStatus"),
    @Index(name = "idx_order_created", columnList = "createdAt"),
    @Index(name = "idx_order_total", columnList = "totalAmount"),
    @Index(name = "idx_order_payment", columnList = "paymentStatus")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MarketplaceOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Unique order number for tracking
     */
    @Column(nullable = false, unique = true, length = 20)
    @NotBlank(message = "Order number is required")
    private String orderNumber;

    /**
     * Farmer who placed the order
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "buyer_id", nullable = false)
    private User buyer;

    /**
     * Farmer/vendor who is selling the product
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "seller_id", nullable = false)
    private User seller;

    /**
     * Total order amount in INR
     */
    @Column(nullable = false, precision = 10, scale = 2)
    @NotNull(message = "Total amount is required")
    @DecimalMin(value = "0.01", message = "Order amount must be positive")
    private BigDecimal totalAmount;

    /**
     * Currency (INR for Indian farmers)
     */
    @Column(nullable = false, length = 3)
    private String currency = "INR";

    /**
     * Current order status
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus orderStatus = OrderStatus.PENDING;

    /**
     * Payment status
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaymentStatus paymentStatus = PaymentStatus.PENDING;

    /**
     * Payment method used
     */
    @Enumerated(EnumType.STRING)
    private PaymentMethod paymentMethod;

    /**
     * Payment transaction ID
     */
    @Column(length = 100)
    private String paymentTransactionId;

    /**
     * Delivery address for agricultural products
     */
    @Column(nullable = false, length = 500)
    @NotBlank(message = "Delivery address is required")
    private String deliveryAddress;

    /**
     * Delivery state
     */
    @Column(nullable = false, length = 50)
    @NotBlank(message = "Delivery state is required")
    private String deliveryState;

    /**
     * Delivery district
     */
    @Column(nullable = false, length = 50)
    @NotBlank(message = "Delivery district is required")
    private String deliveryDistrict;

    /**
     * Delivery PIN code
     */
    @Column(nullable = false, length = 6)
    @Pattern(regexp = "^\\d{6}$", message = "PIN code must be 6 digits")
    private String deliveryPinCode;

    /**
     * Buyer's contact number for delivery
     */
    @Column(nullable = false, length = 10)
    @Pattern(regexp = "^[6-9]\\d{9}$", message = "Contact number must be valid Indian format")
    private String contactNumber;

    /**
     * Expected delivery date
     */
    @Column
    private LocalDateTime expectedDeliveryDate;

    /**
     * Actual delivery date
     */
    @Column
    private LocalDateTime actualDeliveryDate;

    /**
     * Order notes from buyer
     */
    @Column(length = 1000)
    @Size(max = 1000, message = "Order notes too long")
    private String orderNotes;

    /**
     * Seller notes and instructions
     */
    @Column(length = 1000)
    @Size(max = 1000, message = "Seller notes too long")
    private String sellerNotes;

    /**
     * Order cancellation reason
     */
    @Column(length = 500)
    private String cancellationReason;

    /**
     * Order creation timestamp
     */
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    /**
     * Last update timestamp
     */
    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    /**
     * Order confirmation timestamp
     */
    @Column
    private LocalDateTime confirmedAt;

    /**
     * Order cancellation timestamp
     */
    @Column
    private LocalDateTime cancelledAt;

    /**
     * One-to-many relationship with order items
     */
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<OrderItem> orderItems;

    /**
     * Order status for agricultural marketplace
     */
    public enum OrderStatus {
        PENDING,        // Order placed, awaiting seller confirmation
        CONFIRMED,      // Seller confirmed order
        PROCESSING,     // Order being prepared
        SHIPPED,        // Order shipped/dispatched
        DELIVERED,      // Order delivered to farmer
        CANCELLED,      // Order cancelled
        RETURNED        // Order returned
    }

    /**
     * Payment status tracking
     */
    public enum PaymentStatus {
        PENDING,        // Payment not initiated
        PROCESSING,     // Payment in progress
        COMPLETED,      // Payment successful
        FAILED,         // Payment failed
        REFUNDED        // Payment refunded
    }

    /**
     * Payment methods for Indian farmers
     */
    public enum PaymentMethod {
        UPI,            // Unified Payments Interface
        NET_BANKING,    // Internet banking
        DEBIT_CARD,     // Debit card payment
        CREDIT_CARD,    // Credit card payment
        COD,            // Cash on delivery
        WALLET          // Digital wallet (Paytm, PhonePe, etc.)
    }

    /**
     * Update the updatedAt timestamp before saving
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Mark order as confirmed by seller
     */
    public void confirmOrder() {
        this.orderStatus = OrderStatus.CONFIRMED;
        this.confirmedAt = LocalDateTime.now();
    }

    /**
     * Cancel order with reason
     */
    public void cancelOrder(String reason) {
        this.orderStatus = OrderStatus.CANCELLED;
        this.cancellationReason = reason;
        this.cancelledAt = LocalDateTime.now();
    }

    /**
     * Mark order as delivered
     */
    public void markDelivered() {
        this.orderStatus = OrderStatus.DELIVERED;
        this.actualDeliveryDate = LocalDateTime.now();
    }

    /**
     * Check if order can be cancelled
     */
    public boolean canBeCancelled() {
        return this.orderStatus == OrderStatus.PENDING || 
               this.orderStatus == OrderStatus.CONFIRMED;
    }

    /**
     * Calculate order processing time in hours
     */
    public long getProcessingTimeHours() {
        if (confirmedAt == null) return 0;
        return java.time.Duration.between(createdAt, confirmedAt).toHours();
    }

    /**
     * Get formatted total amount with currency
     */
    public String getFormattedTotal() {
        return String.format("₹%.2f", totalAmount);
    }
}

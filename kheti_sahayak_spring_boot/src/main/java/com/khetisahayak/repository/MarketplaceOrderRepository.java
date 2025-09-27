package com.khetisahayak.repository;

import com.khetisahayak.model.MarketplaceOrder;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Marketplace Order Repository for Kheti Sahayak Agricultural Platform
 * Handles database operations for agricultural marketplace orders and transactions
 * Implements CodeRabbit data access patterns for agricultural commerce
 */
@Repository
public interface MarketplaceOrderRepository extends JpaRepository<MarketplaceOrder, Long> {

    /**
     * Find orders by buyer
     */
    List<MarketplaceOrder> findByBuyerId(Long buyerId);
    
    Page<MarketplaceOrder> findByBuyerId(Long buyerId, Pageable pageable);

    /**
     * Find orders by seller
     */
    List<MarketplaceOrder> findBySellerId(Long sellerId);
    
    Page<MarketplaceOrder> findBySellerId(Long sellerId, Pageable pageable);

    /**
     * Find orders by buyer and status
     */
    List<MarketplaceOrder> findByBuyerIdAndOrderStatus(Long buyerId, MarketplaceOrder.OrderStatus status);

    /**
     * Find orders by seller and status
     */
    List<MarketplaceOrder> findBySellerIdAndOrderStatus(Long sellerId, MarketplaceOrder.OrderStatus status);

    /**
     * Find orders by status
     */
    Page<MarketplaceOrder> findByOrderStatus(MarketplaceOrder.OrderStatus status, Pageable pageable);

    /**
     * Find orders by payment status
     */
    Page<MarketplaceOrder> findByPaymentStatus(MarketplaceOrder.PaymentStatus status, Pageable pageable);

    /**
     * Find orders by order number
     */
    Optional<MarketplaceOrder> findByOrderNumber(String orderNumber);

    /**
     * Check if order number exists
     */
    boolean existsByOrderNumber(String orderNumber);

    /**
     * Find orders by delivery location
     */
    Page<MarketplaceOrder> findByDeliveryStateAndDeliveryDistrict(
        String state, 
        String district, 
        Pageable pageable
    );

    /**
     * Find orders by delivery PIN code
     */
    List<MarketplaceOrder> findByDeliveryPinCode(String pinCode);

    /**
     * Find orders by payment method
     */
    Page<MarketplaceOrder> findByPaymentMethod(MarketplaceOrder.PaymentMethod method, Pageable pageable);

    /**
     * Find orders by total amount range
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.totalAmount BETWEEN :minAmount AND :maxAmount " +
           "ORDER BY mo.totalAmount DESC")
    Page<MarketplaceOrder> findByTotalAmountRange(
        @Param("minAmount") BigDecimal minAmount,
        @Param("maxAmount") BigDecimal maxAmount,
        Pageable pageable
    );

    /**
     * Find orders created between dates
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.createdAt BETWEEN :startDate AND :endDate " +
           "ORDER BY mo.createdAt DESC")
    Page<MarketplaceOrder> findOrdersByDateRange(
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate,
        Pageable pageable
    );

    /**
     * Find orders with pending delivery
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.orderStatus IN ('CONFIRMED', 'PROCESSING', 'SHIPPED') " +
           "AND mo.expectedDeliveryDate <= :deliveryDate")
    List<MarketplaceOrder> findOrdersPendingDelivery(@Param("deliveryDate") LocalDateTime deliveryDate);

    /**
     * Find overdue orders
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.expectedDeliveryDate < :currentDate " +
           "AND mo.orderStatus NOT IN ('DELIVERED', 'CANCELLED')")
    List<MarketplaceOrder> findOverdueOrders(@Param("currentDate") LocalDateTime currentDate);

    /**
     * Find orders requiring payment confirmation
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.paymentStatus = 'PENDING' " +
           "AND mo.createdAt < :cutoffDate")
    List<MarketplaceOrder> findOrdersRequiringPaymentConfirmation(@Param("cutoffDate") LocalDateTime cutoffDate);

    /**
     * Find orders by buyer and date range
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.buyerId = :buyerId " +
           "AND mo.createdAt BETWEEN :startDate AND :endDate ORDER BY mo.createdAt DESC")
    Page<MarketplaceOrder> findOrdersByBuyerAndDateRange(
        @Param("buyerId") Long buyerId,
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate,
        Pageable pageable
    );

    /**
     * Find orders by seller and date range
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.sellerId = :sellerId " +
           "AND mo.createdAt BETWEEN :startDate AND :endDate ORDER BY mo.createdAt DESC")
    Page<MarketplaceOrder> findOrdersBySellerAndDateRange(
        @Param("sellerId") Long sellerId,
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate,
        Pageable pageable
    );

    /**
     * Find cancelled orders
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.orderStatus = 'CANCELLED' " +
           "ORDER BY mo.cancelledAt DESC")
    Page<MarketplaceOrder> findCancelledOrders(Pageable pageable);

    /**
     * Find orders with payment transaction ID
     */
    List<MarketplaceOrder> findByPaymentTransactionId(String transactionId);

    /**
     * Get order statistics by status
     */
    @Query("SELECT mo.orderStatus, COUNT(mo) FROM MarketplaceOrder mo GROUP BY mo.orderStatus")
    List<Object[]> getOrderStatsByStatus();

    /**
     * Get order statistics by payment status
     */
    @Query("SELECT mo.paymentStatus, COUNT(mo) FROM MarketplaceOrder mo GROUP BY mo.paymentStatus")
    List<Object[]> getOrderStatsByPaymentStatus();

    /**
     * Get order statistics by payment method
     */
    @Query("SELECT mo.paymentMethod, COUNT(mo), SUM(mo.totalAmount) FROM MarketplaceOrder mo " +
           "WHERE mo.paymentMethod IS NOT NULL GROUP BY mo.paymentMethod")
    List<Object[]> getOrderStatsByPaymentMethod();

    /**
     * Get order statistics by delivery state
     */
    @Query("SELECT mo.deliveryState, COUNT(mo), SUM(mo.totalAmount) FROM MarketplaceOrder mo " +
           "GROUP BY mo.deliveryState")
    List<Object[]> getOrderStatsByDeliveryState();

    /**
     * Get monthly order statistics
     */
    @Query("SELECT YEAR(mo.createdAt), MONTH(mo.createdAt), COUNT(mo), SUM(mo.totalAmount), AVG(mo.totalAmount) " +
           "FROM MarketplaceOrder mo GROUP BY YEAR(mo.createdAt), MONTH(mo.createdAt) " +
           "ORDER BY YEAR(mo.createdAt) DESC, MONTH(mo.createdAt) DESC")
    List<Object[]> getMonthlyOrderStats();

    /**
     * Get top buyers by order count
     */
    @Query("SELECT mo.buyerId, COUNT(mo), SUM(mo.totalAmount) FROM MarketplaceOrder mo " +
           "GROUP BY mo.buyerId ORDER BY COUNT(mo) DESC")
    Page<Object[]> getTopBuyers(Pageable pageable);

    /**
     * Get top sellers by order count
     */
    @Query("SELECT mo.sellerId, COUNT(mo), SUM(mo.totalAmount) FROM MarketplaceOrder mo " +
           "GROUP BY mo.sellerId ORDER BY COUNT(mo) DESC")
    Page<Object[]> getTopSellers(Pageable pageable);

    /**
     * Find orders with COD payment
     */
    Page<MarketplaceOrder> findByPaymentMethodAndOrderStatus(
        MarketplaceOrder.PaymentMethod method,
        MarketplaceOrder.OrderStatus status,
        Pageable pageable
    );

    /**
     * Find orders by contact number
     */
    List<MarketplaceOrder> findByContactNumber(String contactNumber);

    /**
     * Find orders with failed payments
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.paymentStatus = 'FAILED' " +
           "ORDER BY mo.createdAt DESC")
    Page<MarketplaceOrder> findOrdersWithFailedPayments(Pageable pageable);

    /**
     * Find orders requiring refund
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.paymentStatus = 'FAILED' " +
           "AND mo.orderStatus IN ('CANCELLED', 'RETURNED')")
    List<MarketplaceOrder> findOrdersRequiringRefund();

    /**
     * Get average order value by buyer
     */
    @Query("SELECT mo.buyerId, AVG(mo.totalAmount) FROM MarketplaceOrder mo " +
           "WHERE mo.orderStatus = 'DELIVERED' GROUP BY mo.buyerId")
    List<Object[]> getAverageOrderValueByBuyer();

    /**
     * Get average order value by seller
     */
    @Query("SELECT mo.sellerId, AVG(mo.totalAmount) FROM MarketplaceOrder mo " +
           "WHERE mo.orderStatus = 'DELIVERED' GROUP BY mo.sellerId")
    List<Object[]> getAverageOrderValueBySeller();

    /**
     * Find orders by multiple statuses
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.orderStatus IN :statuses " +
           "ORDER BY mo.createdAt DESC")
    Page<MarketplaceOrder> findOrdersByStatuses(
        @Param("statuses") List<MarketplaceOrder.OrderStatus> statuses,
        Pageable pageable
    );

    /**
     * Find orders by multiple payment statuses
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.paymentStatus IN :statuses " +
           "ORDER BY mo.createdAt DESC")
    Page<MarketplaceOrder> findOrdersByPaymentStatuses(
        @Param("statuses") List<MarketplaceOrder.PaymentStatus> statuses,
        Pageable pageable
    );

    /**
     * Count orders by buyer and status
     */
    Long countByBuyerIdAndOrderStatus(Long buyerId, MarketplaceOrder.OrderStatus status);

    /**
     * Count orders by seller and status
     */
    Long countBySellerIdAndOrderStatus(Long sellerId, MarketplaceOrder.OrderStatus status);

    /**
     * Find orders by buyer and seller
     */
    List<MarketplaceOrder> findByBuyerIdAndSellerId(Long buyerId, Long sellerId);

    /**
     * Get total revenue by seller
     */
    @Query("SELECT SUM(mo.totalAmount) FROM MarketplaceOrder mo WHERE mo.sellerId = :sellerId " +
           "AND mo.paymentStatus = 'COMPLETED'")
    BigDecimal getTotalRevenueBySeller(@Param("sellerId") Long sellerId);

    /**
     * Get total spending by buyer
     */
    @Query("SELECT SUM(mo.totalAmount) FROM MarketplaceOrder mo WHERE mo.buyerId = :buyerId " +
           "AND mo.paymentStatus = 'COMPLETED'")
    BigDecimal getTotalSpendingByBuyer(@Param("buyerId") Long buyerId);

    /**
     * Find orders with delivery issues
     */
    @Query("SELECT mo FROM MarketplaceOrder mo WHERE mo.orderStatus = 'RETURNED' " +
           "OR (mo.orderStatus = 'SHIPPED' AND mo.expectedDeliveryDate < :currentDate)")
    List<MarketplaceOrder> findOrdersWithDeliveryIssues(@Param("currentDate") LocalDateTime currentDate);

    /**
     * Update order status
     */
    @Query("UPDATE MarketplaceOrder mo SET mo.orderStatus = :status, mo.updatedAt = CURRENT_TIMESTAMP " +
           "WHERE mo.id = :orderId")
    void updateOrderStatus(@Param("orderId") Long orderId, @Param("status") MarketplaceOrder.OrderStatus status);

    /**
     * Update payment status
     */
    @Query("UPDATE MarketplaceOrder mo SET mo.paymentStatus = :status, mo.updatedAt = CURRENT_TIMESTAMP " +
           "WHERE mo.id = :orderId")
    void updatePaymentStatus(@Param("orderId") Long orderId, @Param("status") MarketplaceOrder.PaymentStatus status);
}

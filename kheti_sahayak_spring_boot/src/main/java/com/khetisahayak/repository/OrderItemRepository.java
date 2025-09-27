package com.khetisahayak.repository;

import com.khetisahayak.model.MarketplaceOrder;
import com.khetisahayak.model.OrderItem;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Order Item Repository for Kheti Sahayak Agricultural Platform
 * Handles database operations for individual products in marketplace orders
 * Implements CodeRabbit data access patterns for agricultural product tracking
 */
@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {

    /**
     * Find order items by order
     */
    List<OrderItem> findByOrderId(Long orderId);

    /**
     * Find order items by order with pagination
     */
    Page<OrderItem> findByOrderId(Long orderId, Pageable pageable);

    /**
     * Find order items by order
     */
    List<OrderItem> findByOrder(MarketplaceOrder order);

    /**
     * Find order items by product name
     */
    Page<OrderItem> findByProductNameContainingIgnoreCase(String productName, Pageable pageable);

    /**
     * Find order items by product category
     */
    Page<OrderItem> findByProductCategory(OrderItem.ProductCategory category, Pageable pageable);

    /**
     * Find order items by quality grade
     */
    Page<OrderItem> findByQualityGrade(OrderItem.QualityGrade qualityGrade, Pageable pageable);

    /**
     * Find organic order items
     */
    Page<OrderItem> findByIsOrganicTrue(Pageable pageable);

    /**
     * Find order items by unit
     */
    Page<OrderItem> findByUnit(OrderItem.Unit unit, Pageable pageable);

    /**
     * Find order items by origin
     */
    Page<OrderItem> findByOriginContainingIgnoreCase(String origin, Pageable pageable);

    /**
     * Find order items by harvest date range
     */
    @Query("SELECT oi FROM OrderItem oi WHERE oi.harvestDate BETWEEN :startDate AND :endDate " +
           "ORDER BY oi.harvestDate DESC")
    Page<OrderItem> findByHarvestDateRange(
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        Pageable pageable
    );

    /**
     * Find order items by expiry date range
     */
    @Query("SELECT oi FROM OrderItem oi WHERE oi.expiryDate BETWEEN :startDate AND :endDate " +
           "ORDER BY oi.expiryDate ASC")
    Page<OrderItem> findByExpiryDateRange(
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        Pageable pageable
    );

    /**
     * Find order items expiring soon
     */
    @Query("SELECT oi FROM OrderItem oi WHERE oi.expiryDate IS NOT NULL " +
           "AND oi.expiryDate BETWEEN CURRENT_DATE AND :expiryDate")
    List<OrderItem> findOrderItemsExpiringSoon(@Param("expiryDate") LocalDate expiryDate);

    /**
     * Find order items by price range
     */
    @Query("SELECT oi FROM OrderItem oi WHERE oi.unitPrice BETWEEN :minPrice AND :maxPrice " +
           "ORDER BY oi.unitPrice ASC")
    Page<OrderItem> findByPriceRange(
        @Param("minPrice") BigDecimal minPrice,
        @Param("maxPrice") BigDecimal maxPrice,
        Pageable pageable
    );

    /**
     * Find order items by total price range
     */
    @Query("SELECT oi FROM OrderItem oi WHERE oi.totalPrice BETWEEN :minPrice AND :maxPrice " +
           "ORDER BY oi.totalPrice DESC")
    Page<OrderItem> findByTotalPriceRange(
        @Param("minPrice") BigDecimal minPrice,
        @Param("maxPrice") BigDecimal maxPrice,
        Pageable pageable
    );

    /**
     * Find order items by quantity range
     */
    @Query("SELECT oi FROM OrderItem oi WHERE oi.quantity BETWEEN :minQuantity AND :maxQuantity " +
           "ORDER BY oi.quantity DESC")
    Page<OrderItem> findByQuantityRange(
        @Param("minQuantity") BigDecimal minQuantity,
        @Param("maxQuantity") BigDecimal maxQuantity,
        Pageable pageable
    );

    /**
     * Find order items by currency
     */
    Page<OrderItem> findByCurrency(String currency, Pageable pageable);

    /**
     * Find order items by multiple categories
     */
    @Query("SELECT oi FROM OrderItem oi WHERE oi.productCategory IN :categories")
    Page<OrderItem> findByProductCategories(
        @Param("categories") List<OrderItem.ProductCategory> categories,
        Pageable pageable
    );

    /**
     * Find order items by multiple quality grades
     */
    @Query("SELECT oi FROM OrderItem oi WHERE oi.qualityGrade IN :grades")
    Page<OrderItem> findByQualityGrades(
        @Param("grades") List<OrderItem.QualityGrade> grades,
        Pageable pageable
    );

    /**
     * Find order items by multiple units
     */
    @Query("SELECT oi FROM OrderItem oi WHERE oi.unit IN :units")
    Page<OrderItem> findByUnits(
        @Param("units") List<OrderItem.Unit> units,
        Pageable pageable
    );

    /**
     * Search order items by product name or description
     */
    @Query("SELECT oi FROM OrderItem oi WHERE " +
           "LOWER(oi.productName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(oi.variety) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    Page<OrderItem> searchOrderItems(@Param("searchTerm") String searchTerm, Pageable pageable);

    /**
     * Find order items by order and category
     */
    List<OrderItem> findByOrderAndProductCategory(MarketplaceOrder order, OrderItem.ProductCategory category);

    /**
     * Find order items by order and quality grade
     */
    List<OrderItem> findByOrderAndQualityGrade(MarketplaceOrder order, OrderItem.QualityGrade qualityGrade);

    /**
     * Find order items by order and organic status
     */
    List<OrderItem> findByOrderAndIsOrganic(MarketplaceOrder order, Boolean isOrganic);

    /**
     * Get order item statistics by category
     */
    @Query("SELECT oi.productCategory, COUNT(oi), SUM(oi.quantity), SUM(oi.totalPrice) " +
           "FROM OrderItem oi GROUP BY oi.productCategory")
    List<Object[]> getOrderItemStatsByCategory();

    /**
     * Get order item statistics by quality grade
     */
    @Query("SELECT oi.qualityGrade, COUNT(oi), SUM(oi.quantity), SUM(oi.totalPrice) " +
           "FROM OrderItem oi GROUP BY oi.qualityGrade")
    List<Object[]> getOrderItemStatsByQualityGrade();

    /**
     * Get order item statistics by unit
     */
    @Query("SELECT oi.unit, COUNT(oi), SUM(oi.quantity) FROM OrderItem oi GROUP BY oi.unit")
    List<Object[]> getOrderItemStatsByUnit();

    /**
     * Get order item statistics by origin
     */
    @Query("SELECT oi.origin, COUNT(oi), SUM(oi.quantity), SUM(oi.totalPrice) " +
           "FROM OrderItem oi WHERE oi.origin IS NOT NULL GROUP BY oi.origin")
    List<Object[]> getOrderItemStatsByOrigin();

    /**
     * Get organic vs non-organic statistics
     */
    @Query("SELECT oi.isOrganic, COUNT(oi), SUM(oi.quantity), SUM(oi.totalPrice) " +
           "FROM OrderItem oi GROUP BY oi.isOrganic")
    List<Object[]> getOrganicVsNonOrganicStats();

    /**
     * Get order item statistics by currency
     */
    @Query("SELECT oi.currency, COUNT(oi), SUM(oi.totalPrice) FROM OrderItem oi GROUP BY oi.currency")
    List<Object[]> getOrderItemStatsByCurrency();

    /**
     * Find most popular products by order count
     */
    @Query("SELECT oi.productName, oi.productCategory, COUNT(oi), SUM(oi.quantity), SUM(oi.totalPrice) " +
           "FROM OrderItem oi GROUP BY oi.productName, oi.productCategory " +
           "ORDER BY COUNT(oi) DESC")
    Page<Object[]> findMostPopularProducts(Pageable pageable);

    /**
     * Find highest value products
     */
    @Query("SELECT oi.productName, oi.productCategory, SUM(oi.totalPrice), COUNT(oi), SUM(oi.quantity) " +
           "FROM OrderItem oi GROUP BY oi.productName, oi.productCategory " +
           "ORDER BY SUM(oi.totalPrice) DESC")
    Page<Object[]> findHighestValueProducts(Pageable pageable);

    /**
     * Find products by average unit price
     */
    @Query("SELECT oi.productName, oi.productCategory, AVG(oi.unitPrice), COUNT(oi) " +
           "FROM OrderItem oi GROUP BY oi.productName, oi.productCategory " +
           "ORDER BY AVG(oi.unitPrice) DESC")
    Page<Object[]> findProductsByAverageUnitPrice(Pageable pageable);

    /**
     * Find order items with handling instructions
     */
    @Query("SELECT oi FROM OrderItem oi WHERE oi.handlingInstructions IS NOT NULL " +
           "AND oi.handlingInstructions != ''")
    Page<OrderItem> findOrderItemsWithHandlingInstructions(Pageable pageable);

    /**
     * Find order items by variety
     */
    Page<OrderItem> findByVarietyContainingIgnoreCase(String variety, Pageable pageable);

    /**
     * Find order items by multiple varieties
     */
    @Query("SELECT oi FROM OrderItem oi WHERE LOWER(oi.variety) IN " +
           "(SELECT LOWER(v) FROM :varieties v)")
    Page<OrderItem> findByVarieties(
        @Param("varieties") List<String> varieties,
        Pageable pageable
    );

    /**
     * Get price statistics for a product category
     */
    @Query("SELECT MIN(oi.unitPrice), MAX(oi.unitPrice), AVG(oi.unitPrice) " +
           "FROM OrderItem oi WHERE oi.productCategory = :category")
    Object[] getPriceStatisticsForCategory(@Param("category") OrderItem.ProductCategory category);

    /**
     * Get quantity statistics for a product category
     */
    @Query("SELECT MIN(oi.quantity), MAX(oi.quantity), AVG(oi.quantity) " +
           "FROM OrderItem oi WHERE oi.productCategory = :category")
    Object[] getQuantityStatisticsForCategory(@Param("category") OrderItem.ProductCategory category);

    /**
     * Find order items by order date range (through order relationship)
     */
    @Query("SELECT oi FROM OrderItem oi JOIN oi.order o WHERE o.createdAt BETWEEN :startDate AND :endDate " +
           "ORDER BY o.createdAt DESC")
    Page<OrderItem> findOrderItemsByOrderDateRange(
        @Param("startDate") java.time.LocalDateTime startDate,
        @Param("endDate") java.time.LocalDateTime endDate,
        Pageable pageable
    );

    /**
     * Count order items by category
     */
    Long countByProductCategory(OrderItem.ProductCategory category);

    /**
     * Count order items by quality grade
     */
    Long countByQualityGrade(OrderItem.QualityGrade qualityGrade);

    /**
     * Count organic order items
     */
    Long countByIsOrganicTrue();

    /**
     * Find order items by order ID and category
     */
    List<OrderItem> findByOrderIdAndProductCategory(Long orderId, OrderItem.ProductCategory category);

    /**
     * Find order items by order ID and quality grade
     */
    List<OrderItem> findByOrderIdAndQualityGrade(Long orderId, OrderItem.QualityGrade qualityGrade);

    /**
     * Find order items by order ID and organic status
     */
    List<OrderItem> findByOrderIdAndIsOrganic(Long orderId, Boolean isOrganic);

    /**
     * Get total quantity by product category
     */
    @Query("SELECT oi.productCategory, SUM(oi.quantity) FROM OrderItem oi GROUP BY oi.productCategory")
    List<Object[]> getTotalQuantityByCategory();

    /**
     * Get total value by product category
     */
    @Query("SELECT oi.productCategory, SUM(oi.totalPrice) FROM OrderItem oi GROUP BY oi.productCategory")
    List<Object[]> getTotalValueByCategory();

    /**
     * Find order items with expired products
     */
    @Query("SELECT oi FROM OrderItem oi WHERE oi.expiryDate IS NOT NULL " +
           "AND oi.expiryDate < CURRENT_DATE")
    List<OrderItem> findOrderItemsWithExpiredProducts();

    /**
     * Find order items by harvest season
     */
    @Query("SELECT oi FROM OrderItem oi WHERE MONTH(oi.harvestDate) BETWEEN :startMonth AND :endMonth " +
           "ORDER BY oi.harvestDate DESC")
    Page<OrderItem> findOrderItemsByHarvestSeason(
        @Param("startMonth") int startMonth,
        @Param("endMonth") int endMonth,
        Pageable pageable
    );
}

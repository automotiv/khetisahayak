package com.khetisahayak.repository;

import com.khetisahayak.model.Product;
import com.khetisahayak.model.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Product Repository for Kheti Sahayak Agricultural Marketplace
 * Handles database operations for agricultural products and marketplace
 * Implements CodeRabbit data access patterns for agricultural commerce
 */
@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    /**
     * Find products by seller
     */
    List<Product> findBySeller(User seller);
    
    Page<Product> findBySeller(User seller, Pageable pageable);

    /**
     * Find active products by seller
     */
    List<Product> findBySellerAndStatus(User seller, Product.ProductStatus status);

    /**
     * Find products by category
     */
    Page<Product> findByCategory(Product.ProductCategory category, Pageable pageable);

    /**
     * Find active products by category
     */
    Page<Product> findByCategoryAndStatus(
        Product.ProductCategory category, 
        Product.ProductStatus status, 
        Pageable pageable
    );

    /**
     * Find products by location (state and district)
     */
    Page<Product> findByStateAndDistrict(String state, String district, Pageable pageable);

    /**
     * Find active products by location
     */
    Page<Product> findByStateAndDistrictAndStatus(
        String state, 
        String district, 
        Product.ProductStatus status, 
        Pageable pageable
    );

    /**
     * Find products by price range
     */
    @Query("SELECT p FROM Product p WHERE p.pricePerUnit BETWEEN :minPrice AND :maxPrice " +
           "AND p.status = 'ACTIVE' ORDER BY p.pricePerUnit ASC")
    Page<Product> findByPriceRange(
        @Param("minPrice") BigDecimal minPrice,
        @Param("maxPrice") BigDecimal maxPrice,
        Pageable pageable
    );

    /**
     * Search products by name or description
     */
    @Query("SELECT p FROM Product p WHERE " +
           "(LOWER(p.name) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(p.description) LIKE LOWER(CONCAT('%', :searchTerm, '%'))) " +
           "AND p.status = 'ACTIVE'")
    Page<Product> searchProducts(@Param("searchTerm") String searchTerm, Pageable pageable);

    /**
     * Find organic certified products
     */
    Page<Product> findByIsOrganicCertifiedTrueAndStatus(
        Product.ProductStatus status, 
        Pageable pageable
    );

    /**
     * Find featured products
     */
    Page<Product> findByIsFeaturedTrueAndStatus(
        Product.ProductStatus status, 
        Pageable pageable
    );

    /**
     * Find products with delivery available
     */
    Page<Product> findByAllowsHomeDeliveryTrueAndStatus(
        Product.ProductStatus status, 
        Pageable pageable
    );

    /**
     * Find products by quality grade
     */
    Page<Product> findByQualityGradeAndStatus(
        Product.QualityGrade qualityGrade, 
        Product.ProductStatus status, 
        Pageable pageable
    );

    /**
     * Find products expiring soon (within specified days)
     */
    @Query("SELECT p FROM Product p WHERE p.expiryDate IS NOT NULL " +
           "AND p.expiryDate BETWEEN CURRENT_DATE AND :expiryDate " +
           "AND p.status = 'ACTIVE'")
    List<Product> findProductsExpiringSoon(@Param("expiryDate") LocalDate expiryDate);

    /**
     * Find recently harvested products
     */
    @Query("SELECT p FROM Product p WHERE p.harvestDate >= :since " +
           "AND p.status = 'ACTIVE' ORDER BY p.harvestDate DESC")
    Page<Product> findRecentlyHarvestedProducts(
        @Param("since") LocalDate since, 
        Pageable pageable
    );

    /**
     * Find products by season
     */
    @Query("SELECT p FROM Product p WHERE LOWER(p.season) = LOWER(:season) " +
           "AND p.status = 'ACTIVE'")
    Page<Product> findBySeasonAndActive(@Param("season") String season, Pageable pageable);

    /**
     * Advanced search with multiple filters
     */
    @Query("SELECT p FROM Product p WHERE " +
           "(:category IS NULL OR p.category = :category) AND " +
           "(:state IS NULL OR p.state = :state) AND " +
           "(:district IS NULL OR p.district = :district) AND " +
           "(:minPrice IS NULL OR p.pricePerUnit >= :minPrice) AND " +
           "(:maxPrice IS NULL OR p.pricePerUnit <= :maxPrice) AND " +
           "(:organic IS NULL OR p.isOrganicCertified = :organic) AND " +
           "(:delivery IS NULL OR p.allowsHomeDelivery = :delivery) AND " +
           "(:searchTerm IS NULL OR LOWER(p.name) LIKE LOWER(CONCAT('%', :searchTerm, '%'))) AND " +
           "p.status = 'ACTIVE' AND p.availableQuantity > 0")
    Page<Product> findWithFilters(
        @Param("category") Product.ProductCategory category,
        @Param("state") String state,
        @Param("district") String district,
        @Param("minPrice") BigDecimal minPrice,
        @Param("maxPrice") BigDecimal maxPrice,
        @Param("organic") Boolean organic,
        @Param("delivery") Boolean delivery,
        @Param("searchTerm") String searchTerm,
        Pageable pageable
    );

    /**
     * Find products near location (within radius)
     */
    @Query("SELECT p FROM Product p JOIN p.seller s WHERE " +
           "s.latitude IS NOT NULL AND s.longitude IS NOT NULL AND " +
           "p.status = 'ACTIVE' AND " +
           "(6371 * acos(cos(radians(:latitude)) * cos(radians(s.latitude)) * " +
           "cos(radians(s.longitude) - radians(:longitude)) + " +
           "sin(radians(:latitude)) * sin(radians(s.latitude)))) <= :radiusKm")
    Page<Product> findProductsNearLocation(
        @Param("latitude") Double latitude,
        @Param("longitude") Double longitude,
        @Param("radiusKm") Double radiusKm,
        Pageable pageable
    );

    /**
     * Get product statistics by category
     */
    @Query("SELECT p.category, COUNT(p), AVG(p.pricePerUnit) FROM Product p " +
           "WHERE p.status = 'ACTIVE' GROUP BY p.category")
    List<Object[]> getProductStatsByCategory();

    /**
     * Get product statistics by state
     */
    @Query("SELECT p.state, COUNT(p), AVG(p.pricePerUnit) FROM Product p " +
           "WHERE p.status = 'ACTIVE' GROUP BY p.state")
    List<Object[]> getProductStatsByState();

    /**
     * Find top-rated products
     */
    @Query("SELECT p FROM Product p WHERE p.averageRating IS NOT NULL " +
           "AND p.status = 'ACTIVE' ORDER BY p.averageRating DESC, p.totalReviews DESC")
    Page<Product> findTopRatedProducts(Pageable pageable);

    /**
     * Find best-selling products
     */
    @Query("SELECT p FROM Product p WHERE p.totalSales > 0 " +
           "AND p.status = 'ACTIVE' ORDER BY p.totalSales DESC")
    Page<Product> findBestSellingProducts(Pageable pageable);

    /**
     * Find products with low stock (below minimum threshold)
     */
    @Query("SELECT p FROM Product p WHERE p.availableQuantity <= :threshold " +
           "AND p.status = 'ACTIVE'")
    List<Product> findLowStockProducts(@Param("threshold") Integer threshold);

    /**
     * Find products by seller and category
     */
    List<Product> findBySellerAndCategory(User seller, Product.ProductCategory category);

    /**
     * Find products requiring approval
     */
    List<Product> findByStatus(Product.ProductStatus status);

    /**
     * Find recently added products
     */
    @Query("SELECT p FROM Product p WHERE p.createdAt >= :since " +
           "AND p.status = 'ACTIVE' ORDER BY p.createdAt DESC")
    Page<Product> findRecentlyAddedProducts(
        @Param("since") LocalDateTime since, 
        Pageable pageable
    );

    /**
     * Update product last active timestamp
     */
    @Query("UPDATE Product p SET p.lastActiveAt = :timestamp WHERE p.id = :productId")
    void updateLastActiveTime(@Param("productId") Long productId, @Param("timestamp") LocalDateTime timestamp);

    /**
     * Find expired products
     */
    @Query("SELECT p FROM Product p WHERE p.expiryDate IS NOT NULL " +
           "AND p.expiryDate < CURRENT_DATE AND p.status != 'EXPIRED'")
    List<Product> findExpiredProducts();

    /**
     * Count products by seller and status
     */
    Long countBySellerAndStatus(User seller, Product.ProductStatus status);

    /**
     * Count total active products
     */
    Long countByStatus(Product.ProductStatus status);

    /**
     * Find similar products (same category, different seller)
     */
    @Query("SELECT p FROM Product p WHERE p.category = :category " +
           "AND p.seller != :seller AND p.status = 'ACTIVE' " +
           "ORDER BY p.averageRating DESC")
    Page<Product> findSimilarProducts(
        @Param("category") Product.ProductCategory category,
        @Param("seller") User seller,
        Pageable pageable
    );

    /**
     * Find products by multiple categories
     */
    @Query("SELECT p FROM Product p WHERE p.category IN :categories " +
           "AND p.status = 'ACTIVE'")
    Page<Product> findByCategories(
        @Param("categories") List<Product.ProductCategory> categories,
        Pageable pageable
    );

    /**
     * Get price statistics for a category
     */
    @Query("SELECT MIN(p.pricePerUnit), MAX(p.pricePerUnit), AVG(p.pricePerUnit) " +
           "FROM Product p WHERE p.category = :category AND p.status = 'ACTIVE'")
    Object[] getPriceStatisticsForCategory(@Param("category") Product.ProductCategory category);

    /**
     * Find products with negotiable prices
     */
    Page<Product> findByIsNegotiableTrueAndStatus(
        Product.ProductStatus status, 
        Pageable pageable
    );
}

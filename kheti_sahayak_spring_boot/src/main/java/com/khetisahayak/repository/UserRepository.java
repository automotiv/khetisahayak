package com.khetisahayak.repository;

import com.khetisahayak.model.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * User Repository for Kheti Sahayak Agricultural Platform
 * Handles database operations for farmers, experts, and administrators
 * Implements CodeRabbit data access patterns for agricultural user management
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * Find user by mobile number (primary identifier for farmers)
     */
    Optional<User> findByMobileNumber(String mobileNumber);

    /**
     * Find user by email address
     */
    Optional<User> findByEmail(String email);

    /**
     * Check if mobile number already exists
     */
    boolean existsByMobileNumber(String mobileNumber);

    /**
     * Check if email already exists
     */
    boolean existsByEmail(String email);

    /**
     * Find users by user type (for role-based queries)
     */
    List<User> findByUserType(User.UserType userType);

    /**
     * Find verified users by type
     */
    List<User> findByUserTypeAndIsVerifiedTrue(User.UserType userType);

    /**
     * Find active users by type
     */
    List<User> findByUserTypeAndIsActiveTrue(User.UserType userType);

    /**
     * Find farmers by state (for location-based services)
     */
    List<User> findByUserTypeAndState(User.UserType userType, String state);

    /**
     * Find farmers by state and district
     */
    List<User> findByUserTypeAndStateAndDistrict(User.UserType userType, String state, String district);

    /**
     * Find farmers by primary crop type
     */
    List<User> findByUserTypeAndPrimaryCrop(User.UserType userType, String primaryCrop);

    /**
     * Find farmers in a geographical area (within latitude/longitude bounds)
     */
    @Query("SELECT u FROM User u WHERE u.userType = :userType " +
           "AND u.latitude BETWEEN :minLat AND :maxLat " +
           "AND u.longitude BETWEEN :minLon AND :maxLon " +
           "AND u.isActive = true")
    List<User> findFarmersInArea(
        @Param("userType") User.UserType userType,
        @Param("minLat") Double minLatitude,
        @Param("maxLat") Double maxLatitude,
        @Param("minLon") Double minLongitude,
        @Param("maxLon") Double maxLongitude
    );

    /**
     * Find recently registered farmers (for onboarding support)
     */
    @Query("SELECT u FROM User u WHERE u.userType = 'FARMER' " +
           "AND u.createdAt >= :since " +
           "ORDER BY u.createdAt DESC")
    List<User> findRecentlyRegisteredFarmers(@Param("since") LocalDateTime since);

    /**
     * Find farmers by irrigation type (for targeted recommendations)
     */
    List<User> findByUserTypeAndIrrigationType(User.UserType userType, User.IrrigationType irrigationType);

    /**
     * Find users by preferred language (for content localization)
     */
    List<User> findByPreferredLanguage(User.Language language);

    /**
     * Find experts available for consultation
     */
    @Query("SELECT u FROM User u WHERE u.userType = 'EXPERT' " +
           "AND u.isVerified = true AND u.isActive = true")
    List<User> findAvailableExperts();

    /**
     * Search farmers by name (for admin/expert lookup)
     */
    @Query("SELECT u FROM User u WHERE u.userType = 'FARMER' " +
           "AND LOWER(u.fullName) LIKE LOWER(CONCAT('%', :name, '%'))")
    List<User> searchFarmersByName(@Param("name") String name);

    /**
     * Find farmers with farm size in range (for targeted services)
     */
    @Query("SELECT u FROM User u WHERE u.userType = 'FARMER' " +
           "AND u.farmSize BETWEEN :minSize AND :maxSize")
    List<User> findFarmersByFarmSizeRange(
        @Param("minSize") Double minFarmSize,
        @Param("maxSize") Double maxFarmSize
    );

    /**
     * Get user statistics for dashboard
     */
    @Query("SELECT u.userType, COUNT(u) FROM User u GROUP BY u.userType")
    List<Object[]> getUserStatsByType();

    /**
     * Get farmer statistics by state
     */
    @Query("SELECT u.state, COUNT(u) FROM User u WHERE u.userType = 'FARMER' GROUP BY u.state")
    List<Object[]> getFarmerStatsByState();

    /**
     * Get farmer statistics by primary crop
     */
    @Query("SELECT u.primaryCrop, COUNT(u) FROM User u WHERE u.userType = 'FARMER' " +
           "AND u.primaryCrop IS NOT NULL GROUP BY u.primaryCrop")
    List<Object[]> getFarmerStatsByCrop();

    /**
     * Find inactive users (for engagement campaigns)
     */
    @Query("SELECT u FROM User u WHERE u.lastLoginAt < :cutoffDate " +
           "OR u.lastLoginAt IS NULL")
    List<User> findInactiveUsers(@Param("cutoffDate") LocalDateTime cutoffDate);

    /**
     * Find users registered but not verified (for follow-up)
     */
    List<User> findByIsVerifiedFalseAndCreatedAtBefore(LocalDateTime cutoffDate);

    /**
     * Get paginated farmers for admin management
     */
    Page<User> findByUserType(User.UserType userType, Pageable pageable);

    /**
     * Get paginated farmers by state
     */
    Page<User> findByUserTypeAndState(User.UserType userType, String state, Pageable pageable);

    /**
     * Search users with filters (admin function)
     */
    @Query("SELECT u FROM User u WHERE " +
           "(:userType IS NULL OR u.userType = :userType) AND " +
           "(:state IS NULL OR u.state = :state) AND " +
           "(:verified IS NULL OR u.isVerified = :verified) AND " +
           "(:active IS NULL OR u.isActive = :active) AND " +
           "(:searchTerm IS NULL OR LOWER(u.fullName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) " +
           " OR u.mobileNumber LIKE CONCAT('%', :searchTerm, '%'))")
    Page<User> searchUsersWithFilters(
        @Param("userType") User.UserType userType,
        @Param("state") String state,
        @Param("verified") Boolean verified,
        @Param("active") Boolean active,
        @Param("searchTerm") String searchTerm,
        Pageable pageable
    );

    /**
     * Update last login timestamp
     */
    @Query("UPDATE User u SET u.lastLoginAt = :loginTime WHERE u.id = :userId")
    void updateLastLoginTime(@Param("userId") Long userId, @Param("loginTime") LocalDateTime loginTime);

    /**
     * Find users for birthday/anniversary notifications
     */
    @Query("SELECT u FROM User u WHERE MONTH(u.createdAt) = :month AND DAY(u.createdAt) = :day")
    List<User> findUsersWithAnniversary(@Param("month") int month, @Param("day") int day);
}

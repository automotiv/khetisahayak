package com.khetisahayak.repository;

import com.khetisahayak.model.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Repository for Notification data access
 * Handles farmer alerts and system notifications
 */
@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    // Find all notifications for a user
    Page<Notification> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    // Find unread notifications for a user
    Page<Notification> findByUserIdAndIsReadFalseOrderByCreatedAtDesc(Long userId, Pageable pageable);

    // Find notifications by type
    Page<Notification> findByUserIdAndTypeOrderByCreatedAtDesc(
        Long userId, 
        Notification.NotificationType type, 
        Pageable pageable
    );

    // Find urgent notifications
    @Query("SELECT n FROM Notification n WHERE n.userId = :userId AND n.priority = 'URGENT' AND n.isRead = false ORDER BY n.createdAt DESC")
    List<Notification> findUrgentUnreadNotifications(@Param("userId") Long userId);

    // Count unread notifications
    long countByUserIdAndIsReadFalse(Long userId);

    // Count notifications by type
    long countByUserIdAndType(Long userId, Notification.NotificationType type);

    // Mark notification as read
    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = :readAt WHERE n.id = :id AND n.userId = :userId")
    int markAsRead(@Param("id") Long id, @Param("userId") Long userId, @Param("readAt") LocalDateTime readAt);

    // Mark all notifications as read for a user
    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = :readAt WHERE n.userId = :userId AND n.isRead = false")
    int markAllAsRead(@Param("userId") Long userId, @Param("readAt") LocalDateTime readAt);

    // Delete old read notifications
    @Modifying
    @Query("DELETE FROM Notification n WHERE n.isRead = true AND n.createdAt < :cutoffDate")
    int deleteOldReadNotifications(@Param("cutoffDate") LocalDateTime cutoffDate);

    // Delete expired notifications
    @Modifying
    @Query("DELETE FROM Notification n WHERE n.expiresAt IS NOT NULL AND n.expiresAt < :now")
    int deleteExpiredNotifications(@Param("now") LocalDateTime now);

    // Find recent notifications (last 24 hours)
    @Query("SELECT n FROM Notification n WHERE n.userId = :userId AND n.createdAt >= :since ORDER BY n.createdAt DESC")
    List<Notification> findRecentNotifications(@Param("userId") Long userId, @Param("since") LocalDateTime since);

    // Find notifications by priority
    Page<Notification> findByUserIdAndPriorityOrderByCreatedAtDesc(
        Long userId, 
        Notification.Priority priority, 
        Pageable pageable
    );
}


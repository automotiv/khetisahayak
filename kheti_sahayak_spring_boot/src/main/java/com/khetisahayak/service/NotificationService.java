package com.khetisahayak.service;

import com.khetisahayak.model.Notification;
import com.khetisahayak.repository.NotificationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Service for managing notifications and alerts for farmers
 * Handles weather alerts, system notifications, and agricultural advisories
 */
@Service
@Transactional
public class NotificationService {

    private static final Logger logger = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;

    @Autowired
    public NotificationService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    /**
     * Create a new notification
     */
    public Notification createNotification(Notification notification) {
        logger.info("Creating notification for user: {}, type: {}", 
            notification.getUserId(), notification.getType());
        return notificationRepository.save(notification);
    }

    /**
     * Create a simple notification
     */
    public Notification createSimpleNotification(
            Long userId, 
            String title, 
            String message, 
            Notification.NotificationType type) {
        
        Notification notification = new Notification(userId, title, message, type);
        return createNotification(notification);
    }

    /**
     * Create a weather alert notification
     */
    public Notification createWeatherAlert(Long userId, String title, String message) {
        Notification notification = new Notification(userId, title, message, 
            Notification.NotificationType.WEATHER_ALERT, Notification.Priority.URGENT);
        notification.setIcon("weather-alert");
        notification.setExpiresAt(LocalDateTime.now().plusDays(1)); // Expires in 24 hours
        return createNotification(notification);
    }

    /**
     * Create a crop disease alert
     */
    public Notification createCropDiseaseAlert(Long userId, String title, String message) {
        Notification notification = new Notification(userId, title, message, 
            Notification.NotificationType.CROP_DISEASE_ALERT, Notification.Priority.HIGH);
        notification.setIcon("disease-alert");
        notification.setActionText("View Details");
        notification.setActionUrl("/diagnostics");
        return createNotification(notification);
    }

    /**
     * Create a market price update notification
     */
    public Notification createMarketPriceUpdate(Long userId, String cropName, String newPrice) {
        String title = cropName + " Price Update";
        String message = String.format("New market price for %s: ₹%s", cropName, newPrice);
        Notification notification = new Notification(userId, title, message, 
            Notification.NotificationType.MARKET_PRICE_UPDATE, Notification.Priority.MEDIUM);
        notification.setIcon("market-update");
        notification.setActionText("View Market");
        notification.setActionUrl("/marketplace");
        return createNotification(notification);
    }

    /**
     * Get all notifications for a user
     */
    public Page<Notification> getUserNotifications(Long userId, Pageable pageable) {
        logger.debug("Fetching notifications for user: {}", userId);
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
    }

    /**
     * Get unread notifications for a user
     */
    public Page<Notification> getUnreadNotifications(Long userId, Pageable pageable) {
        logger.debug("Fetching unread notifications for user: {}", userId);
        return notificationRepository.findByUserIdAndIsReadFalseOrderByCreatedAtDesc(userId, pageable);
    }

    /**
     * Get urgent unread notifications
     */
    public List<Notification> getUrgentNotifications(Long userId) {
        logger.debug("Fetching urgent notifications for user: {}", userId);
        return notificationRepository.findUrgentUnreadNotifications(userId);
    }

    /**
     * Get notifications by type
     */
    public Page<Notification> getNotificationsByType(
            Long userId, 
            Notification.NotificationType type, 
            Pageable pageable) {
        logger.debug("Fetching {} notifications for user: {}", type, userId);
        return notificationRepository.findByUserIdAndTypeOrderByCreatedAtDesc(userId, type, pageable);
    }

    /**
     * Get notification by ID
     */
    public Optional<Notification> getNotificationById(Long id) {
        return notificationRepository.findById(id);
    }

    /**
     * Mark notification as read
     */
    public boolean markAsRead(Long notificationId, Long userId) {
        logger.info("Marking notification {} as read for user: {}", notificationId, userId);
        int updated = notificationRepository.markAsRead(notificationId, userId, LocalDateTime.now());
        return updated > 0;
    }

    /**
     * Mark all notifications as read for a user
     */
    public int markAllAsRead(Long userId) {
        logger.info("Marking all notifications as read for user: {}", userId);
        return notificationRepository.markAllAsRead(userId, LocalDateTime.now());
    }

    /**
     * Count unread notifications
     */
    public long countUnreadNotifications(Long userId) {
        return notificationRepository.countByUserIdAndIsReadFalse(userId);
    }

    /**
     * Get recent notifications (last 24 hours)
     */
    public List<Notification> getRecentNotifications(Long userId) {
        LocalDateTime since = LocalDateTime.now().minusDays(1);
        return notificationRepository.findRecentNotifications(userId, since);
    }

    /**
     * Delete notification
     */
    public void deleteNotification(Long id) {
        logger.info("Deleting notification: {}", id);
        notificationRepository.deleteById(id);
    }

    /**
     * Cleanup old read notifications (scheduled task)
     * Runs daily at 2 AM to delete read notifications older than 30 days
     */
    @Scheduled(cron = "0 0 2 * * *") // 2 AM daily
    public void cleanupOldNotifications() {
        LocalDateTime cutoffDate = LocalDateTime.now().minusDays(30);
        int deleted = notificationRepository.deleteOldReadNotifications(cutoffDate);
        logger.info("Cleaned up {} old read notifications", deleted);
    }

    /**
     * Delete expired notifications (scheduled task)
     * Runs every 6 hours
     */
    @Scheduled(fixedRate = 21600000) // 6 hours in milliseconds
    public void deleteExpiredNotifications() {
        int deleted = notificationRepository.deleteExpiredNotifications(LocalDateTime.now());
        if (deleted > 0) {
            logger.info("Deleted {} expired notifications", deleted);
        }
    }

    /**
     * Send bulk notifications to multiple users
     */
    public void sendBulkNotification(
            List<Long> userIds, 
            String title, 
            String message, 
            Notification.NotificationType type,
            Notification.Priority priority) {
        
        logger.info("Sending bulk notification to {} users", userIds.size());
        userIds.forEach(userId -> {
            Notification notification = new Notification(userId, title, message, type, priority);
            createNotification(notification);
        });
    }

    /**
     * Get notification statistics for a user
     */
    public NotificationStats getNotificationStats(Long userId) {
        long totalUnread = countUnreadNotifications(userId);
        long urgentUnread = notificationRepository.findUrgentUnreadNotifications(userId).size();
        long weatherAlerts = notificationRepository.countByUserIdAndType(userId, 
            Notification.NotificationType.WEATHER_ALERT);
        
        return new NotificationStats(totalUnread, urgentUnread, weatherAlerts);
    }

    /**
     * Inner class for notification statistics
     */
    public static class NotificationStats {
        private final long totalUnread;
        private final long urgentUnread;
        private final long weatherAlerts;

        public NotificationStats(long totalUnread, long urgentUnread, long weatherAlerts) {
            this.totalUnread = totalUnread;
            this.urgentUnread = urgentUnread;
            this.weatherAlerts = weatherAlerts;
        }

        public long getTotalUnread() {
            return totalUnread;
        }

        public long getUrgentUnread() {
            return urgentUnread;
        }

        public long getWeatherAlerts() {
            return weatherAlerts;
        }
    }
}


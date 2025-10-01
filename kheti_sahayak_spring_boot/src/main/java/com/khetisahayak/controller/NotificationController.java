package com.khetisahayak.controller;

import com.khetisahayak.model.Notification;
import com.khetisahayak.service.JwtService;
import com.khetisahayak.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Notification Controller for Kheti Sahayak Agricultural Platform
 * Handles weather alerts, system notifications, and agricultural advisories
 * Implements CodeRabbit standards for notification delivery
 */
@Tag(name = "Notifications", description = "Notification and alert management APIs for farmers")
@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = "*")
public class NotificationController {

    private final NotificationService notificationService;
    private final JwtService jwtService;

    @Autowired
    public NotificationController(NotificationService notificationService, JwtService jwtService) {
        this.notificationService = notificationService;
        this.jwtService = jwtService;
    }

    /**
     * Helper method to get authenticated user ID
     */
    private Long getAuthenticatedUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()) {
            return Long.parseLong(authentication.getName());
        }
        throw new RuntimeException("User not authenticated");
    }

    @Operation(summary = "Get all notifications", 
               description = "Retrieve all notifications for the authenticated user")
    @PreAuthorize("hasRole('FARMER')")
    @GetMapping
    public ResponseEntity<Map<String, Object>> getAllNotifications(
            @Parameter(description = "Page number") @RequestParam(defaultValue = "0") int page,
            @Parameter(description = "Page size") @RequestParam(defaultValue = "20") int size) {
        
        try {
            Long userId = getAuthenticatedUserId();
            Pageable pageable = PageRequest.of(page, size);
            
            Page<Notification> notificationsPage = notificationService.getUserNotifications(userId, pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", notificationsPage.getContent());
            response.put("currentPage", notificationsPage.getNumber());
            response.put("totalItems", notificationsPage.getTotalElements());
            response.put("totalPages", notificationsPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch notifications");
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get unread notifications", 
               description = "Retrieve unread notifications for the authenticated user")
    @PreAuthorize("hasRole('FARMER')")
    @GetMapping("/unread")
    public ResponseEntity<Map<String, Object>> getUnreadNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        try {
            Long userId = getAuthenticatedUserId();
            Pageable pageable = PageRequest.of(page, size);
            
            Page<Notification> notificationsPage = notificationService.getUnreadNotifications(userId, pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", notificationsPage.getContent());
            response.put("currentPage", notificationsPage.getNumber());
            response.put("totalItems", notificationsPage.getTotalElements());
            response.put("totalPages", notificationsPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch unread notifications");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get urgent notifications", 
               description = "Retrieve urgent unread notifications (weather alerts, disease outbreaks)")
    @PreAuthorize("hasRole('FARMER')")
    @GetMapping("/urgent")
    public ResponseEntity<Map<String, Object>> getUrgentNotifications() {
        try {
            Long userId = getAuthenticatedUserId();
            List<Notification> urgentNotifications = notificationService.getUrgentNotifications(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", urgentNotifications);
            response.put("count", urgentNotifications.size());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch urgent notifications");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get recent notifications", 
               description = "Retrieve notifications from the last 24 hours")
    @PreAuthorize("hasRole('FARMER')")
    @GetMapping("/recent")
    public ResponseEntity<Map<String, Object>> getRecentNotifications() {
        try {
            Long userId = getAuthenticatedUserId();
            List<Notification> recentNotifications = notificationService.getRecentNotifications(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", recentNotifications);
            response.put("count", recentNotifications.size());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch recent notifications");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get notification statistics", 
               description = "Get notification counts and statistics")
    @PreAuthorize("hasRole('FARMER')")
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getNotificationStats() {
        try {
            Long userId = getAuthenticatedUserId();
            NotificationService.NotificationStats stats = notificationService.getNotificationStats(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", Map.of(
                "totalUnread", stats.getTotalUnread(),
                "urgentUnread", stats.getUrgentUnread(),
                "weatherAlerts", stats.getWeatherAlerts()
            ));
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch notification statistics");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Mark notification as read", 
               description = "Mark a specific notification as read")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping("/{id}/read")
    public ResponseEntity<Map<String, Object>> markAsRead(
            @Parameter(description = "Notification ID") @PathVariable Long id) {
        
        try {
            Long userId = getAuthenticatedUserId();
            boolean success = notificationService.markAsRead(id, userId);
            
            if (success) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("message", "Notification marked as read");
                return ResponseEntity.ok(response);
            } else {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("error", "Notification not found or not authorized");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
            }
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to mark notification as read");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Mark all notifications as read", 
               description = "Mark all notifications as read for the authenticated user")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping("/read-all")
    public ResponseEntity<Map<String, Object>> markAllAsRead() {
        try {
            Long userId = getAuthenticatedUserId();
            int updatedCount = notificationService.markAllAsRead(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "All notifications marked as read");
            response.put("updatedCount", updatedCount);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to mark all notifications as read");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Delete notification", 
               description = "Delete a specific notification")
    @PreAuthorize("hasRole('FARMER')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, Object>> deleteNotification(
            @Parameter(description = "Notification ID") @PathVariable Long id) {
        
        try {
            // Verify the notification belongs to the authenticated user
            Long userId = getAuthenticatedUserId();
            notificationService.getNotificationById(id).ifPresent(notification -> {
                if (!notification.getUserId().equals(userId)) {
                    throw new RuntimeException("Not authorized to delete this notification");
                }
            });
            
            notificationService.deleteNotification(id);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Notification deleted successfully");
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to delete notification");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get notification by ID", 
               description = "Retrieve a specific notification by ID")
    @PreAuthorize("hasRole('FARMER')")
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getNotificationById(
            @Parameter(description = "Notification ID") @PathVariable Long id) {
        
        try {
            Long userId = getAuthenticatedUserId();
            
            return notificationService.getNotificationById(id)
                .map(notification -> {
                    // Verify the notification belongs to the authenticated user
                    if (!notification.getUserId().equals(userId)) {
                        Map<String, Object> errorResponse = new HashMap<>();
                        errorResponse.put("success", false);
                        errorResponse.put("error", "Not authorized to view this notification");
                        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
                    }
                    
                    Map<String, Object> response = new HashMap<>();
                    response.put("success", true);
                    response.put("data", notification);
                    return ResponseEntity.ok(response);
                })
                .orElseGet(() -> {
                    Map<String, Object> errorResponse = new HashMap<>();
                    errorResponse.put("success", false);
                    errorResponse.put("error", "Notification not found");
                    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
                });
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch notification");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get notifications by type", 
               description = "Retrieve notifications filtered by type (weather alerts, market updates, etc.)")
    @PreAuthorize("hasRole('FARMER')")
    @GetMapping("/type/{type}")
    public ResponseEntity<Map<String, Object>> getNotificationsByType(
            @Parameter(description = "Notification type") @PathVariable String type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        try {
            Long userId = getAuthenticatedUserId();
            Notification.NotificationType notificationType = Notification.NotificationType.valueOf(type.toUpperCase());
            Pageable pageable = PageRequest.of(page, size);
            
            Page<Notification> notificationsPage = notificationService.getNotificationsByType(
                userId, notificationType, pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", notificationsPage.getContent());
            response.put("currentPage", notificationsPage.getNumber());
            response.put("totalItems", notificationsPage.getTotalElements());
            response.put("totalPages", notificationsPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Invalid notification type");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch notifications by type");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
}


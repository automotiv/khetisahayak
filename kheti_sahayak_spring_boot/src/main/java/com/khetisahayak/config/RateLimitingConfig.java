package com.khetisahayak.config;

import com.khetisahayak.util.AgriculturalConstants;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.lang.NonNull;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Rate Limiting Configuration for Kheti Sahayak Agricultural Platform
 * Optimized for rural connectivity scenarios
 * Implements CodeRabbit performance standards for API protection
 */
@Configuration
public class RateLimitingConfig implements WebMvcConfigurer {

    private static final ConcurrentHashMap<String, RateLimitInfo> rateLimitCache = new ConcurrentHashMap<>();
    private static final long CLEANUP_INTERVAL_MS = 60000; // 1 minute
    private static long lastCleanup = System.currentTimeMillis();

    @Bean
    public RateLimitingInterceptor rateLimitingInterceptor() {
        return new RateLimitingInterceptor();
    }

    @Override
    public void addInterceptors(@NonNull InterceptorRegistry registry) {
        registry.addInterceptor(rateLimitingInterceptor())
                .addPathPatterns("/api/**")
                .excludePathPatterns("/api/health", "/api-docs/**", "/v3/api-docs/**");
    }

    /**
     * Rate limiting interceptor
     * Tracks requests per IP address with sliding window
     */
    public static class RateLimitingInterceptor implements HandlerInterceptor {

        @Override
        public boolean preHandle(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response, @NonNull Object handler) {
            // Cleanup old entries periodically
            cleanupOldEntries();

            String clientId = getClientIdentifier(request);
            String path = request.getRequestURI();

            // Different limits for different endpoints
            int maxRequests;
            long windowMs;

            if (path.contains("/upload") || path.contains("/diagnostics/upload")) {
                // Stricter limits for upload endpoints
                maxRequests = AgriculturalConstants.RATE_LIMIT_UPLOAD_PER_DAY / 24; // Per hour
                windowMs = 3600000; // 1 hour
            } else {
                // Standard API limits
                maxRequests = AgriculturalConstants.RATE_LIMIT_REQUESTS_PER_MINUTE;
                windowMs = 60000; // 1 minute
            }

            RateLimitInfo limitInfo = rateLimitCache.computeIfAbsent(
                clientId + ":" + path,
                k -> new RateLimitInfo()
            );

            long now = System.currentTimeMillis();
            
            // Reset if window expired
            if (now - limitInfo.windowStart > windowMs) {
                limitInfo.windowStart = now;
                limitInfo.requestCount.set(0);
            }

            // Check if limit exceeded
            if (limitInfo.requestCount.incrementAndGet() > maxRequests) {
                response.setStatus(429); // HTTP 429 Too Many Requests
                response.setHeader("X-RateLimit-Limit", String.valueOf(maxRequests));
                response.setHeader("X-RateLimit-Remaining", "0");
                response.setHeader("Retry-After", String.valueOf((windowMs - (now - limitInfo.windowStart)) / 1000));
                response.setContentType("application/json");
                
                try {
                    response.getWriter().write("{\"success\":false,\"error\":\"Rate limit exceeded. Please try again later.\",\"message\":\"Too many requests. This helps ensure service availability for all farmers.\"}");
                } catch (Exception e) {
                    // Ignore
                }
                return false;
            }

            // Set rate limit headers
            response.setHeader("X-RateLimit-Limit", String.valueOf(maxRequests));
            response.setHeader("X-RateLimit-Remaining", String.valueOf(maxRequests - limitInfo.requestCount.get()));
            response.setHeader("X-RateLimit-Reset", String.valueOf((limitInfo.windowStart + windowMs) / 1000));

            return true;
        }

        /**
         * Get client identifier (IP address or user ID if authenticated)
         */
        private String getClientIdentifier(HttpServletRequest request) {
            // Try to get authenticated user ID first
            String userId = request.getHeader("X-User-Id");
            if (userId != null && !userId.isEmpty()) {
                return "user:" + userId;
            }
            
            // Fall back to IP address
            String ip = request.getRemoteAddr();
            String forwardedFor = request.getHeader("X-Forwarded-For");
            if (forwardedFor != null && !forwardedFor.isEmpty()) {
                ip = forwardedFor.split(",")[0].trim();
            }
            return "ip:" + ip;
        }

        /**
         * Cleanup old rate limit entries to prevent memory leaks
         */
        private void cleanupOldEntries() {
            long now = System.currentTimeMillis();
            if (now - lastCleanup < CLEANUP_INTERVAL_MS) {
                return;
            }
            lastCleanup = now;

            rateLimitCache.entrySet().removeIf(entry -> {
                RateLimitInfo info = entry.getValue();
                return (now - info.windowStart) > 3600000; // Remove entries older than 1 hour
            });
        }
    }

    /**
     * Rate limit information holder
     */
    private static class RateLimitInfo {
        long windowStart = System.currentTimeMillis();
        AtomicInteger requestCount = new AtomicInteger(0);
    }
}


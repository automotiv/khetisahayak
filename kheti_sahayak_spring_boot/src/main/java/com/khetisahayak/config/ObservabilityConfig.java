package com.khetisahayak.config;

import io.micrometer.core.aop.TimedAspect;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.boot.actuate.autoconfigure.metrics.MeterRegistryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.EnableAspectJAutoProxy;

/**
 * Observability Configuration for Kheti Sahayak
 * Implements QPS/Latency/Error telemetry as per Issue #256
 * Provides comprehensive monitoring and dashboards for production
 */
@Configuration
@EnableAspectJAutoProxy
public class ObservabilityConfig {

    /**
     * Configure meter registry with common tags
     * Adds application metadata to all metrics
     */
    @Bean
    public MeterRegistryCustomizer<MeterRegistry> metricsCommonTags() {
        return registry -> registry.config()
            .commonTags(
                "application", "kheti-sahayak",
                "environment", System.getProperty("spring.profiles.active", "local"),
                "version", "2.0.0",
                "platform", "agricultural-tech"
            );
    }

    /**
     * Enable @Timed annotation support
     * Allows automatic timing of methods for latency tracking
     */
    @Bean
    public TimedAspect timedAspect(MeterRegistry registry) {
        return new TimedAspect(registry);
    }

    /**
     * Custom metrics for agricultural operations
     */
    @Bean
    public AgricultureMetrics agricultureMetrics(MeterRegistry registry) {
        return new AgricultureMetrics(registry);
    }

    /**
     * Agricultural-specific metrics tracker
     */
    public static class AgricultureMetrics {
        private final MeterRegistry registry;
        private final Timer diagnosticTimer;
        private final Timer weatherTimer;
        private final Timer marketplaceTimer;

        public AgricultureMetrics(MeterRegistry registry) {
            this.registry = registry;
            
            // Create timers for agricultural operations
            this.diagnosticTimer = Timer.builder("agriculture.diagnostic.duration")
                .description("Time taken for crop diagnostic operations")
                .tag("operation", "crop_diagnosis")
                .register(registry);
            
            this.weatherTimer = Timer.builder("agriculture.weather.duration")
                .description("Time taken for weather API calls")
                .tag("operation", "weather_fetch")
                .register(registry);
            
            this.marketplaceTimer = Timer.builder("agriculture.marketplace.duration")
                .description("Time taken for marketplace operations")
                .tag("operation", "product_search")
                .register(registry);
        }

        // Counters for agricultural events
        public void incrementCropDiagnosis(String cropType, boolean success) {
            registry.counter("agriculture.diagnostic.count",
                "crop_type", cropType,
                "success", String.valueOf(success)
            ).increment();
        }

        public void incrementWeatherRequest(String region) {
            registry.counter("agriculture.weather.request.count",
                "region", region
            ).increment();
        }

        public void incrementMarketplaceTransaction(String productCategory) {
            registry.counter("agriculture.marketplace.transaction.count",
                "category", productCategory
            ).increment();
        }

        public void incrementExpertConsultation(String category) {
            registry.counter("agriculture.expert.consultation.count",
                "category", category
            ).increment();
        }

        public void incrementForumActivity(String activityType) {
            registry.counter("agriculture.forum.activity.count",
                "type", activityType
            ).increment();
        }

        public void recordNotificationSent(String notificationType, String priority) {
            registry.counter("agriculture.notification.sent.count",
                "type", notificationType,
                "priority", priority
            ).increment();
        }

        // Gauges for current state
        public void recordActiveUsers(int count) {
            registry.gauge("agriculture.users.active", count);
        }

        public void recordPendingConsultations(int count) {
            registry.gauge("agriculture.consultations.pending", count);
        }

        public Timer getDiagnosticTimer() {
            return diagnosticTimer;
        }

        public Timer getWeatherTimer() {
            return weatherTimer;
        }

        public Timer getMarketplaceTimer() {
            return marketplaceTimer;
        }
    }
}


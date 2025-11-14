package com.khetisahayak.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;

/**
 * Agricultural Logging Utility for Kheti Sahayak Platform
 * Provides structured logging with agricultural context
 * Implements CodeRabbit standards for comprehensive logging
 */
public class AgriculturalLogger {

    private final Logger logger;
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public AgriculturalLogger(Class<?> clazz) {
        this.logger = LoggerFactory.getLogger(clazz);
    }

    /**
     * Log agricultural operation with context
     */
    public void logAgriculturalOperation(String operation, String cropType, String farmerId, String details) {
        MDC.put("operation", operation);
        MDC.put("cropType", cropType);
        MDC.put("farmerId", farmerId);
        MDC.put("timestamp", LocalDateTime.now().format(DATE_FORMATTER));
        
        logger.info("Agricultural Operation: {} | Crop: {} | Farmer: {} | Details: {}", 
                   operation, cropType, farmerId, details);
        
        MDC.clear();
    }

    /**
     * Log crop diagnosis with ML results
     */
    public void logCropDiagnosis(Long diagnosisId, String cropType, Double confidence, String diagnosis) {
        MDC.put("diagnosisId", String.valueOf(diagnosisId));
        MDC.put("cropType", cropType);
        MDC.put("confidence", confidence != null ? String.valueOf(confidence) : "N/A");
        MDC.put("diagnosis", diagnosis);
        
        logger.info("Crop Diagnosis | ID: {} | Crop: {} | Confidence: {} | Diagnosis: {}", 
                   diagnosisId, cropType, confidence, diagnosis);
        
        MDC.clear();
    }

    /**
     * Log marketplace transaction
     */
    public void logMarketplaceTransaction(String transactionType, Long orderId, String farmerId, Double amount) {
        MDC.put("transactionType", transactionType);
        MDC.put("orderId", String.valueOf(orderId));
        MDC.put("farmerId", farmerId);
        MDC.put("amount", amount != null ? String.valueOf(amount) : "0.0");
        
        logger.info("Marketplace Transaction | Type: {} | Order: {} | Farmer: {} | Amount: ₹{}", 
                   transactionType, orderId, farmerId, amount);
        
        MDC.clear();
    }

    /**
     * Log expert consultation
     */
    public void logExpertConsultation(Long consultationId, Long farmerId, Long expertId, String status) {
        MDC.put("consultationId", String.valueOf(consultationId));
        MDC.put("farmerId", String.valueOf(farmerId));
        MDC.put("expertId", String.valueOf(expertId));
        MDC.put("status", status);
        
        logger.info("Expert Consultation | ID: {} | Farmer: {} | Expert: {} | Status: {}", 
                   consultationId, farmerId, expertId, status);
        
        MDC.clear();
    }

    /**
     * Log weather alert for farmers
     */
    public void logWeatherAlert(String state, String district, String alertType, String message) {
        MDC.put("state", state);
        MDC.put("district", district);
        MDC.put("alertType", alertType);
        
        logger.warn("Weather Alert | State: {} | District: {} | Type: {} | Message: {}", 
                   state, district, alertType, message);
        
        MDC.clear();
    }

    /**
     * Log network connectivity issue (common in rural areas)
     */
    public void logNetworkIssue(String operation, String farmerId, String errorMessage) {
        MDC.put("operation", operation);
        MDC.put("farmerId", farmerId);
        MDC.put("errorType", "NETWORK_ISSUE");
        
        logger.warn("Network Connectivity Issue | Operation: {} | Farmer: {} | Error: {}", 
                   operation, farmerId, errorMessage);
        
        MDC.clear();
    }

    /**
     * Log performance metrics for agricultural operations
     */
    public void logPerformanceMetric(String operation, long durationMs, String additionalInfo) {
        MDC.put("operation", operation);
        MDC.put("durationMs", String.valueOf(durationMs));
        
        if (durationMs > 5000) {
            logger.warn("Slow Operation Detected | Operation: {} | Duration: {}ms | Info: {}", 
                       operation, durationMs, additionalInfo);
        } else {
            logger.debug("Performance Metric | Operation: {} | Duration: {}ms | Info: {}", 
                        operation, durationMs, additionalInfo);
        }
        
        MDC.clear();
    }

    /**
     * Log agricultural data validation failure
     */
    public void logValidationFailure(String field, Object value, String reason) {
        MDC.put("validationField", field);
        MDC.put("validationValue", value != null ? value.toString() : "null");
        MDC.put("validationReason", reason);
        
        logger.warn("Agricultural Validation Failure | Field: {} | Value: {} | Reason: {}", 
                   field, value, reason);
        
        MDC.clear();
    }

    /**
     * Log security event in agricultural context
     */
    public void logSecurityEvent(String eventType, String userId, String details) {
        MDC.put("securityEvent", eventType);
        MDC.put("userId", userId);
        
        logger.warn("Security Event | Type: {} | User: {} | Details: {}", 
                   eventType, userId, details);
        
        MDC.clear();
    }

    /**
     * Log agricultural error with full context
     */
    public void logAgriculturalError(String operation, String errorCode, String message, Throwable throwable) {
        MDC.put("operation", operation);
        MDC.put("errorCode", errorCode);
        
        logger.error("Agricultural Error | Operation: {} | Code: {} | Message: {}", 
                    operation, errorCode, message, throwable);
        
        MDC.clear();
    }

    /**
     * Log API request with agricultural context
     */
    public void logApiRequest(String method, String endpoint, String userId, Map<String, String> params) {
        MDC.put("httpMethod", method);
        MDC.put("endpoint", endpoint);
        MDC.put("userId", userId);
        
        if (params != null && !params.isEmpty()) {
            params.forEach((key, value) -> MDC.put("param_" + key, value));
        }
        
        logger.debug("API Request | {} {} | User: {} | Params: {}", 
                    method, endpoint, userId, params);
        
        MDC.clear();
    }

    /**
     * Standard info logging
     */
    public void info(String message, Object... args) {
        logger.info(message, args);
    }

    /**
     * Standard warning logging
     */
    public void warn(String message, Object... args) {
        logger.warn(message, args);
    }

    /**
     * Standard error logging
     */
    public void error(String message, Object... args) {
        logger.error(message, args);
    }

    /**
     * Standard error logging with exception
     */
    public void error(String message, Throwable throwable) {
        logger.error(message, throwable);
    }

    /**
     * Standard debug logging
     */
    public void debug(String message, Object... args) {
        logger.debug(message, args);
    }
}


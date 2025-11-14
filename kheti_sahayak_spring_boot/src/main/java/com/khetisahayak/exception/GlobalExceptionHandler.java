package com.khetisahayak.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Global Exception Handler for Kheti Sahayak Agricultural Platform
 * Handles all exceptions with agricultural context and rural connectivity considerations
 * Implements CodeRabbit standards for error handling and logging
 */
@ControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /**
     * Handle agricultural domain-specific exceptions
     */
    @ExceptionHandler(AgriculturalException.class)
    public ResponseEntity<Object> handleAgriculturalException(AgriculturalException ex, WebRequest request) {
        logger.warn("Agricultural exception: {} [Code: {}] [Context: {}]", 
                   ex.getMessage(), ex.getErrorCode(), ex.getAgriculturalContext());
        
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("timestamp", LocalDateTime.now());
        body.put("status", HttpStatus.BAD_REQUEST.value());
        body.put("error", "Agricultural Validation Error");
        body.put("errorCode", ex.getErrorCode());
        body.put("message", ex.getMessage());
        if (ex.getAgriculturalContext() != null) {
            body.put("agriculturalContext", ex.getAgriculturalContext());
        }
        body.put("path", request.getDescription(false).replace("uri=", ""));

        return new ResponseEntity<>(body, HttpStatus.BAD_REQUEST);
    }

    /**
     * Handle validation exceptions with agricultural context
     */
    @ExceptionHandler(jakarta.validation.ConstraintViolationException.class)
    public ResponseEntity<Object> handleConstraintViolation(
            jakarta.validation.ConstraintViolationException ex, WebRequest request) {
        logger.warn("Validation constraint violation: {}", ex.getMessage());
        
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("timestamp", LocalDateTime.now());
        body.put("status", HttpStatus.BAD_REQUEST.value());
        body.put("error", "Validation Error");
        body.put("message", "Invalid input data. Please check your request.");
        body.put("violations", ex.getConstraintViolations().stream()
            .map(v -> Map.of(
                "field", v.getPropertyPath().toString(),
                "message", v.getMessage(),
                "invalidValue", v.getInvalidValue()
            ))
            .toList());
        body.put("path", request.getDescription(false).replace("uri=", ""));

        return new ResponseEntity<>(body, HttpStatus.BAD_REQUEST);
    }

    /**
     * Handle method argument validation exceptions
     */
    @ExceptionHandler(org.springframework.web.bind.MethodArgumentNotValidException.class)
    public ResponseEntity<Object> handleMethodArgumentNotValid(
            org.springframework.web.bind.MethodArgumentNotValidException ex, WebRequest request) {
        logger.warn("Method argument validation failed: {}", ex.getMessage());
        
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("timestamp", LocalDateTime.now());
        body.put("status", HttpStatus.BAD_REQUEST.value());
        body.put("error", "Validation Error");
        body.put("message", "Invalid request data. Please check all required fields.");
        body.put("violations", ex.getBindingResult().getFieldErrors().stream()
            .map(error -> {
                Object rejectedValue = error.getRejectedValue();
                return Map.of(
                    "field", error.getField(),
                    "message", error.getDefaultMessage() != null ? error.getDefaultMessage() : "Invalid value",
                    "rejectedValue", rejectedValue != null ? rejectedValue.toString() : "null"
                );
            })
            .toList());
        body.put("path", request.getDescription(false).replace("uri=", ""));

        return new ResponseEntity<>(body, HttpStatus.BAD_REQUEST);
    }

    /**
     * Handle response status exceptions
     */
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Object> handleResponseStatusException(ResponseStatusException ex, WebRequest request) {
        logger.error("ResponseStatusException: {}", ex.getMessage());
        return buildErrorResponse(ex, ex.getStatusCode(), request);
    }

    /**
     * Handle generic exceptions with agricultural context logging
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Object> handleGenericException(Exception ex, WebRequest request) {
        logger.error("Unhandled exception in agricultural platform: {} [Path: {}]", 
                    ex.getMessage(), 
                    request.getDescription(false), 
                    ex);
        
        // Check if it's a network-related error (common in rural areas)
        if (ex.getMessage() != null && 
            (ex.getMessage().contains("Connection") || 
             ex.getMessage().contains("timeout") ||
             ex.getMessage().contains("network"))) {
            return buildNetworkErrorResponse(ex, request);
        }
        
        return buildErrorResponse(ex, HttpStatus.INTERNAL_SERVER_ERROR, request);
    }

    /**
     * Build standard error response
     */
    private ResponseEntity<Object> buildErrorResponse(Exception ex, org.springframework.http.HttpStatusCode status, WebRequest request) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("timestamp", LocalDateTime.now());
        body.put("status", status.value());
        body.put("error", status.toString());
        body.put("message", ex.getMessage() != null ? ex.getMessage() : "An error occurred");
        body.put("path", request.getDescription(false).replace("uri=", ""));

        return new ResponseEntity<>(body, status);
    }

    /**
     * Build network error response with rural connectivity context
     */
    private ResponseEntity<Object> buildNetworkErrorResponse(Exception ex, WebRequest request) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("timestamp", LocalDateTime.now());
        body.put("status", HttpStatus.SERVICE_UNAVAILABLE.value());
        body.put("error", "Network Connectivity Issue");
        body.put("message", "Network connection problem detected. This is common in rural areas. Please check your internet connection and try again.");
        body.put("suggestion", "If you're in a low-connectivity area, try again later or use offline features if available.");
        body.put("path", request.getDescription(false).replace("uri=", ""));

        return new ResponseEntity<>(body, HttpStatus.SERVICE_UNAVAILABLE);
    }
}

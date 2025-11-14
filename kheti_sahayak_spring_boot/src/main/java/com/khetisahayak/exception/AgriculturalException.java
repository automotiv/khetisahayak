package com.khetisahayak.exception;

/**
 * Custom exception for agricultural domain-specific errors
 * Provides context-aware error messages for Indian farming scenarios
 * Implements CodeRabbit standards for error handling
 */
public class AgriculturalException extends RuntimeException {

    private final String errorCode;
    private final String agriculturalContext;

    public AgriculturalException(String message) {
        super(message);
        this.errorCode = "AGRICULTURAL_ERROR";
        this.agriculturalContext = null;
    }

    public AgriculturalException(String message, String errorCode) {
        super(message);
        this.errorCode = errorCode;
        this.agriculturalContext = null;
    }

    public AgriculturalException(String message, String errorCode, String agriculturalContext) {
        super(message);
        this.errorCode = errorCode;
        this.agriculturalContext = agriculturalContext;
    }

    public AgriculturalException(String message, Throwable cause) {
        super(message, cause);
        this.errorCode = "AGRICULTURAL_ERROR";
        this.agriculturalContext = null;
    }

    public AgriculturalException(String message, String errorCode, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
        this.agriculturalContext = null;
    }

    public String getErrorCode() {
        return errorCode;
    }

    public String getAgriculturalContext() {
        return agriculturalContext;
    }

    /**
     * Create exception for invalid crop type
     */
    public static AgriculturalException invalidCrop(String cropType) {
        return new AgriculturalException(
            String.format("Invalid crop type: %s. Please select a valid Indian crop.", cropType),
            "INVALID_CROP",
            String.format("Crop: %s", cropType)
        );
    }

    /**
     * Create exception for invalid season
     */
    public static AgriculturalException invalidSeason(String season) {
        return new AgriculturalException(
            String.format("Invalid season: %s. Valid seasons are: Kharif, Rabi, Zaid.", season),
            "INVALID_SEASON",
            String.format("Season: %s", season)
        );
    }

    /**
     * Create exception for invalid coordinates
     */
    public static AgriculturalException invalidCoordinates(Double latitude, Double longitude) {
        return new AgriculturalException(
            "Coordinates must be within India (Latitude: 6.0-37.0, Longitude: 68.0-97.0).",
            "INVALID_COORDINATES",
            String.format("Lat: %s, Lon: %s", latitude, longitude)
        );
    }

    /**
     * Create exception for invalid farm size
     */
    public static AgriculturalException invalidFarmSize(Double farmSize) {
        return new AgriculturalException(
            String.format("Farm size %.2f acres is invalid. Must be between 0.1 and 1000 acres.", farmSize),
            "INVALID_FARM_SIZE",
            String.format("Farm Size: %.2f acres", farmSize)
        );
    }

    /**
     * Create exception for image size exceeding limit
     */
    public static AgriculturalException imageTooLarge(long sizeBytes) {
        long sizeMB = sizeBytes / (1024 * 1024);
        return new AgriculturalException(
            String.format("Image size %d MB exceeds 5MB limit for rural network compatibility.", sizeMB),
            "IMAGE_TOO_LARGE",
            String.format("Size: %d bytes", sizeBytes)
        );
    }

    /**
     * Create exception for network connectivity issues (rural context)
     */
    public static AgriculturalException networkError(String operation) {
        return new AgriculturalException(
            String.format("Network connectivity issue during %s. Please check your internet connection and try again.", operation),
            "NETWORK_ERROR",
            String.format("Operation: %s", operation)
        );
    }

    /**
     * Create exception for ML service unavailable
     */
    public static AgriculturalException mlServiceUnavailable() {
        return new AgriculturalException(
            "Crop diagnosis service is temporarily unavailable. Please try again later or request expert consultation.",
            "ML_SERVICE_UNAVAILABLE",
            "ML Service: Unavailable"
        );
    }
}


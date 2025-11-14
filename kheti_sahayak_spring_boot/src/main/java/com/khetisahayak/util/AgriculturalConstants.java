package com.khetisahayak.util;

/**
 * Agricultural Constants for Kheti Sahayak Platform
 * Contains Indian agricultural domain constants and configurations
 * Implements CodeRabbit standards for agricultural data accuracy
 */
public final class AgriculturalConstants {

    private AgriculturalConstants() {
        // Utility class - prevent instantiation
    }

    // Indian geographical boundaries
    public static final double INDIA_MIN_LATITUDE = 6.0;
    public static final double INDIA_MAX_LATITUDE = 37.0;
    public static final double INDIA_MIN_LONGITUDE = 68.0;
    public static final double INDIA_MAX_LONGITUDE = 97.0;

    // Farm size constraints (in acres)
    public static final double MIN_FARM_SIZE = 0.1;
    public static final double MAX_FARM_SIZE = 1000.0;

    // Image upload constraints for rural networks
    public static final long MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024; // 5MB
    public static final long MAX_IMAGE_SIZE_KB = 5120; // 5MB in KB
    public static final int MAX_IMAGE_DIMENSION = 2048; // Max width/height in pixels

    // Supported image formats for crop diagnosis
    public static final String[] SUPPORTED_IMAGE_FORMATS = {
        "image/jpeg", "image/jpg", "image/png", "image/webp"
    };

    // OTP configuration for Indian mobile numbers
    public static final int OTP_LENGTH = 6;
    public static final int OTP_EXPIRY_MINUTES = 5;
    public static final int OTP_MAX_ATTEMPTS = 3;

    // Crop diagnosis confidence thresholds
    public static final double HIGH_CONFIDENCE_THRESHOLD = 0.85;
    public static final double MEDIUM_CONFIDENCE_THRESHOLD = 0.65;
    public static final double LOW_CONFIDENCE_THRESHOLD = 0.50;

    // Weather alert thresholds for farming
    public static final double MIN_TEMPERATURE_C = 0.0;
    public static final double MAX_TEMPERATURE_C = 50.0;
    public static final double MIN_RAINFALL_MM = 0.0;
    public static final double MAX_RAINFALL_MM = 1000.0;
    public static final double MIN_HUMIDITY_PERCENT = 0.0;
    public static final double MAX_HUMIDITY_PERCENT = 100.0;

    // Marketplace constraints
    public static final double MIN_PRODUCT_PRICE = 1.0;
    public static final double MAX_PRODUCT_PRICE = 1000000.0; // 10 lakh INR
    public static final int MIN_PRODUCT_QUANTITY = 1;
    public static final int MAX_PRODUCT_QUANTITY = 10000;

    // Expert consultation constraints
    public static final int MIN_CONSULTATION_DURATION_MINUTES = 15;
    public static final int MAX_CONSULTATION_DURATION_MINUTES = 120;
    public static final int MIN_RATING = 1;
    public static final int MAX_RATING = 5;

    // Notification priorities
    public static final String NOTIFICATION_PRIORITY_URGENT = "URGENT";
    public static final String NOTIFICATION_PRIORITY_HIGH = "HIGH";
    public static final String NOTIFICATION_PRIORITY_MEDIUM = "MEDIUM";
    public static final String NOTIFICATION_PRIORITY_LOW = "LOW";

    // Agricultural seasons in India
    public static final String SEASON_KHARIF = "KHARIF"; // Monsoon season (June-October)
    public static final String SEASON_RABI = "RABI"; // Winter season (November-March)
    public static final String SEASON_ZAID = "ZAID"; // Summer season (March-June)

    // Common crop categories
    public static final String CATEGORY_CEREALS = "CEREALS";
    public static final String CATEGORY_PULSES = "PULSES";
    public static final String CATEGORY_OILSEEDS = "OILSEEDS";
    public static final String CATEGORY_VEGETABLES = "VEGETABLES";
    public static final String CATEGORY_FRUITS = "FRUITS";
    public static final String CATEGORY_SPICES = "SPICES";

    // Irrigation types
    public static final String IRRIGATION_RAIN_FED = "RAIN_FED";
    public static final String IRRIGATION_DRIP = "DRIP";
    public static final String IRRIGATION_SPRINKLER = "SPRINKLER";
    public static final String IRRIGATION_FLOOD = "FLOOD";
    public static final String IRRIGATION_TUBE_WELL = "TUBE_WELL";
    public static final String IRRIGATION_CANAL = "CANAL";

    // Currency
    public static final String CURRENCY_INR = "INR";
    public static final String CURRENCY_SYMBOL = "₹";

    // Date formats for agricultural calendar
    public static final String DATE_FORMAT_ISO = "yyyy-MM-dd";
    public static final String DATETIME_FORMAT_ISO = "yyyy-MM-dd HH:mm:ss";
    public static final String DATE_FORMAT_INDIAN = "dd/MM/yyyy";

    // Pagination defaults optimized for rural networks
    public static final int DEFAULT_PAGE_SIZE = 20;
    public static final int MAX_PAGE_SIZE = 100;
    public static final int MIN_PAGE_SIZE = 10;

    // Cache TTL for agricultural data (in seconds)
    public static final long CACHE_TTL_WEATHER = 3600; // 1 hour
    public static final long CACHE_TTL_MARKET_PRICES = 1800; // 30 minutes
    public static final long CACHE_TTL_CROP_INFO = 86400; // 24 hours
    public static final long CACHE_TTL_EXPERT_LIST = 3600; // 1 hour

    // API rate limiting for rural connectivity
    public static final int RATE_LIMIT_REQUESTS_PER_MINUTE = 60;
    public static final int RATE_LIMIT_REQUESTS_PER_HOUR = 1000;
    public static final int RATE_LIMIT_UPLOAD_PER_DAY = 50; // Image uploads per day

    // File storage paths
    public static final String UPLOAD_PATH_DIAGNOSTICS = "/uploads/diagnostics/";
    public static final String UPLOAD_PATH_PRODUCTS = "/uploads/products/";
    public static final String UPLOAD_PATH_PROFILES = "/uploads/profiles/";
    public static final String UPLOAD_PATH_DOCUMENTS = "/uploads/documents/";

    // Error messages for agricultural context
    public static final String ERROR_INVALID_CROP = "Invalid crop type. Please select a valid Indian crop.";
    public static final String ERROR_INVALID_SEASON = "Invalid season. Valid seasons are: Kharif, Rabi, Zaid.";
    public static final String ERROR_INVALID_STATE = "Invalid state. Please provide a valid Indian state.";
    public static final String ERROR_INVALID_COORDINATES = "Coordinates must be within India (Lat: 6.0-37.0, Lon: 68.0-97.0).";
    public static final String ERROR_INVALID_FARM_SIZE = "Farm size must be between 0.1 and 1000 acres.";
    public static final String ERROR_IMAGE_TOO_LARGE = "Image size exceeds 5MB limit for rural network compatibility.";
    public static final String ERROR_INVALID_MOBILE = "Invalid Indian mobile number. Must be 10 digits starting with 6-9.";

    // Success messages
    public static final String SUCCESS_DIAGNOSIS_COMPLETE = "Crop diagnosis completed successfully.";
    public static final String SUCCESS_ORDER_PLACED = "Order placed successfully. You will receive confirmation via SMS.";
    public static final String SUCCESS_CONSULTATION_BOOKED = "Expert consultation booked successfully.";
    public static final String SUCCESS_PROFILE_UPDATED = "Profile updated successfully.";
}


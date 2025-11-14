package com.khetisahayak.util;

import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;

/**
 * Agricultural Validator for Kheti Sahayak Platform
 * Validates Indian agricultural data including crops, seasons, states, and regions
 * Implements CodeRabbit standards for agricultural domain accuracy
 */
@Component
public class AgriculturalValidator {

    // Indian crop types commonly grown
    private static final Set<String> VALID_CROPS = Set.of(
        "RICE", "WHEAT", "COTTON", "SUGARCANE", "MAIZE", "SOYBEAN", "PULSES",
        "OILSEEDS", "GROUNDNUT", "MUSTARD", "SESAME", "SUNFLOWER", "TOMATO",
        "ONION", "POTATO", "CHILLI", "BRINJAL", "OKRA", "CUCUMBER", "BITTER_GOURD",
        "BOTTLE_GOURD", "RIDGE_GOURD", "LADY_FINGER", "CAULIFLOWER", "CABBAGE",
        "TURMERIC", "GINGER", "GARLIC", "CUMIN", "CORIANDER", "FENUGREEK",
        "MANGO", "BANANA", "ORANGE", "GUAVA", "PAPAYA", "POMEGRANATE",
        "GRAPES", "WATERMELON", "MUSKMELON", "CITRUS", "COCONUT", "CASHEW"
    );

    // Indian agricultural seasons
    private static final Set<String> VALID_SEASONS = Set.of(
        "KHARIF", "RABI", "ZAID", "SUMMER", "WINTER", "MONSOON"
    );

    // Indian states and union territories
    private static final Set<String> VALID_STATES = Set.of(
        "ANDHRA_PRADESH", "ARUNACHAL_PRADESH", "ASSAM", "BIHAR", "CHHATTISGARH",
        "GOA", "GUJARAT", "HARYANA", "HIMACHAL_PRADESH", "JHARKHAND",
        "KARNATAKA", "KERALA", "MADHYA_PRADESH", "MAHARASHTRA", "MANIPUR",
        "MEGHALAYA", "MIZORAM", "NAGALAND", "ODISHA", "PUNJAB",
        "RAJASTHAN", "SIKKIM", "TAMIL_NADU", "TELANGANA", "TRIPURA",
        "UTTAR_PRADESH", "UTTARAKHAND", "WEST_BENGAL", "ANDAMAN_NICOBAR",
        "CHANDIGARH", "DADRA_NAGAR_HAVELI", "DAMAN_DIU", "DELHI", "JAMMU_KASHMIR",
        "LADAKH", "LAKSHADWEEP", "PUDUCHERRY"
    );

    // Common irrigation types in India
    private static final Set<String> VALID_IRRIGATION_TYPES = Set.of(
        "RAIN_FED", "DRIP", "SPRINKLER", "FLOOD", "MICRO_SPRINKLER",
        "TUBE_WELL", "CANAL", "BORE_WELL", "OPEN_WELL"
    );

    // Crop categories for marketplace
    private static final Set<String> VALID_CROP_CATEGORIES = Set.of(
        "CEREALS", "PULSES", "OILSEEDS", "VEGETABLES", "FRUITS", "SPICES",
        "FIBER_CROPS", "SUGAR_CROPS", "MEDICINAL_PLANTS", "FLOWERS"
    );

    /**
     * Validate crop type against known Indian crops
     */
    public boolean isValidCrop(String cropType) {
        if (cropType == null || cropType.trim().isEmpty()) {
            return false;
        }
        return VALID_CROPS.contains(cropType.toUpperCase().trim());
    }

    /**
     * Validate agricultural season
     */
    public boolean isValidSeason(String season) {
        if (season == null || season.trim().isEmpty()) {
            return false;
        }
        return VALID_SEASONS.contains(season.toUpperCase().trim());
    }

    /**
     * Validate Indian state name
     */
    public boolean isValidState(String state) {
        if (state == null || state.trim().isEmpty()) {
            return false;
        }
        // Check exact match or case-insensitive match
        String normalizedState = state.toUpperCase().trim().replace(" ", "_");
        return VALID_STATES.contains(normalizedState) || 
               VALID_STATES.stream().anyMatch(s -> s.equalsIgnoreCase(normalizedState));
    }

    /**
     * Validate irrigation type
     */
    public boolean isValidIrrigationType(String irrigationType) {
        if (irrigationType == null || irrigationType.trim().isEmpty()) {
            return false;
        }
        return VALID_IRRIGATION_TYPES.contains(irrigationType.toUpperCase().trim());
    }

    /**
     * Validate crop category
     */
    public boolean isValidCropCategory(String category) {
        if (category == null || category.trim().isEmpty()) {
            return false;
        }
        return VALID_CROP_CATEGORIES.contains(category.toUpperCase().trim());
    }

    /**
     * Validate Indian geographical coordinates
     * India boundaries: Latitude 6.0-37.0, Longitude 68.0-97.0
     */
    public boolean isValidIndianCoordinates(Double latitude, Double longitude) {
        if (latitude == null || longitude == null) {
            return false;
        }
        return latitude >= 6.0 && latitude <= 37.0 &&
               longitude >= 68.0 && longitude <= 97.0;
    }

    /**
     * Validate farm size (reasonable range for Indian farms)
     * Typical range: 0.1 acres to 1000 acres
     */
    public boolean isValidFarmSize(Double farmSize) {
        if (farmSize == null) {
            return false;
        }
        return farmSize >= 0.1 && farmSize <= 1000.0;
    }

    /**
     * Get all valid crop types
     */
    public Set<String> getValidCrops() {
        return VALID_CROPS;
    }

    /**
     * Get all valid seasons
     */
    public Set<String> getValidSeasons() {
        return VALID_SEASONS;
    }

    /**
     * Get all valid states
     */
    public Set<String> getValidStates() {
        return VALID_STATES;
    }

    /**
     * Get crops by season (Indian agricultural calendar)
     */
    public List<String> getCropsBySeason(String season) {
        if (!isValidSeason(season)) {
            return List.of();
        }

        String normalizedSeason = season.toUpperCase().trim();
        
        switch (normalizedSeason) {
            case "KHARIF":
                return List.of("RICE", "COTTON", "SUGARCANE", "MAIZE", "SOYBEAN", 
                              "GROUNDNUT", "PULSES", "TOMATO", "ONION", "CHILLI");
            case "RABI":
                return List.of("WHEAT", "MUSTARD", "BARLEY", "GRAM", "POTATO", 
                              "ONION", "CAULIFLOWER", "CABBAGE", "PEAS");
            case "ZAID":
                return List.of("CUCUMBER", "BITTER_GOURD", "BOTTLE_GOURD", 
                              "MUSKMELON", "WATERMELON", "RIDGE_GOURD");
            default:
                return List.of();
        }
    }

    /**
     * Validate mobile number format (Indian 10-digit starting with 6-9)
     */
    public boolean isValidIndianMobileNumber(String mobileNumber) {
        if (mobileNumber == null || mobileNumber.trim().isEmpty()) {
            return false;
        }
        // Remove any spaces, dashes, or country code
        String cleaned = mobileNumber.trim().replaceAll("[\\s\\-+]", "");
        if (cleaned.startsWith("91") && cleaned.length() == 12) {
            cleaned = cleaned.substring(2);
        }
        // Indian mobile numbers: 10 digits starting with 6, 7, 8, or 9
        return cleaned.matches("^[6-9]\\d{9}$");
    }

    /**
     * Normalize state name to standard format
     */
    public String normalizeStateName(String state) {
        if (state == null || state.trim().isEmpty()) {
            return null;
        }
        return state.toUpperCase().trim().replace(" ", "_");
    }

    /**
     * Normalize crop name to standard format
     */
    public String normalizeCropName(String crop) {
        if (crop == null || crop.trim().isEmpty()) {
            return null;
        }
        return crop.toUpperCase().trim().replace(" ", "_");
    }
}


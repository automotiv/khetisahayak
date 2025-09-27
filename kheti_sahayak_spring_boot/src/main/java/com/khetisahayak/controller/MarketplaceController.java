package com.khetisahayak.controller;

import com.khetisahayak.model.Product;
import com.khetisahayak.service.ProductService;
import com.khetisahayak.service.JwtService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.util.Map;
import java.util.HashMap;

/**
 * Marketplace Controller for Kheti Sahayak Agricultural Platform
 * Handles agricultural product listings, orders, and farmer-to-farmer commerce
 * Implements CodeRabbit security standards for agricultural marketplace operations
 */
@Tag(name = "Marketplace", description = "Agricultural marketplace operations for buying and selling")
@RestController
@RequestMapping("/api/marketplace")
@Validated
public class MarketplaceController {

    @Autowired
    private ProductService productService;

    @Autowired
    private JwtService jwtService;

    /**
     * Create new agricultural product listing
     * Allows farmers and vendors to list their products for sale
     */
    @Operation(summary = "Create product listing", 
               description = "Create new agricultural product listing for marketplace")
    @PostMapping("/products")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR')")
    public ResponseEntity<Map<String, Object>> createProduct(
            @Parameter(description = "Product details including name, category, price, and agricultural specs")
            @RequestBody @Valid Map<String, Object> productData) {
        
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String token = (String) auth.getCredentials();
            Long userId = Long.valueOf(jwtService.extractUserId(token));
            
            Map<String, Object> response = productService.createProduct(userId, productData);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to create product: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Search agricultural products with advanced filtering
     * Supports filtering by category, location, price range, and agricultural attributes
     */
    @Operation(summary = "Search marketplace products", 
               description = "Search agricultural products with filtering by category, location, price, and quality")
    @GetMapping("/products")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR') or hasRole('EXPERT')")
    public ResponseEntity<Map<String, Object>> searchProducts(
            @Parameter(description = "Page number (0-based)")
            @RequestParam(defaultValue = "0") @Min(0) Integer page,
            
            @Parameter(description = "Page size (max 50)")
            @RequestParam(defaultValue = "20") @Min(1) @Max(50) Integer size,
            
            @Parameter(description = "Product category filter")
            @RequestParam(required = false) String category,
            
            @Parameter(description = "State filter for local products")
            @RequestParam(required = false) @Size(max = 50) String state,
            
            @Parameter(description = "District filter")
            @RequestParam(required = false) @Size(max = 50) String district,
            
            @Parameter(description = "Minimum price filter")
            @RequestParam(required = false) @DecimalMin("0.0") BigDecimal minPrice,
            
            @Parameter(description = "Maximum price filter")
            @RequestParam(required = false) @DecimalMin("0.0") BigDecimal maxPrice,
            
            @Parameter(description = "Organic certified products only")
            @RequestParam(required = false) Boolean organic,
            
            @Parameter(description = "Products with home delivery")
            @RequestParam(required = false) Boolean delivery,
            
            @Parameter(description = "Search query for product name")
            @RequestParam(required = false) @Size(max = 100) String search,
            
            @Parameter(description = "Sort by: price, name, date, rating")
            @RequestParam(defaultValue = "date") @Pattern(regexp = "^(price|name|date|rating)$") String sortBy,
            
            @Parameter(description = "Sort direction: asc or desc")
            @RequestParam(defaultValue = "desc") @Pattern(regexp = "^(asc|desc)$") String sortDir) {
        
        try {
            // Create sort configuration
            Sort.Direction direction = sortDir.equalsIgnoreCase("asc") ? Sort.Direction.ASC : Sort.Direction.DESC;
            String sortField = switch (sortBy) {
                case "price" -> "pricePerUnit";
                case "name" -> "name";
                case "rating" -> "averageRating";
                default -> "createdAt";
            };
            
            Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortField));
            
            // Parse category if provided
            Product.ProductCategory categoryEnum = null;
            if (category != null && !category.trim().isEmpty()) {
                try {
                    categoryEnum = Product.ProductCategory.valueOf(category.toUpperCase());
                } catch (IllegalArgumentException e) {
                    return ResponseEntity.badRequest()
                        .body(Map.of("error", "Invalid category: " + category));
                }
            }
            
            Map<String, Object> response = productService.searchProducts(
                categoryEnum, state, district, minPrice, maxPrice, 
                organic, delivery, search, pageable
            );
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to search products: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Get specific agricultural product details by ID
     * Provides comprehensive product information including seller details and agricultural specs
     */
    @Operation(summary = "Get product details", 
               description = "Retrieve detailed information about a specific agricultural product")
    @GetMapping("/products/{id}")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR') or hasRole('EXPERT')")
    public ResponseEntity<Map<String, Object>> getProductById(
            @Parameter(description = "Product ID")
            @PathVariable @Positive Long id) {
        
        try {
            Map<String, Object> product = productService.getProduct(id);
            return ResponseEntity.ok(product);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Product not found: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        }
    }

    /**
     * Update existing product listing
     * Allows sellers to update their product information
     */
    @Operation(summary = "Update product listing", 
               description = "Update existing agricultural product listing")
    @PutMapping("/products/{id}")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR')")
    public ResponseEntity<Map<String, Object>> updateProduct(
            @Parameter(description = "Product ID")
            @PathVariable @Positive Long id,
            
            @Parameter(description = "Updated product information")
            @RequestBody @Valid Map<String, Object> updateData) {
        
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String token = (String) auth.getCredentials();
            Long userId = Long.valueOf(jwtService.extractUserId(token));
            
            Map<String, Object> response = productService.updateProduct(id, userId, updateData);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to update product: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Delete product listing
     * Allows sellers to remove their products from marketplace
     */
    @Operation(summary = "Delete product listing", 
               description = "Remove agricultural product from marketplace")
    @DeleteMapping("/products/{id}")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR')")
    public ResponseEntity<Map<String, Object>> deleteProduct(
            @Parameter(description = "Product ID")
            @PathVariable @Positive Long id) {
        
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String token = (String) auth.getCredentials();
            Long userId = Long.valueOf(jwtService.extractUserId(token));
            
            Map<String, Object> response = productService.deleteProduct(id, userId);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to delete product: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    /**
     * Get seller's product listings
     * Returns all products listed by the authenticated seller
     */
    @Operation(summary = "Get seller products", 
               description = "Retrieve all products listed by the authenticated seller")
    @GetMapping("/my-products")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR')")
    public ResponseEntity<Map<String, Object>> getMyProducts(
            @Parameter(description = "Page number (0-based)")
            @RequestParam(defaultValue = "0") @Min(0) Integer page,
            
            @Parameter(description = "Page size (max 50)")
            @RequestParam(defaultValue = "20") @Min(1) @Max(50) Integer size) {
        
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String token = (String) auth.getCredentials();
            Long userId = Long.valueOf(jwtService.extractUserId(token));
            
            Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
            Map<String, Object> response = productService.getSellerProducts(userId, pageable);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to retrieve products: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Find products near location
     * Search for agricultural products within specified radius
     */
    @Operation(summary = "Find products near location", 
               description = "Search for agricultural products within specified radius of coordinates")
    @GetMapping("/products/near")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR') or hasRole('EXPERT')")
    public ResponseEntity<Map<String, Object>> getProductsNearLocation(
            @Parameter(description = "Latitude")
            @RequestParam @DecimalMin("-90.0") @DecimalMax("90.0") Double latitude,
            
            @Parameter(description = "Longitude")
            @RequestParam @DecimalMin("-180.0") @DecimalMax("180.0") Double longitude,
            
            @Parameter(description = "Search radius in kilometers")
            @RequestParam(defaultValue = "50.0") @DecimalMin("1.0") @DecimalMax("500.0") Double radiusKm,
            
            @Parameter(description = "Page number (0-based)")
            @RequestParam(defaultValue = "0") @Min(0) Integer page,
            
            @Parameter(description = "Page size (max 50)")
            @RequestParam(defaultValue = "20") @Min(1) @Max(50) Integer size) {
        
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
            Map<String, Object> response = productService.getProductsNearLocation(
                latitude, longitude, radiusKm, pageable
            );
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to find nearby products: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Get featured agricultural products
     * Returns curated list of high-quality products
     */
    @Operation(summary = "Get featured products", 
               description = "Retrieve featured agricultural products with high ratings and quality")
    @GetMapping("/products/featured")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR') or hasRole('EXPERT')")
    public ResponseEntity<Map<String, Object>> getFeaturedProducts(
            @Parameter(description = "Page number (0-based)")
            @RequestParam(defaultValue = "0") @Min(0) Integer page,
            
            @Parameter(description = "Page size (max 50)")
            @RequestParam(defaultValue = "20") @Min(1) @Max(50) Integer size) {
        
        try {
            Pageable pageable = PageRequest.of(page, size);
            Map<String, Object> response = productService.getFeaturedProducts(pageable);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to retrieve featured products: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Get agricultural product categories
     * Returns all available product categories with statistics
     */
    @Operation(summary = "Get product categories", 
               description = "Retrieve all available agricultural product categories with counts")
    @GetMapping("/categories")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR') or hasRole('EXPERT')")
    public ResponseEntity<Map<String, Object>> getProductCategories() {
        
        try {
            Map<String, Object> response = productService.getProductCategories();
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to retrieve categories: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Get marketplace statistics
     * Returns comprehensive marketplace analytics and insights
     */
    @Operation(summary = "Get marketplace statistics", 
               description = "Retrieve marketplace analytics including product counts and pricing insights")
    @GetMapping("/statistics")
    @PreAuthorize("hasRole('ADMIN') or hasRole('EXPERT')")
    public ResponseEntity<Map<String, Object>> getMarketplaceStatistics() {
        
        try {
            Map<String, Object> response = productService.getMarketplaceStatistics();
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to retrieve statistics: " + e.getMessage());
            errorResponse.put("timestamp", System.currentTimeMillis());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Get units of measurement for agricultural products
     * Returns standardized units used in Indian agriculture
     */
    @Operation(summary = "Get measurement units", 
               description = "Retrieve available units of measurement for agricultural products")
    @GetMapping("/units")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR')")
    public ResponseEntity<Map<String, Object>> getMeasurementUnits() {
        
        Map<String, Object> response = new HashMap<>();
        Map<String, String> units = new HashMap<>();
        
        for (Product.UnitOfMeasurement unit : Product.UnitOfMeasurement.values()) {
            units.put(unit.toString(), unit.getDisplayName());
        }
        
        response.put("units", units);
        response.put("timestamp", System.currentTimeMillis());
        
        return ResponseEntity.ok(response);
    }

    /**
     * Get quality grades for agricultural products
     * Returns available quality classifications
     */
    @Operation(summary = "Get quality grades", 
               description = "Retrieve available quality grades for agricultural products")
    @GetMapping("/quality-grades")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR')")
    public ResponseEntity<Map<String, Object>> getQualityGrades() {
        
        Map<String, Object> response = new HashMap<>();
        Map<String, String> grades = new HashMap<>();
        
        for (Product.QualityGrade grade : Product.QualityGrade.values()) {
            grades.put(grade.toString(), grade.getDisplayName());
        }
        
        response.put("qualityGrades", grades);
        response.put("timestamp", System.currentTimeMillis());
        
        return ResponseEntity.ok(response);
    }
}
package com.khetisahayak.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Marketplace Controller for Kheti Sahayak Agricultural Platform
 * Handles agricultural product listings, orders, and farmer-to-farmer commerce
 * Implements secure marketplace operations for Indian agricultural products
 */
@Tag(name = "Marketplace", description = "Agricultural marketplace operations for buying and selling")
@RestController
@RequestMapping("/api/marketplace")
@Validated
public class MarketplaceController {

    /**
     * Get all agricultural products with filtering and pagination
     * Supports search by crop type, location, and price range
     */
    @Operation(summary = "Get marketplace products", 
               description = "Retrieve agricultural products with filtering and pagination")
    @GetMapping("/products")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR')")
    public ResponseEntity<Map<String, Object>> getProducts(
            @Parameter(description = "Page number (0-based)")
            @RequestParam(defaultValue = "0") @Min(0) Integer page,
            
            @Parameter(description = "Page size (max 50)")
            @RequestParam(defaultValue = "20") @Min(1) @Max(50) Integer size,
            
            @Parameter(description = "Product category filter")
            @RequestParam(required = false) String category,
            
            @Parameter(description = "Search query for product name")
            @RequestParam(required = false) @Size(max = 100) String search,
            
            @Parameter(description = "State filter for local products")
            @RequestParam(required = false) @Size(max = 50) String state,
            
            @Parameter(description = "Minimum price filter")
            @RequestParam(required = false) @DecimalMin("0.0") BigDecimal minPrice,
            
            @Parameter(description = "Maximum price filter")
            @RequestParam(required = false) @DecimalMin("0.0") BigDecimal maxPrice,
            
            @Parameter(description = "Sort by: price, name, date, rating")
            @RequestParam(defaultValue = "date") @Pattern(regexp = "^(price|name|date|rating)$") String sortBy,
            
            @Parameter(description = "Sort direction: asc or desc")
            @RequestParam(defaultValue = "desc") @Pattern(regexp = "^(asc|desc)$") String sortDir) {
        
        // Mock product data for agricultural marketplace
        List<Map<String, Object>> products = generateMockProducts(page, size, category, search, state);
        
        Map<String, Object> response = new HashMap<>();
        response.put("content", products);
        response.put("page", page);
        response.put("size", size);
        response.put("totalElements", products.size() * 5); // Simulate more products
        response.put("totalPages", 5);
        response.put("filters", Map.of(
            "category", category,
            "search", search,
            "state", state,
            "priceRange", Map.of("min", minPrice, "max", maxPrice)
        ));
        
        return ResponseEntity.ok(response);
    }

    /**
     * Get specific product details by ID
     * Provides comprehensive agricultural product information
     */
    @Operation(summary = "Get product details", 
               description = "Retrieve detailed information about a specific agricultural product")
    @GetMapping("/products/{id}")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR')")
    public ResponseEntity<Map<String, Object>> getProductById(
            @Parameter(description = "Product ID")
            @PathVariable @Positive Long id) {
        
        Map<String, Object> product = new HashMap<>();
        product.put("id", id);
        product.put("name", "Premium Basmati Rice Seeds");
        product.put("category", "SEEDS");
        product.put("variety", "Pusa Basmati 1121");
        product.put("description", "High-yield, disease-resistant basmati rice seeds suitable for Kharif season");
        product.put("price", BigDecimal.valueOf(2500.00));
        product.put("unit", "KG");
        product.put("minimumOrder", BigDecimal.valueOf(5.0));
        product.put("availableQuantity", BigDecimal.valueOf(1000.0));
        product.put("qualityGrade", "PREMIUM");
        product.put("isOrganic", false);
        product.put("origin", "Punjab");
        product.put("harvestSeason", "Kharif");
        product.put("shelfLife", "12 months");
        product.put("certification", "IARI Certified");
        
        // Seller information
        Map<String, Object> seller = new HashMap<>();
        seller.put("id", "vendor_123");
        seller.put("name", "Green Valley Seeds");
        seller.put("rating", 4.5);
        seller.put("totalSales", 250);
        seller.put("location", "Ludhiana, Punjab");
        seller.put("verified", true);
        
        product.put("seller", seller);
        
        // Agricultural specifications
        Map<String, Object> specifications = new HashMap<>();
        specifications.put("seedRate", "20-25 kg per acre");
        specifications.put("sowingDepth", "2-3 cm");
        specifications.put("spacing", "20 cm between rows");
        specifications.put("maturityPeriod", "120-130 days");
        specifications.put("expectedYield", "25-30 quintals per acre");
        specifications.put("soilType", "Well-drained loamy soil");
        specifications.put("waterRequirement", "1200-1500 mm");
        
        product.put("specifications", specifications);
        
        return ResponseEntity.ok(product);
    }

    /**
     * Create new order for agricultural products
     * Handles farmer purchase orders with agricultural context
     */
    @Operation(summary = "Create marketplace order", 
               description = "Create new order for agricultural products")
    @PostMapping("/orders")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<Map<String, Object>> createOrder(
            @Parameter(description = "Order details with items and delivery information")
            @RequestBody @Valid Map<String, Object> orderData) {
        
        // Validate order data
        List<Map<String, Object>> items = (List<Map<String, Object>>) orderData.get("items");
        if (items == null || items.isEmpty()) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", "Order must contain at least one item"));
        }
        
        // Generate order
        String orderNumber = "KS" + System.currentTimeMillis();
        Map<String, Object> order = new HashMap<>();
        order.put("orderNumber", orderNumber);
        order.put("status", "PENDING");
        order.put("paymentStatus", "PENDING");
        order.put("items", items);
        order.put("totalAmount", calculateOrderTotal(items));
        order.put("currency", "INR");
        order.put("deliveryAddress", orderData.get("deliveryAddress"));
        order.put("contactNumber", orderData.get("contactNumber"));
        order.put("orderNotes", orderData.get("orderNotes"));
        order.put("expectedDeliveryDays", 3);
        order.put("createdAt", LocalDateTime.now());
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Order created successfully");
        response.put("order", order);
        response.put("paymentUrl", "/api/marketplace/orders/" + orderNumber + "/payment");
        
        return ResponseEntity.ok(response);
    }

    /**
     * Get farmer's order history
     * Returns paginated list of agricultural product orders
     */
    @Operation(summary = "Get order history", 
               description = "Retrieve farmer's marketplace order history")
    @GetMapping("/orders")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<Map<String, Object>> getOrderHistory(
            @Parameter(description = "Page number (0-based)")
            @RequestParam(defaultValue = "0") @Min(0) Integer page,
            
            @Parameter(description = "Page size (max 50)")
            @RequestParam(defaultValue = "20") @Min(1) @Max(50) Integer size,
            
            @Parameter(description = "Order status filter")
            @RequestParam(required = false) String status) {
        
        List<Map<String, Object>> orders = generateMockOrders(page, size, status);
        
        Map<String, Object> response = new HashMap<>();
        response.put("content", orders);
        response.put("page", page);
        response.put("size", size);
        response.put("totalElements", orders.size() * 3);
        response.put("totalPages", 3);
        
        return ResponseEntity.ok(response);
    }

    /**
     * Get specific order details by order number
     */
    @Operation(summary = "Get order details", 
               description = "Retrieve detailed information about a specific order")
    @GetMapping("/orders/{orderNumber}")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR')")
    public ResponseEntity<Map<String, Object>> getOrderDetails(
            @Parameter(description = "Order number")
            @PathVariable @Pattern(regexp = "^KS\\d+$") String orderNumber) {
        
        Map<String, Object> order = new HashMap<>();
        order.put("orderNumber", orderNumber);
        order.put("status", "CONFIRMED");
        order.put("paymentStatus", "COMPLETED");
        order.put("totalAmount", BigDecimal.valueOf(5250.00));
        order.put("currency", "INR");
        order.put("createdAt", LocalDateTime.now().minusDays(2));
        order.put("expectedDeliveryDate", LocalDateTime.now().plusDays(1));
        
        // Order items
        List<Map<String, Object>> items = new ArrayList<>();
        Map<String, Object> item = new HashMap<>();
        item.put("productName", "Premium Basmati Rice Seeds");
        item.put("quantity", BigDecimal.valueOf(10.0));
        item.put("unit", "KG");
        item.put("unitPrice", BigDecimal.valueOf(525.00));
        item.put("totalPrice", BigDecimal.valueOf(5250.00));
        items.add(item);
        
        order.put("items", items);
        
        return ResponseEntity.ok(order);
    }

    /**
     * Cancel marketplace order
     */
    @Operation(summary = "Cancel order", 
               description = "Cancel marketplace order before processing")
    @PutMapping("/orders/{orderNumber}/cancel")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<Map<String, Object>> cancelOrder(
            @Parameter(description = "Order number to cancel")
            @PathVariable @Pattern(regexp = "^KS\\d+$") String orderNumber,
            
            @Parameter(description = "Cancellation reason")
            @RequestParam @NotBlank @Size(max = 500) String reason) {
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Order cancelled successfully");
        response.put("orderNumber", orderNumber);
        response.put("cancellationReason", reason);
        response.put("refundStatus", "PROCESSING");
        response.put("refundAmount", BigDecimal.valueOf(5250.00));
        response.put("cancelledAt", LocalDateTime.now());
        
        return ResponseEntity.ok(response);
    }

    /**
     * Get product categories for agricultural marketplace
     */
    @Operation(summary = "Get product categories", 
               description = "Retrieve all available agricultural product categories")
    @GetMapping("/categories")
    @PreAuthorize("hasRole('FARMER') or hasRole('VENDOR')")
    public ResponseEntity<List<Map<String, Object>>> getProductCategories() {
        
        List<Map<String, Object>> categories = new ArrayList<>();
        
        String[] categoryNames = {"SEEDS", "FERTILIZERS", "PESTICIDES", "TOOLS", 
                                "FRESH_PRODUCE", "GRAINS", "IRRIGATION", "MACHINERY"};
        String[] categoryDescriptions = {
            "Seeds and planting materials for all crops",
            "Chemical and organic fertilizers",
            "Pest control and plant protection products",
            "Farming tools and hand implements",
            "Fresh fruits and vegetables",
            "Cereals, pulses, and grains",
            "Irrigation equipment and systems",
            "Agricultural machinery and equipment"
        };
        
        for (int i = 0; i < categoryNames.length; i++) {
            Map<String, Object> category = new HashMap<>();
            category.put("name", categoryNames[i]);
            category.put("displayName", categoryNames[i].replace("_", " "));
            category.put("description", categoryDescriptions[i]);
            category.put("productCount", 50 + (int)(Math.random() * 200));
            category.put("icon", categoryNames[i].toLowerCase() + "_icon.png");
            categories.add(category);
        }
        
        return ResponseEntity.ok(categories);
    }

    /**
     * Helper method to generate mock products for development
     */
    private List<Map<String, Object>> generateMockProducts(int page, int size, String category, String search, String state) {
        List<Map<String, Object>> products = new ArrayList<>();
        
        String[] productNames = {
            "Premium Basmati Rice Seeds", "Organic Wheat Seeds", "Hybrid Cotton Seeds",
            "NPK Fertilizer 10:26:26", "Organic Compost", "Pesticide Spray",
            "Drip Irrigation Kit", "Solar Water Pump", "Fresh Tomatoes",
            "Quality Onions", "Farm Tools Set", "Tractor Attachment"
        };
        
        String[] categories = {"SEEDS", "FERTILIZERS", "PESTICIDES", "IRRIGATION", "FRESH_PRODUCE", "TOOLS"};
        String[] states = {"Maharashtra", "Punjab", "Haryana", "Gujarat", "Karnataka"};
        
        for (int i = 0; i < size; i++) {
            Map<String, Object> product = new HashMap<>();
            product.put("id", (long) (page * size + i + 1));
            product.put("name", productNames[i % productNames.length]);
            product.put("category", categories[i % categories.length]);
            product.put("price", BigDecimal.valueOf(500 + (Math.random() * 2000)));
            product.put("unit", "KG");
            product.put("seller", Map.of(
                "name", "Farmer " + (i + 1),
                "location", states[i % states.length],
                "rating", 4.0 + (Math.random() * 1.0),
                "verified", true
            ));
            product.put("availableQuantity", BigDecimal.valueOf(10 + (Math.random() * 90)));
            product.put("qualityGrade", "GRADE_A");
            product.put("isOrganic", Math.random() > 0.7);
            product.put("imageUrl", "/images/products/product_" + (i + 1) + ".jpg");
            product.put("inStock", true);
            products.add(product);
        }
        
        return products;
    }

    /**
     * Helper method to generate mock orders for development
     */
    private List<Map<String, Object>> generateMockOrders(int page, int size, String status) {
        List<Map<String, Object>> orders = new ArrayList<>();
        
        String[] statuses = {"PENDING", "CONFIRMED", "SHIPPED", "DELIVERED", "CANCELLED"};
        
        for (int i = 0; i < size; i++) {
            Map<String, Object> order = new HashMap<>();
            order.put("orderNumber", "KS" + (System.currentTimeMillis() - i * 1000));
            order.put("status", statuses[i % statuses.length]);
            order.put("paymentStatus", "COMPLETED");
            order.put("totalAmount", BigDecimal.valueOf(1000 + (Math.random() * 5000)));
            order.put("currency", "INR");
            order.put("itemCount", 1 + (int)(Math.random() * 3));
            order.put("createdAt", LocalDateTime.now().minusDays(i));
            order.put("seller", Map.of(
                "name", "Agricultural Supplier " + (i + 1),
                "location", "Maharashtra"
            ));
            orders.add(order);
        }
        
        return orders;
    }

    /**
     * Calculate total order amount from items
     */
    private BigDecimal calculateOrderTotal(List<Map<String, Object>> items) {
        return items.stream()
            .map(item -> {
                BigDecimal quantity = new BigDecimal(item.get("quantity").toString());
                BigDecimal price = new BigDecimal(item.get("unitPrice").toString());
                return quantity.multiply(price);
            })
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}

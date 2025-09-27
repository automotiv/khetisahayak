package com.khetisahayak.service;

import com.khetisahayak.model.Product;
import com.khetisahayak.model.User;
import com.khetisahayak.repository.ProductRepository;
import com.khetisahayak.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Product Service for Kheti Sahayak Agricultural Marketplace
 * Handles business logic for agricultural product management
 * Implements CodeRabbit business logic standards for agricultural commerce
 */
@Service
@Transactional
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * Create a new product listing
     */
    public Map<String, Object> createProduct(Long sellerId, Map<String, Object> productData) {
        try {
            User seller = userRepository.findById(sellerId)
                .orElseThrow(() -> new RuntimeException("Seller not found"));

            // Validate seller can list products
            if (seller.getUserType() != User.UserType.FARMER && 
                seller.getUserType() != User.UserType.VENDOR) {
                throw new RuntimeException("Only farmers and vendors can list products");
            }

            Product product = new Product();
            product.setSeller(seller);
            
            // Set basic product information
            product.setName((String) productData.get("name"));
            product.setDescription((String) productData.get("description"));
            
            // Set category
            String categoryStr = (String) productData.get("category");
            product.setCategory(Product.ProductCategory.valueOf(categoryStr));
            product.setSubcategory((String) productData.get("subcategory"));
            
            // Set pricing
            BigDecimal price = new BigDecimal(productData.get("pricePerUnit").toString());
            product.setPricePerUnit(price);
            
            String unitStr = (String) productData.get("unitOfMeasurement");
            if (unitStr != null) {
                product.setUnitOfMeasurement(Product.UnitOfMeasurement.valueOf(unitStr));
            }
            
            // Set stock information
            product.setAvailableQuantity((Integer) productData.get("availableQuantity"));
            if (productData.containsKey("minimumOrderQuantity")) {
                product.setMinimumOrderQuantity((Integer) productData.get("minimumOrderQuantity"));
            }
            
            // Set quality information
            if (productData.containsKey("qualityGrade")) {
                String gradeStr = (String) productData.get("qualityGrade");
                product.setQualityGrade(Product.QualityGrade.valueOf(gradeStr));
            }
            
            Boolean isOrganic = (Boolean) productData.get("isOrganicCertified");
            if (isOrganic != null) {
                product.setIsOrganicCertified(isOrganic);
            }
            
            product.setCertificationBody((String) productData.get("certificationBody"));
            
            // Set agricultural details
            if (productData.containsKey("harvestDate")) {
                product.setHarvestDate(LocalDate.parse((String) productData.get("harvestDate")));
            }
            if (productData.containsKey("expiryDate")) {
                product.setExpiryDate(LocalDate.parse((String) productData.get("expiryDate")));
            }
            
            product.setVariety((String) productData.get("variety"));
            product.setSeason((String) productData.get("season"));
            
            // Set location (use seller's location as default)
            product.setState(seller.getState());
            product.setDistrict(seller.getDistrict());
            product.setVillage(seller.getVillage());
            product.setPincode((String) productData.get("pincode"));
            
            // Set delivery preferences
            Boolean allowsDelivery = (Boolean) productData.get("allowsHomeDelivery");
            if (allowsDelivery != null) {
                product.setAllowsHomeDelivery(allowsDelivery);
            }
            
            if (productData.containsKey("deliveryChargePerKm")) {
                BigDecimal deliveryCharge = new BigDecimal(productData.get("deliveryChargePerKm").toString());
                product.setDeliveryChargePerKm(deliveryCharge);
            }
            
            if (productData.containsKey("maxDeliveryDistanceKm")) {
                product.setMaxDeliveryDistanceKm((Integer) productData.get("maxDeliveryDistanceKm"));
            }
            
            // Set other preferences
            Boolean negotiable = (Boolean) productData.get("isNegotiable");
            if (negotiable != null) {
                product.setIsNegotiable(negotiable);
            }
            
            Boolean onlinePayment = (Boolean) productData.get("acceptsOnlinePayment");
            if (onlinePayment != null) {
                product.setAcceptsOnlinePayment(onlinePayment);
            }
            
            // Set image URLs if provided
            @SuppressWarnings("unchecked")
            List<String> imageUrls = (List<String>) productData.get("imageUrls");
            if (imageUrls != null) {
                product.setImageUrls(imageUrls);
            }
            
            // Set initial status
            product.setStatus(Product.ProductStatus.ACTIVE);
            product.setCreatedAt(LocalDateTime.now());
            product.setUpdatedAt(LocalDateTime.now());
            
            Product savedProduct = productRepository.save(product);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Product listed successfully");
            response.put("productId", savedProduct.getId());
            response.put("status", savedProduct.getStatus());
            response.put("product", createProductResponseMap(savedProduct));
            
            return response;
            
        } catch (Exception e) {
            throw new RuntimeException("Failed to create product: " + e.getMessage());
        }
    }

    /**
     * Update existing product
     */
    public Map<String, Object> updateProduct(Long productId, Long sellerId, Map<String, Object> updateData) {
        Product product = productRepository.findById(productId)
            .orElseThrow(() -> new RuntimeException("Product not found"));
        
        // Verify seller ownership
        if (!product.getSeller().getId().equals(sellerId)) {
            throw new RuntimeException("Unauthorized: You can only update your own products");
        }
        
        // Update allowed fields
        if (updateData.containsKey("name")) {
            product.setName((String) updateData.get("name"));
        }
        if (updateData.containsKey("description")) {
            product.setDescription((String) updateData.get("description"));
        }
        if (updateData.containsKey("pricePerUnit")) {
            BigDecimal price = new BigDecimal(updateData.get("pricePerUnit").toString());
            product.setPricePerUnit(price);
        }
        if (updateData.containsKey("availableQuantity")) {
            Integer quantity = (Integer) updateData.get("availableQuantity");
            product.setAvailableQuantity(quantity);
            
            // Update status based on quantity
            if (quantity > 0 && product.getStatus() == Product.ProductStatus.OUT_OF_STOCK) {
                product.setStatus(Product.ProductStatus.ACTIVE);
            } else if (quantity == 0) {
                product.setStatus(Product.ProductStatus.OUT_OF_STOCK);
            }
        }
        if (updateData.containsKey("isNegotiable")) {
            product.setIsNegotiable((Boolean) updateData.get("isNegotiable"));
        }
        if (updateData.containsKey("allowsHomeDelivery")) {
            product.setAllowsHomeDelivery((Boolean) updateData.get("allowsHomeDelivery"));
        }
        
        product.setUpdatedAt(LocalDateTime.now());
        Product updatedProduct = productRepository.save(product);
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Product updated successfully");
        response.put("product", createProductResponseMap(updatedProduct));
        
        return response;
    }

    /**
     * Get product details by ID
     */
    public Map<String, Object> getProduct(Long productId) {
        Product product = productRepository.findById(productId)
            .orElseThrow(() -> new RuntimeException("Product not found"));
        
        // Update last active time
        productRepository.updateLastActiveTime(productId, LocalDateTime.now());
        
        return createDetailedProductResponseMap(product);
    }

    /**
     * Search products with filters
     */
    public Map<String, Object> searchProducts(
            Product.ProductCategory category,
            String state,
            String district,
            BigDecimal minPrice,
            BigDecimal maxPrice,
            Boolean organic,
            Boolean delivery,
            String searchTerm,
            Pageable pageable) {
        
        Page<Product> productsPage = productRepository.findWithFilters(
            category, state, district, minPrice, maxPrice, 
            organic, delivery, searchTerm, pageable
        );
        
        Map<String, Object> response = new HashMap<>();
        response.put("products", productsPage.getContent().stream()
            .map(this::createProductResponseMap).toList());
        response.put("totalElements", productsPage.getTotalElements());
        response.put("totalPages", productsPage.getTotalPages());
        response.put("currentPage", productsPage.getNumber());
        response.put("pageSize", productsPage.getSize());
        
        return response;
    }

    /**
     * Get products by seller
     */
    public Map<String, Object> getSellerProducts(Long sellerId, Pageable pageable) {
        User seller = userRepository.findById(sellerId)
            .orElseThrow(() -> new RuntimeException("Seller not found"));
        
        Page<Product> productsPage = productRepository.findBySeller(seller, pageable);
        
        Map<String, Object> response = new HashMap<>();
        response.put("products", productsPage.getContent().stream()
            .map(this::createProductResponseMap).toList());
        response.put("totalElements", productsPage.getTotalElements());
        response.put("totalPages", productsPage.getTotalPages());
        response.put("seller", createSellerInfoMap(seller));
        
        return response;
    }

    /**
     * Get products near location
     */
    public Map<String, Object> getProductsNearLocation(
            Double latitude, 
            Double longitude, 
            Double radiusKm, 
            Pageable pageable) {
        
        Page<Product> productsPage = productRepository.findProductsNearLocation(
            latitude, longitude, radiusKm, pageable
        );
        
        Map<String, Object> response = new HashMap<>();
        response.put("products", productsPage.getContent().stream()
            .map(this::createProductResponseMap).toList());
        response.put("totalElements", productsPage.getTotalElements());
        response.put("searchLocation", Map.of("latitude", latitude, "longitude", longitude));
        response.put("radiusKm", radiusKm);
        
        return response;
    }

    /**
     * Get featured products
     */
    public Map<String, Object> getFeaturedProducts(Pageable pageable) {
        Page<Product> productsPage = productRepository.findByIsFeaturedTrueAndStatus(
            Product.ProductStatus.ACTIVE, pageable
        );
        
        Map<String, Object> response = new HashMap<>();
        response.put("products", productsPage.getContent().stream()
            .map(this::createProductResponseMap).toList());
        response.put("totalElements", productsPage.getTotalElements());
        
        return response;
    }

    /**
     * Get marketplace statistics
     */
    public Map<String, Object> getMarketplaceStatistics() {
        Map<String, Object> stats = new HashMap<>();
        
        // Product counts by category
        List<Object[]> categoryStats = productRepository.getProductStatsByCategory();
        Map<String, Map<String, Object>> categoryData = new HashMap<>();
        for (Object[] stat : categoryStats) {
            Product.ProductCategory category = (Product.ProductCategory) stat[0];
            Long count = (Long) stat[1];
            BigDecimal avgPrice = (BigDecimal) stat[2];
            
            Map<String, Object> categoryInfo = new HashMap<>();
            categoryInfo.put("count", count);
            categoryInfo.put("averagePrice", avgPrice);
            categoryData.put(category.toString(), categoryInfo);
        }
        stats.put("productsByCategory", categoryData);
        
        // Product counts by state
        List<Object[]> stateStats = productRepository.getProductStatsByState();
        Map<String, Map<String, Object>> stateData = new HashMap<>();
        for (Object[] stat : stateStats) {
            String state = (String) stat[0];
            Long count = (Long) stat[1];
            BigDecimal avgPrice = (BigDecimal) stat[2];
            
            Map<String, Object> stateInfo = new HashMap<>();
            stateInfo.put("count", count);
            stateInfo.put("averagePrice", avgPrice);
            stateData.put(state, stateInfo);
        }
        stats.put("productsByState", stateData);
        
        // Total counts
        stats.put("totalActiveProducts", productRepository.countByStatus(Product.ProductStatus.ACTIVE));
        stats.put("totalOutOfStock", productRepository.countByStatus(Product.ProductStatus.OUT_OF_STOCK));
        
        return stats;
    }

    /**
     * Update product stock after sale
     */
    public void updateProductStock(Long productId, int quantitySold) {
        Product product = productRepository.findById(productId)
            .orElseThrow(() -> new RuntimeException("Product not found"));
        
        product.updateStockAfterSale(quantitySold);
        productRepository.save(product);
    }

    /**
     * Delete product (soft delete by changing status)
     */
    public Map<String, Object> deleteProduct(Long productId, Long sellerId) {
        Product product = productRepository.findById(productId)
            .orElseThrow(() -> new RuntimeException("Product not found"));
        
        // Verify seller ownership
        if (!product.getSeller().getId().equals(sellerId)) {
            throw new RuntimeException("Unauthorized: You can only delete your own products");
        }
        
        product.setStatus(Product.ProductStatus.INACTIVE);
        product.setUpdatedAt(LocalDateTime.now());
        productRepository.save(product);
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Product deleted successfully");
        response.put("productId", productId);
        
        return response;
    }

    /**
     * Get product categories with statistics
     */
    public Map<String, Object> getProductCategories() {
        Map<String, Object> response = new HashMap<>();
        
        Product.ProductCategory[] categories = Product.ProductCategory.values();
        Map<String, Object> categoryInfo = new HashMap<>();
        
        for (Product.ProductCategory category : categories) {
            Map<String, Object> info = new HashMap<>();
            info.put("name", category.getDisplayName());
            info.put("value", category.toString());
            
            // Get count for this category
            Page<Product> categoryProducts = productRepository.findByCategoryAndStatus(
                category, Product.ProductStatus.ACTIVE, Pageable.unpaged()
            );
            info.put("productCount", categoryProducts.getTotalElements());
            
            categoryInfo.put(category.toString(), info);
        }
        
        response.put("categories", categoryInfo);
        return response;
    }

    /**
     * Helper method to create product response map
     */
    private Map<String, Object> createProductResponseMap(Product product) {
        Map<String, Object> productMap = new HashMap<>();
        productMap.put("id", product.getId());
        productMap.put("name", product.getName());
        productMap.put("description", product.getDescription());
        productMap.put("category", product.getCategory());
        productMap.put("subcategory", product.getSubcategory());
        productMap.put("pricePerUnit", product.getPricePerUnit());
        productMap.put("unitOfMeasurement", product.getUnitOfMeasurement());
        productMap.put("availableQuantity", product.getAvailableQuantity());
        productMap.put("qualityGrade", product.getQualityGrade());
        productMap.put("isOrganicCertified", product.getIsOrganicCertified());
        productMap.put("location", Map.of(
            "state", product.getState(),
            "district", product.getDistrict(),
            "village", product.getVillage()
        ));
        productMap.put("imageUrls", product.getImageUrls());
        productMap.put("status", product.getStatus());
        productMap.put("averageRating", product.getAverageRating());
        productMap.put("totalReviews", product.getTotalReviews());
        productMap.put("createdAt", product.getCreatedAt());
        
        return productMap;
    }

    /**
     * Helper method to create detailed product response map
     */
    private Map<String, Object> createDetailedProductResponseMap(Product product) {
        Map<String, Object> productMap = createProductResponseMap(product);
        
        // Add seller information
        productMap.put("seller", createSellerInfoMap(product.getSeller()));
        
        // Add detailed agricultural information
        productMap.put("harvestDate", product.getHarvestDate());
        productMap.put("expiryDate", product.getExpiryDate());
        productMap.put("variety", product.getVariety());
        productMap.put("season", product.getSeason());
        productMap.put("certificationBody", product.getCertificationBody());
        
        // Add delivery information
        productMap.put("allowsHomeDelivery", product.getAllowsHomeDelivery());
        productMap.put("deliveryChargePerKm", product.getDeliveryChargePerKm());
        productMap.put("maxDeliveryDistanceKm", product.getMaxDeliveryDistanceKm());
        
        // Add additional preferences
        productMap.put("isNegotiable", product.getIsNegotiable());
        productMap.put("acceptsOnlinePayment", product.getAcceptsOnlinePayment());
        productMap.put("minimumOrderQuantity", product.getMinimumOrderQuantity());
        productMap.put("totalSales", product.getTotalSales());
        
        return productMap;
    }

    /**
     * Helper method to create seller info map
     */
    private Map<String, Object> createSellerInfoMap(User seller) {
        Map<String, Object> sellerMap = new HashMap<>();
        sellerMap.put("id", seller.getId());
        sellerMap.put("name", seller.getFullName());
        sellerMap.put("userType", seller.getUserType());
        sellerMap.put("location", Map.of(
            "state", seller.getState(),
            "district", seller.getDistrict(),
            "village", seller.getVillage()
        ));
        sellerMap.put("isVerified", seller.getIsVerified());
        
        return sellerMap;
    }
}

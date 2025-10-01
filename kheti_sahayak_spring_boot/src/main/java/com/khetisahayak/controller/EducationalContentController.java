package com.khetisahayak.controller;

import com.khetisahayak.model.EducationalContent;
import com.khetisahayak.service.EducationalContentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Educational Content Controller for Kheti Sahayak Agricultural Platform
 * Provides access to agricultural knowledge base and learning resources
 * Implements CodeRabbit standards for agricultural education content delivery
 */
@Tag(name = "Educational Content", description = "Agricultural educational content and knowledge base APIs")
@RestController
@RequestMapping("/api/education")
@CrossOrigin(origins = "*")
public class EducationalContentController {

    private final EducationalContentService contentService;

    @Autowired
    public EducationalContentController(EducationalContentService contentService) {
        this.contentService = contentService;
    }

    @Operation(summary = "Get all published educational content", 
               description = "Retrieve all published agricultural educational content with pagination")
    @GetMapping("/content")
    public ResponseEntity<Map<String, Object>> getAllContent(
            @Parameter(description = "Page number (0-indexed)") @RequestParam(defaultValue = "0") int page,
            @Parameter(description = "Page size") @RequestParam(defaultValue = "10") int size,
            @Parameter(description = "Sort field") @RequestParam(defaultValue = "publishedAt") String sortBy,
            @Parameter(description = "Sort direction (asc/desc)") @RequestParam(defaultValue = "desc") String sortDir) {
        
        try {
            Sort sort = sortDir.equalsIgnoreCase("asc") ? Sort.by(sortBy).ascending() : Sort.by(sortBy).descending();
            Pageable pageable = PageRequest.of(page, size, sort);
            
            Page<EducationalContent> contentPage = contentService.getAllPublishedContent(pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", contentPage.getContent());
            response.put("currentPage", contentPage.getNumber());
            response.put("totalItems", contentPage.getTotalElements());
            response.put("totalPages", contentPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch educational content");
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get content by ID", 
               description = "Retrieve specific educational content by ID and increment view count")
    @GetMapping("/content/{id}")
    public ResponseEntity<Map<String, Object>> getContentById(
            @Parameter(description = "Content ID") @PathVariable Long id) {
        
        return contentService.getContentByIdAndIncrementViews(id)
            .map(content -> {
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("data", content);
                return ResponseEntity.ok(response);
            })
            .orElseGet(() -> {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("error", "Content not found");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
            });
    }

    @Operation(summary = "Get featured content", 
               description = "Retrieve featured agricultural educational content")
    @GetMapping("/content/featured")
    public ResponseEntity<Map<String, Object>> getFeaturedContent() {
        try {
            List<EducationalContent> featuredContent = contentService.getFeaturedContent();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", featuredContent);
            response.put("count", featuredContent.size());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch featured content");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get content by category", 
               description = "Retrieve educational content filtered by agricultural category")
    @GetMapping("/content/category/{category}")
    public ResponseEntity<Map<String, Object>> getContentByCategory(
            @Parameter(description = "Content category") @PathVariable String category,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("publishedAt").descending());
            Page<EducationalContent> contentPage = contentService.getContentByCategory(category, pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", contentPage.getContent());
            response.put("currentPage", contentPage.getNumber());
            response.put("totalItems", contentPage.getTotalElements());
            response.put("totalPages", contentPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch content by category");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Search educational content", 
               description = "Search agricultural educational content by keywords")
    @GetMapping("/content/search")
    public ResponseEntity<Map<String, Object>> searchContent(
            @Parameter(description = "Search query") @RequestParam String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<EducationalContent> contentPage = contentService.searchContent(q, pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", contentPage.getContent());
            response.put("query", q);
            response.put("currentPage", contentPage.getNumber());
            response.put("totalItems", contentPage.getTotalElements());
            response.put("totalPages", contentPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Search failed");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get popular content", 
               description = "Retrieve most viewed agricultural educational content")
    @GetMapping("/content/popular")
    public ResponseEntity<Map<String, Object>> getPopularContent(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<EducationalContent> contentPage = contentService.getPopularContent(pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", contentPage.getContent());
            response.put("currentPage", contentPage.getNumber());
            response.put("totalItems", contentPage.getTotalElements());
            response.put("totalPages", contentPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch popular content");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get recent content", 
               description = "Retrieve recently published agricultural educational content")
    @GetMapping("/content/recent")
    public ResponseEntity<Map<String, Object>> getRecentContent(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<EducationalContent> contentPage = contentService.getRecentContent(pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", contentPage.getContent());
            response.put("currentPage", contentPage.getNumber());
            response.put("totalItems", contentPage.getTotalElements());
            response.put("totalPages", contentPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch recent content");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Like content", 
               description = "Like a piece of educational content")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping("/content/{id}/like")
    public ResponseEntity<Map<String, Object>> likeContent(
            @Parameter(description = "Content ID") @PathVariable Long id) {
        
        try {
            EducationalContent content = contentService.likeContent(id);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Content liked successfully");
            response.put("likeCount", content.getLikeCount());
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to like content");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Unlike content", 
               description = "Unlike a piece of educational content")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping("/content/{id}/unlike")
    public ResponseEntity<Map<String, Object>> unlikeContent(
            @Parameter(description = "Content ID") @PathVariable Long id) {
        
        try {
            EducationalContent content = contentService.unlikeContent(id);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Content unliked successfully");
            response.put("likeCount", content.getLikeCount());
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to unlike content");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get content categories", 
               description = "Get list of available content categories with counts")
    @GetMapping("/categories")
    public ResponseEntity<Map<String, Object>> getCategories() {
        try {
            // Define agricultural content categories
            String[] categories = {
                "CROP_MANAGEMENT",
                "PEST_CONTROL",
                "IRRIGATION",
                "ORGANIC_FARMING",
                "SOIL_HEALTH",
                "WEATHER_MANAGEMENT",
                "MARKET_ACCESS",
                "GOVERNMENT_SCHEMES",
                "SUSTAINABLE_PRACTICES",
                "TECHNOLOGY_IN_FARMING"
            };
            
            Map<String, Long> categoryCountsMap = new HashMap<>();
            for (String category : categories) {
                long count = contentService.getContentCountByCategory(category);
                categoryCountsMap.put(category, count);
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("categories", categories);
            response.put("counts", categoryCountsMap);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch categories");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    // Admin endpoints for content management
    
    @Operation(summary = "Create educational content", 
               description = "Create new agricultural educational content (Admin only)")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/content")
    public ResponseEntity<Map<String, Object>> createContent(@Valid @RequestBody EducationalContent content) {
        try {
            EducationalContent createdContent = contentService.createContent(content);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Content created successfully");
            response.put("data", createdContent);
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to create content");
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Update educational content", 
               description = "Update existing educational content (Admin only)")
    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/content/{id}")
    public ResponseEntity<Map<String, Object>> updateContent(
            @PathVariable Long id, 
            @Valid @RequestBody EducationalContent content) {
        
        try {
            EducationalContent updatedContent = contentService.updateContent(id, content);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Content updated successfully");
            response.put("data", updatedContent);
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to update content");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Delete educational content", 
               description = "Delete educational content (Admin only)")
    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/content/{id}")
    public ResponseEntity<Map<String, Object>> deleteContent(@PathVariable Long id) {
        try {
            contentService.deleteContent(id);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Content deleted successfully");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to delete content");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
}


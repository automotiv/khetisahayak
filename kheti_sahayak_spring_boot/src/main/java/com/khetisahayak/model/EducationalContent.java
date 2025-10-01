package com.khetisahayak.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

/**
 * Educational Content Model for Kheti Sahayak Agricultural Platform
 * Stores agricultural knowledge, best practices, and educational resources for farmers
 */
@Entity
@Table(name = "educational_content")
public class EducationalContent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Title is required")
    @Size(max = 200, message = "Title must not exceed 200 characters")
    @Column(nullable = false, length = 200)
    private String title;

    @NotBlank(message = "Content is required")
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @NotBlank(message = "Category is required")
    @Column(nullable = false, length = 50)
    private String category; // e.g., CROP_MANAGEMENT, PEST_CONTROL, IRRIGATION, ORGANIC_FARMING

    @ElementCollection
    @CollectionTable(name = "content_tags", joinColumns = @JoinColumn(name = "content_id"))
    @Column(name = "tag")
    private Set<String> tags = new HashSet<>();

    @NotBlank(message = "Author is required")
    @Column(nullable = false, length = 100)
    private String author;

    @Column(length = 500)
    private String excerpt; // Short summary

    @Column(name = "featured_image_url", length = 500)
    private String featuredImageUrl;

    @Column(name = "video_url", length = 500)
    private String videoUrl;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ContentType contentType = ContentType.ARTICLE;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DifficultyLevel difficultyLevel = DifficultyLevel.BEGINNER;

    @Min(value = 0, message = "Reading time must be non-negative")
    @Column(name = "estimated_reading_time_minutes")
    private Integer estimatedReadingTimeMinutes;

    @Min(value = 0, message = "View count must be non-negative")
    @Column(name = "view_count")
    private Integer viewCount = 0;

    @Min(value = 0, message = "Like count must be non-negative")
    @Column(name = "like_count")
    private Integer likeCount = 0;

    @Column(name = "published")
    private Boolean published = false;

    @Column(name = "featured")
    private Boolean featured = false;

    @NotNull
    @Column(name = "language", nullable = false, length = 10)
    private String language = "en"; // en, hi, mr, ta, te, etc.

    @Column(name = "crops_applicable")
    private String cropsApplicable; // Comma-separated crop types

    @Column(name = "season_applicable", length = 50)
    private String seasonApplicable; // KHARIF, RABI, ZAID, ALL

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "published_at")
    private LocalDateTime publishedAt;

    // Enums
    public enum ContentType {
        ARTICLE,
        VIDEO,
        INFOGRAPHIC,
        TUTORIAL,
        CASE_STUDY,
        FAQ
    }

    public enum DifficultyLevel {
        BEGINNER,
        INTERMEDIATE,
        ADVANCED,
        EXPERT
    }

    // Constructors
    public EducationalContent() {
    }

    public EducationalContent(String title, String content, String category, String author) {
        this.title = title;
        this.content = content;
        this.category = category;
        this.author = author;
    }

    // Lifecycle callbacks
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (published && publishedAt == null) {
            publishedAt = LocalDateTime.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
        if (published && publishedAt == null) {
            publishedAt = LocalDateTime.now();
        }
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public Set<String> getTags() {
        return tags;
    }

    public void setTags(Set<String> tags) {
        this.tags = tags;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public String getExcerpt() {
        return excerpt;
    }

    public void setExcerpt(String excerpt) {
        this.excerpt = excerpt;
    }

    public String getFeaturedImageUrl() {
        return featuredImageUrl;
    }

    public void setFeaturedImageUrl(String featuredImageUrl) {
        this.featuredImageUrl = featuredImageUrl;
    }

    public String getVideoUrl() {
        return videoUrl;
    }

    public void setVideoUrl(String videoUrl) {
        this.videoUrl = videoUrl;
    }

    public ContentType getContentType() {
        return contentType;
    }

    public void setContentType(ContentType contentType) {
        this.contentType = contentType;
    }

    public DifficultyLevel getDifficultyLevel() {
        return difficultyLevel;
    }

    public void setDifficultyLevel(DifficultyLevel difficultyLevel) {
        this.difficultyLevel = difficultyLevel;
    }

    public Integer getEstimatedReadingTimeMinutes() {
        return estimatedReadingTimeMinutes;
    }

    public void setEstimatedReadingTimeMinutes(Integer estimatedReadingTimeMinutes) {
        this.estimatedReadingTimeMinutes = estimatedReadingTimeMinutes;
    }

    public Integer getViewCount() {
        return viewCount;
    }

    public void setViewCount(Integer viewCount) {
        this.viewCount = viewCount;
    }

    public Integer getLikeCount() {
        return likeCount;
    }

    public void setLikeCount(Integer likeCount) {
        this.likeCount = likeCount;
    }

    public Boolean getPublished() {
        return published;
    }

    public void setPublished(Boolean published) {
        this.published = published;
    }

    public Boolean getFeatured() {
        return featured;
    }

    public void setFeatured(Boolean featured) {
        this.featured = featured;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public String getCropsApplicable() {
        return cropsApplicable;
    }

    public void setCropsApplicable(String cropsApplicable) {
        this.cropsApplicable = cropsApplicable;
    }

    public String getSeasonApplicable() {
        return seasonApplicable;
    }

    public void setSeasonApplicable(String seasonApplicable) {
        this.seasonApplicable = seasonApplicable;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public LocalDateTime getPublishedAt() {
        return publishedAt;
    }

    public void setPublishedAt(LocalDateTime publishedAt) {
        this.publishedAt = publishedAt;
    }

    // Helper methods
    public void incrementViewCount() {
        this.viewCount++;
    }

    public void incrementLikeCount() {
        this.likeCount++;
    }

    public void decrementLikeCount() {
        if (this.likeCount > 0) {
            this.likeCount--;
        }
    }
}


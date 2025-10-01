package com.khetisahayak.service;

import com.khetisahayak.model.EducationalContent;
import com.khetisahayak.repository.EducationalContentRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * Service for managing agricultural educational content
 * Provides knowledge base and learning resources for farmers
 */
@Service
@Transactional
public class EducationalContentService {

    private static final Logger logger = LoggerFactory.getLogger(EducationalContentService.class);

    private final EducationalContentRepository contentRepository;

    @Autowired
    public EducationalContentService(EducationalContentRepository contentRepository) {
        this.contentRepository = contentRepository;
    }

    /**
     * Get all published educational content
     */
    public Page<EducationalContent> getAllPublishedContent(Pageable pageable) {
        logger.debug("Fetching all published content with pagination");
        return contentRepository.findByPublishedTrue(pageable);
    }

    /**
     * Get content by ID
     */
    public Optional<EducationalContent> getContentById(Long id) {
        logger.debug("Fetching content by ID: {}", id);
        return contentRepository.findById(id);
    }

    /**
     * Get content by ID and increment view count
     */
    public Optional<EducationalContent> getContentByIdAndIncrementViews(Long id) {
        logger.debug("Fetching content by ID and incrementing views: {}", id);
        Optional<EducationalContent> content = contentRepository.findById(id);
        content.ifPresent(c -> {
            c.incrementViewCount();
            contentRepository.save(c);
            logger.info("Incremented view count for content: {}", id);
        });
        return content;
    }

    /**
     * Get content by category
     */
    public Page<EducationalContent> getContentByCategory(String category, Pageable pageable) {
        logger.debug("Fetching content for category: {}", category);
        return contentRepository.findByCategoryAndPublishedTrue(category, pageable);
    }

    /**
     * Get featured content
     */
    public List<EducationalContent> getFeaturedContent() {
        logger.debug("Fetching featured content");
        return contentRepository.findByFeaturedTrueAndPublishedTrueOrderByPublishedAtDesc();
    }

    /**
     * Get content by language
     */
    public Page<EducationalContent> getContentByLanguage(String language, Pageable pageable) {
        logger.debug("Fetching content for language: {}", language);
        return contentRepository.findByLanguageAndPublishedTrue(language, pageable);
    }

    /**
     * Get content by crop type
     */
    public Page<EducationalContent> getContentByCropType(String cropType, Pageable pageable) {
        logger.debug("Fetching content for crop type: {}", cropType);
        return contentRepository.findByCropType(cropType, pageable);
    }

    /**
     * Search content
     */
    public Page<EducationalContent> searchContent(String query, Pageable pageable) {
        logger.debug("Searching content with query: {}", query);
        return contentRepository.searchContent(query, pageable);
    }

    /**
     * Get popular content
     */
    public Page<EducationalContent> getPopularContent(Pageable pageable) {
        logger.debug("Fetching popular content");
        return contentRepository.findByPublishedTrueOrderByViewCountDesc(pageable);
    }

    /**
     * Get recent content
     */
    public Page<EducationalContent> getRecentContent(Pageable pageable) {
        logger.debug("Fetching recent content");
        return contentRepository.findByPublishedTrueOrderByPublishedAtDesc(pageable);
    }

    /**
     * Get content by difficulty level
     */
    public Page<EducationalContent> getContentByDifficultyLevel(
            EducationalContent.DifficultyLevel difficultyLevel, 
            Pageable pageable) {
        logger.debug("Fetching content for difficulty level: {}", difficultyLevel);
        return contentRepository.findByDifficultyLevelAndPublishedTrue(difficultyLevel, pageable);
    }

    /**
     * Get content by type
     */
    public Page<EducationalContent> getContentByType(
            EducationalContent.ContentType contentType, 
            Pageable pageable) {
        logger.debug("Fetching content for type: {}", contentType);
        return contentRepository.findByContentTypeAndPublishedTrue(contentType, pageable);
    }

    /**
     * Create new educational content
     */
    public EducationalContent createContent(EducationalContent content) {
        logger.info("Creating new educational content: {}", content.getTitle());
        return contentRepository.save(content);
    }

    /**
     * Update existing content
     */
    public EducationalContent updateContent(Long id, EducationalContent updatedContent) {
        logger.info("Updating content: {}", id);
        return contentRepository.findById(id)
            .map(existing -> {
                existing.setTitle(updatedContent.getTitle());
                existing.setContent(updatedContent.getContent());
                existing.setCategory(updatedContent.getCategory());
                existing.setTags(updatedContent.getTags());
                existing.setExcerpt(updatedContent.getExcerpt());
                existing.setFeaturedImageUrl(updatedContent.getFeaturedImageUrl());
                existing.setVideoUrl(updatedContent.getVideoUrl());
                existing.setContentType(updatedContent.getContentType());
                existing.setDifficultyLevel(updatedContent.getDifficultyLevel());
                existing.setEstimatedReadingTimeMinutes(updatedContent.getEstimatedReadingTimeMinutes());
                existing.setPublished(updatedContent.getPublished());
                existing.setFeatured(updatedContent.getFeatured());
                existing.setLanguage(updatedContent.getLanguage());
                existing.setCropsApplicable(updatedContent.getCropsApplicable());
                existing.setSeasonApplicable(updatedContent.getSeasonApplicable());
                return contentRepository.save(existing);
            })
            .orElseThrow(() -> new RuntimeException("Content not found with id: " + id));
    }

    /**
     * Delete content
     */
    public void deleteContent(Long id) {
        logger.info("Deleting content: {}", id);
        contentRepository.deleteById(id);
    }

    /**
     * Like content
     */
    public EducationalContent likeContent(Long id) {
        logger.debug("Liking content: {}", id);
        return contentRepository.findById(id)
            .map(content -> {
                content.incrementLikeCount();
                return contentRepository.save(content);
            })
            .orElseThrow(() -> new RuntimeException("Content not found with id: " + id));
    }

    /**
     * Unlike content
     */
    public EducationalContent unlikeContent(Long id) {
        logger.debug("Unliking content: {}", id);
        return contentRepository.findById(id)
            .map(content -> {
                content.decrementLikeCount();
                return contentRepository.save(content);
            })
            .orElseThrow(() -> new RuntimeException("Content not found with id: " + id));
    }

    /**
     * Get content count by category
     */
    public long getContentCountByCategory(String category) {
        logger.debug("Getting content count for category: {}", category);
        return contentRepository.countByCategoryAndPublishedTrue(category);
    }
}


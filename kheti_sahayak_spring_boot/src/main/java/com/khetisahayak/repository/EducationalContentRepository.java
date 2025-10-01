package com.khetisahayak.repository;

import com.khetisahayak.model.EducationalContent;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository for Educational Content data access
 * Optimized for agricultural knowledge search and retrieval
 */
@Repository
public interface EducationalContentRepository extends JpaRepository<EducationalContent, Long> {

    // Find all published content
    Page<EducationalContent> findByPublishedTrue(Pageable pageable);

    // Find content by category
    Page<EducationalContent> findByCategoryAndPublishedTrue(String category, Pageable pageable);

    // Find featured content
    List<EducationalContent> findByFeaturedTrueAndPublishedTrueOrderByPublishedAtDesc();

    // Find content by language
    Page<EducationalContent> findByLanguageAndPublishedTrue(String language, Pageable pageable);

    // Find content by crop type
    @Query("SELECT c FROM EducationalContent c WHERE c.published = true AND c.cropsApplicable LIKE %:cropType%")
    Page<EducationalContent> findByCropType(@Param("cropType") String cropType, Pageable pageable);

    // Search content by title or content
    @Query("SELECT c FROM EducationalContent c WHERE c.published = true AND " +
           "(LOWER(c.title) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(c.content) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<EducationalContent> searchContent(@Param("query") String query, Pageable pageable);

    // Find popular content (by view count)
    Page<EducationalContent> findByPublishedTrueOrderByViewCountDesc(Pageable pageable);

    // Find recent content
    Page<EducationalContent> findByPublishedTrueOrderByPublishedAtDesc(Pageable pageable);

    // Find content by difficulty level
    Page<EducationalContent> findByDifficultyLevelAndPublishedTrue(
        EducationalContent.DifficultyLevel difficultyLevel, 
        Pageable pageable
    );

    // Find content by type
    Page<EducationalContent> findByContentTypeAndPublishedTrue(
        EducationalContent.ContentType contentType, 
        Pageable pageable
    );

    // Count published content by category
    long countByCategoryAndPublishedTrue(String category);
}


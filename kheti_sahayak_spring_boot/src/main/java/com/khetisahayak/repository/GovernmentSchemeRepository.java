package com.khetisahayak.repository;

import com.khetisahayak.model.GovernmentScheme;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface GovernmentSchemeRepository extends JpaRepository<GovernmentScheme, Long> {
    Page<GovernmentScheme> findByIsActiveTrueOrderByCreatedAtDesc(Pageable pageable);
    Page<GovernmentScheme> findByCategoryAndIsActiveTrueOrderByCreatedAtDesc(String category, Pageable pageable);
    
    @Query("SELECT s FROM GovernmentScheme s WHERE s.isActive = true AND " +
           "(LOWER(s.name) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(s.description) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<GovernmentScheme> searchSchemes(@Param("query") String query, Pageable pageable);
}


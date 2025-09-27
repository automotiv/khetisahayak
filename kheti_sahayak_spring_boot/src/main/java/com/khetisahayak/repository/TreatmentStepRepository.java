package com.khetisahayak.repository;

import com.khetisahayak.model.CropDiagnosis;
import com.khetisahayak.model.TreatmentStep;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

/**
 * Treatment Step Repository for Kheti Sahayak Agricultural Platform
 * Handles database operations for agricultural treatment guidance and recommendations
 * Implements CodeRabbit data access patterns for agricultural treatment management
 */
@Repository
public interface TreatmentStepRepository extends JpaRepository<TreatmentStep, Long> {

    /**
     * Find treatment steps by diagnosis
     */
    List<TreatmentStep> findByDiagnosisId(Long diagnosisId);
    
    Page<TreatmentStep> findByDiagnosisId(Long diagnosisId, Pageable pageable);

    /**
     * Find treatment steps by diagnosis entity
     */
    List<TreatmentStep> findByDiagnosis(CropDiagnosis diagnosis);

    /**
     * Find treatment steps by step number and diagnosis
     */
    TreatmentStep findByDiagnosisIdAndStepNumber(Long diagnosisId, Integer stepNumber);

    /**
     * Find treatment steps by category
     */
    Page<TreatmentStep> findByCategory(TreatmentStep.TreatmentCategory category, Pageable pageable);

    /**
     * Find treatment steps by priority
     */
    Page<TreatmentStep> findByPriority(TreatmentStep.Priority priority, Pageable pageable);

    /**
     * Find treatment steps by category and priority
     */
    Page<TreatmentStep> findByCategoryAndPriority(
        TreatmentStep.TreatmentCategory category, 
        TreatmentStep.Priority priority,
        Pageable pageable
    );

    /**
     * Find organic treatment steps
     */
    Page<TreatmentStep> findByIsOrganicTrue(Pageable pageable);

    /**
     * Find treatment steps suitable for small farmers
     */
    Page<TreatmentStep> findBySuitableForSmallFarmersTrue(Pageable pageable);

    /**
     * Find organic treatment steps suitable for small farmers
     */
    Page<TreatmentStep> findByIsOrganicTrueAndSuitableForSmallFarmersTrue(Pageable pageable);

    /**
     * Find treatment steps by cost range
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE ts.estimatedCost BETWEEN :minCost AND :maxCost " +
           "ORDER BY ts.estimatedCost ASC")
    Page<TreatmentStep> findByCostRange(
        @Param("minCost") BigDecimal minCost,
        @Param("maxCost") BigDecimal maxCost,
        Pageable pageable
    );

    /**
     * Find low-cost treatment steps
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE ts.estimatedCost <= :maxCost " +
           "ORDER BY ts.estimatedCost ASC")
    Page<TreatmentStep> findLowCostTreatmentSteps(@Param("maxCost") BigDecimal maxCost, Pageable pageable);

    /**
     * Find treatment steps by multiple categories
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE ts.category IN :categories")
    Page<TreatmentStep> findByCategories(
        @Param("categories") List<TreatmentStep.TreatmentCategory> categories,
        Pageable pageable
    );

    /**
     * Find treatment steps by multiple priorities
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE ts.priority IN :priorities")
    Page<TreatmentStep> findByPriorities(
        @Param("priorities") List<TreatmentStep.Priority> priorities,
        Pageable pageable
    );

    /**
     * Find urgent treatment steps
     */
    List<TreatmentStep> findByPriority(TreatmentStep.Priority priority);

    /**
     * Find high priority treatment steps
     */
    List<TreatmentStep> findByPriorityIn(List<TreatmentStep.Priority> priorities);

    /**
     * Search treatment steps by title or description
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE " +
           "LOWER(ts.title) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(ts.description) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    Page<TreatmentStep> searchTreatmentSteps(@Param("searchTerm") String searchTerm, Pageable pageable);

    /**
     * Find treatment steps by best time to apply
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE " +
           "LOWER(ts.bestTimeToApply) LIKE LOWER(CONCAT('%', :timePeriod, '%'))")
    Page<TreatmentStep> findByBestTimeToApply(@Param("timePeriod") String timePeriod, Pageable pageable);

    /**
     * Find treatment steps by weather requirements
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE " +
           "LOWER(ts.weatherRequirements) LIKE LOWER(CONCAT('%', :weather, '%'))")
    Page<TreatmentStep> findByWeatherRequirements(@Param("weather") String weather, Pageable pageable);

    /**
     * Find treatment steps with safety precautions
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE ts.safetyPrecautions IS NOT NULL " +
           "AND ts.safetyPrecautions != ''")
    Page<TreatmentStep> findTreatmentStepsWithSafetyPrecautions(Pageable pageable);

    /**
     * Find treatment steps by expected results
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE " +
           "LOWER(ts.expectedResults) LIKE LOWER(CONCAT('%', :result, '%'))")
    Page<TreatmentStep> findByExpectedResults(@Param("result") String result, Pageable pageable);

    /**
     * Find treatment steps with alternatives
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE ts.alternatives IS NOT NULL " +
           "AND ts.alternatives != ''")
    Page<TreatmentStep> findTreatmentStepsWithAlternatives(Pageable pageable);

    /**
     * Get treatment step statistics by category
     */
    @Query("SELECT ts.category, COUNT(ts), AVG(ts.estimatedCost) FROM TreatmentStep ts GROUP BY ts.category")
    List<Object[]> getTreatmentStepStatsByCategory();

    /**
     * Get treatment step statistics by priority
     */
    @Query("SELECT ts.priority, COUNT(ts), AVG(ts.estimatedCost) FROM TreatmentStep ts GROUP BY ts.priority")
    List<Object[]> getTreatmentStepStatsByPriority();

    /**
     * Get organic vs non-organic treatment statistics
     */
    @Query("SELECT ts.isOrganic, COUNT(ts), AVG(ts.estimatedCost) FROM TreatmentStep ts GROUP BY ts.isOrganic")
    List<Object[]> getOrganicVsNonOrganicStats();

    /**
     * Get small farmer suitable treatment statistics
     */
    @Query("SELECT ts.suitableForSmallFarmers, COUNT(ts), AVG(ts.estimatedCost) " +
           "FROM TreatmentStep ts GROUP BY ts.suitableForSmallFarmers")
    List<Object[]> getSmallFarmerSuitableStats();

    /**
     * Get treatment step statistics by currency
     */
    @Query("SELECT ts.currency, COUNT(ts), AVG(ts.estimatedCost) FROM TreatmentStep ts GROUP BY ts.currency")
    List<Object[]> getTreatmentStepStatsByCurrency();

    /**
     * Find most cost-effective treatment steps
     */
    @Query("SELECT ts FROM TreatmentStep ts ORDER BY ts.estimatedCost ASC")
    Page<TreatmentStep> findMostCostEffectiveTreatmentSteps(Pageable pageable);

    /**
     * Find most expensive treatment steps
     */
    @Query("SELECT ts FROM TreatmentStep ts ORDER BY ts.estimatedCost DESC")
    Page<TreatmentStep> findMostExpensiveTreatmentSteps(Pageable pageable);

    /**
     * Find treatment steps by diagnosis and category
     */
    List<TreatmentStep> findByDiagnosisIdAndCategory(Long diagnosisId, TreatmentStep.TreatmentCategory category);

    /**
     * Find treatment steps by diagnosis and priority
     */
    List<TreatmentStep> findByDiagnosisIdAndPriority(Long diagnosisId, TreatmentStep.Priority priority);

    /**
     * Find treatment steps by diagnosis and organic status
     */
    List<TreatmentStep> findByDiagnosisIdAndIsOrganic(Long diagnosisId, Boolean isOrganic);

    /**
     * Find treatment steps by diagnosis and small farmer suitability
     */
    List<TreatmentStep> findByDiagnosisIdAndSuitableForSmallFarmers(Long diagnosisId, Boolean suitableForSmallFarmers);

    /**
     * Get next step number for a diagnosis
     */
    @Query("SELECT MAX(ts.stepNumber) FROM TreatmentStep ts WHERE ts.diagnosisId = :diagnosisId")
    Integer getNextStepNumber(@Param("diagnosisId") Long diagnosisId);

    /**
     * Find treatment steps by diagnosis ordered by step number
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE ts.diagnosisId = :diagnosisId " +
           "ORDER BY ts.stepNumber ASC")
    List<TreatmentStep> findByDiagnosisIdOrderByStepNumber(@Param("diagnosisId") Long diagnosisId);

    /**
     * Find treatment steps by diagnosis and category ordered by priority
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE ts.diagnosisId = :diagnosisId " +
           "AND ts.category = :category ORDER BY " +
           "CASE ts.priority WHEN 'URGENT' THEN 1 WHEN 'HIGH' THEN 2 WHEN 'MEDIUM' THEN 3 WHEN 'LOW' THEN 4 END")
    List<TreatmentStep> findByDiagnosisIdAndCategoryOrderByPriority(
        @Param("diagnosisId") Long diagnosisId,
        @Param("category") TreatmentStep.TreatmentCategory category
    );

    /**
     * Find urgent treatment steps for a diagnosis
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE ts.diagnosisId = :diagnosisId " +
           "AND ts.priority = 'URGENT' ORDER BY ts.stepNumber ASC")
    List<TreatmentStep> findUrgentTreatmentStepsForDiagnosis(@Param("diagnosisId") Long diagnosisId);

    /**
     * Find high priority treatment steps for a diagnosis
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE ts.diagnosisId = :diagnosisId " +
           "AND ts.priority IN ('URGENT', 'HIGH') ORDER BY ts.stepNumber ASC")
    List<TreatmentStep> findHighPriorityTreatmentStepsForDiagnosis(@Param("diagnosisId") Long diagnosisId);

    /**
     * Count treatment steps by diagnosis
     */
    Long countByDiagnosisId(Long diagnosisId);

    /**
     * Count treatment steps by diagnosis and category
     */
    Long countByDiagnosisIdAndCategory(Long diagnosisId, TreatmentStep.TreatmentCategory category);

    /**
     * Count treatment steps by diagnosis and priority
     */
    Long countByDiagnosisIdAndPriority(Long diagnosisId, TreatmentStep.Priority priority);

    /**
     * Count organic treatment steps by diagnosis
     */
    Long countByDiagnosisIdAndIsOrganicTrue(Long diagnosisId);

    /**
     * Count small farmer suitable treatment steps by diagnosis
     */
    Long countByDiagnosisIdAndSuitableForSmallFarmersTrue(Long diagnosisId);

    /**
     * Find treatment steps by required materials
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE " +
           "LOWER(ts.requiredMaterials) LIKE LOWER(CONCAT('%', :material, '%'))")
    Page<TreatmentStep> findByRequiredMaterials(@Param("material") String material, Pageable pageable);

    /**
     * Find treatment steps by estimated time
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE " +
           "LOWER(ts.estimatedTime) LIKE LOWER(CONCAT('%', :time, '%'))")
    Page<TreatmentStep> findByEstimatedTime(@Param("time") String time, Pageable pageable);

    /**
     * Get total estimated cost for a diagnosis
     */
    @Query("SELECT SUM(ts.estimatedCost) FROM TreatmentStep ts WHERE ts.diagnosisId = :diagnosisId")
    BigDecimal getTotalEstimatedCostForDiagnosis(@Param("diagnosisId") Long diagnosisId);

    /**
     * Get average cost by treatment category
     */
    @Query("SELECT ts.category, AVG(ts.estimatedCost) FROM TreatmentStep ts GROUP BY ts.category")
    List<Object[]> getAverageCostByCategory();

    /**
     * Get average cost by priority level
     */
    @Query("SELECT ts.priority, AVG(ts.estimatedCost) FROM TreatmentStep ts GROUP BY ts.priority")
    List<Object[]> getAverageCostByPriority();

    /**
     * Find treatment steps with specific materials
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE ts.requiredMaterials IN :materials")
    Page<TreatmentStep> findByRequiredMaterialsIn(
        @Param("materials") List<String> materials,
        Pageable pageable
    );

    /**
     * Find treatment steps by multiple time periods
     */
    @Query("SELECT ts FROM TreatmentStep ts WHERE ts.bestTimeToApply IN :timePeriods")
    Page<TreatmentStep> findByBestTimeToApplyIn(
        @Param("timePeriods") List<String> timePeriods,
        Pageable pageable
    );
}

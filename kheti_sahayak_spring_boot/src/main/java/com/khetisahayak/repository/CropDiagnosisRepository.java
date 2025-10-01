package com.khetisahayak.repository;

import com.khetisahayak.model.CropDiagnosis;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Crop Diagnosis Repository for Kheti Sahayak Agricultural Platform
 * Handles database operations for crop health diagnoses and AI recommendations
 * Implements CodeRabbit data access patterns for agricultural health tracking
 */
@Repository
public interface CropDiagnosisRepository extends JpaRepository<CropDiagnosis, Long> {

    /**
     * Find diagnoses by farmer
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.farmer.id = :farmerId")
    List<CropDiagnosis> findByFarmerId(@Param("farmerId") Long farmerId);
    
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.farmer.id = :farmerId")
    Page<CropDiagnosis> findByFarmerId(@Param("farmerId") Long farmerId, Pageable pageable);

    /**
     * Find diagnoses by farmer and status
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.farmer.id = :farmerId AND cd.status = :status")
    List<CropDiagnosis> findByFarmerIdAndStatus(@Param("farmerId") Long farmerId, @Param("status") CropDiagnosis.DiagnosisStatus status);

    /**
     * Find diagnoses by crop type
     */
    Page<CropDiagnosis> findByCropType(String cropType, Pageable pageable);

    /**
     * Find diagnoses by status
     */
    Page<CropDiagnosis> findByStatus(CropDiagnosis.DiagnosisStatus status, Pageable pageable);

    /**
     * Find high-confidence diagnoses
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.confidence >= :minConfidence " +
           "AND cd.status = 'AI_COMPLETED' ORDER BY cd.confidence DESC")
    Page<CropDiagnosis> findHighConfidenceDiagnoses(
        @Param("minConfidence") Double minConfidence, 
        Pageable pageable
    );

    /**
     * Find critical severity diagnoses
     */
    List<CropDiagnosis> findBySeverityAndStatus(
        CropDiagnosis.Severity severity, 
        CropDiagnosis.DiagnosisStatus status
    );

    /**
     * Find diagnoses requiring expert review
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.status = 'EXPERT_REVIEW' " +
           "ORDER BY cd.createdAt ASC")
    Page<CropDiagnosis> findDiagnosesRequiringExpertReview(Pageable pageable);

    /**
     * Find diagnoses by expert
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.expert.id = :expertId")
    List<CropDiagnosis> findByExpertId(@Param("expertId") Long expertId);

    /**
     * Find pending diagnoses for expert
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.status = 'EXPERT_REVIEW' " +
           "AND (cd.expert IS NULL OR cd.expert.id = :expertId)")
    Page<CropDiagnosis> findPendingDiagnosesForExpert(
        @Param("expertId") Long expertId, 
        Pageable pageable
    );

    /**
     * Find diagnoses in geographical area
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE " +
           "cd.latitude BETWEEN :minLat AND :maxLat AND " +
           "cd.longitude BETWEEN :minLon AND :maxLon")
    List<CropDiagnosis> findDiagnosesInArea(
        @Param("minLat") Double minLatitude,
        @Param("maxLat") Double maxLatitude,
        @Param("minLon") Double minLongitude,
        @Param("maxLon") Double maxLongitude
    );

    /**
     * Find recent diagnoses for farmer
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.farmer.id = :farmerId " +
           "AND cd.createdAt >= :since ORDER BY cd.createdAt DESC")
    List<CropDiagnosis> findRecentDiagnosesForFarmer(
        @Param("farmerId") Long farmerId,
        @Param("since") LocalDateTime since
    );

    /**
     * Find diagnoses by crop type and farmer
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.farmer.id = :farmerId AND cd.cropType = :cropType")
    List<CropDiagnosis> findByFarmerIdAndCropType(@Param("farmerId") Long farmerId, @Param("cropType") String cropType);

    /**
     * Find diagnoses requiring follow-up
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.followUpRequired = true " +
           "AND cd.followUpDate <= :currentDate AND cd.status != 'COMPLETED'")
    List<CropDiagnosis> findDiagnosesRequiringFollowUp(@Param("currentDate") LocalDateTime currentDate);

    /**
     * Find completed diagnoses with expert review
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.status = 'COMPLETED' " +
           "AND cd.expert IS NOT NULL ORDER BY cd.expertReviewedAt DESC")
    Page<CropDiagnosis> findCompletedDiagnosesWithExpertReview(Pageable pageable);

    /**
     * Find diagnoses by confidence range
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.confidence BETWEEN :minConfidence AND :maxConfidence " +
           "AND cd.status = 'AI_COMPLETED'")
    Page<CropDiagnosis> findDiagnosesByConfidenceRange(
        @Param("minConfidence") Double minConfidence,
        @Param("maxConfidence") Double maxConfidence,
        Pageable pageable
    );

    /**
     * Get diagnosis statistics by crop type
     */
    @Query("SELECT cd.cropType, COUNT(cd), AVG(cd.confidence), " +
           "COUNT(CASE WHEN cd.severity = 'HIGH' OR cd.severity = 'CRITICAL' THEN 1 END) " +
           "FROM CropDiagnosis cd GROUP BY cd.cropType")
    List<Object[]> getDiagnosisStatsByCropType();

    /**
     * Get diagnosis statistics by severity
     */
    @Query("SELECT cd.severity, COUNT(cd) FROM CropDiagnosis cd GROUP BY cd.severity")
    List<Object[]> getDiagnosisStatsBySeverity();

    /**
     * Get diagnosis statistics by status
     */
    @Query("SELECT cd.status, COUNT(cd) FROM CropDiagnosis cd GROUP BY cd.status")
    List<Object[]> getDiagnosisStatsByStatus();

    /**
     * Get expert performance statistics
     */
    @Query("SELECT cd.expert.id, COUNT(cd), AVG(cd.expertConfidence) " +
           "FROM CropDiagnosis cd WHERE cd.expert IS NOT NULL " +
           "GROUP BY cd.expert.id")
    List<Object[]> getExpertPerformanceStats();

    /**
     * Find diagnoses with low confidence requiring expert review
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.confidence < :threshold " +
           "AND cd.status = 'AI_COMPLETED' ORDER BY cd.confidence ASC")
    List<CropDiagnosis> findLowConfidenceDiagnoses(@Param("threshold") Double threshold);

    /**
     * Find diagnoses by treatment cost range
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.estimatedTreatmentCost BETWEEN :minCost AND :maxCost " +
           "AND cd.status = 'COMPLETED'")
    Page<CropDiagnosis> findDiagnosesByTreatmentCostRange(
        @Param("minCost") Double minCost,
        @Param("maxCost") Double maxCost,
        Pageable pageable
    );

    /**
     * Find diagnoses by weather conditions
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE LOWER(cd.weatherConditions) LIKE LOWER(CONCAT('%', :weather, '%'))")
    Page<CropDiagnosis> findDiagnosesByWeatherConditions(
        @Param("weather") String weather, 
        Pageable pageable
    );

    /**
     * Find diagnoses created between dates
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.createdAt BETWEEN :startDate AND :endDate " +
           "ORDER BY cd.createdAt DESC")
    Page<CropDiagnosis> findDiagnosesByDateRange(
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate,
        Pageable pageable
    );

    /**
     * Count diagnoses by farmer and status
     */
    @Query("SELECT COUNT(cd) FROM CropDiagnosis cd WHERE cd.farmer.id = :farmerId AND cd.status = :status")
    Long countByFarmerIdAndStatus(@Param("farmerId") Long farmerId, @Param("status") CropDiagnosis.DiagnosisStatus status);

    /**
     * Count diagnoses by expert and status
     */
    @Query("SELECT COUNT(cd) FROM CropDiagnosis cd WHERE cd.expert.id = :expertId AND cd.status = :status")
    Long countByExpertIdAndStatus(@Param("expertId") Long expertId, @Param("status") CropDiagnosis.DiagnosisStatus status);

    /**
     * Find similar diagnoses (same crop type, similar symptoms)
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.cropType = :cropType " +
           "AND cd.diagnosis = :diagnosis AND cd.id != :excludeId " +
           "AND cd.status = 'COMPLETED' ORDER BY cd.confidence DESC")
    List<CropDiagnosis> findSimilarDiagnoses(
        @Param("cropType") String cropType,
        @Param("diagnosis") String diagnosis,
        @Param("excludeId") Long excludeId
    );

    /**
     * Find diagnoses by multiple crop types
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.cropType IN :cropTypes " +
           "AND cd.status = 'COMPLETED' ORDER BY cd.createdAt DESC")
    Page<CropDiagnosis> findDiagnosesByCropTypes(
        @Param("cropTypes") List<String> cropTypes,
        Pageable pageable
    );

    /**
     * Get average confidence by crop type
     */
    @Query("SELECT cd.cropType, AVG(cd.confidence) FROM CropDiagnosis cd " +
           "WHERE cd.status = 'AI_COMPLETED' GROUP BY cd.cropType")
    List<Object[]> getAverageConfidenceByCropType();

    /**
     * Find diagnoses with treatment recommendations
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.aiRecommendations IS NOT NULL " +
           "AND cd.aiRecommendations != '' AND cd.status = 'COMPLETED'")
    Page<CropDiagnosis> findDiagnosesWithRecommendations(Pageable pageable);

    /**
     * Update diagnosis status
     */
    @Query("UPDATE CropDiagnosis cd SET cd.status = :status, cd.updatedAt = CURRENT_TIMESTAMP " +
           "WHERE cd.id = :diagnosisId")
    void updateDiagnosisStatus(@Param("diagnosisId") Long diagnosisId, @Param("status") CropDiagnosis.DiagnosisStatus status);

    /**
     * Find diagnoses by farmer and crop type with pagination
     */
    @Query("SELECT cd FROM CropDiagnosis cd WHERE cd.farmer.id = :farmerId AND cd.cropType = :cropType AND cd.status = :status")
    Page<CropDiagnosis> findByFarmerIdAndCropTypeAndStatus(
        @Param("farmerId") Long farmerId, 
        @Param("cropType") String cropType, 
        @Param("status") CropDiagnosis.DiagnosisStatus status,
        Pageable pageable
    );
}

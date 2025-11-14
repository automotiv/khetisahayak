package com.khetisahayak.repository;

import com.khetisahayak.model.ExpertConsultation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExpertConsultationRepository extends JpaRepository<ExpertConsultation, Long> {
    Page<ExpertConsultation> findByFarmerIdOrderByCreatedAtDesc(Long farmerId, Pageable pageable);
    Page<ExpertConsultation> findByExpertIdOrderByCreatedAtDesc(Long expertId, Pageable pageable);
    Page<ExpertConsultation> findByStatusOrderByCreatedAtDesc(ExpertConsultation.ConsultationStatus status, Pageable pageable);
    long countByFarmerIdAndStatus(Long farmerId, ExpertConsultation.ConsultationStatus status);
    
    // Additional methods for expert service
    List<ExpertConsultation> findByExpertId(Long expertId);
    Page<ExpertConsultation> findByExpertIdAndRatingIsNotNullOrderByCreatedAtDesc(Long expertId, Pageable pageable);
}


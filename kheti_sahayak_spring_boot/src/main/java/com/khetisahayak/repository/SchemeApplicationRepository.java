package com.khetisahayak.repository;

import com.khetisahayak.model.SchemeApplication;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SchemeApplicationRepository extends JpaRepository<SchemeApplication, Long> {
    Page<SchemeApplication> findByFarmerIdOrderByCreatedAtDesc(Long farmerId, Pageable pageable);
    Page<SchemeApplication> findBySchemeIdOrderByCreatedAtDesc(Long schemeId, Pageable pageable);
    Page<SchemeApplication> findByStatusOrderByCreatedAtDesc(SchemeApplication.ApplicationStatus status, Pageable pageable);
    Optional<SchemeApplication> findByApplicationNumber(String applicationNumber);
    long countByFarmerIdAndStatus(Long farmerId, SchemeApplication.ApplicationStatus status);
}


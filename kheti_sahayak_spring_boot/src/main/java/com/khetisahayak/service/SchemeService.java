package com.khetisahayak.service;

import com.khetisahayak.model.GovernmentScheme;
import com.khetisahayak.model.SchemeApplication;
import com.khetisahayak.repository.GovernmentSchemeRepository;
import com.khetisahayak.repository.SchemeApplicationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
@Transactional
public class SchemeService {

    private static final Logger logger = LoggerFactory.getLogger(SchemeService.class);
    
    private final GovernmentSchemeRepository schemeRepository;
    private final SchemeApplicationRepository applicationRepository;

    @Autowired
    public SchemeService(GovernmentSchemeRepository schemeRepository, 
                        SchemeApplicationRepository applicationRepository) {
        this.schemeRepository = schemeRepository;
        this.applicationRepository = applicationRepository;
    }

    // Scheme operations
    public Page<GovernmentScheme> getAllActiveSchemes(Pageable pageable) {
        return schemeRepository.findByIsActiveTrueOrderByCreatedAtDesc(pageable);
    }

    public Optional<GovernmentScheme> getSchemeById(Long id) {
        return schemeRepository.findById(id);
    }

    public Page<GovernmentScheme> getSchemesByCategory(String category, Pageable pageable) {
        return schemeRepository.findByCategoryAndIsActiveTrueOrderByCreatedAtDesc(category, pageable);
    }

    public Page<GovernmentScheme> searchSchemes(String query, Pageable pageable) {
        return schemeRepository.searchSchemes(query, pageable);
    }

    public GovernmentScheme createScheme(GovernmentScheme scheme) {
        logger.info("Creating scheme: {}", scheme.getName());
        return schemeRepository.save(scheme);
    }

    // Application operations
    public Page<SchemeApplication> getFarmerApplications(Long farmerId, Pageable pageable) {
        return applicationRepository.findByFarmerIdOrderByCreatedAtDesc(farmerId, pageable);
    }

    public Optional<SchemeApplication> getApplicationById(Long id) {
        return applicationRepository.findById(id);
    }

    public Optional<SchemeApplication> getApplicationByNumber(String applicationNumber) {
        return applicationRepository.findByApplicationNumber(applicationNumber);
    }

    public SchemeApplication createApplication(SchemeApplication application) {
        logger.info("Creating scheme application for scheme: {}", application.getSchemeId());
        return applicationRepository.save(application);
    }

    public SchemeApplication updateApplicationStatus(Long id, SchemeApplication.ApplicationStatus status, 
                                                     String notes) {
        return applicationRepository.findById(id)
            .map(app -> {
                app.setStatus(status);
                app.setAdminNotes(notes);
                if (status == SchemeApplication.ApplicationStatus.APPROVED) {
                    app.setApprovalDate(LocalDateTime.now());
                }
                return applicationRepository.save(app);
            })
            .orElseThrow(() -> new RuntimeException("Application not found"));
    }
}


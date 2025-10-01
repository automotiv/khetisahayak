package com.khetisahayak.service;

import com.khetisahayak.model.ExpertConsultation;
import com.khetisahayak.repository.ExpertConsultationRepository;
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
public class ExpertService {

    private static final Logger logger = LoggerFactory.getLogger(ExpertService.class);
    
    private final ExpertConsultationRepository consultationRepository;

    @Autowired
    public ExpertService(ExpertConsultationRepository consultationRepository) {
        this.consultationRepository = consultationRepository;
    }

    public Page<ExpertConsultation> getFarmerConsultations(Long farmerId, Pageable pageable) {
        return consultationRepository.findByFarmerIdOrderByCreatedAtDesc(farmerId, pageable);
    }

    public Page<ExpertConsultation> getExpertConsultations(Long expertId, Pageable pageable) {
        return consultationRepository.findByExpertIdOrderByCreatedAtDesc(expertId, pageable);
    }

    public Optional<ExpertConsultation> getConsultationById(Long id) {
        return consultationRepository.findById(id);
    }

    public ExpertConsultation createConsultation(ExpertConsultation consultation) {
        logger.info("Creating consultation for farmer: {}", consultation.getFarmerId());
        return consultationRepository.save(consultation);
    }

    public ExpertConsultation updateConsultation(Long id, ExpertConsultation updated) {
        return consultationRepository.findById(id)
            .map(existing -> {
                existing.setStatus(updated.getStatus());
                existing.setScheduledAt(updated.getScheduledAt());
                existing.setExpertResponse(updated.getExpertResponse());
                existing.setRating(updated.getRating());
                existing.setFeedback(updated.getFeedback());
                if (updated.getStatus() == ExpertConsultation.ConsultationStatus.COMPLETED) {
                    existing.setCompletedAt(LocalDateTime.now());
                }
                return consultationRepository.save(existing);
            })
            .orElseThrow(() -> new RuntimeException("Consultation not found"));
    }
}


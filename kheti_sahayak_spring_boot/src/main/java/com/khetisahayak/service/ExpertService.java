package com.khetisahayak.service;

import com.khetisahayak.model.ExpertConsultation;
import com.khetisahayak.model.User;
import com.khetisahayak.repository.ExpertConsultationRepository;
import com.khetisahayak.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Expert Service for Kheti Sahayak Agricultural Platform
 * Handles expert profiles, consultations, ratings, and statistics
 * Implements CodeRabbit standards for expert-farmer interactions
 */
@Service
@Transactional
public class ExpertService {

    private static final Logger logger = LoggerFactory.getLogger(ExpertService.class);
    
    private final ExpertConsultationRepository consultationRepository;
    private final UserRepository userRepository;

    @Autowired
    public ExpertService(ExpertConsultationRepository consultationRepository, 
                        UserRepository userRepository) {
        this.consultationRepository = consultationRepository;
        this.userRepository = userRepository;
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

    /**
     * Get all available experts with pagination and filters
     */
    public Page<Map<String, Object>> getAllExperts(Pageable pageable, String state, String category) {
        logger.debug("Fetching experts with filters - state: {}, category: {}", state, category);
        
        List<User> experts = userRepository.findByUserTypeAndIsVerifiedTrueAndIsActiveTrue(User.UserType.EXPERT);
        
        // Apply filters
        if (state != null && !state.isEmpty()) {
            experts = experts.stream()
                .filter(e -> state.equalsIgnoreCase(e.getState()))
                .collect(Collectors.toList());
        }
        
        // Map to response format with statistics
        List<Map<String, Object>> expertList = experts.stream()
            .map(this::mapExpertToResponse)
            .collect(Collectors.toList());
        
        // Apply pagination
        int start = (int) pageable.getOffset();
        int end = Math.min((start + pageable.getPageSize()), expertList.size());
        List<Map<String, Object>> pagedList = expertList.subList(start, end);
        
        return new PageImpl<>(pagedList, pageable, expertList.size());
    }

    /**
     * Get detailed expert profile with ratings and statistics
     */
    public Map<String, Object> getExpertProfile(Long expertId) {
        User expert = userRepository.findById(expertId)
            .filter(u -> u.getUserType() == User.UserType.EXPERT)
            .orElseThrow(() -> new RuntimeException("Expert not found"));
        
        Map<String, Object> profile = mapExpertToResponse(expert);
        
        // Add detailed statistics
        List<ExpertConsultation> allConsultations = consultationRepository.findByExpertId(expertId);
        long totalConsultations = allConsultations.size();
        long completedConsultations = allConsultations.stream()
            .filter(c -> c.getStatus() == ExpertConsultation.ConsultationStatus.COMPLETED)
            .count();
        
        // Calculate average rating
        OptionalDouble avgRating = allConsultations.stream()
            .filter(c -> c.getRating() != null && c.getRating() > 0)
            .mapToInt(ExpertConsultation::getRating)
            .average();
        
        profile.put("totalConsultations", totalConsultations);
        profile.put("completedConsultations", completedConsultations);
        profile.put("averageRating", avgRating.isPresent() ? Math.round(avgRating.getAsDouble() * 10.0) / 10.0 : 0.0);
        profile.put("totalRatings", allConsultations.stream()
            .filter(c -> c.getRating() != null && c.getRating() > 0)
            .count());
        
        return profile;
    }

    /**
     * Get expert ratings and reviews
     */
    public Page<ExpertConsultation> getExpertRatings(Long expertId, Pageable pageable) {
        logger.debug("Fetching ratings for expert: {}", expertId);
        return consultationRepository.findByExpertIdAndRatingIsNotNullOrderByCreatedAtDesc(expertId, pageable);
    }

    /**
     * Submit rating for a consultation
     */
    public ExpertConsultation submitRating(Long consultationId, Long farmerId, Integer rating, String feedback) {
        if (rating == null || rating < 1 || rating > 5) {
            throw new RuntimeException("Rating must be between 1 and 5");
        }
        
        ExpertConsultation consultation = consultationRepository.findById(consultationId)
            .orElseThrow(() -> new RuntimeException("Consultation not found"));
        
        // Verify farmer owns this consultation
        if (!consultation.getFarmerId().equals(farmerId)) {
            throw new RuntimeException("Not authorized to rate this consultation");
        }
        
        // Verify consultation is completed
        if (consultation.getStatus() != ExpertConsultation.ConsultationStatus.COMPLETED) {
            throw new RuntimeException("Can only rate completed consultations");
        }
        
        consultation.setRating(rating);
        if (feedback != null && !feedback.isEmpty()) {
            consultation.setFeedback(feedback);
        }
        
        logger.info("Rating submitted for consultation {}: {} stars", consultationId, rating);
        return consultationRepository.save(consultation);
    }

    /**
     * Map User entity to expert response format
     */
    private Map<String, Object> mapExpertToResponse(User expert) {
        Map<String, Object> response = new HashMap<>();
        response.put("id", expert.getId());
        response.put("fullName", expert.getFullName());
        response.put("state", expert.getState());
        response.put("district", expert.getDistrict());
        response.put("village", expert.getVillage());
        response.put("primaryCrop", expert.getPrimaryCrop());
        response.put("farmingExperience", expert.getFarmingExperience());
        response.put("profileImageUrl", expert.getProfileImageUrl());
        response.put("preferredLanguage", expert.getPreferredLanguage());
        
        // Calculate quick stats
        List<ExpertConsultation> consultations = consultationRepository.findByExpertId(expert.getId());
        long completedCount = consultations.stream()
            .filter(c -> c.getStatus() == ExpertConsultation.ConsultationStatus.COMPLETED)
            .count();
        
        OptionalDouble avgRating = consultations.stream()
            .filter(c -> c.getRating() != null && c.getRating() > 0)
            .mapToInt(ExpertConsultation::getRating)
            .average();
        
        response.put("totalConsultations", consultations.size());
        response.put("completedConsultations", completedCount);
        response.put("averageRating", avgRating.isPresent() ? Math.round(avgRating.getAsDouble() * 10.0) / 10.0 : 0.0);
        
        return response;
    }
}


package com.khetisahayak.service;

import com.khetisahayak.model.UserConsent;
import com.khetisahayak.repository.UserConsentRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * Consent Management Service
 * Handles user privacy consents as per Issue #255
 */
@Service
@Transactional
public class ConsentService {

    private static final Logger logger = LoggerFactory.getLogger(ConsentService.class);

    private final UserConsentRepository consentRepository;

    @Autowired
    public ConsentService(UserConsentRepository consentRepository) {
        this.consentRepository = consentRepository;
    }

    public Optional<UserConsent> getUserConsent(Long userId) {
        return consentRepository.findByUserId(userId);
    }

    public UserConsent createOrUpdateConsent(Long userId, UserConsent consent) {
        logger.info("Updating consent for user: {}", userId);
        
        return consentRepository.findByUserId(userId)
            .map(existing -> {
                updateConsentFields(existing, consent);
                return consentRepository.save(existing);
            })
            .orElseGet(() -> {
                consent.setUserId(userId);
                return consentRepository.save(consent);
            });
    }

    private void updateConsentFields(UserConsent existing, UserConsent updated) {
        if (updated.getMlDataUsageConsent() != null) {
            existing.setMlDataUsageConsent(updated.getMlDataUsageConsent());
        }
        if (updated.getChatbotConsent() != null) {
            existing.setChatbotConsent(updated.getChatbotConsent());
        }
        if (updated.getLocationSharingConsent() != null) {
            existing.setLocationSharingConsent(updated.getLocationSharingConsent());
        }
        if (updated.getImageSharingMlConsent() != null) {
            existing.setImageSharingMlConsent(updated.getImageSharingMlConsent());
        }
        if (updated.getMarketingConsent() != null) {
            existing.setMarketingConsent(updated.getMarketingConsent());
        }
        if (updated.getAnalyticsConsent() != null) {
            existing.setAnalyticsConsent(updated.getAnalyticsConsent());
        }
        if (updated.getThirdPartySharingConsent() != null) {
            existing.setThirdPartySharingConsent(updated.getThirdPartySharingConsent());
        }
        if (updated.getIpAddress() != null) {
            existing.setIpAddress(updated.getIpAddress());
        }
        if (updated.getUserAgent() != null) {
            existing.setUserAgent(updated.getUserAgent());
        }
    }

    public boolean canUseDataForMl(Long userId) {
        return getUserConsent(userId)
            .map(UserConsent::hasGivenMlConsent)
            .orElse(false);
    }

    public boolean canTrackLocation(Long userId) {
        return getUserConsent(userId)
            .map(UserConsent::canTrackLocation)
            .orElse(false);
    }
}


package com.khetisahayak.repository;

import com.khetisahayak.model.UserConsent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserConsentRepository extends JpaRepository<UserConsent, Long> {
    Optional<UserConsent> findByUserId(Long userId);
    long countByMlDataUsageConsentTrue();
    long countByChatbotConsentTrue();
}


package com.khetisahayak.repository;

import com.khetisahayak.model.EmailVerificationToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface EmailVerificationTokenRepository extends JpaRepository<EmailVerificationToken, Long> {

    Optional<EmailVerificationToken> findByTokenAndIsUsedFalse(String token);

    void deleteByUserId(Long userId);

    void deleteAllByExpiresAtBefore(LocalDateTime dateTime);
}


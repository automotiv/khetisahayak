package com.khetisahayak.service;

import com.khetisahayak.exception.AgriculturalException;
import com.khetisahayak.model.EmailVerificationToken;
import com.khetisahayak.model.User;
import com.khetisahayak.repository.EmailVerificationTokenRepository;
import com.khetisahayak.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * Email Verification Service for Kheti Sahayak Platform
 * Handles token generation, verification, and notifications
 */
@Service
@Transactional
public class EmailVerificationService {

    private final EmailVerificationTokenRepository tokenRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final SecureRandom secureRandom = new SecureRandom();

    @Value("${app.email.verification-expiry-hours:24}")
    private int verificationExpiryHours;

    @Autowired
    public EmailVerificationService(EmailVerificationTokenRepository tokenRepository,
                                    UserRepository userRepository,
                                    EmailService emailService) {
        this.tokenRepository = tokenRepository;
        this.userRepository = userRepository;
        this.emailService = emailService;
    }

    /**
     * Send email verification link to user (and update email if provided)
     */
    public Map<String, Object> sendVerificationEmail(User user, String email) {
        if (user == null) {
            throw new AgriculturalException("User not found for email verification", "USER_NOT_FOUND");
        }

        if (email == null || email.isBlank()) {
            email = user.getEmail();
        }

        if (email == null || email.isBlank()) {
            throw new AgriculturalException("Email address is required for verification", "EMAIL_REQUIRED");
        }

        if (Boolean.TRUE.equals(user.getIsEmailVerified())) {
            throw new AgriculturalException("Email already verified", "EMAIL_ALREADY_VERIFIED");
        }

        // Update email if changed
        if (!email.equalsIgnoreCase(Optional.ofNullable(user.getEmail()).orElse(""))) {
            user.setEmail(email);
            user.setIsEmailVerified(false);
            userRepository.save(user);
        }

        // Remove previous tokens
        tokenRepository.deleteByUserId(user.getId());

        // Create new token
        EmailVerificationToken token = new EmailVerificationToken();
        token.setUser(user);
        token.setToken(generateSecureToken());
        token.setExpiresAt(LocalDateTime.now().plusHours(verificationExpiryHours));
        tokenRepository.save(token);

        emailService.sendEmailVerification(email, token.getToken());

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Verification email sent successfully");
        response.put("email", email);
        response.put("expiresAt", token.getExpiresAt());

        return response;
    }

    /**
     * Verify token and mark user's email as verified
     */
    public Map<String, Object> verifyToken(String tokenString) {
        EmailVerificationToken token = tokenRepository.findByTokenAndIsUsedFalse(tokenString)
                .orElseThrow(() -> new AgriculturalException(
                        "Verification token not found or already used",
                        "TOKEN_NOT_FOUND"));

        if (token.isExpired()) {
            throw new AgriculturalException("Verification token has expired", "TOKEN_EXPIRED");
        }

        User user = token.getUser();
        user.setIsEmailVerified(true);
        user.setIsVerified(true); // overall verification
        userRepository.save(user);

        token.markAsUsed();
        tokenRepository.save(token);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Email verified successfully");
        response.put("verifiedAt", token.getVerifiedAt());

        return response;
    }

    /**
     * Generate secure random token
     */
    private String generateSecureToken() {
        byte[] bytes = new byte[24];
        secureRandom.nextBytes(bytes);
        return java.util.Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}


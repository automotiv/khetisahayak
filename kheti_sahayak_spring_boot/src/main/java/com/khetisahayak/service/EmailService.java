package com.khetisahayak.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Email Service for Kheti Sahayak Agricultural Platform
 * Simulates email delivery for verification and notifications
 */
@Service
public class EmailService {

    private static final Logger logger = LoggerFactory.getLogger(EmailService.class);

    @Value("${app.email.enabled:false}")
    private boolean emailEnabled;

    @Value("${app.email.from-address:no-reply@khetisahayak.com}")
    private String fromAddress;

    /**
     * Send email verification link (simulated)
     */
    public void sendEmailVerification(String toEmail, String verificationToken) {
        if (!emailEnabled) {
            logger.info("Email sending disabled. Verification token for {} -> {}", toEmail, verificationToken);
            return;
        }

        // Placeholder for actual email integration
        logger.info("Sending email verification to {} from {} with token {}", toEmail, fromAddress, verificationToken);
    }
}


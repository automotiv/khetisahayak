package com.khetisahayak.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * SMS Service for Kheti Sahayak Agricultural Platform
 * Handles SMS delivery for OTP and notifications to Indian farmers
 * Implements CodeRabbit security standards for SMS communication
 * 
 * Supports multiple SMS providers (Twilio, AWS SNS, custom providers)
 * Falls back to console logging in development mode
 */
@Service
public class SmsService {

    private static final Logger logger = LoggerFactory.getLogger(SmsService.class);

    @Value("${app.sms.enabled:false}")
    private boolean smsEnabled;

    @Value("${app.sms.provider:console}")
    private String smsProvider;

    @Value("${app.sms.api-key:}")
    private String smsApiKey;

    @Value("${app.sms.sender-id:KHETI}")
    private String senderId;

    /**
     * Send OTP SMS to mobile number
     * Implements CodeRabbit security standards for SMS delivery
     * 
     * @param mobileNumber Indian mobile number (10 digits)
     * @param otp OTP code to send
     * @return true if SMS sent successfully, false otherwise
     */
    public boolean sendOtp(String mobileNumber, String otp) {
        if (!smsEnabled) {
            logger.info("SMS service disabled. OTP for {}: {}", mobileNumber, otp);
            return true; // Return true for development mode
        }

        try {
            String message = String.format("Your Kheti Sahayak OTP is %s. Valid for 5 minutes. Do not share with anyone.", otp);
            return sendSms(mobileNumber, message);
        } catch (Exception e) {
            logger.error("Failed to send OTP SMS to {}: {}", mobileNumber, e.getMessage());
            return false;
        }
    }

    /**
     * Send notification SMS to mobile number
     * 
     * @param mobileNumber Indian mobile number (10 digits)
     * @param message SMS message content
     * @return true if SMS sent successfully, false otherwise
     */
    public boolean sendNotification(String mobileNumber, String message) {
        if (!smsEnabled) {
            logger.info("SMS service disabled. Notification for {}: {}", mobileNumber, message);
            return true; // Return true for development mode
        }

        try {
            return sendSms(mobileNumber, message);
        } catch (Exception e) {
            logger.error("Failed to send notification SMS to {}: {}", mobileNumber, e.getMessage());
            return false;
        }
    }

    /**
     * Send SMS using configured provider
     * Implements CodeRabbit security standards for SMS provider integration
     * 
     * @param mobileNumber Indian mobile number (10 digits)
     * @param message SMS message content
     * @return true if SMS sent successfully, false otherwise
     */
    private boolean sendSms(String mobileNumber, String message) {
        // Validate Indian mobile number format
        if (!mobileNumber.matches("^[6-9]\\d{9}$")) {
            logger.error("Invalid Indian mobile number format: {}", mobileNumber);
            return false;
        }

        // Format mobile number with country code for SMS providers
        String formattedNumber = "+91" + mobileNumber;

        switch (smsProvider.toLowerCase()) {
            case "twilio":
                return sendViaTwilio(formattedNumber, message);
            case "aws-sns":
                return sendViaAwsSns(formattedNumber, message);
            case "custom":
                return sendViaCustomProvider(formattedNumber, message);
            case "console":
            default:
                logger.info("SMS (Console Mode) - To: {}, Message: {}", formattedNumber, message);
                return true;
        }
    }

    /**
     * Send SMS via Twilio provider
     * TODO: Implement Twilio integration when SMS_ENABLED=true
     */
    private boolean sendViaTwilio(String mobileNumber, String message) {
        logger.info("Twilio SMS integration not yet implemented. To: {}, Message: {}", mobileNumber, message);
        // TODO: Implement Twilio SDK integration
        // Twilio.init(accountSid, authToken);
        // Message.creator(new PhoneNumber(mobileNumber), new PhoneNumber(senderId), message).create();
        return false;
    }

    /**
     * Send SMS via AWS SNS provider
     * TODO: Implement AWS SNS integration when SMS_ENABLED=true
     */
    private boolean sendViaAwsSns(String mobileNumber, String message) {
        logger.info("AWS SNS SMS integration not yet implemented. To: {}, Message: {}", mobileNumber, message);
        // TODO: Implement AWS SNS SDK integration
        // SnsClient snsClient = SnsClient.builder().region(Region.AP_SOUTH_1).build();
        // PublishRequest request = PublishRequest.builder().phoneNumber(mobileNumber).message(message).build();
        // snsClient.publish(request);
        return false;
    }

    /**
     * Send SMS via custom provider
     * TODO: Implement custom SMS provider integration when SMS_ENABLED=true
     */
    private boolean sendViaCustomProvider(String mobileNumber, String message) {
        logger.info("Custom SMS provider integration not yet implemented. To: {}, Message: {}", mobileNumber, message);
        // TODO: Implement custom SMS provider API integration
        return false;
    }

    /**
     * Check if SMS service is enabled
     */
    public boolean isEnabled() {
        return smsEnabled;
    }
}


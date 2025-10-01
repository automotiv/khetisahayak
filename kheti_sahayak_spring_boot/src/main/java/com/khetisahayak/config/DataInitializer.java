package com.khetisahayak.config;

import com.khetisahayak.model.*;
import com.khetisahayak.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.HashSet;

/**
 * Data Initializer for H2 In-Memory Database
 * Automatically creates sample data when using H2 profile
 */
@Configuration
@Profile("h2")
public class DataInitializer {

    private static final Logger logger = LoggerFactory.getLogger(DataInitializer.class);

    @Bean
    CommandLineRunner initDatabase(
            UserRepository userRepository,
            ProductRepository productRepository,
            EducationalContentRepository educationalContentRepository,
            NotificationRepository notificationRepository,
            GovernmentSchemeRepository governmentSchemeRepository,
            ForumTopicRepository forumTopicRepository,
            PasswordEncoder passwordEncoder) {
        
        return args -> {
            logger.info("🌾 Initializing H2 database with sample agricultural data...");

            // Create sample user
            if (userRepository.count() == 0) {
                User farmer = new User();
                farmer.setMobileNumber("9876543210");
                farmer.setFullName("राम कुमार (Ram Kumar)");
                farmer.setPrimaryCrop("Rice");
                farmer.setState("Maharashtra");
                farmer.setDistrict("Nashik");
                farmer.setVillage("Vani");
                farmer.setFarmSize(BigDecimal.valueOf(2.5));
                farmer.setUserType(User.UserType.FARMER);
                farmer.setRole(User.Role.ROLE_FARMER);
                farmer.setOtpVerified(true);
                farmer.setAccountActive(true);
                userRepository.save(farmer);
                logger.info("✅ Created sample user: {}", farmer.getFullName());
            }

            // Create sample educational content
            if (educationalContentRepository.count() == 0) {
                EducationalContent[] contents = {
                    createContent("Best Practices for Rice Cultivation", "Rice farming guide", "CROP_MANAGEMENT", "Dr. Ramesh Kumar"),
                    createContent("Organic Pest Control Methods", "Natural pest control", "PEST_CONTROL", "Dr. Priya Sharma"),
                    createContent("Drip Irrigation Techniques", "Water-saving irrigation", "IRRIGATION", "Engineer Suresh Patel"),
                    createContent("Soil Health Management", "Soil fertility guide", "SOIL_HEALTH", "Dr. Anjali Verma"),
                    createContent("PM-KISAN Scheme Guide", "Government subsidy application", "GOVERNMENT_SCHEMES", "Government Officer")
                };
                educationalContentRepository.saveAll(Arrays.asList(contents));
                logger.info("✅ Created {} educational content items", contents.length);
            }

            // Create sample notifications
            if (notificationRepository.count() == 0 && userRepository.count() > 0) {
                Long userId = userRepository.findAll().get(0).getId();
                Notification[] notifications = {
                    createNotification(userId, "Heavy Rainfall Alert", "Heavy rainfall expected tomorrow", Notification.NotificationType.WEATHER_ALERT, Notification.Priority.URGENT),
                    createNotification(userId, "PM-KISAN Scheme Open", "Apply for PM-KISAN", Notification.NotificationType.GOVERNMENT_SCHEME, Notification.Priority.MEDIUM),
                    createNotification(userId, "Rice Price Update", "Price increased to ₹2,200/quintal", Notification.NotificationType.MARKET_PRICE_UPDATE, Notification.Priority.MEDIUM)
                };
                notificationRepository.saveAll(Arrays.asList(notifications));
                logger.info("✅ Created {} notifications", notifications.length);
            }

            // Create sample government schemes
            if (governmentSchemeRepository.count() == 0) {
                GovernmentScheme[] schemes = {
                    createScheme("PM-KISAN", "Direct income support of ₹6,000/year", "SUBSIDY", 6000.00),
                    createScheme("PM Fasal Bima Yojana", "Crop insurance scheme", "INSURANCE", null),
                    createScheme("Kisan Credit Card", "Credit facility for farmers", "LOAN", null)
                };
                governmentSchemeRepository.saveAll(Arrays.asList(schemes));
                logger.info("✅ Created {} government schemes", schemes.length);
            }

            // Create sample forum topics
            if (forumTopicRepository.count() == 0 && userRepository.count() > 0) {
                Long userId = userRepository.findAll().get(0).getId();
                ForumTopic[] topics = {
                    createForumTopic(userId, "Best pest control for rice?", "Need organic methods", "PEST_CONTROL"),
                    createForumTopic(userId, "Drip irrigation installation cost?", "What is the investment?", "IRRIGATION"),
                    createForumTopic(userId, "Government subsidy for organic farming?", "Are there schemes available?", "GOVERNMENT_SCHEMES")
                };
                forumTopicRepository.saveAll(Arrays.asList(topics));
                logger.info("✅ Created {} forum topics", topics.length);
            }

            // Create sample products
            if (productRepository.count() == 0 && userRepository.count() > 0) {
                Long userId = userRepository.findAll().get(0).getId();
                Product[] products = {
                    createProduct(userId, "Organic Basmati Rice", "Premium quality", 65.50, "CROPS"),
                    createProduct(userId, "Fresh Tomatoes", "Farm fresh", 40.00, "VEGETABLES"),
                    createProduct(userId, "Wheat Seeds", "High yield variety", 35.00, "SEEDS")
                };
                productRepository.saveAll(Arrays.asList(products));
                logger.info("✅ Created {} marketplace products", products.length);
            }

            logger.info("🎉 Sample data initialization complete!");
        };
    }

    private EducationalContent createContent(String title, String excerpt, String category, String author) {
        EducationalContent content = new EducationalContent();
        content.setTitle(title);
        content.setContent("Complete guide for " + title.toLowerCase());
        content.setExcerpt(excerpt);
        content.setCategory(category);
        content.setAuthor(author);
        content.setPublished(true);
        content.setFeatured(true);
        content.setContentType(EducationalContent.ContentType.ARTICLE);
        content.setDifficultyLevel(EducationalContent.DifficultyLevel.BEGINNER);
        content.setEstimatedReadingTimeMinutes(10);
        return content;
    }

    private Notification createNotification(Long userId, String title, String message, 
                                           Notification.NotificationType type, Notification.Priority priority) {
        Notification notification = new Notification();
        notification.setUserId(userId);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setType(type);
        notification.setPriority(priority);
        notification.setIsRead(false);
        return notification;
    }

    private GovernmentScheme createScheme(String name, String description, String category, Double benefitAmount) {
        GovernmentScheme scheme = new GovernmentScheme();
        scheme.setName(name);
        scheme.setDescription(description);
        scheme.setCategory(category);
        if (benefitAmount != null) {
            scheme.setBenefitAmount(BigDecimal.valueOf(benefitAmount));
        }
        scheme.setIsActive(true);
        scheme.setOfficialWebsite("https://example.com");
        scheme.setHelplineNumber("1800-XXX-XXXX");
        return scheme;
    }

    private ForumTopic createForumTopic(Long userId, String title, String content, String category) {
        ForumTopic topic = new ForumTopic();
        topic.setUserId(userId);
        topic.setTitle(title);
        topic.setContent(content);
        topic.setCategory(category);
        topic.setStatus(ForumTopic.TopicStatus.ACTIVE);
        return topic;
    }

    private Product createProduct(Long userId, String name, String description, Double price, String category) {
        Product product = new Product();
        product.setSellerId(userId);
        product.setProductName(name);
        product.setDescription(description);
        product.setPrice(BigDecimal.valueOf(price));
        product.setCategory(category);
        product.setQuantityAvailable(BigDecimal.valueOf(100));
        product.setUnit("kg");
        product.setQualityGrade("PREMIUM");
        product.setOrganicCertified(true);
        product.setAvailableForSale(true);
        return product;
    }
}


# Kheti Sahayak - Product Requirements Document (PRD)

## 1. Introduction

### 1.1. Document Overview
This document provides a detailed overview of the Kheti Sahayak platform, including its purpose, goals, scope, target audience, and success metrics. It also outlines the functional and non-functional requirements for the initial release (v1.0).

### 1.2. Purpose and Goals
**Purpose:** "Kheti Sahayak" intends to empower Indian farmers by introducing digital solutions that bridge informational and transactional gaps in the agricultural sector.

**Goals:**
*   Increase farmer income by 15% within the first two years of adoption.
*   Reduce crop loss due to pests and diseases by 20% through timely diagnostics and advisories.
*   Achieve a user base of 1 million active farmers within the first 18 months of launch.
*   Provide timely and accurate agricultural information (weather, market prices, best practices).
*   Facilitate access to resources (seeds, fertilizers, equipment, labor).
*   Connect farmers with experts and a supportive community.
*   Offer tools for better farm management and record-keeping.

### 1.3. Scope
**In Scope (v1.0):**
*   Mobile application for Android.
*   Core features: Localised Weather Forecast, Crop Health Diagnostics, Marketplace (for inputs), Educational Content, Community Forum, and Digital Logbook.
*   Support for 5 major Indian languages.

**Out of Scope (v1.0):**
*   iOS application.
*   Web portal for farmers (a basic admin panel will be available).
*   Advanced features like AI-powered price predictions and AR-based farm tours.
*   Full-fledged equipment and labor sharing marketplace (will be a simplified version).
*   Integration with all government schemes (will start with a select few).

### 1.4. Success Metrics
*   **User Adoption:** Number of app downloads, registrations, and monthly active users (MAUs).
*   **Feature Engagement:** Frequency of use for key features (e.g., number of diagnostic scans, marketplace transactions, forum posts).
*   **User Satisfaction:** Net Promoter Score (NPS) and app store ratings.
*   **Impact:** Surveys and data analysis to measure the impact on farmer income and crop yield.
*   **Marketplace Performance:** Gross Merchandise Value (GMV) and number of transactions.

## 2. User Profiles

### 2.1. Farmers
*   **Role:** Primary users of the platform.
*   **Needs:** Timely information, access to resources, expert advice, and a supportive community.
*   **Responsibilities:** Seek information, consume from the marketplace, participate in the community, and maintain their farm logbook.

### 2.2. Experts
*   **Role:** Agronomists and agricultural scientists.
*   **Needs:** A platform to share their knowledge and connect with farmers.
*   **Responsibilities:** Provide expert advice, host webinars, and contribute to the educational content.

### 2.3. Vendors
*   **Role:** Suppliers of agricultural inputs.
*   **Needs:** A platform to reach a wider customer base.
*   **Responsibilities:** List products, manage orders, and ensure quality.

### 2.4. Laborers
*   **Role:** Individuals offering farm labor services.
*   **Needs:** A platform to find work opportunities.
*   **Responsibilities:** Maintain a profile and fulfill tasks professionally.

### 2.5. Platform Administrators
*   **Role:** Internal team managing the platform.
*   **Needs:** Tools to manage users, content, and transactions.
*   **Responsibilities:** Content moderation, user verification, dispute resolution, and platform analytics.

## 3. Features and Functionalities

### 3.1. Localised Weather Forecast
**User Story:** As a farmer, I want to see the weather forecast for my specific location so that I can plan my farming activities accordingly.

**Acceptance Criteria:**
*   The app must display the current weather conditions, including temperature, humidity, and wind speed.
*   The app must provide a 7-day weather forecast.
*   The app must send push notifications for critical weather events, such as heavy rain, storms, or heatwaves.
*   The weather data must be accurate to the village level.
### 3.2. Crop Health Diagnostics
**User Story:** As a farmer, I want to take a photo of my crop to identify diseases, and receive treatment recommendations, so that I can take timely action to protect my crops.

**Acceptance Criteria:**
*   The user must be able to capture or upload a photo of the affected crop.
*   The app must use an AI model to identify the disease/pest with at least 85% accuracy.
*   The app must provide a detailed diagnosis, including the name of the issue and its symptoms.
*   The app must recommend appropriate treatments, including organic and chemical options.
*   The app must save a history of all diagnoses for future reference.
*   The feature must have basic offline capabilities. For more details, see [Crop Health Diagnostics](./features/crop_health_diagnostics.md).
### 3.3. Marketplace
**User Story:** As a farmer, I want to buy seeds, fertilizers, and other farming inputs from a trusted online marketplace, so that I can get quality products at a fair price.

**Acceptance Criteria:**
*   The marketplace must list products from verified vendors.
*   The user must be able to search and filter products based on category, brand, and price.
*   The user must be able to view product details, including description, price, and vendor information.
*   The user must be able to add products to a cart and place an order.
*   The app must support multiple payment options, including cash on delivery, UPI, and net banking.
*   The app must provide order tracking and delivery updates.
### 3.4. Educational Content
**User Story:** As a farmer, I want to access articles, videos, and other educational resources on modern farming techniques, so that I can improve my knowledge and skills.

**Acceptance Criteria:**
*   The app must provide a library of educational content in various formats (articles, videos, infographics).
*   The content must be curated by agricultural experts and cover a wide range of topics.
*   The user must be able to search and filter content by crop, topic, and format.
*   The content must be available in multiple Indian languages.
*   The app must allow users to save content for offline viewing.
### 3.5. Community Forum
**User Story:** As a farmer, I want to connect with other farmers and experts in a community forum, so that I can ask questions, share my experiences, and learn from others.

**Acceptance Criteria:**
*   The user must be able to create a profile and participate in discussions.
*   The user must be able to create new posts and comment on existing posts.
*   The forum must be organized into categories based on crops and topics.
*   The user must be able to search for posts and filter them by category and date.
*   The forum must be moderated to ensure a safe and respectful environment.
*   The user must be able to receive notifications for replies and mentions.
### 3.6. Digital Logbook
**User Story:** As a farmer, I want to maintain a digital logbook of my farming activities, so that I can track my expenses, yields, and other important data.

**Acceptance Criteria:**
*   The user must be able to record various activities, such as sowing, irrigation, fertilization, and harvesting.
*   The user must be able to track expenses for each activity, such as the cost of seeds, fertilizers, and labor.
*   The user must be able to record the yield for each crop.
*   The app must provide a summary of the data in the logbook, including total expenses, total yield, and profit/loss.
*   The user must be able to export the logbook data as a PDF or CSV file.

### 3.7. Government Scheme Portal
**User Story:** As a farmer, I want to get information about relevant government schemes and subsidies, so that I can avail the benefits.

**Acceptance Criteria:**
*   The app must provide a list of relevant government schemes for farmers.
*   The user must be able to filter the schemes by state and category.
*   The app must provide detailed information about each scheme, including eligibility criteria, benefits, and application process.
*   The app must provide links to the official government websites for applying to the schemes.
*   The user must be able to receive notifications about new and upcoming schemes.

### 3.8. Expert Connect
**User Story:** As a farmer, I want to connect with agricultural experts to get personalized advice and answers to my questions.

**Acceptance Criteria:**
*   The app must provide a list of available experts with their profiles, including their area of expertise and experience.
*   The user must be able to schedule a chat or video call with an expert.
*   The app must have a real-time chat and video call functionality.
*   The user must be able to share images and documents with the expert during the consultation.
*   The user must be able to rate and review the expert after the consultation.

## 4. Non-Functional Requirements

### 4.1. Performance
*   The app should launch within 3 seconds.
*   All screens should load within 2 seconds on a 3G connection.
*   The app should not consume more than 150MB of RAM.

### 4.2. Scalability
*   The backend infrastructure must be able to handle 1 million active users.
*   The database should be able to store and process large amounts of data, including images and user-generated content.

### 4.3. Security
*   All user data must be encrypted, both in transit and at rest.
*   The app must be protected against common security vulnerabilities, such as SQL injection and cross-site scripting (XSS).
*   User authentication must be secure, with support for password hashing and session management.

### 4.4. Usability
*   The app must have a simple and intuitive user interface, designed for users with low digital literacy.
*   The app must be available in at least 5 major Indian languages.
*   The app must provide clear and concise instructions and feedback to the user.

### 4.5. Reliability
*   The app must have an uptime of at least 99.5%.
*   The app should handle network interruptions gracefully and sync data when the connection is restored.
*   The app should have a robust error handling mechanism to prevent crashes.

## 5. Future Enhancements
*   Interactive AI Advisor (Chatbot).
*   Market Price Predictions.
*   Virtual Farm Tours (AR).
*   Integration with a wider range of government schemes.
*   Full-fledged equipment and labor sharing marketplace.
*   iOS application and web portal.

# Component Diagram

```mermaid
graph TD
    subgraph "Client Tier"
        direction LR
        component "Mobile App" as MobileApp
        component "Web Portal" as WebPortal
    end

    subgraph "Application Tier (Backend Services)"
        direction TB
        component "API Gateway" as APIGateway
        component "Authentication Service" as AuthService
        component "User Profile Service" as UserProfileService
        component "Marketplace Service" as MarketplaceService
        component "Crop Diagnostics Service" as CropDiagnosticsService
        component "Notification Service" as NotificationService
        component "Integration Service" as IntegrationService
        component "Admin & Monitoring Service" as AdminService
        component "Knowledge Base Service" as KnowledgeBaseService
        component "Expert Advisory Service" as ExpertAdvisoryService
        component "AI/ML Module" as AI_ML_Module
    end

    subgraph "Data Tier"
        direction LR
        database "Relational DB" as RelationalDB
        database "NoSQL DB" as NoSQLDB
        database "Object Storage" as ObjectStorage
        database "Caching Layer" as Cache
    end

    subgraph "External Services"
        direction TB
        component "Weather Service" as WeatherService
        component "Payment Gateway" as PaymentGateway
        component "Translation Service" as TranslationService
        component "Government Schemes API" as GovtAPI
        component "SMS/Email Service" as SMSEmailService
    end

    MobileApp --> APIGateway
    WebPortal --> APIGateway

    APIGateway --> AuthService
    APIGateway --> UserProfileService
    APIGateway --> MarketplaceService
    APIGateway --> CropDiagnosticsService
    APIGateway --> NotificationService
    APIGateway --> IntegrationService
    APIGateway --> AdminService
    APIGateway --> KnowledgeBaseService
    APIGateway --> ExpertAdvisoryService

    CropDiagnosticsService --> AI_ML_Module
    UserProfileService --> RelationalDB
    MarketplaceService --> RelationalDB
    MarketplaceService --> NoSQLDB
    CropDiagnosticsService --> NoSQLDB
    CropDiagnosticsService --> ObjectStorage
    KnowledgeBaseService --> NoSQLDB
    ExpertAdvisoryService --> RelationalDB

    IntegrationService --> WeatherService
    IntegrationService --> PaymentGateway
    IntegrationService --> TranslationService
    IntegrationService --> GovtAPI
    NotificationService --> SMSEmailService

    AuthService --> RelationalDB
    AdminService --> RelationalDB

    MarketplaceService --> Cache
    CropDiagnosticsService --> Cache
    KnowledgeBaseService --> Cache
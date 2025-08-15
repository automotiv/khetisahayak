# Sequence Diagrams

## User Registration

```mermaid
sequenceDiagram
    participant User
    participant MobileApp
    participant APIGateway
    participant AuthService
    participant UserProfileService
    participant RelationalDB

    User->>MobileApp: Enters registration details
    MobileApp->>APIGateway: POST /register (details)
    APIGateway->>AuthService: register(details)
    AuthService->>RelationalDB: Check if user exists
    RelationalDB-->>AuthService: User does not exist
    AuthService->>RelationalDB: Create user record (hashed password)
    RelationalDB-->>AuthService: User record created
    AuthService->>UserProfileService: createUserProfile(userId, details)
    UserProfileService->>RelationalDB: Create user profile record
    RelationalDB-->>UserProfileService: Profile created
    UserProfileService-->>AuthService: Profile creation successful
    AuthService-->>APIGateway: Registration successful (JWT token)
    APIGateway-->>MobileApp: 201 Created (JWT token)
    MobileApp-->>User: Display success message
```

## Crop Diagnostics

```mermaid
sequenceDiagram
    participant Farmer
    participant MobileApp
    participant APIGateway
    participant CropDiagnosticsService
    participant ObjectStorage
    participant AI_ML_Module
    participant ExpertAdvisoryService
    participant NotificationService

    Farmer->>MobileApp: Uploads crop image
    MobileApp->>APIGateway: POST /diagnostics/upload (image)
    APIGateway->>CropDiagnosticsService: uploadImage(image)
    CropDiagnosticsService->>ObjectStorage: Store image
    ObjectStorage-->>CropDiagnosticsService: Image URL
    CropDiagnosticsService->>AI_ML_Module: analyzeImage(imageURL)
    AI_ML_Module-->>CropDiagnosticsService: Analysis result (disease, confidence)
    alt Confidence is high
        CropDiagnosticsService->>APIGateway: Diagnosis result
        APIGateway-->>MobileApp: Display diagnosis to Farmer
    else Confidence is low
        CropDiagnosticsService->>ExpertAdvisoryService: createHelpTicket(imageURL, analysis)
        ExpertAdvisoryService-->>CropDiagnosticsService: Ticket created
        CropDiagnosticsService->>NotificationService: notifyExpert(ticketId)
        NotificationService-->>CropDiagnosticsService: Notification sent
        CropDiagnosticsService->>APIGateway: "Diagnosis sent for expert review"
        APIGateway-->>MobileApp: Display message to Farmer
    end
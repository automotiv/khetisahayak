# Sequence Diagrams – Kheti Sahayak Platform

This document presents key workflow sequence diagrams using Mermaid syntax for clarity and developer reference.

---

## 1. User Registration & Login

```mermaid
sequenceDiagram
    participant User
    participant MobileApp
    participant AuthService
    participant Database
    User->>MobileApp: Open app, select register/login
    MobileApp->>AuthService: POST /register or /login (credentials)
    AuthService->>Database: Validate/store user, check password
    Database-->>AuthService: Success/failure
    AuthService-->>MobileApp: JWT token or error
    MobileApp-->>User: Show success/error
```

---

## 2. Marketplace Listing Creation & Purchase

```mermaid
sequenceDiagram
    participant Seller
    participant MobileApp
    participant MarketplaceAPI
    participant Database
    Seller->>MobileApp: Create listing
    MobileApp->>MarketplaceAPI: POST /listings (listing data)
    MarketplaceAPI->>Database: Store listing
    Database-->>MarketplaceAPI: Listing ID
    MarketplaceAPI-->>MobileApp: Listing created
    MobileApp-->>Seller: Show confirmation
    Note over Buyer,MobileApp: Buyer views listings
    Buyer->>MobileApp: Browse listings
    MobileApp->>MarketplaceAPI: GET /listings
    MarketplaceAPI-->>MobileApp: Listings
    MobileApp-->>Buyer: Show listings
    Buyer->>MobileApp: Initiate purchase
    MobileApp->>MarketplaceAPI: POST /transactions
    MarketplaceAPI->>Database: Create transaction
    Database-->>MarketplaceAPI: Transaction ID
    MarketplaceAPI-->>MobileApp: Transaction started
    MobileApp-->>Buyer: Proceed to payment
```

---

## 3. Payment Transaction

```mermaid
sequenceDiagram
    participant Buyer
    participant MobileApp
    participant MarketplaceAPI
    participant PaymentGateway
    Buyer->>MobileApp: Confirm purchase
    MobileApp->>MarketplaceAPI: POST /payments/initiate
    MarketplaceAPI->>PaymentGateway: Initiate payment
    PaymentGateway-->>MarketplaceAPI: Payment URL
    MarketplaceAPI-->>MobileApp: Show payment link
    Buyer->>PaymentGateway: Complete payment
    PaymentGateway-->>MarketplaceAPI: Payment status callback
    MarketplaceAPI->>MobileApp: Confirm payment
    MobileApp-->>Buyer: Show confirmation
```

---

## 4. Crop Diagnostics Request & Result

```mermaid
sequenceDiagram
    participant Farmer
    participant MobileApp
    participant DiagnosticsAPI
    participant AIModule
    participant Database
    Farmer->>MobileApp: Upload crop image
    MobileApp->>DiagnosticsAPI: POST /diagnostics/submit
    DiagnosticsAPI->>AIModule: Analyze image
    AIModule-->>DiagnosticsAPI: Diagnosis result
    DiagnosticsAPI->>Database: Store result
    Database-->>DiagnosticsAPI: Confirm store
    DiagnosticsAPI-->>MobileApp: Notify result ready
    MobileApp-->>Farmer: Show diagnosis/advisory
```

---

## 5. Notification Delivery

```mermaid
sequenceDiagram
    participant System
    participant NotificationAPI
    participant SMSProvider
    participant PushService
    participant User
    System->>NotificationAPI: POST /send (message, type)
    alt SMS
        NotificationAPI->>SMSProvider: Send SMS
        SMSProvider-->>NotificationAPI: Delivery status
    else Push
        NotificationAPI->>PushService: Send push notification
        PushService-->>NotificationAPI: Delivery status
    end
    NotificationAPI-->>System: Status
    User-->>NotificationAPI: Receives message
```

---

## 6. Admin Audit & Monitoring

```mermaid
sequenceDiagram
    participant Admin
    participant AdminApp
    participant AdminAPI
    participant Database
    Admin->>AdminApp: Request audit logs/system status
    AdminApp->>AdminAPI: GET /audit/logs or /system/status
    AdminAPI->>Database: Query logs/status
    Database-->>AdminAPI: Data
    AdminAPI-->>AdminApp: Results
    AdminApp-->>Admin: Display logs/status
```

---

## 7. User Password Reset (via OTP)

```mermaid
sequenceDiagram
    participant User
    participant MobileApp
    participant AuthService
    participant SMSProvider
    User->>MobileApp: Request password reset
    MobileApp->>AuthService: POST /auth/request-reset (phone)
    AuthService->>SMSProvider: Send OTP
    SMSProvider-->>User: Deliver OTP
    User->>MobileApp: Enter OTP, new password
    MobileApp->>AuthService: POST /auth/reset-password (OTP, new password)
    AuthService-->>MobileApp: Success/failure
    MobileApp-->>User: Show result
```

---

## 8. User Profile Update

```mermaid
sequenceDiagram
    participant User
    participant MobileApp
    participant UserAPI
    participant Database
    User->>MobileApp: Edit profile details
    MobileApp->>UserAPI: PUT /users/me (profile data)
    UserAPI->>Database: Update user record
    Database-->>UserAPI: Confirm update
    UserAPI-->>MobileApp: Success/failure
    MobileApp-->>User: Show result
```

---

## 9. External API Integration (Weather Example)

```mermaid
sequenceDiagram
    participant User
    participant MobileApp
    participant IntegrationAPI
    participant WeatherAPI
    User->>MobileApp: Request weather info
    MobileApp->>IntegrationAPI: GET /integrations/weather (location)
    IntegrationAPI->>WeatherAPI: Fetch weather data
    WeatherAPI-->>IntegrationAPI: Weather response
    IntegrationAPI-->>MobileApp: Weather data
    MobileApp-->>User: Show weather info
```

---

## 10. Data Backup and Restore

```mermaid
sequenceDiagram
    participant System
    participant BackupService
    participant ObjectStorage
    participant Database
    System->>BackupService: Schedule/trigger backup
    BackupService->>Database: Export data
    Database-->>BackupService: Data dump
    BackupService->>ObjectStorage: Store backup
    ObjectStorage-->>BackupService: Confirm store
    BackupService-->>System: Backup complete
    Note over System,BackupService: Restore flow similar, in reverse
```

---

## 11. Mobile App: Offline Data Sync

```mermaid
sequenceDiagram
    participant User
    participant MobileApp
    participant SyncAPI
    participant Database
    User->>MobileApp: Use app offline
    MobileApp->>MobileApp: Store changes locally
    alt Connectivity Restored
        MobileApp->>SyncAPI: Sync local changes
        SyncAPI->>Database: Update records
        Database-->>SyncAPI: Confirm
        SyncAPI-->>MobileApp: Sync complete
    end
    MobileApp-->>User: Data up-to-date
```

---

## 12. Admin: User Deletion or Suspension

```mermaid
sequenceDiagram
    participant Admin
    participant AdminApp
    participant AdminAPI
    participant Database
    Admin->>AdminApp: Select user to delete/suspend
    AdminApp->>AdminAPI: DELETE /users/{user_id} or POST /users/{user_id}/suspend
    AdminAPI->>Database: Update/delete user record
    Database-->>AdminAPI: Confirm action
    AdminAPI-->>AdminApp: Success/failure
    AdminApp-->>Admin: Show result
```

---

## 13. Marketplace Dispute Resolution

```mermaid
sequenceDiagram
    participant Buyer
    participant Seller
    participant MobileApp
    participant MarketplaceAPI
    participant Admin
    Buyer->>MobileApp: Raise dispute
    MobileApp->>MarketplaceAPI: POST /disputes (details)
    MarketplaceAPI->>Admin: Notify admin
    Admin->>MarketplaceAPI: Review dispute
    MarketplaceAPI->>Buyer: Request additional info (if needed)
    Buyer-->>MarketplaceAPI: Provide info
    Admin->>MarketplaceAPI: Resolve dispute
    MarketplaceAPI->>Buyer: Notify resolution
    MarketplaceAPI->>Seller: Notify resolution
```

---

## 14. Notification: Multichannel Delivery (SMS, Email, Push)

```mermaid
sequenceDiagram
    participant System
    participant NotificationAPI
    participant SMSProvider
    participant EmailProvider
    participant PushService
    participant User
    System->>NotificationAPI: POST /send (message, type)
    alt SMS
        NotificationAPI->>SMSProvider: Send SMS
        SMSProvider-->>NotificationAPI: Delivery status
    else Email
        NotificationAPI->>EmailProvider: Send Email
        EmailProvider-->>NotificationAPI: Delivery status
    else Push
        NotificationAPI->>PushService: Send push notification
        PushService-->>NotificationAPI: Delivery status
    end
    NotificationAPI-->>System: Status
    User-->>NotificationAPI: Receives message
```

---

## 15. Audit Log Review and Export

```mermaid
sequenceDiagram
    participant Admin
    participant AdminApp
    participant AdminAPI
    participant Database
    Admin->>AdminApp: Request audit logs/export
    AdminApp->>AdminAPI: GET /audit/logs or /audit/export
    AdminAPI->>Database: Query/export logs
    Database-->>AdminAPI: Log data/file
    AdminAPI-->>AdminApp: Download link or logs
    AdminApp-->>Admin: Display logs/provide download
```

---

## 16. Role/Permission Change by Admin

```mermaid
sequenceDiagram
    participant Admin
    participant AdminApp
    participant AdminAPI
    participant Database
    Admin->>AdminApp: Change user role/permissions
    AdminApp->>AdminAPI: POST /users/{user_id}/role (new role)
    AdminAPI->>Database: Update role/permissions
    Database-->>AdminAPI: Confirm update
    AdminAPI-->>AdminApp: Success/failure
    AdminApp-->>Admin: Show result
```

---

## 17. Payment Refund Process

```mermaid
sequenceDiagram
    participant User
    participant MobileApp
    participant MarketplaceAPI
    participant PaymentGateway
    User->>MobileApp: Request refund
    MobileApp->>MarketplaceAPI: POST /refunds (transaction_id)
    MarketplaceAPI->>PaymentGateway: Initiate refund
    PaymentGateway-->>MarketplaceAPI: Refund status
    MarketplaceAPI-->>MobileApp: Notify refund processed
    MobileApp-->>User: Show refund status
```

---

## 18. User Consent Management / Privacy Controls

```mermaid
sequenceDiagram
    participant User
    participant MobileApp
    participant UserAPI
    participant Database
    User->>MobileApp: Update privacy/consent settings
    MobileApp->>UserAPI: PUT /users/me/consent (settings)
    UserAPI->>Database: Update consent record
    Database-->>UserAPI: Confirm update
    UserAPI-->>MobileApp: Success/failure
    MobileApp-->>User: Show result
```

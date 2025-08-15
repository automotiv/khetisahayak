# Deployment Diagram

```mermaid
graph TD
    subgraph "User Devices"
        direction LR
        node "Mobile Device (Android/iOS)" {
            artifact "Kheti Sahayak App" as MobileApp
        }
        node "Web Browser" {
            artifact "Web Portal" as WebPortal
        }
    end

    subgraph "Cloud Infrastructure (e.g., AWS, Azure, GCP)"
        direction TB
        node "Kubernetes Cluster" {
            node "Node 1" {
                pod "Auth Service Pod" {
                    artifact "Auth Service" as AuthService
                }
                pod "User Profile Pod" {
                    artifact "User Profile Service" as UserProfileService
                }
            }
            node "Node 2" {
                pod "Marketplace Pod" {
                    artifact "Marketplace Service" as MarketplaceService
                }
                pod "Crop Diagnostics Pod" {
                    artifact "Crop Diagnostics Service" as CropDiagnosticsService
                }
            }
            node "Node 3" {
                pod "Notification Pod" {
                    artifact "Notification Service" as NotificationService
                }
                pod "Integration Pod" {
                    artifact "Integration Service" as IntegrationService
                }
            }
        }

        node "Managed Databases" {
            database "Relational DB (e.g., PostgreSQL, MySQL)" as RelationalDB
            database "NoSQL DB (e.g., MongoDB, DynamoDB)" as NoSQLDB
            database "Object Storage (e.g., S3, Blob Storage)" as ObjectStorage
            database "Cache (e.g., Redis, Memcached)" as Cache
        }
    end

    subgraph "Third-Party Services"
        direction TB
        node "Weather API"
        node "Payment Gateway"
        node "Translation API"
        node "SMS/Email Gateway"
        node "Government APIs"
    end

    MobileApp --> "Kubernetes Cluster"
    WebPortal --> "Kubernetes Cluster"

    AuthService --> RelationalDB
    UserProfileService --> RelationalDB
    MarketplaceService --> RelationalDB
    MarketplaceService --> NoSQLDB
    CropDiagnosticsService --> NoSQLDB
    CropDiagnosticsService --> ObjectStorage
    MarketplaceService --> Cache

    IntegrationService --> "Weather API"
    IntegrationService --> "Payment Gateway"
    IntegrationService --> "Translation API"
    IntegrationService --> "Government APIs"
    NotificationService --> "SMS/Email Gateway"
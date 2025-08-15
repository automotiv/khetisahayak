# Use Case Diagram

```mermaid
graph TD
    subgraph "Kheti Sahayak Platform"
        direction LR

        actor Farmer
        actor Expert
        actor Vendor
        actor Laborer
        actor Administrator

        rectangle "User Management" {
            usecase "Manage Profile" as UC1
            usecase "User Authentication" as UC1a
        }

        rectangle "Core Features" {
            usecase "View Weather Forecast" as UC2
            usecase "Diagnose Crop Health" as UC3
            usecase "Get Farming Recommendations" as UC4
            usecase "Access Educational Content" as UC7
            usecase "Connect with Experts" as UC8
            usecase "Participate in Community Forum" as UC9
            usecase "Maintain Digital Logbook" as UC10
            usecase "View Government Schemes" as UC11
        }

        rectangle "Marketplace" {
            usecase "Manage Marketplace Listings" as UC5
            usecase "Purchase Products" as UC6
            usecase "Share/Rent Equipment & Labor" as UC6a
        }

        rectangle "Admin Functions" {
            usecase "Manage Users" as UC12
            usecase "Moderate Content" as UC13
            usecase "Monitor System" as UC14
        }

        Farmer --> UC1
        Farmer --> UC2
        Farmer --> UC3
        Farmer --> UC4
        Farmer --> UC6
        Farmer --> UC6a
        Farmer --> UC7
        Farmer --> UC8
        Farmer --> UC9
        Farmer --> UC10
        Farmer --> UC11

        Expert --> UC1
        Expert --> UC7
        Expert --> UC8
        Expert --> UC9

        Vendor --> UC1
        Vendor --> UC5

        Laborer --> UC1
        Laborer --> UC6a

        Administrator --> UC12
        Administrator --> UC13
        Administrator --> UC14

        UC1 --> UC1a
    end
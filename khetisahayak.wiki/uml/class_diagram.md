# Class Diagram

```mermaid
classDiagram
    class User {
        +UUID userId
        +string username
        +string hashedPassword
        +string email
        +UserRole role
        +register()
        +login()
        +logout()
    }

    class UserProfile {
        +UUID profileId
        +string firstName
        +string lastName
        +string location
        +string contactNumber
        +updateProfile()
    }

    class Farm {
        +UUID farmId
        +string name
        +string location
        +float size
        +list~LogEntry~ logbook
    }

    class LogEntry {
        +UUID entryId
        +datetime date
        +string activity
        +string notes
    }

    enum UserRole {
        FARMER
        EXPERT
        VENDOR
        LABORER
        ADMIN
    }

    class Farmer {
        +list~Farm~ farms
    }

    class Expert {
        +string specialization
        +string qualifications
        +provideAdvice()
        +createContent()
    }

    class Vendor {
        +string businessName
        +list~Product~ products
        +addProduct()
        +removeProduct()
    }

    class Laborer {
        +list~string~ skills
        +datetime availability
    }

    class Product {
        +UUID productId
        +string name
        +string description
        +float price
        +int stock
    }

    class Order {
        +UUID orderId
        +datetime orderDate
        +OrderStatus status
        +list~Product~ items
        +calculateTotal()
    }

    class DiagnosticRequest {
        +UUID requestId
        +string imageUrl
        +string description
        +datetime requestDate
        +DiagnosticStatus status
        +string aiResult
        +string expertFeedback
    }

    class EducationalContent {
        +UUID contentId
        +string title
        +string body
        +ContentType type
        +datetime publishedDate
    }

    class ForumThread {
        +UUID threadId
        +string title
        +list~ForumPost~ posts
    }

    class ForumPost {
        +UUID postId
        +string content
        +datetime postDate
    }

    User "1" -- "1" UserProfile : has
    User <|-- Farmer
    User <|-- Expert
    User <|-- Vendor
    User <|-- Laborer

    Farmer "1" -- "*" Farm : owns
    Farm "1" -- "*" LogEntry : has

    Vendor "1" -- "*" Product : lists
    Farmer "1" -- "*" Order : places
    Order "*" -- "*" Product : contains

    Farmer "1" -- "*" DiagnosticRequest : creates
    Expert "0..1" -- "*" DiagnosticRequest : reviews

    Expert "1" -- "*" EducationalContent : authors

    User "1" -- "*" ForumThread : starts
    User "1" -- "*" ForumPost : writes
    ForumThread "1" -- "*" ForumPost : contains
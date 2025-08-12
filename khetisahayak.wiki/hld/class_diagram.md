# Class Diagram

```plantuml
@startuml
class User {
  +String userId
  +String name
  +String email
  +String password
  +String role
  +void login()
  +void logout()
  +void register()
  +void updateProfile()
}

class Farmer {
  +List<Farm> farms
  +void addFarm()
  +void viewWeatherForecast()
  +void diagnoseCropHealth()
  +void browseMarketplace()
  +void purchaseProducts()
  +void manageOrders()
  +void viewEducationalContent()
  +void participateInCommunityForum()
  +void maintainDigitalLogbook()
  +void viewGovernmentSchemes()
  +void connectWithExperts()
}

class Expert {
  +String specialization
  +void provideAdvice()
  +void answerQuestions()
}

class Vendor {
  +List<Product> products
  +void addProduct()
  +void manageProducts()
  +void manageOrders()
}

class Administrator {
  +void manageUsers()
  +void manageContent()
}

class Farm {
  +String farmId
  +String location
  +double size
  +List<Crop> crops
}

class Crop {
  +String cropId
  +String name
  +String variety
}

class Product {
  +String productId
  +String name
  +String description
  +double price
  +int quantity
}

class Order {
  +String orderId
  +List<Product> products
  +double totalPrice
  +String status
}

class WeatherForecast {
  +String location
  +Date date
  +double temperature
  +double humidity
  +double windSpeed
}

class CropHealthDiagnostic {
  +String diagnosticId
  +Image image
  +String disease
  +String recommendation
}

class EducationalContent {
  +String contentId
  +String title
  +String content
  +String author
}

class ForumPost {
  +String postId
  +String title
  +String content
  +User author
  +List<Comment> comments
}

class Comment {
  +String commentId
  +String content
  +User author
}

class DigitalLogbook {
  +String logbookId
  +List<LogEntry> entries
}

class LogEntry {
  +String entryId
  +Date date
  +String activity
  +double cost
}

class GovernmentScheme {
  +String schemeId
  +String name
  +String description
  +String eligibility
}

User <|-- Farmer
User <|-- Expert
User <|-- Vendor
User <|-- Administrator

Farmer "1" -- "1..*" Farm
Farm "1" -- "1..*" Crop
Vendor "1" -- "0..*" Product
Farmer "1" -- "0..*" Order
Order "1" -- "1..*" Product
Farmer "1" -- "1" WeatherForecast
Farmer "1" -- "0..*" CropHealthDiagnostic
Farmer "1" -- "0..*" EducationalContent
Farmer "1" -- "0..*" ForumPost
ForumPost "1" -- "0..*" Comment
Farmer "1" -- "1" DigitalLogbook
DigitalLogbook "1" -- "0..*" LogEntry
Farmer "1" -- "0..*" GovernmentScheme
@enduml

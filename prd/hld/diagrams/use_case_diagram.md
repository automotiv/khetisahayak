# Use Case Diagram

```plantuml
@startuml
left to right direction
actor Farmer
actor Expert
actor Vendor
actor Administrator

rectangle "Kheti Sahayak" {
  usecase "Manage Profile" as UC1
  usecase "View Weather Forecast" as UC2
  usecase "Diagnose Crop Health" as UC3
  usecase "Browse Marketplace" as UC4
  usecase "Purchase Products" as UC5
  usecase "Manage Orders" as UC6
  usecase "View Educational Content" as UC7
  usecase "Participate in Community Forum" as UC8
  usecase "Maintain Digital Logbook" as UC9
  usecase "View Government Schemes" as UC10
  usecase "Connect with Experts" as UC11
  usecase "Provide Expert Advice" as UC12
  usecase "Manage Products" as UC13
  usecase "Manage Users" as UC14
  usecase "Manage Content" as UC15
}

Farmer -- (UC1)
Farmer -- (UC2)
Farmer -- (UC3)
Farmer -- (UC4)
Farmer -- (UC5)
Farmer -- (UC6)
Farmer -- (UC7)
Farmer -- (UC8)
Farmer -- (UC9)
Farmer -- (UC10)
Farmer -- (UC11)

Expert -- (UC1)
Expert -- (UC12)
Expert -- (UC8)

Vendor -- (UC1)
Vendor -- (UC13)
Vendor -- (UC6)

Administrator -- (UC14)
Administrator -- (UC15)
@enduml

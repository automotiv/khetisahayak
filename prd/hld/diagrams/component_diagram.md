# Component Diagram

```plantuml
@startuml
package "Kheti Sahayak App" {
  [UI]
  [Business Logic]
  [Data Access]
}

package "Kheti Sahayak Server" {
  [API]
  [Business Logic]
  [Data Access]
}

database "Database" {
  [Users]
  [Farms]
  [Crops]
  [Products]
  [Orders]
  [Weather Data]
  [Diagnostics]
  [Educational Content]
  [Forum]
  [Logbook]
  [Government Schemes]
}

actor "External Services" {
  [Weather Service]
  [AI Service]
  [Payment Gateway]
}

[UI] --> [Business Logic]
[Business Logic] --> [Data Access]
[Data Access] --> [API]

[API] --> [Business Logic]
[Business Logic] --> [Data Access]
[Data Access] --> [Database]

[Business Logic] --> [Weather Service]
[Business Logic] --> [AI Service]
[Business Logic] --> [Payment Gateway]
@enduml

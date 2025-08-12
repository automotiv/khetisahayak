# Deployment Diagram

```plantuml
@startuml
node "Mobile Device" {
  artifact "Kheti Sahayak App"
}

node "Cloud Server" {
  node "Web Server" {
    artifact "Kheti Sahayak Server"
  }
  database "Database" {
    artifact "Kheti Sahayak Database"
  }
}

"Kheti Sahayak App" -- "Kheti Sahayak Server" : HTTPS
"Kheti Sahayak Server" -- "Kheti Sahayak Database" : TCP/IP
@enduml

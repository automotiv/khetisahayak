# Sequence Diagram

## User Registration

```plantuml
@startuml
actor User
participant App
participant Server
database Database

User -> App: Enters registration details
App -> Server: POST /api/register
Server -> Database: INSERT into Users table
Database --> Server: Success
Server --> App: 201 Created
App --> User: Shows success message
@enduml
```

## Crop Health Diagnostics

```plantuml
@startuml
actor Farmer
participant App
participant Server
participant AI_Service

Farmer -> App: Uploads crop image
App -> Server: POST /api/diagnose
Server -> AI_Service: POST /diagnose
AI_Service --> Server: Returns diagnosis
Server -> App: Returns diagnosis
App -> Farmer: Displays diagnosis and recommendations
@enduml

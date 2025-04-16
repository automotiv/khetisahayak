# HLD Overview: Kheti Sahayak

## System Architecture

```mermaid
graph TD
  A[Mobile App (Android/iOS)] --API--> B(Backend Services)
  C[Web Portal (Optional)] --API--> B
  B --DB--> D[(Relational DB)]
  B --NoSQL--> E[(NoSQL DB)]
  B --Object Storage--> F[(Object Storage)]
  B --Cache--> G[(Caching Layer)]
  B --Weather API--> H[Weather Service]
  B --Payment Gateway--> I[Payment Service]
  B --SMS/Email--> J[Notification Service]
  B --Translation API--> K[Translation Service]
  B --Govt Data--> L[Government Schemes]
```

## Major Components
- Mobile App (Android/iOS)
- Web Portal (optional)
- Backend Services (Microservices)
- Databases (Relational, NoSQL)
- Object Storage
- Caching
- Third-party Integrations

See detailed files for each subsystem.

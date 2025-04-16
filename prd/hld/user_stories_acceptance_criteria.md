# User Stories & Acceptance Criteria – Kheti Sahayak Platform

This document provides user stories and acceptance criteria for the major modules of the platform, supporting development, QA, and stakeholder alignment.

---

## 1. Authentication & User Management

### User Stories
- As a farmer, I want to register using my phone number so that I can access the platform securely.
- As a user, I want to log in with my credentials so that I can access my personalized data.
- As a user, I want to reset my password using OTP so that I can recover my account securely.
- As an admin, I want to suspend or delete users so that I can manage platform access.

### Acceptance Criteria
- Registration requires valid phone and password; duplicate phone numbers are rejected.
- Login issues a JWT token on success; invalid credentials return an error.
- Password reset requires OTP verification; OTP expires after 5 minutes.
- Only admins can suspend/delete users; actions are audited.

---

## 2. Marketplace

### User Stories
- As a farmer, I want to create listings for my produce so that buyers can discover and purchase them.
- As a buyer, I want to browse and filter marketplace listings so that I can find relevant products.
- As a buyer, I want to initiate and complete purchases securely.
- As a user, I want to raise disputes for problematic transactions so that issues are resolved fairly.

### Acceptance Criteria
- Listings require title, description, price, and location; missing fields are rejected.
- Buyers can filter listings by category/location.
- Transactions are only possible for available listings; payment must be confirmed.
- Disputes are logged, assigned to admin, and resolved with notification to both parties.

---

## 3. Crop Diagnostics

### User Stories
- As a farmer, I want to upload crop images for diagnosis so that I can receive timely advice.
- As a user, I want to view the results and advisories for my past diagnoses.

### Acceptance Criteria
- Image upload requires crop type and location; invalid files are rejected.
- Results are available within 2 minutes for 90% of cases.
- Only the submitting user can access their diagnosis history.

---

## 4. Notification Service

### User Stories
- As a user, I want to receive important alerts via SMS, email, or push so that I stay informed.
- As an admin, I want to broadcast notifications to all users or segments.

### Acceptance Criteria
- Users can opt-in/out of notification channels in profile settings.
- Broadcasts are restricted to admin users.
- Delivery status is tracked for each notification.

---

## 5. Integration (External APIs)

### User Stories
- As a user, I want to view real-time weather data and government advisories within the app.
- As a buyer, I want to complete payments securely via integrated gateways.
- As a multilingual user, I want app content in my preferred language.

### Acceptance Criteria
- Weather and government data are updated at least hourly.
- Payment gateway integration is PCI DSS compliant.
- Translations are available for all supported languages.

---

## 6. Admin & Monitoring

### User Stories
- As an admin, I want to review audit logs so that I can track sensitive actions.
- As an admin, I want to monitor system health and uptime.
- As an admin, I want to export user and transaction data for compliance.

### Acceptance Criteria
- Only admins can access audit logs and system health endpoints.
- Audit logs are tamper-evident and exportable.
- System health dashboard updates every 5 minutes.

---

## 7. Data Privacy & Consent

### User Stories
- As a user, I want to control my data sharing and privacy settings.
- As a user, I want to withdraw consent for data processing at any time.

### Acceptance Criteria
- Privacy/consent settings are accessible in the app.
- Consent changes are logged and take effect immediately.
- Data subject requests (e.g., deletion) are processed within 7 days.

---

## 8. Mobile App: Offline & Sync

### User Stories
- As a user, I want to continue using the app offline and sync data when connectivity is restored.

### Acceptance Criteria
- All offline actions are queued and synced automatically.
- Users are notified of sync status and conflicts.

---

## 9. Backup & Restore

### User Stories
- As an admin, I want to schedule and restore system backups to prevent data loss.

### Acceptance Criteria
- Backups are performed daily and stored securely.
- Restore operations are auditable and require admin approval.

---

For any module-specific expansion, please specify the module or user role.

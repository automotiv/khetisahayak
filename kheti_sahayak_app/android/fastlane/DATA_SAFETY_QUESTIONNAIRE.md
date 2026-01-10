# Google Play Data Safety Questionnaire - Kheti Sahayak

This document provides answers for the Google Play Console Data Safety form based on the app's actual data collection and usage.

---

## Overview

**App Package:** `com.khetisahayak.app`  
**Last Updated:** January 7, 2026

---

## Section 1: Data Collection and Security

### Does your app collect or share any of the required user data types?
**Answer:** YES

### Is all of the user data collected by your app encrypted in transit?
**Answer:** YES
- All API communications use HTTPS/TLS 1.3
- No plain HTTP requests are made

### Do you provide a way for users to request that their data be deleted?
**Answer:** YES
- Users can delete their account from Settings > Account > Delete Account
- Contact support@khetisahayak.com for data deletion requests

---

## Section 2: Data Types Collected

### 2.1 Personal Info

| Data Type | Collected | Shared | Purpose | Required | User Control |
|-----------|-----------|--------|---------|----------|--------------|
| **Name** | YES | NO | Account identification, personalization | Required | Can edit in profile |
| **Email address** | YES | NO | Account recovery, notifications (optional) | Optional | Can remove |
| **Phone number** | YES | NO | Account authentication, OTP verification | Required | Cannot remove |
| **Address** | NO | - | - | - | - |

### 2.2 Location

| Data Type | Collected | Shared | Purpose | Required | User Control |
|-----------|-----------|--------|---------|----------|--------------|
| **Approximate location** | YES | NO | Weather services, local marketplace | Optional | Can disable |
| **Precise location** | YES | NO | Hyperlocal weather forecasts | Optional | Can disable |

**Location Collection Details:**
- Permission: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
- When: Only when user actively uses weather or location features
- Storage: Location is sent to server for weather lookup, not permanently stored

### 2.3 Photos and Videos

| Data Type | Collected | Shared | Purpose | Required | User Control |
|-----------|-----------|--------|---------|----------|--------------|
| **Photos** | YES | YES* | Crop disease detection AI | Optional | Can delete anytime |
| **Videos** | NO | - | - | - | - |

*Photos are shared with our ML service for disease detection. May be retained (anonymized) for model improvement.

**Photo Collection Details:**
- Permission: `CAMERA`, `READ_MEDIA_IMAGES`
- When: User takes photo for disease diagnosis
- Storage: Uploaded to secure cloud storage
- Retention: Up to 2 years for AI training (anonymized)

### 2.4 App Activity

| Data Type | Collected | Shared | Purpose | Required | User Control |
|-----------|-----------|--------|---------|----------|--------------|
| **App interactions** | YES | NO | Analytics, UX improvement | Auto-collected | Via analytics opt-out |
| **In-app search history** | YES | NO | Improve search results | Auto-collected | Can clear in settings |
| **Installed apps** | NO | - | - | - | - |
| **Other user-generated content** | YES | NO | Forum posts, reviews | User-initiated | Can delete posts |

### 2.5 Device or Other Identifiers

| Data Type | Collected | Shared | Purpose | Required | User Control |
|-----------|-----------|--------|---------|----------|--------------|
| **Device identifiers** | YES | NO | Analytics, crash reporting | Auto-collected | Cannot disable |

**Device ID Details:**
- Used for: Firebase Analytics, Crashlytics
- Purpose: App stability, usage patterns
- Not linked to personal identity

---

## Section 3: Data Usage Purposes

For each data type collected, indicate the purpose:

### App Functionality
- Name, Phone: Account creation and authentication
- Location: Weather forecasts, local marketplace
- Photos: Crop disease detection

### Analytics
- Device identifiers: Usage patterns, crash analysis
- App interactions: Feature usage tracking

### Personalization
- Name: Personalized greetings
- Preferences: Crop-specific content
- Location: Regional content

### Account Management
- Email: Password recovery (optional)
- Phone: OTP verification

---

## Section 4: Data Handling Practices

### Data Sharing

| Third Party | Data Shared | Purpose |
|------------|-------------|---------|
| Firebase (Google) | Device ID, crash logs | Analytics, crash reporting |
| Weather API Provider | Location coordinates | Weather data lookup |
| Cloud Storage (AWS/GCP) | Photos | Disease detection processing |

**Note:** No data is sold to third parties.

### Data Security Measures
- TLS 1.3 encryption in transit
- AES-256 encryption at rest
- Secure key management
- Regular security audits
- Access controls and logging

---

## Section 5: Specific Declarations

### Does your app contain ads?
**Answer:** NO (as of v1.0)

### Does your app target children?
**Answer:** NO
- App is rated for ages 13+
- No features specifically designed for children

### Does your app process financial transactions?
**Answer:** YES (Marketplace feature)
- Uses third-party payment gateway (Razorpay/Stripe)
- App doesn't directly handle payment card data
- PCI-DSS compliant payment processing

---

## Section 6: Play Console Form Quick Reference

Use these exact answers when filling out the Play Console Data Safety form:

### Screen 1: Data Collection
- [x] My app collects or shares user data

### Screen 2: Security Practices  
- [x] All data transmitted encrypted
- [x] Users can request data deletion

### Screen 3: Data Types (Select these)
- [x] Personal info > Name
- [x] Personal info > Email (Optional)
- [x] Personal info > Phone number
- [x] Location > Approximate location
- [x] Location > Precise location  
- [x] Photos and videos > Photos
- [x] App activity > App interactions
- [x] App activity > Other user-generated content
- [x] Device or other IDs > Device identifiers

### Screen 4: For Each Data Type
- Collection: Required OR Optional (as noted above)
- Sharing: Only Photos shared with service providers
- Processing: On-device AND cloud
- Purposes: App functionality, Analytics, Personalization

---

## Section 7: Privacy Policy URL

**Privacy Policy URL for Play Console:**
```
https://yourusername.github.io/khetisahayak/privacy-policy.html
```

Or host on your own domain:
```
https://www.khetisahayak.com/privacy-policy
```

---

## Important Notes

1. **Keep Updated:** Update this document when adding new features that collect data
2. **Review Quarterly:** Review data practices quarterly
3. **User Transparency:** Always inform users about data collection
4. **Minimal Collection:** Only collect data necessary for functionality
5. **Secure Handling:** Follow security best practices

---

## Checklist Before Submission

- [ ] Privacy policy URL is accessible and working
- [ ] Privacy policy matches Data Safety declarations
- [ ] All data collection is documented
- [ ] Data deletion mechanism is implemented
- [ ] Security measures are in place
- [ ] Third-party SDKs are documented

---

*Document prepared for Kheti Sahayak Play Store submission*

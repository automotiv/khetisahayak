# Integration API Specification

This document defines the RESTful API endpoints for integrating with external services (Weather, Payment Gateway, Translation, Government Data) in the Kheti Sahayak platform.

---

## Authentication
All endpoints require a valid JWT access token (OAuth2) in the `Authorization: Bearer <token>` header unless otherwise noted.

---

## 1. Weather API Integration
### 1.1 Get Weather Data
- **GET** `/api/integrations/weather`
- **Description:** Retrieve weather data for a location.
- **Query Params:**
  - `location` (required): e.g., "Pune"
- **Response:**
```json
{
  "location": "Pune",
  "temperature_c": 32,
  "humidity": 60,
  "forecast": [
    { "date": "2025-04-16", "rain_mm": 2, "temp_c": 33 }
  ]
}
```
- **Errors:**
  - `400 Bad Request`
  - `401 Unauthorized`

---

## 2. Payment Gateway Integration
### 2.1 Initiate Payment
- **POST** `/api/integrations/payment/initiate`
- **Description:** Initiate a payment with an external gateway.
- **Body:**
```json
{
  "amount": 1500,
  "currency": "INR",
  "purpose": "marketplace_purchase",
  "reference_id": "tx_001"
}
```
- **Response:**
```json
{
  "payment_url": "https://gateway.com/pay/abc",
  "status": "pending"
}
```
- **Errors:**
  - `400 Bad Request`
  - `401 Unauthorized`

### 2.2 Verify Payment
- **POST** `/api/integrations/payment/verify`
- **Description:** Verify payment status.
- **Body:**
```json
{
  "reference_id": "tx_001"
}
```
- **Response:**
```json
{
  "status": "success"
}
```
- **Errors:**
  - `400 Bad Request`
  - `401 Unauthorized`

---

## 3. Translation API Integration
### 3.1 Translate Text
- **POST** `/api/integrations/translate`
- **Description:** Translate text to a target language.
- **Body:**
```json
{
  "text": "Welcome",
  "target_language": "hi"
}
```
- **Response:**
```json
{
  "translated_text": "स्वागत है"
}
```
- **Errors:**
  - `400 Bad Request`
  - `401 Unauthorized`

---

## 4. Government Data Integration
### 4.1 Get Schemes/Advisories
- **GET** `/api/integrations/gov/schemes`
- **Description:** Retrieve government schemes and advisories for farmers.
- **Query Params:**
  - `category` (optional): e.g., "Insurance"
- **Response:**
```json
[
  {
    "scheme_id": "gov_001",
    "title": "Crop Insurance",
    "description": "Comprehensive insurance for crops.",
    "eligibility": "All registered farmers"
  }
]
```
- **Errors:**
  - `401 Unauthorized`

---

## Security Notes
- All integrations use secure API keys/secrets (stored in KMS).
- All requests to external APIs are over TLS.
- Rate limiting and monitoring enforced.

---

## Error Codes
| Code | Meaning                |
|------|------------------------|
| 400  | Bad Request            |
| 401  | Unauthorized           |
| 404  | Not Found              |
| 500  | Internal Server Error  |

---

## Contact
For questions or onboarding, contact the backend/API lead or refer to the HLD backend services documentation.

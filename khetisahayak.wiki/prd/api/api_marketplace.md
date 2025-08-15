# Marketplace API Specification

This document defines the RESTful API endpoints for the Kheti Sahayak Marketplace service, supporting listings, transactions, and payment integration.

---

## Authentication
All endpoints require a valid JWT access token (OAuth2) in the `Authorization: Bearer <token>` header.

---

## 1. Listings

### 1.1 Get All Listings
- **GET** `/api/marketplace/listings`
- **Description:** Retrieve a list of all active marketplace listings.
- **Query Params:**
  - `category` (optional): Filter by category
  - `location` (optional): Filter by location
- **Response:**
```json
[
  {
    "id": "123",
    "title": "Organic Wheat",
    "description": "High quality wheat",
    "price": 1200,
    "unit": "quintal",
    "category": "Grains",
    "location": "Pune",
    "seller_id": "user_456",
    "created_at": "2025-04-15T10:00:00Z"
  }
]
```
- **Errors:**
  - `401 Unauthorized` – Missing/invalid token

### 1.2 Create Listing
- **POST** `/api/marketplace/listings`
- **Description:** Create a new marketplace listing.
- **Body:**
```json
{
  "title": "Organic Wheat",
  "description": "High quality wheat",
  "price": 1200,
  "unit": "quintal",
  "category": "Grains",
  "location": "Pune"
}
```
- **Response:**
```json
{
  "id": "123",
  "status": "created"
}
```
- **Errors:**
  - `400 Bad Request` – Invalid/missing fields
  - `401 Unauthorized`

### 1.3 Update Listing
- **PUT** `/api/marketplace/listings/{id}`
- **Description:** Update an existing listing (only by owner).
- **Body:** (any updatable fields)
- **Response:** `{ "status": "updated" }`
- **Errors:**
  - `403 Forbidden` – Not owner
  - `404 Not Found`

### 1.4 Delete Listing
- **DELETE** `/api/marketplace/listings/{id}`
- **Description:** Delete a listing (only by owner).
- **Response:** `{ "status": "deleted" }`
- **Errors:**
  - `403 Forbidden` – Not owner
  - `404 Not Found`

---

## 2. Transactions

### 2.1 Initiate Transaction
- **POST** `/api/marketplace/transactions`
- **Description:** Initiate a transaction for a listing.
- **Body:**
```json
{
  "listing_id": "123",
  "buyer_id": "user_789",
  "quantity": 2
}
```
- **Response:**
```json
{
  "transaction_id": "tx_001",
  "status": "pending_payment"
}
```
- **Errors:**
  - `400 Bad Request` – Invalid listing/quantity
  - `401 Unauthorized`

### 2.2 Confirm Transaction
- **POST** `/api/marketplace/transactions/{transaction_id}/confirm`
- **Description:** Confirm and finalize a transaction (after payment).
- **Response:** `{ "status": "confirmed" }`
- **Errors:**
  - `404 Not Found`
  - `403 Forbidden` – Not buyer/seller

### 2.3 Cancel Transaction
- **POST** `/api/marketplace/transactions/{transaction_id}/cancel`
- **Description:** Cancel a transaction.
- **Response:** `{ "status": "cancelled" }`
- **Errors:**
  - `404 Not Found`
  - `403 Forbidden`

---

## 3. Payment Integration

### 3.1 Initiate Payment
- **POST** `/api/marketplace/payments/initiate`
- **Description:** Initiate payment for a transaction.
- **Body:**
```json
{
  "transaction_id": "tx_001",
  "payment_method": "UPI"
}
```
- **Response:**
```json
{
  "payment_url": "https://payment-gateway.com/pay/xyz",
  "status": "pending"
}
```
- **Errors:**
  - `400 Bad Request` – Invalid transaction

### 3.2 Verify Payment
- **POST** `/api/marketplace/payments/verify`
- **Description:** Verify payment status for a transaction.
- **Body:**
```json
{
  "transaction_id": "tx_001"
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

---

## Security Notes
- All endpoints require authentication.
- Sensitive actions (create/update/delete listing, transaction, payment) are logged and auditable.
- Input validation and rate limiting are enforced.

---

## Error Codes
| Code | Meaning                |
|------|------------------------|
| 400  | Bad Request            |
| 401  | Unauthorized           |
| 403  | Forbidden              |
| 404  | Not Found              |
| 500  | Internal Server Error  |

---

## Contact
For questions or onboarding, contact the backend/API lead or refer to the HLD backend services documentation.

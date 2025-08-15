# Authentication API Specification

This document defines the RESTful API endpoints for authentication and authorization in the Kheti Sahayak platform.

---

## Authentication Flow
- OAuth2 with JWT tokens.
- All sensitive endpoints require `Authorization: Bearer <token>` header.

---

## 1. User Registration
- **POST** `/api/auth/register`
- **Description:** Register a new user (farmer/admin).
- **Body:**
```json
{
  "name": "Amit Kumar",
  "phone": "+919876543210",
  "password": "string",
  "role": "farmer"
}
```
- **Response:**
```json
{
  "user_id": "user_001",
  "status": "registered"
}
```
- **Errors:**
  - `400 Bad Request` – Invalid/missing fields
  - `409 Conflict` – Phone already registered

## 2. Login
- **POST** `/api/auth/login`
- **Description:** Authenticate user and issue JWT.
- **Body:**
```json
{
  "phone": "+919876543210",
  "password": "string"
}
```
- **Response:**
```json
{
  "access_token": "jwt_token",
  "refresh_token": "refresh_token",
  "expires_in": 3600
}
```
- **Errors:**
  - `401 Unauthorized` – Invalid credentials

## 3. Refresh Token
- **POST** `/api/auth/refresh`
- **Description:** Refresh JWT using a valid refresh token.
- **Body:**
```json
{
  "refresh_token": "refresh_token"
}
```
- **Response:**
```json
{
  "access_token": "new_jwt_token",
  "expires_in": 3600
}
```
- **Errors:**
  - `401 Unauthorized` – Invalid/expired refresh token

## 4. Logout
- **POST** `/api/auth/logout`
- **Description:** Invalidate access and refresh tokens.
- **Body:** `{}`
- **Response:** `{ "status": "logged_out" }`

## 5. Password Reset (OTP)
- **POST** `/api/auth/request-reset`
- **Description:** Request OTP for password reset.
- **Body:**
```json
{
  "phone": "+919876543210"
}
```
- **Response:** `{ "status": "otp_sent" }`

- **POST** `/api/auth/reset-password`
- **Description:** Reset password using OTP.
- **Body:**
```json
{
  "phone": "+919876543210",
  "otp": "123456",
  "new_password": "string"
}
```
- **Response:** `{ "status": "password_reset" }`

---

## Security Notes
- All passwords are hashed (bcrypt/argon2).
- OTPs expire after 5 minutes.
- Rate limiting and brute-force protection enforced.

---

## Error Codes
| Code | Meaning                |
|------|------------------------|
| 400  | Bad Request            |
| 401  | Unauthorized           |
| 403  | Forbidden              |
| 404  | Not Found              |
| 409  | Conflict               |
| 500  | Internal Server Error  |

---

## Contact
For questions or onboarding, contact the backend/API lead or refer to the HLD backend services documentation.

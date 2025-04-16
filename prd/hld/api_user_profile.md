# User Profile API Specification

This document defines the RESTful API endpoints for managing user profiles in the Kheti Sahayak platform.

---

## Authentication
All endpoints require a valid JWT access token (OAuth2) in the `Authorization: Bearer <token>` header.

---

## 1. Get User Profile
- **GET** `/api/users/me`
- **Description:** Retrieve the authenticated user's profile.
- **Response:**
```json
{
  "user_id": "user_001",
  "name": "Amit Kumar",
  "phone": "+919876543210",
  "role": "farmer",
  "location": "Pune",
  "language": "hi",
  "created_at": "2025-04-15T10:00:00Z"
}
```
- **Errors:**
  - `401 Unauthorized`

## 2. Update User Profile
- **PUT** `/api/users/me`
- **Description:** Update profile details (name, location, language).
- **Body:**
```json
{
  "name": "Amit Kumar",
  "location": "Nagpur",
  "language": "en"
}
```
- **Response:** `{ "status": "updated" }`
- **Errors:**
  - `400 Bad Request`
  - `401 Unauthorized`

## 3. Get Another User (Admin)
- **GET** `/api/users/{user_id}`
- **Description:** Retrieve another user's profile (admin only).
- **Response:** (same as above)
- **Errors:**
  - `401 Unauthorized`
  - `403 Forbidden`
  - `404 Not Found`

## 4. Delete User (Admin)
- **DELETE** `/api/users/{user_id}`
- **Description:** Delete a user account (admin only).
- **Response:** `{ "status": "deleted" }`
- **Errors:**
  - `401 Unauthorized`
  - `403 Forbidden`
  - `404 Not Found`

---

## Security Notes
- All profile updates are audited.
- Only admins can access or delete other users.
- Input validation and rate limiting enforced.

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

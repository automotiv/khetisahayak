# Admin & Monitoring API Specification

This document defines the RESTful API endpoints for admin and monitoring functions in the Kheti Sahayak platform.

---

## Authentication
All endpoints require a valid JWT access token (OAuth2) in the `Authorization: Bearer <token>` header. Only users with `admin` role may access these endpoints.

---

## 1. User Management

### 1.1 List All Users
- **GET** `/api/admin/users`
- **Description:** Retrieve a list of all users (paginated).
- **Query Params:**
  - `role` (optional): Filter by user role
  - `page` (optional): Page number
- **Response:**
```json
[
  {
    "user_id": "user_001",
    "name": "Amit Kumar",
    "role": "farmer",
    "phone": "+919876543210",
    "created_at": "2025-04-15T10:00:00Z"
  }
]
```
- **Errors:**
  - `401 Unauthorized`
  - `403 Forbidden`

### 1.2 Get User Details
- **GET** `/api/admin/users/{user_id}`
- **Description:** Retrieve details for a specific user.
- **Response:** (same as above)
- **Errors:**
  - `401 Unauthorized`
  - `403 Forbidden`
  - `404 Not Found`

---

## 2. Audit Logs

### 2.1 Get Audit Logs
- **GET** `/api/admin/audit/logs`
- **Description:** Retrieve audit logs for sensitive actions.
- **Query Params:**
  - `action` (optional): Filter by action type
  - `user_id` (optional): Filter by user
  - `date_from`, `date_to` (optional): Date range
- **Response:**
```json
[
  {
    "log_id": "log_001",
    "user_id": "user_001",
    "action": "login",
    "timestamp": "2025-04-15T12:00:00Z",
    "details": "Successful login from IP 1.2.3.4"
  }
]
```
- **Errors:**
  - `401 Unauthorized`
  - `403 Forbidden`

---

## 3. System Health & Monitoring

### 3.1 Get System Status
- **GET** `/api/admin/system/status`
- **Description:** Retrieve system health and uptime information.
- **Response:**
```json
{
  "status": "ok",
  "uptime": 86400,
  "services": [
    { "name": "marketplace", "status": "ok" },
    { "name": "diagnostics", "status": "degraded" }
  ]
}
```
- **Errors:**
  - `401 Unauthorized`
  - `403 Forbidden`

---

## Security Notes
- All admin actions are audited.
- Rate limiting and access control enforced.

---

## Error Codes
| Code | Meaning                |
|------|------------------------|
| 401  | Unauthorized           |
| 403  | Forbidden              |
| 404  | Not Found              |
| 500  | Internal Server Error  |

---

## Contact
For questions or onboarding, contact the backend/API lead or refer to the HLD backend services documentation.

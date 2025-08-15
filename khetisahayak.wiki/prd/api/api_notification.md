# Notification Service API Specification

This document defines the RESTful API endpoints for the Notification Service in the Kheti Sahayak platform, supporting SMS, email, and push notifications.

---

## Authentication
All endpoints require a valid JWT access token (OAuth2) in the `Authorization: Bearer <token>` header unless otherwise noted.

---

## 1. Send Notification
- **POST** `/api/notifications/send`
- **Description:** Send a notification to a user or group of users.
- **Body:**
```json
{
  "recipient_ids": ["user_001", "user_002"],
  "type": "sms", // sms | email | push
  "subject": "Market Update",
  "message": "Wheat prices up 5% in Pune market.",
  "data": { "listing_id": "123" } // optional, for deep links or context
}
```
- **Response:**
```json
{
  "status": "sent",
  "notification_ids": ["notif_001", "notif_002"]
}
```
- **Errors:**
  - `400 Bad Request` – Invalid/missing fields
  - `401 Unauthorized`

## 2. Get Notification History
- **GET** `/api/notifications/history`
- **Description:** Retrieve notification history for the authenticated user.
- **Query Params:**
  - `type` (optional): Filter by notification type
- **Response:**
```json
[
  {
    "notification_id": "notif_001",
    "type": "sms",
    "subject": "Market Update",
    "message": "Wheat prices up 5% in Pune market.",
    "status": "delivered",
    "sent_at": "2025-04-15T12:00:00Z"
  }
]
```
- **Errors:**
  - `401 Unauthorized`

## 3. Admin: Broadcast Notification
- **POST** `/api/notifications/broadcast`
- **Description:** Send a broadcast notification to all users or a segment (admin only).
- **Body:**
```json
{
  "segment": "all_farmers", // or any custom segment
  "type": "push",
  "subject": "App Update",
  "message": "New version available!"
}
```
- **Response:** `{ "status": "broadcast_sent" }`
- **Errors:**
  - `401 Unauthorized`
  - `403 Forbidden` – Not admin

---

## Security Notes
- All notifications are logged and auditable.
- Rate limiting and abuse prevention enforced.
- Only admins can use broadcast endpoint.

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

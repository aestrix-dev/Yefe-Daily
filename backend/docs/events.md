# Events API Documentation

This document provides documentation for the events-related API endpoints.

## Base Path

All endpoints are prefixed with `/v1`.

---

## Event Management

### Get Recent Events

- **Endpoint:** `GET /events`
- **Description:** Retrieves a list of recent user activities.
- **Query Parameters:**
    - `limit` (integer, optional, default: 10): The maximum number of events to return.
- **Successful Response (200 OK):**
    ```json
    {
        "message": "User events",
        "data": [
            {
                "id": "event_id_1",
                "user_id": "user_id_123",
                "event_type": "login_success",
                "details": "User logged in successfully from IP 192.168.1.1",
                "created_at": "2025-07-21T10:00:00Z"
            },
            {
                "id": "event_id_2",
                "user_id": "user_id_456",
                "event_type": "password_change_success",
                "details": "User changed their password successfully",
                "created_at": "2025-07-21T09:30:00Z"
            }
        ]
    }
    ```

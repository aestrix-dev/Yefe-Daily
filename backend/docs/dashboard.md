# Dashboard API Documentation

This document provides documentation for the dashboard-related API endpoints.

## Base Path

All endpoints are prefixed with `/v1`.

---

## Dashboard Management

### Get Dashboard Data

- **Endpoint:** `GET /dashboard`
- **Description:** Retrieves aggregated data for the admin dashboard.
- **Successful Response (200 OK):**
    ```json
    {
        "message": "Dashboard Data",
        "data": {
            "total_users": {
                "value": 1500,
                "change": 1.04,
                "change_type": "increase"
            },
            "premium_subscribers": {
                "value": 500,
                "change": 0.5,
                "change_type": "increase"
            },
            "recent_activity": [
                {
                    "id": "event_id_1",
                    "type": "login",
                    "user": "user@example.com",
                    "description": "User logged in successfully",
                    "time_ago": "2 hours ago"
                }
            ],
            "quick_insights": {
                "premium_conversion_rate": 33.33,
                "active_users_today": 1200,
                "pending_invitations": 5
            },
                        "last_updated": "2025-07-21T12:00:00Z",
            "monthly_registrations": [
                {
                    "month": "January",
                    "count": 100
                },
                {
                    "month": "February",
                    "count": 150
                },
                {
                    "month": "March",
                    "count": 200
                }
            ]
        }
    }
    ```

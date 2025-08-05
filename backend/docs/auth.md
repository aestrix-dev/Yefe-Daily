# Auth API Documentation

This document provides documentation for the authentication-related API endpoints.

## Base Path

All endpoints are prefixed with `/v1`.

---

## Authentication

### User Login

- **Endpoint:** `POST /auth/login`
- **Description:** Authenticates a user and returns a JWT token.
- **Request Body:**
    ```json
    {
        "email": "user@example.com",
        "password": "password123"
    }
    ```
- **Successful Response (201 Created):**
    ```json
    {
        "message": "User logined-in successfully",
        "data": {
            "access_token": "your_access_token",
            "refresh_token": "your_refresh_token",
            "expires_in": 3600
        }
    }
    ```

### User Registration

- **Endpoint:** `POST /auth/register`
- **Description:** Registers a new user.
- **Request Body:**
    ```json
    {
        "email": "newuser@example.com",
        "name": "New User",
        "password": "password123",
        "confirm_password": "password123",
        "user_prefs": {
            "morning_prompt": true,
            "evening_reflection": true,
            "challenge": true,
            "language": "English",
            "reminders": {
                "morning_reminder": "08:00", # 12 hour format
                "evening_reminder": "09:00" # 12 hour format
            }
        }
    }
    ```
- **Successful Response (201 Created):**
    ```json
    {
        "message": "User registered successfully",
        "data": {
            "user": {
                "id": "user_id_123",
                "name": "New User",
                "email": "newuser@example.com",
                "plan_type": "free",
                "status": "active",
                "last_login": null,
                "created_at": "2025-07-21T10:00:00Z",
                "updated_at": "2025-07-21T10:00:00Z"
            },
            "message": "Please check your email to verify your account"
        }
    }
    ```

### User Logout

- **Endpoint:** `POST /auth/logout`
- **Description:** Logs out the currently authenticated user.
- **Successful Response (201 Created):**
    ```json
    {
        "message": "User loggedout"
    }
    ```

### Accept Notifications

- **Endpoint:** `POST /auth/accept`
- **Description:** Allows a user to accept push notifications.
- **Request Body:**
    ```json
    {
        "fcm_token": "your_fcm_token"
    }
    ```
- **Successful Response (201 Created):**
    ```json
    {
        "message": "User notifiaction created"
    }
    ```

### Accept Invitation

- **Endpoint:** `POST /accept-invitation`
- **Description:** Accepts an admin invitation.
- **Request Body:**
    ```json
    {
        "token": "your_invitation_token"
    }
    ```
- **Successful Response (200 OK):**
    ```json
    {
        "message": "Invitation accepted"
    }
    ```

# Admin API Documentation

This document provides documentation for the admin-related API endpoints.

## Base Path

All endpoints are prefixed with `/v1`.

---

## User Management

### List Users

- **Endpoint:** `GET /admin/users`
- **Description:** Retrieves a paginated list of users with optional filters.
- **Query Parameters:**
    - `email` (string, optional): Filter by user email.
    - `status` (string, optional): Filter by user status. Can be `active` or `suspended`.
    - `plan` (string, optional): Filter by user plan. Can be `free` or `yefe_plus`.
    - `limit` (integer, optional, default: 50): The maximum number of users to return.
    - `offset` (integer, optional, default: 0): The starting offset for pagination.
- **Successful Response (200 OK):**
    ```json
    {
        "users": [
            {
                "id": "user_id_1",
                "name": "John Doe",
                "email": "john.doe@example.com",
                "plan_type": "yefe_plus",
                "status": "active",
                "last_login": "2025-07-21T10:00:00Z",
                "created_at": "2025-01-15T09:00:00Z",
                "updated_at": "2025-07-21T10:00:00Z"
            }
        ],
        "total": 1,
        "page": 1,
        "page_size": 50,
        "total_pages": 1
    }
    ```

### Get User by ID

- **Endpoint:** `GET /admin/users/{userID}`
- **Description:** Retrieves a single user by their ID.
- **Path Parameters:**
    - `userID` (string, required): The ID of the user to retrieve.
- **Successful Response (200 OK):**
    ```json
    {
        "id": "user_id_1",
        "name": "John Doe",
        "email": "john.doe@example.com",
        "plan_type": "yefe_plus",
        "status": "active",
        "last_login": "2025-07-21T10:00:00Z",
        "created_at": "2025-01-15T09:00:00Z",
        "updated_at": "2025-07-21T10:00:00Z"
    }
    ```

### List Admins

- **Endpoint:** `GET /admin/admins`
- **Description:** Retrieves a list of admin users.
- **Successful Response (200 OK):**
    ```json
    {
        "users": [
            {
                "id": "admin_id_1",
                "name": "Admin User",
                "email": "admin@example.com",
                "plan_type": "yefe_plus",
                "status": "active",
                "last_login": "2025-07-21T11:00:00Z",
                "created_at": "2025-01-10T08:00:00Z",
                "updated_at": "2025-07-21T11:00:00Z"
            }
        ]
    }
    ```

### Update User Status

- **Endpoint:** `PUT /admin/users/{userID}/status`
- **Description:** Updates the status of a user's account.
- **Path Parameters:**
    - `userID` (string, required): The ID of the user to update.
- **Request Body:**
    ```json
    {
        "status": "suspended"
    }
    ```
- **Successful Response:** `204 No Content`

### Update User Plan

- **Endpoint:** `PUT /admin/users/{userID}/plan`
- **Description:** Updates the subscription plan of a user.
- **Path Parameters:**
    - `userID` (string, required): The ID of the user to update.
- **Request Body:**
    ```json
    {
        "plan": "yefe_plus"
    }
    ```
- **Successful Response:** `204 No Content`

---

## Admin Invitations

### Invite New Admin

- **Endpoint:** `POST /admin/invite`
- **Description:** Sends an invitation to a new admin user.
- **Request Body:**
    ```json
    {
        "email": "new.admin@example.com"
    }
    ```
- **Successful Response:** `201 Created`

### Get Pending Invitations

- **Endpoint:** `GET /admin/invitations`
- **Description:** Retrieves a list of pending admin invitations.
- **Successful Response (200 OK):**
    ```json
    [
        {
            "id": "invitation_id_1",
            "email": "pending.admin@example.com",
            "status": "pending",
            "expires_at": "2025-07-28T12:00:00Z"
        }
    ]
    ```

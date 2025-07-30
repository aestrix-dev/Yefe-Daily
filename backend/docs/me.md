# Get User Profile

Retrieves the authenticated user's profile information.

**Endpoint:** `GET /v1/me`

**Authentication:** Required. The user must be authenticated to access this endpoint.

## Responses

### 200 OK

Returns the user's profile information.

**Example Response:**

```json
{
    "status": "success",
    "message": "user",
    "data": {
        "user": {
            "id": "user_id",
            "name": "John Doe",
            "email": "john.doe@example.com",
            "role": "user",
            "created_at": "2025-07-30T12:00:00Z"
        }
    }
}
```

### 500 Internal Server Error

Returned if there is an error retrieving the user's information.

**Example Response:**

```json
{
    "status": "error",
    "message": "Failed to get users",
    "errors": null
}
```

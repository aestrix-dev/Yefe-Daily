# Journal API Documentation

This document provides documentation for the journal-related API endpoints.

## Base Path

All endpoints are prefixed with `/v1`.

---

## Journal Management

### Create a Journal Entry

- **Endpoint:** `POST /journal/entries`
- **Description:** Creates a new journal entry for the authenticated user.
- **Request Body:**
    ```json
    {
        "content": "This is a sample journal entry.",
        "type": "morning",
        "tags": ["personal", "reflection"]
    }
    ```
- **Successful Response (201 Created):**
    ```json
    {
        "message": "new entry created",
        "data": {
            "id": "entry_id_1",
            "content": "This is a sample journal entry.",
            "type": "morning",
            "tags": ["personal", "reflection"],
            "created_at": "2025-07-21T10:00:00Z",
            "updated_at": "2025-07-21T10:00:00Z"
        }
    }
    ```

### Get Journal Entries

- **Endpoint:** `GET /journal/entries`
- **Description:** Retrieves a paginated list of journal entries for the authenticated user, with optional filters.
- **Query Parameters:**
    - `limit` (integer, optional, default: 20): The maximum number of entries to return.
    - `offset` (integer, optional, default: 0): The starting offset for pagination.
    - `type` (string, optional): Filter by entry type (e.g., `morning`, `evening`).
    - `tags` (string, optional): A comma-separated list of tags to filter by.
    - `search` (string, optional): A search term to filter entries by content.
    - `start_date` (string, optional, format: YYYY-MM-DD): The start date for filtering entries.
    - `end_date` (string, optional, format: YYYY-MM-DD): The end date for filtering entries.
- **Successful Response (200 OK):**
    ```json
    {
        "entries": [
            {
                "id": "entry_id_1",
                "content": "This is a sample journal entry.",
                "type": "morning",
                "tags": ["personal", "reflection"],
                "created_at": "2025-07-21T10:00:00Z",
                "updated_at": "2025-07-21T10:00:00Z"
            }
        ],
        "total": 1,
        "limit": 20,
        "offset": 0,
        "has_more": false,
        "total_pages": 1
    }
    ```

### Get a Single Journal Entry

- **Endpoint:** `GET /journal/entries/{id}`
- **Description:** Retrieves a single journal entry by its ID.
- **Path Parameters:**
    - `id` (string, required): The ID of the journal entry to retrieve.
- **Successful Response (200 OK):**
    ```json
    {
        "id": "entry_id_1",
        "content": "This is a sample journal entry.",
        "type": "morning",
        "tags": ["personal", "reflection"],
        "created_at": "2025-07-21T10:00:00Z",
        "updated_at": "2025-07-21T10:00:00Z"
    }
    ```

### Update a Journal Entry

- **Endpoint:** `PUT /journal/entries/{id}`
- **Description:** Updates an existing journal entry.
- **Path Parameters:**
    - `id` (string, required): The ID of the journal entry to update.
- **Request Body:**
    ```json
    {
        "content": "This is the updated content.",
        "tags": ["personal", "updated"]
    }
    ```
- **Successful Response (200 OK):**
    ```json
    {
        "id": "entry_id_1",
        "content": "This is the updated content.",
        "type": "morning",
        "tags": ["personal", "updated"],
        "created_at": "2025-07-21T10:00:00Z",
        "updated_at": "2025-07-21T10:05:00Z"
    }
    ```

### Delete a Journal Entry

- **Endpoint:** `DELETE /journal/entries/{id}`
- **Description:** Deletes a journal entry.
- **Path Parameters:**
    - `id` (string, required): The ID of the journal entry to delete.
- **Successful Response:** `204 No Content`

### Get Today's Journal Entry

- **Endpoint:** `GET /journal/entries/today/{type}`
- **Description:** Retrieves the journal entry for the current day and specified type.
- **Path Parameters:**
    - `type` (string, required): The type of entry to retrieve (e.g., `morning`, `evening`).
- **Successful Response (200 OK):**
    ```json
    {
        "entry": {
            "id": "entry_id_1",
            "content": "This is today's morning entry.",
            "type": "morning",
            "tags": [],
            "created_at": "2025-07-21T08:00:00Z",
            "updated_at": "2025-07-21T08:00:00Z"
        },
        "exists": true
    }
    ```

### Get Journal Stats

- **Endpoint:** `GET /journal/stats`
- **Description:** Retrieves statistics about the user's journal entries.
- **Successful Response (200 OK):**
    ```json
    {
        "total_entries": 50,
        "entries_by_type": {
            "morning": 25,
            "evening": 25
        },
        "current_streak": 10,
        "longest_streak": 15,
        "tags_usage": {
            "personal": 30,
            "work": 20
        },
        "recent_activity": [
            {
                "id": "entry_id_50",
                "content": "A recent entry.",
                "type": "evening",
                "tags": ["recap"],
                "created_at": "2025-07-20T20:00:00Z",
                "updated_at": "2025-07-20T20:00:00Z"
            }
        ],
        "monthly_progress": [
            {
                "month": "2025-07",
                "count": 21,
                "target": 31,
                "percent": 67
            }
        ]
    }
    ```

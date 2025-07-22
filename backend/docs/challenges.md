# Challenges API Documentation

This document provides documentation for the challenges-related API endpoints.

## Base Path

All endpoints are prefixed with `/v1`.

---

## Challenge Management

### Get Today's Challenges

- **Endpoint:** `GET /challenges/today`
- **Description:** Retrieves the challenges for the authenticated user for the current day.
- **Successful Response (200 OK):**
    ```json
    {
        "challenge": {
            "id": "user_challenge_id_1",
            "user_id": "user_id_123",
            "challenge_id": "challenge_id_abc",
            "status": "pending",
            "completed_at": null,
            "created_at": "2025-07-21T08:00:00Z",
            "updated_at": "2025-07-21T08:00:00Z"
        }
    }
    ```

### Get Challenge History

- **Endpoint:** `GET /challenges/history`
- **Description:** Retrieves the authenticated user's challenge history.
- **Query Parameters:**
    - `limit` (integer, optional, default: 10): The maximum number of challenges to return.
- **Successful Response (200 OK):**
    ```json
    {
        "challenge": [
            {
                "id": "user_challenge_id_1",
                "user_id": "user_id_123",
                "challenge_id": "challenge_id_abc",
                "status": "completed",
                "completed_at": "2025-07-20T10:00:00Z",
                "created_at": "2025-07-20T08:00:00Z",
                "updated_at": "2025-07-20T10:00:00Z"
            }
        ]
    }
    ```

### Complete a Challenge

- **Endpoint:** `PUT /challenges/{challengeID}/complete`
- **Description:** Marks a specific challenge as completed for the authenticated user.
- **Path Parameters:**
    - `challengeID` (string, required): The ID of the challenge to complete.
- **Successful Response (200 OK):**
    ```json
    {
        "message": "Challenge completed successfully",
        "status": "completed"
    }
    ```

### Get Dashboard

- **Endpoint:** `GET /challenges/dashboard`
- **Description:** Retrieves a dashboard of the user's challenge-related data.
- **Successful Response (200 OK):**
    ```json
    {
        "todays_challenges": {
            "challenge": {
                "id": "challenge_id_1",
                "title": "Today's Challenge",
                "description": "A challenge for today.",
                "type": "general",
                "points": 10,
                "date": "2025-07-21T00:00:00Z",
                "created_at": "2025-07-21T08:00:00Z",
                "updated_at": "2025-07-21T08:00:00Z"
            },
            "user_challenge": {
                "id": "user_challenge_id_1",
                "user_id": "user_id_123",
                "challenge_id": "challenge_id_1",
                "status": "pending",
                "completed_at": null,
                "created_at": "2025-07-21T08:00:00Z",
                "updated_at": "2025-07-21T08:00:00Z"
            },
            "is_completed": false,
            "can_complete": true
        },
        "recently_completed": [],
        "stats": {
            "user_id": "user_id_123",
            "total_challenges": 10,
            "completed_count": 5,
            "total_points": 50,
            "current_streak": 3,
            "longest_streak": 5
        },
        "current_streak": 3,
        "total_points": 50
    }
    ```

### Get User Stats

- **Endpoint:** `GET /challenges/stats`
- **Description:** Retrieves the challenge statistics for the authenticated user.
- **Successful Response (200 OK):**
    ```json
    {
        "user_id": "user_id_123",
        "total_challenges": 10,
        "completed_count": 5,
        "total_points": 50,
        "current_streak": 3,
        "longest_streak": 5
    }
    ```

### Get Leaderboard

- **Endpoint:** `GET /challenges/leaderboard`
- **Description:** Retrieves the challenge leaderboard.
- **Query Parameters:**
    - `limit` (integer, optional, default: 10): The maximum number of users to return on the leaderboard.
- **Successful Response (200 OK):**
    ```json
    {
        "leaderboard": [
            {
                "user_id": "user_id_123",
                "total_challenges": 20,
                "completed_count": 18,
                "total_points": 180,
                "current_streak": 10,
                "longest_streak": 15
            },
            {
                "user_id": "user_id_456",
                "total_challenges": 15,
                "completed_count": 15,
                "total_points": 150,
                "current_streak": 15,
                "longest_streak": 15
            }
        ]
    }
    ```

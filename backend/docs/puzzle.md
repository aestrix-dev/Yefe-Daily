# Puzzle API Documentation

This document provides documentation for the puzzle-related API endpoints.

## Base Path

All endpoints are prefixed with `/v1`.

---

## Puzzle Management

### Get Daily Puzzle

- **Endpoint:** `GET /puzzle/daily`
- **Description:** Retrieves the daily puzzle for the authenticated user.
- **Successful Response (200 OK):**
    ```json
    {
        "data": {
            "puzzle": {
                "id": "puzzle_id_1",
                "title": "Daily Riddle",
                "question": "I have cities, but no houses. I have mountains, but no trees. I have water, but no fish. What am I?",
                "options": ["A map", "A dream", "A book"],
                "created_at": "2025-07-21T08:00:00Z"
            },
            "isCompleted": false,
            "progress": null,
            "date": "2025-07-21"
        }
    }
    ```

### Submit Daily Puzzle Answer

- **Endpoint:** `PUT /puzzle/submit`
- **Description:** Submits an answer for the daily puzzle.
- **Request Body:**
    ```json
    {
        "puzzle_id": "puzzle_id_1",
        "selectedAnswer": 0
    }
    ```
- **Successful Response (200 OK):**
    ```json
    {
        "data": {
            "isCorrect": true,
            "correctAnswer": 0,
            "explanation": "A map has all of these features represented on it.",
            "pointsEarned": 10,
            "isFirstAttempt": true
        }
    }
    ```

### Get User Puzzle Stats

- **Endpoint:** `GET /puzzle/stats`
- **Description:** Retrieves the puzzle statistics for the authenticated user.
- **Successful Response (200 OK):**
    ```json
    {
        "data": {
            "total_puzzles_solved": 25,
            "correct_answers": 20,
            "incorrect_answers": 5,
            "average_attempts": 1.2,
            "current_streak": 5
        }
    }
    ```

### Get User Completed Puzzles

- **Endpoint:** `GET /puzzle/completed`
- **Description:** Retrieves the history of completed puzzles for the authenticated user.
- **Successful Response (200 OK):**
    ```json
    {
        "data": [
            {
                "puzzle_id": "puzzle_id_abc",
                "date_solved": "2025-07-20T10:00:00Z",
                "was_correct": true,
                "attempts": 1
            }
        ]
    }
    ```
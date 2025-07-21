# Songs API Documentation

This document provides documentation for the songs-related API endpoints.

## Base Path

All endpoints are prefixed with `/v1`.

---

## Song Management

### Get Songs

- **Endpoint:** `GET /songs`
- **Description:** Retrieves a list of songs based on the user's access level (free or pro).
- **Successful Response (200 OK):**
    ```json
    {
        "message": "successfully got songs",
        "data": [
            {
                "id": "song_id_1",
                "title": "Uplifting Melody",
                "artist": "Composer A",
                "url": "https://example.com/song1.mp3",
                "mood": "happy"
            }
        ],
        "meta": {
            "total": 1,
            "access": "free"
        }
    }
    ```

### Get Song Details

- **Endpoint:** `GET /songs/{id}`
- **Description:** Retrieves detailed information about a specific song.
- **Path Parameters:**
    - `id` (string, required): The ID of the song to retrieve.
- **Successful Response (200 OK):**
    ```json
    {
        "message": "users",
        "data": {
            "id": "song_id_1",
            "title": "Uplifting Melody",
            "artist": "Composer A",
            "url": "https://example.com/song1.mp3",
            "mood": "happy",
            "duration": 180,
            "is_pro": false
        }
    }
    ```

### Get Songs by Mood

- **Endpoint:** `GET /songs/mood/{mood}`
- **Description:** Retrieves a list of songs filtered by a specific mood.
- **Path Parameters:**
    - `mood` (string, required): The mood to filter songs by (e.g., `happy`, `calm`).
- **Successful Response (200 OK):**
    ```json
    {
        "message": "successfully got songs",
        "data": [
            {
                "id": "song_id_1",
                "title": "Uplifting Melody",
                "artist": "Composer A",
                "url": "https://example.com/song1.mp3",
                "mood": "happy"
            }
        ],
        "meta": {
            "mood": "happy",
            "total": 1,
            "access": "free"
        }
    }
    ```
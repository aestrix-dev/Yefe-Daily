
# Daily Reflection API

This document outlines the API endpoints for managing daily reflections.

## Get Today's Reflection

This endpoint retrieves the daily reflection for the current day.

- **URL:** `v1/reflection`
- **Method:** `GET`
- **Authentication:** Required
- **Permissions:** None

### Success Response

- **Code:** `200 OK`
- **Content:**

```json
{
    "reflection": {
        "id": 1,
        "title": "Embracing Stillness",
        "quote": "In the midst of movement and chaos, keep stillness inside of you.",
        "reflection": "Take a few moments today to find a quiet space. Close your eyes, breathe deeply, and simply be. Notice the sensations in your body, the thoughts in your mind, without judgment. This practice of stillness can bring clarity and peace to your day.",
        "created_at": "2025-07-28T00:00:00Z"
    }
}
```

### Error Responses

- **Code:** `500 Internal Server Error`
- **Content:**

```json
{
    "error": "Failed to get today's challenges"
}
```

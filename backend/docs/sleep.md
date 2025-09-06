# Sleep API

## Record Sleep

This endpoint allows a user to record their sleep time.

- **URL:** `/v1/sleep`
- **Method:** `POST`
- **Auth required:** Yes (Paid users only)

**Request Body:**

```json
{
  "slept_date": "2023-10-27",
  "slept_time": "22:00:00",
  "woke_up_date": "2023-10-28",
  "woke_up_time": "06:00:00"
}
```

**Response:**

```json
{
  "id": 1,
  "user_id": 123,
  "slept_at": "2023-10-27T22:00:00Z",
  "woke_up_at": "2023-10-28T06:00:00Z",
  "created_at": "2023-10-28T06:00:00Z",
  "updated_at": "2023-10-28T06:00:00Z"
}
```

## Get Sleep Graph Data

This endpoint returns the user's sleep data for a given number of days.

- **URL:** `/v1/sleep/graph`
- **Method:** `GET`
- **Auth required:** Yes (Paid users only)

**Query Parameters:**

- `days` (optional, integer, default: 7): The number of days to get sleep data for.

**Response:**

```json
{
  "graph_data": [
    {
      "date": "2023-10-28T06:00:00Z",
      "duration": 8,
      "day_of_week": "Saturday"
    },
    {
      "date": "2023-10-27T05:30:00Z",
      "duration": 7.5,
      "day_of_week": "Friday"
    }
  ],
  "average_sleep_duration": 7.75,
  "total_entries": 2
}
```

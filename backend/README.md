# Yefe App – API Documentation

Backend API for the **Yefe App**, a journaling and self-growth application.  
This API handles authentication, journaling, puzzles, challenges, songs, and user management.

---

## 📌 Routes Overview

| Method | Path         | Description                  | Anchor |
|--------|--------------|------------------------------|--------|
| POST   | `/auth/login`       | User login                     | [→](#post-authlogin) |
| POST   | `/auth/register`    | User registration              | [→](#post-authregister) |
| POST   | `/auth/logout`      | User logout (auth required)    | [→](#post-authlogout) |
| MOUNT  | `/journal`          | Journal operations             | [→](#journal-routes) |
| MOUNT  | `/puzzle`           | Puzzle interactions            | [→](#puzzle-routes) |
| MOUNT  | `/challenges`       | Daily/weekly challenges        | [→](#challenges-routes) |
| MOUNT  | `/songs`            | Song preferences and mood      | [→](#songs-routes) |
| MOUNT  | `/user`             | Admin-only user management     | [→](#user-routes) |

---

## 🔐 POST `/auth/login` <a name="post-authlogin"></a>

Logs a user into the system.

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "yourpassword"
}
````

**Response:**

```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": 3600
}
```

---

## 📝 POST `/auth/register` <a name="post-authregister"></a>

Registers a new user.

**Request Body:**

```json
{
  "email": "user@example.com",
  "Name": "Jane Doe",
  "password": "yourpassword123",
  "confirm_password": "yourpassword123",
  "user_prefs": {
    "morning_prompt": true,
    "evening_reflection": true,
    "challenge": false,
    "language": "English",
    "reminders": {
      "morning_reminder": "7:00 AM",
      "evening_reminder": "9:00 PM"
    }
  }
}
```

**Response:**

```json
{
  "user": { /* user object */ },
  "message": "Please check your email to verify your account"
}
```

---

## 🚪 POST `/auth/logout` <a name="post-authlogout"></a>

Logs out the current user session.

**Context Only:**

* `session_id`: required from context (middleware)

**Response:**

```json
{
  "message": "User loggedout"
}
```

---

## 📓 Journal Routes <a name="journal-routes"></a>

***\[Details coming soon]***

---

## 🧩 Puzzle Routes <a name="puzzle-routes"></a>

***\[Details coming soon]***

---

## 🏆 Challenges Routes <a name="challenges-routes"></a>

***\[Details coming soon]***

---

## 🎵 Songs Routes <a name="songs-routes"></a>

***\[Details coming soon]***

---

## 👤 User Routes (Admin Only) <a name="user-routes"></a>

***\[Details coming soon]***

---

## 📦 Schemas

### 🔸 `LoginRequest`

```json
{
  "email": "string (required, email)",
  "password": "string (required)"
}
```

---

### 🔸 `RegisterRequest`

```json
{
  "email": "string (required, email)",
  "Name": "string (3–50 characters)",
  "password": "string (min 8)",
  "confirm_password": "string (must match password)",
  "user_prefs": UserPrefsRequest
}
```

---

### 🔸 `UserPrefsRequest`

```json
{
  "morning_prompt": "boolean",
  "evening_reflection": "boolean",
  "challenge": "boolean",
  "language": "English | French | Spanish | Portuguese (required)",
  "reminders": ReminderRequest
}
```

---

### 🔸 `ReminderRequest`

```json
{
  "morning_reminder": "string (required HH:MM)",
  "evening_reminder": "string (required HH:MM)"
}
```

---

### 🔸 `LoginResponse`

```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": "number (seconds)"
}
```

---

### 🔸 `LogoutRequest` (Context)

```json
{
  "session_id": "string (required)"
}
```



# Yefe App – API Documentation

Backend API for the **Yefe App**, a journaling and self-growth application.  
This API handles authentication, user preferences, and more.

---

## 📌 Routes

| Method | Path | Description |
|--------|------|-------------|
| POST | [**/auth/login**](#post-authlogin) | Log in a user |
| POST | [**/auth/register**](#post-authregister) | Register a new user |
| POST | [**/auth/logout**](#post-authlogout) | Log out a user |

---

## 🔐 POST `/auth/login`

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

## 📝 POST `/auth/register`

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

## 🚪 POST `/auth/logout`

Logs out the current user session.

**Context:**
Requires `session_id` in request context (e.g. from auth middleware).

**Response:**

```json
{
  "message": "User loggedout"
}
```

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
  "morning_reminder": "string (required, HH:MM)",
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




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
  "Name": "Jane",
  "password": "yourpassword123",
  "confirm_password": "yourpassword123",
  "user_prefs": {
    "morning_prompt": true,
    "evening_reflection": true,
    "challenge": false,
    "language": "English",
    "reminders": {
      "morning_reminder": "07:00",
      "evening_reminder": "09:00"
    }
  }
}
```

**Response:**

```json
{
	"success": true,
	"message": "User registered successfully",
	"data": {
		"message": "Please check your email to verify your account",
		"user": {
			"id": "(uuid sting)",
			"email": "user@example.com",
			"Name": "Jane",
			"is_email_verified": false,
			"is_active": true,
			"created_at": "2025-07-08T23:06:49.270073247+01:00",
			"updated_at": "2025-07-08T23:06:49.270073413+01:00",
			"last_login_at": null,
			"user_profile": null,
			"role": "",
			"plan_type": "free",
			"plan_name": "Free",
			"plan_start_date": "2025-07-08T23:06:49.270075247+01:00",
			"plan_end_date": null,
			"plan_auto_renew": false,
			"plan_status": "active"
		}
	},
	"timestamp": "2025-07-08T22:06:49Z"
}
```

---

## 🚪 POST `/auth/logout` <a name="post-authlogout"></a>

Logs out the current user session.

**Header:**

* `Authorization`: `Bearer {token}` 

**Response:**

```json
{
  "message": "User loggedout"
}
```
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
  "morning_reminder": "string (required HH:MM 12hr)",
  "evening_reminder": "string (required HH:MM 12hr)"
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



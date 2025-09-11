# Push Notification Guide for Frontend Developers

This document outlines the different types of push notifications sent by the backend and how the Flutter application should handle them. Our system uses Firebase Cloud Messaging (FCM) to deliver notifications.

## Handling Notifications

Each push notification contains a `data` payload with a `type` field. Your app should use this `type` to identify the notification and decide what action to take when the user interacts with it.

Here is a summary of the notification types:

| Notification Type     | `data.type` | Trigger                               | Recommended Frontend Action                  |
| --------------------- | ----------- | ------------------------------------- | -------------------------------------------- |
| **Welcome**           | `welcome`   | User enables notifications            | Display the notification                     |
| **Daily Motivation**  | `daily`     | User's scheduled morning/evening time | Open the app's main dashboard/home screen    |
| **New Daily Challenge** | `challenge` | Once daily when a new challenge is set  | Navigate to the daily challenge screen       |

---

## Notification Types in Detail

### 1. Welcome Notification

This notification is sent once, immediately after a user successfully enables push notifications in the app.

- **Event:** User enables notifications.
- **Payload Example:**
  ```json
  {
    "title": "Welcome to Yefe Daily!",
    "body": "Your notification preferences have been saved.",
    "data": {
      "type": "welcome"
    }
  }
  ```
- **Frontend Action:** No specific in-app navigation is required. This is purely informational. You should simply display the notification to the user.

### 2. Daily Motivation

These notifications are sent at the morning and evening times specified by the user in their preferences. The message body contains a random motivational quote.

- **Event:** A scheduled job that runs at the user's chosen morning and evening times.
- **Payload Example:**
  ```json
  {
    "title": "Daily Motivation",
    "body": "Believe you can and you're halfway there.",
    "data": {
      "type": "daily"
    }
  }
  ```
- **Frontend Action:** When the user taps this notification, it is recommended to open the app to the main dashboard or home screen.

### 3. New Daily Challenge

This notification is sent to all users once a day when a new daily challenge becomes available.

- **Event:** A scheduled job that runs once daily.
- **Payload Example:**
  ```json
  {
    "title": "New Daily Challenge!",
    "body": "Today's challenge is: The 5-Minute Journal",
    "data": {
      "type": "challenge"
    }
  }
  ```
- **Frontend Action:** When the user taps this notification, you should navigate them directly to the new daily challenge screen within the app so they can view and complete it.

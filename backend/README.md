# Yefe App – API Documentation

Backend API for the **Yefe App**, a journaling and self-growth application.  
This API handles authentication, journaling, puzzles, challenges, songs, and user management.

---

## 📌 Routes Overview

| Method | Path                   | Description                          | Anchor |
|--------|------------------------|--------------------------------------|--------|
| POST   | `/auth/login`         | User login                           | [→](#post-authlogin) |
| POST   | `/auth/register`      | User registration                    | [→](#post-authregister) |
| POST   | `/auth/logout`        | User logout (auth required)          | [→](#post-authlogout) |
| POST   | `/auth/accept`        | Accept notifications (auth required) | [→](#post-authaccept) |
| POST   | `/accept-invitation`  | Accept admin invitation              | [→](#post-accept-invitation) |
| POST   | `/webhooks/stripe`    | Stripe webhook endpoint              | [→](#post-webhooksstripe) |
| POST   | `/webhooks/paystack`  | Paystack webhook endpoint            | [→](#post-webhookspaystack) |
| MOUNT  | `/journal`            | Journal operations                   | [→](#journal-routes) |
| MOUNT  | `/puzzle`             | Puzzle interactions                  | [→](#puzzle-routes) |
| MOUNT  | `/challenges`         | Daily/weekly challenges              | [→](#challenges-routes) |
| MOUNT  | `/songs`              | Song preferences and mood            | [→](#songs-routes) |
| MOUNT  | `/payments`           | Payment-related routes               | [→](#payments-routes) |
| POST   | `/payments/upgrade`   | Admin-only: Upgrade user package     | [→](#post-paymentsupgrade) |
| MOUNT  | `/events`             | Admin-only: User activity tracking   | [→](#events-routes) |
| MOUNT  | `/admin`              | Admin-only: User management          | [→](#admin-routes) |
| MOUNT  | `/dashboard`          | Admin-only: Stats and dashboards     | [→](#dashboard-routes) |

---


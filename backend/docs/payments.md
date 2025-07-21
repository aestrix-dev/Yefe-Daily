# Payments API Documentation

This document provides documentation for the payments-related API endpoints.

## Base Path

All endpoints are prefixed with `/v1`.

---

## Payment Management

### Create Payment Intent

- **Endpoint:** `POST /v1/payments/intent`
- **Description:** Creates a payment intent for a user.
- **Headers:**
    - `X-Payment-Provider` (string, required): The payment provider to use. Can be `stripe` or `paystack`.
- **Request Body:**
    ```json
    {
        "payment_method": "card"
    }
    ```
- **Successful Response (201 Created):**
    ```json
    {
        "message": "Payment intent created",
        "data": {
            "payment_id": "pi_12345",
            "client_secret": "pi_12345_secret_67890",
            "payment_ref": "ref_123",
            "payment_url": "https://checkout.provider.com/pay/123",
            "amount": 1000,
            "currency": "usd",
            "status": "requires_payment_method"
        }
    }
    ```

### Confirm Payment

- **Endpoint:** `POST /v1/payments/verify`
- **Description:** Confirms a payment after the user has completed the payment flow.
- **Headers:**
    - `X-Payment-Provider` (string, required): The payment provider to use. Can be `stripe` or `paystack`.
- **Request Body:**
    ```json
    {
        "payment_id": "pi_12345",
        "payment_intent_id": "pi_12345"
    }
    ```
- **Successful Response (200 OK):**
    ```json
    {
        "message": "Payment confirmed",
        "data": {
            "payment_id": "pi_12345",
            "status": "succeeded",
            "processed_at": "2025-07-21T12:00:00Z",
            "message": "Payment successful"
        }
    }
    ```

### Get Payment History

- **Endpoint:** `GET /v1/payments/history/{user_id}`
- **Description:** Retrieves the payment history for a specific user.
- **Path Parameters:**
    - `user_id` (integer, required): The ID of the user to retrieve payment history for.
- **Query Parameters:**
    - `page` (integer, optional, default: 1): The page number for pagination.
    - `limit` (integer, optional, default: 10): The number of payments to return per page.
- **Successful Response (200 OK):**
    ```json
    {
        "message": "Payment history",
        "data": {
            "payments": [
                {
                    "id": "pay_123",
                    "amount": 1000,
                    "currency": "usd",
                    "status": "succeeded",
                    "payment_intent_id": "pi_12345",
                    "payment_method": "card",
                    "processed_at": "2025-07-21T12:00:00Z",
                    "created_at": "2025-07-21T11:55:00Z",
                    "updated_at": "2025-07-21T12:00:00Z"
                }
            ],
            "total": 1,
            "page": 1,
            "limit": 10
        }
    }
    ```

### Upgrade Package (Admin)

- **Endpoint:** `POST /v1/payments/upgrade`
- **Description:** Upgrades a user's package (Admin only).
- **Headers:**
    - `X-Payment-Provider` (string, required): The payment provider to use. Can be `stripe` or `paystack`.
- **Request Body:**
    ```json
    {
        "user_id": "user_123"
    }
    ```
- **Successful Response (201 Created):**
    ```json
    {
        "message": "Plan Upgrade",
        "data": {
            "payment_id": "pi_67890",
            "client_secret": "pi_67890_secret_12345",
            "amount": 5000,
            "message": "Upgrade successful"
        }
    }
    ```

---

## Webhooks

### Stripe Webhook

- **Endpoint:** `POST /v1/webhooks/stripe`
- **Description:** Handles webhook events from Stripe.
- **Headers:**
    - `Stripe-Signature` (string, required): The signature from the Stripe webhook event.
- **Request Body:** The raw request body from Stripe.
- **Successful Response:** `200 OK`

### Paystack Webhook

- **Endpoint:** `POST /v1/webhooks/paystack`
- **Description:** Handles webhook events from Paystack.
- **Headers:**
    - `X-Paystack-Signature` (string, required): The signature from the Paystack webhook event.
- **Request Body:** The raw request body from Paystack.
- **Successful Response:** `200 OK`
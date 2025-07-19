package dto

import (
	"time"
)

type Payment struct {
	ID              string     `json:"id"`
	Amount          int64      `json:"amount"`
	Currency        string     `json:"currency"`
	Status          string     `json:"status"`
	PaymentIntentID string     `json:"payment_intent_id"`
	PaymentMethod   string     `json:"payment_method"`
	ProcessedAt     *time.Time `json:"processed_at"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}
type CreatePaymentIntentRequest struct {
	UserID        string `json:"-"`
	PaymentMethod string `json:"payment_method"`
}

type CreatePaymentIntentResponse struct {
	PaymentID    string `json:"payment_id"`
	ClientSecret string `json:"client_secret"`
	PaymentRef   string `json:"payment_ref,omitempty"`
	PaymentURL   string `json:"payment_url,omitempty"`
	Amount       int64  `json:"amount"`
	Currency     string `json:"currency"`
	Status       string `json:"status"`
}

type ConfirmPaymentRequest struct {
	PaymentID       string `json:"payment_id" binding:"required"`
	PaymentIntentID string `json:"payment_intent_id" binding:"required"`
}

type ConfirmPaymentResponse struct {
	PaymentID   string    `json:"payment_id"`
	Status      string    `json:"status"`
	ProcessedAt time.Time `json:"processed_at"`
	Message     string    `json:"message"`
}

type UpgradePackageRequest struct {
	UserID string `json:"user_id" binding:"required"`
}

type UpgradePackageResponse struct {
	PaymentID    string `json:"payment_id"`
	ClientSecret string `json:"client_secret"`
	Amount       int64  `json:"amount"`
	Message      string `json:"message"`
}

type PaymentHistoryResponse struct {
	Payments []Payment `json:"payments"`
	Total    int64     `json:"total"`
	Page     int       `json:"page"`
	Limit    int       `json:"limit"`
}

type WebhookRequest struct {
	Provider  string         `json:"provider"`
	Event     string         `json:"event"`
	Type      string         `json:"type"`
	Data      map[string]any `json:"data"`
	Signature string         `json:"signature,omitempty"`
	Body      []byte         `json:"body,omitempty"`
}

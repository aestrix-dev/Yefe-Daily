package dto

import (
	"time"
	"yefe_app/v1/internal/domain"
)

type CreatePaymentIntentRequest struct {
	UserID        uint   `json:"user_id" binding:"required"`
	ToPackageID   uint   `json:"to_package_id" binding:"required"`
	PaymentMethod string `json:"payment_method"`
}

type CreatePaymentIntentResponse struct {
	PaymentID    string `json:"payment_id"`
	ClientSecret string `json:"client_secret"`
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
	UserID      uint `json:"user_id" binding:"required"`
	ToPackageID uint `json:"to_package_id" binding:"required"`
}

type UpgradePackageResponse struct {
	PaymentID    string `json:"payment_id"`
	ClientSecret string `json:"client_secret"`
	Amount       int64  `json:"amount"`
	Message      string `json:"message"`
}

type PaymentHistoryResponse struct {
	Payments []domain.Payment `json:"payments"`
	Total    int64            `json:"total"`
	Page     int              `json:"page"`
	Limit    int              `json:"limit"`
}

type WebhookRequest struct {
	Type string                 `json:"type"`
	Data map[string]interface{} `json:"data"`
}

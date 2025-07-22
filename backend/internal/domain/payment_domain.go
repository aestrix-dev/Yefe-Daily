package domain

import (
	"context"
	"time"
	"yefe_app/v1/internal/handlers/dto"
)

type Payment struct {
	ID              string     `json:"id"`
	UserID          string     `json:"user_id"`
	Amount          int64      `json:"amount"`
	Currency        string     `json:"currency"`
	Status          string     `json:"status"`
	PaymentIntentID string     `json:"payment_intent_id"`
	PaymentMethod   string     `json:"payment_method"`
	ProcessedAt     *time.Time `json:"processed_at"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}
type PaymentProviderClient interface {
	InitializeTransaction(ctx context.Context, req dto.PaystackInitializeRequest) (*dto.PaystackInitializeResponse, error)
	VerifyTransaction(ctx context.Context, reference string) (*dto.PaystackVerifyResponse, error)
	ValidateWebhook(body []byte, signature string) bool
}
type PaymentRepository interface {
	CreatePayment(ctx context.Context, payment *Payment) error
	GetPaymentByID(ctx context.Context, id string) (*Payment, error)
	UpdatePayment(ctx context.Context, payment *Payment) error
	GetPaymentsByUserID(ctx context.Context, userID uint, page, limit int) ([]Payment, error)
	GetPaymentByPaymentIntentID(ctx context.Context, paymentIntentID string) (*Payment, error)
}

// ============= USE CASE =============

type PaymentUseCase interface {
	GetPaymentHistory(ctx context.Context, userID uint, page, limit int) (dto.PaymentHistoryResponse, error)
}

type PaymentProvider interface {
	CreatePaymentIntent(ctx context.Context, req dto.CreatePaymentIntentRequest) (dto.CreatePaymentIntentResponse, error)
	ConfirmPayment(ctx context.Context, req dto.ConfirmPaymentRequest) (dto.ConfirmPaymentResponse, error)
	UpgradePackage(ctx context.Context, req dto.UpgradePackageRequest) (dto.UpgradePackageResponse, error)
	ProcessWebhook(ctx context.Context, req dto.WebhookRequest) error
}

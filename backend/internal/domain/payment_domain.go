package domain

import (
	"context"
	"time"
	"yefe_app/v1/internal/handlers/dto"
)

type Payment struct {
	ID               string     `json:"id"`
	UserID           uint       `json:"user_id"`
	Amount           int64      `json:"amount"`
	Currency         string     `json:"currency"`
	Status           string     `json:"status"`
	PaymentIntentID  string     `json:"payment_intent_id"`
	StripeCustomerID string     `json:"stripe_customer_id"`
	PaymentMethod    string     `json:"payment_method"`
	ProcessedAt      *time.Time `json:"processed_at"`
	CreatedAt        time.Time  `json:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at"`
}

type UserSubscription struct {
	ID          uint      `json:"id"`
	UserID      uint      `json:"user_id"`
	PackageID   uint      `json:"package_id"`
	Status      string    `json:"status"`
	StartDate   time.Time `json:"start_date"`
	EndDate     time.Time `json:"end_date"`
	StripeSubID string    `json:"stripe_subscription_id"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}
type PaymentRepository interface {
	CreatePayment(ctx context.Context, payment *Payment) error
	GetPaymentByID(ctx context.Context, id string) (*Payment, error)
	UpdatePayment(ctx context.Context, payment *Payment) error
	GetPaymentsByUserID(ctx context.Context, userID uint, page, limit int) ([]Payment, error)
	GetUserSubscription(ctx context.Context, userID uint) (*UserSubscription, error)
	CreateOrUpdateSubscription(ctx context.Context, subscription UserSubscription) error
}

// ============= USE CASE =============

type PaymentUseCase interface {
	CreatePaymentIntent(ctx context.Context, req dto.CreatePaymentIntentRequest) (dto.CreatePaymentIntentResponse, error)
	ConfirmPayment(ctx context.Context, req dto.ConfirmPaymentRequest) (dto.ConfirmPaymentResponse, error)
	UpgradePackage(ctx context.Context, req dto.UpgradePackageRequest) (dto.UpgradePackageResponse, error)
	GetPaymentHistory(ctx context.Context, userID uint, page, limit int) (dto.PaymentHistoryResponse, error)
	ProcessWebhook(ctx context.Context, req dto.WebhookRequest) error
}
